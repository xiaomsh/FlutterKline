import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klinex/klinex.dart';
import 'package:klinex/src/widget/chart_keys.dart';

List<Bar> _bars(int n) => [
  for (var i = 0; i < n; i++)
    Bar(
      time: 1700000000000 + i * 60000,
      open: 100.0 + i % 7,
      high: 104.0 + i % 7,
      low: 98.0 + i % 5,
      close: 101.0 + i % 9,
      vol: 10,
    ),
];

ChartConfig _config({YAxisPosition axis = YAxisPosition.inside}) => ChartConfig(
  theme: KLineTheme.light(),
  priceFormatter: (v) => v.toStringAsFixed(2),
  timeFormatter: (ms) => '$ms',
  yAxisPosition: axis,
);

class _FakeVsync implements TickerProvider {
  @override
  Ticker createTicker(TickerCallback onTick) => Ticker(onTick);
}

/// Always exclusive; records received drags
class _ExclusiveMode extends InteractionMode {
  final updates = <Offset>[];
  var taps = 0;

  @override
  bool get exclusive => true;

  @override
  void onDragUpdate(Offset p, RenderContext ctx) => updates.add(p);

  @override
  void onTapUp(Offset p, RenderContext ctx) => taps++;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  GestureCoordinator coordinator(ChartController c, ChartConfig config) {
    const size = Size(400, 400);
    c.resolveLayout(size, config);
    return GestureCoordinator(
      controller: c,
      resolve: () => c.resolveLayout(size, config),
      fling: AnimationController.unbounded(vsync: _FakeVsync()),
    );
  }

  test('with the y axis on the left, wheel and pinch keep the bar under the cursor', () {
    final c = ChartController()..setBars(_bars(300));
    final config = _config(axis: YAxisPosition.left);
    final g = coordinator(c, config);
    final ctx0 = g.resolve();
    expect(ctx0.chartRect.left, greaterThan(0));
    const p = Offset(150, 200);
    final before = ctx0.indexAt(p.dx);
    g.onWheel(p, -200);
    expect(g.resolve().indexAt(p.dx), closeTo(before, 0.5));

    final mid = g.resolve().indexAt(p.dx);
    g
      ..onScaleStart(ScaleStartDetails(localFocalPoint: p, pointerCount: 2))
      ..onScaleUpdate(ScaleUpdateDetails(localFocalPoint: p, pointerCount: 2, scale: 1.4));
    expect(g.resolve().indexAt(p.dx), closeTo(mid, 0.5));
    c.dispose();
  });

  test('horizontal wheel scrolls instead of being swallowed', () {
    final c = ChartController()..setBars(_bars(300));
    final g = coordinator(c, _config());
    c.viewport.scroll(400);
    final r0 = c.viewport.rightIndex;
    g.onWheel(const Offset(200, 200), 0, scrollDeltaX: 80);
    expect(c.viewport.rightIndex, greaterThan(r0));
    c.dispose();
  });

  test('a mouse press keeps the hover crosshair; a touch press clears a stale one', () {
    final c = ChartController()..setBars(_bars(300));
    final g = coordinator(c, _config())..onHover(const Offset(200, 200));
    expect(c.crosshair.value, isNotNull);
    g
      ..onPointerDown(kind: PointerDeviceKind.mouse)
      ..onTapUp(
        TapUpDetails(
          kind: PointerDeviceKind.mouse,
          localPosition: const Offset(200, 200),
          globalPosition: const Offset(200, 200),
        ),
      )
      ..onPointerUp();
    expect(c.crosshair.value, isNotNull);
    g.onPointerDown();
    expect(c.crosshair.value, isNull);
    c.dispose();
  });

  testWidgets('a fling stops once it is below a few px/s instead of crawling for seconds', (
    tester,
  ) async {
    final c = ChartController()..setBars(_bars(3000));
    final fling = AnimationController.unbounded(vsync: const TestVSync());
    final g = GestureCoordinator(
      controller: c,
      resolve: () => c.resolveLayout(const Size(400, 400), _config()),
      fling: fling,
    );
    c.resolveLayout(const Size(400, 400), _config());
    c.viewport.scroll(8000);
    g.onHPanEnd(DragEndDetails(velocity: const Velocity(pixelsPerSecond: Offset(3000, 0))));
    expect(fling.isAnimating, isTrue);
    for (var i = 0; i < 50; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(c.viewport.atBoundary, isFalse);
    expect(fling.isAnimating, isFalse);
    g.dispose();
    fling.dispose();
    c.dispose();
  });

  test('modifier shortcuts and drawing mode leave the viewport alone', () async {
    final c = ChartController()..setBars(_bars(300));
    c.viewport.attach(400);
    final r0 = c.viewport.rightIndex;
    const left = KeyDownEvent(
      physicalKey: PhysicalKeyboardKey.arrowLeft,
      logicalKey: LogicalKeyboardKey.arrowLeft,
      timeStamp: Duration.zero,
    );
    expect(handleChartKey(left, c, exclusive: true), KeyEventResult.ignored);
    expect(c.viewport.rightIndex, r0);

    await simulateKeyDownEvent(LogicalKeyboardKey.metaLeft);
    try {
      expect(handleChartKey(left, c), KeyEventResult.ignored);
    } finally {
      await simulateKeyUpEvent(LogicalKeyboardKey.metaLeft);
    }
    expect(c.viewport.rightIndex, r0);
    expect(handleChartKey(left, c), KeyEventResult.handled);
    c.dispose();
  });

  group('on a widget', () {
    late ChartController c;

    setUp(() => c = ChartController()..setBars(_bars(300)));
    tearDown(() => c.dispose());

    testWidgets('a system cancel mid order-line drag does not call onDrop', (tester) async {
      final drops = <double>[];
      final drag = LevelDragController(onDrop: (_, p) => drops.add(p));
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SizedBox(
              width: 400,
              height: 400,
              child: KChart(
                controller: c,
                theme: KLineTheme.light(),
                levelDrag: drag,
                animateRange: false,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final ctx = c.resolveLayout(const Size(400, 400), _config(axis: YAxisPosition.outside));
      final price = ctx.mainPanel.valueOf(ctx.mainPanel.rect.center.dy);
      drag.levels = [DraggableLevel(id: 'o', price: price)];
      final origin = tester.getTopLeft(find.byType(KChart));
      final g = await tester.startGesture(origin + Offset(150, ctx.mainPanel.yOf(price)));
      await g.moveBy(const Offset(0, -50));
      await tester.pump();
      expect(drag.isDragging, isTrue);
      await g.cancel();
      await tester.pump();
      expect(drops, isEmpty);
      expect(drag.isDragging, isFalse);
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('in drawing mode a 600ms hold then drag still reaches the mode', (tester) async {
      final mode = _ExclusiveMode();
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SizedBox(
              width: 400,
              height: 400,
              child: KChart(controller: c, theme: KLineTheme.light(), mode: mode),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final g = await tester.startGesture(tester.getCenter(find.byType(KChart)));
      await tester.pump(const Duration(milliseconds: 600));
      await g.moveBy(const Offset(40, 0));
      await g.moveBy(const Offset(40, 0));
      await tester.pump();
      expect(mode.updates, isNotEmpty);
      await g.up();
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('in drawing mode a vertical drag inside a ListView goes to the mode', (
      tester,
    ) async {
      final mode = _ExclusiveMode();
      final scroll = ScrollController();
      await tester.pumpWidget(
        MaterialApp(
          home: ListView(
            controller: scroll,
            children: [
              SizedBox(
                height: 400,
                child: KChart(controller: c, theme: KLineTheme.light(), mode: mode),
              ),
              const SizedBox(height: 1200),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      final g = await tester.startGesture(tester.getCenter(find.byType(KChart)));
      for (var i = 0; i < 8; i++) {
        await g.moveBy(const Offset(0, -6));
        await tester.pump();
      }
      await g.up();
      await tester.pump();
      expect(scroll.offset, 0);
      expect(mode.updates, isNotEmpty);
      scroll.dispose();
    });

    testWidgets('a second finger double tap while panning does not reset the y scale', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SizedBox(
              width: 400,
              height: 400,
              child: KChart(controller: c, theme: KLineTheme.light()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      c.viewport.zoomY(1.5);
      final center = tester.getCenter(find.byType(KChart));
      final g = await tester.startGesture(center);
      await g.moveBy(const Offset(40, 0));
      await g.moveBy(const Offset(40, 0));
      await tester.pump();
      final other = center + const Offset(-100, 50);
      await tester.tapAt(other);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tapAt(other);
      await tester.pump();
      expect(c.viewport.yScale, 1.5);
      await g.up();
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('a trackpad vertical swipe scrolls the page, not a stale panel resize', (
      tester,
    ) async {
      final scroll = ScrollController();
      final config = _config(axis: YAxisPosition.outside);
      c.dispose();
      c = ChartController(indicators: [Vol()])..setBars(_bars(300));
      await tester.pumpWidget(
        MaterialApp(
          home: ListView(
            controller: scroll,
            children: [
              SizedBox(
                height: 400,
                child: KChart(
                  controller: c,
                  theme: KLineTheme.light(),
                  panelResizable: true,
                ),
              ),
              const SizedBox(height: 1200),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      final origin = tester.getTopLeft(find.byType(KChart));
      final ctx = c.resolveLayout(const Size(800, 400), config);
      final split = origin + Offset(100, ctx.panels.first.rect.bottom);
      final mouse = await tester.startGesture(split, kind: PointerDeviceKind.mouse);
      await mouse.moveBy(const Offset(0, -20));
      await mouse.moveBy(const Offset(0, -20));
      await mouse.up();
      await tester.pump();

      final pad = await tester.createGesture(kind: PointerDeviceKind.trackpad);
      await pad.panZoomStart(origin + const Offset(100, 100));
      for (var i = 1; i <= 8; i++) {
        await pad.panZoomUpdate(origin + const Offset(100, 100), pan: Offset(0, -10.0 * i));
        await tester.pump();
      }
      await pad.panZoomEnd();
      await tester.pumpAndSettle();
      expect(scroll.offset, greaterThan(0));
      scroll.dispose();
    });
  });
}
