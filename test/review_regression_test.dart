import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klinex/klinex.dart';

List<Bar> _bars(int n, {double base = 100, double step = 0}) => [
  for (var i = 0; i < n; i++)
    Bar(
      time: 1700000000000 + i * 60000,
      open: base + i * step,
      high: base + i * step + 4 * (step == 0 ? 1 : step),
      low: base + i * step - 2 * (step == 0 ? 1 : step),
      close: base + i * step + (step == 0 ? 1 : step),
      vol: 10,
    ),
];

ChartConfig _config() => ChartConfig(
  theme: KLineTheme.light(),
  priceFormatter: (v) => v.toStringAsFixed(2),
  timeFormatter: (ms) => '$ms',
);

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

Widget _app(Widget child) => MaterialApp(
  home: Center(child: SizedBox(width: 400, height: 400, child: child)),
);

void main() {
  GestureCoordinator coordinator(ChartController c, AnimationController fling) {
    const size = Size(400, 400);
    c.resolveLayout(size, _config());
    return GestureCoordinator(
      controller: c,
      resolve: () => c.resolveLayout(size, _config()),
      fling: fling,
    );
  }

  testWidgets('a drag whose end never came does not block long press on the next touch', (
    tester,
  ) async {
    final c = ChartController()..setBars(_bars(300));
    final fling = AnimationController.unbounded(vsync: const TestVSync());
    final g = coordinator(c, fling)
      ..onPointerDown()
      ..onHPanStart(DragStartDetails())
      ..onPointerUp();
    g
      ..onPointerDown()
      ..onLongPressStart(const LongPressStartDetails(localPosition: Offset(200, 200)));
    expect(c.crosshair.value, isNotNull);
    g.dispose();
    fling.dispose();
    c.dispose();
  });

  testWidgets('a cancel of one finger does not swallow the fling of the next pan', (tester) async {
    final c = ChartController()..setBars(_bars(3000));
    final fling = AnimationController.unbounded(vsync: const TestVSync());
    final g = coordinator(c, fling);
    c.viewport.scroll(8000);
    g
      ..onPointerDown()
      ..onPointerDown()
      ..onPointerCancelled()
      ..onHPanStart(DragStartDetails())
      ..onHPanEnd(DragEndDetails(velocity: const Velocity(pixelsPerSecond: Offset(3000, 0))));
    expect(fling.isAnimating, isTrue);
    g.dispose();
    fling.dispose();
    c.dispose();
  });

  testWidgets('shift + vertical wheel scrolls horizontally', (tester) async {
    final c = ChartController()..setBars(_bars(300));
    await tester.pumpWidget(_app(KChart(controller: c, theme: KLineTheme.light())));
    await tester.pumpAndSettle();
    c.viewport.scroll(400);
    final r0 = c.viewport.rightIndex;
    final w0 = c.viewport.barWidth;
    final p = tester.getCenter(find.byType(KChart));
    await simulateKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    try {
      await tester.sendEventToBinding(
        PointerScrollEvent(position: p, scrollDelta: const Offset(0, 80)),
      );
    } finally {
      await simulateKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    }
    await tester.pump();
    expect(c.viewport.barWidth, w0);
    expect(c.viewport.rightIndex, isNot(r0));
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });

  testWidgets('in drawing mode a mouse click with a 1.5px jitter is still a tap', (tester) async {
    final c = ChartController()..setBars(_bars(300));
    final mode = _ExclusiveMode();
    await tester.pumpWidget(_app(KChart(controller: c, theme: KLineTheme.light(), mode: mode)));
    await tester.pumpAndSettle();
    final g = await tester.startGesture(
      tester.getCenter(find.byType(KChart)),
      kind: PointerDeviceKind.mouse,
    );
    await g.moveBy(const Offset(1.5, 0));
    await g.up();
    await tester.pump(const Duration(milliseconds: 500));
    expect(mode.updates, isEmpty);
    expect(mode.taps, 1);
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });

  testWidgets('removing the chart does not rebuild crosshair listeners while the tree is locked', (
    tester,
  ) async {
    final c = ChartController()..setBars(_bars(300));
    Widget host({required bool chart}) => _app(
      Column(
        children: [
          ValueListenableBuilder<CrosshairState?>(
            valueListenable: c.crosshair,
            builder: (_, v, _) => Text(v == null ? 'none' : 'on'),
          ),
          if (chart)
            Expanded(
              child: KChart(controller: c, theme: KLineTheme.light()),
            ),
        ],
      ),
    );
    await tester.pumpWidget(host(chart: true));
    await tester.pump();
    c.crosshair.value = CrosshairState(time: c.bars[50].time, position: const Offset(100, 100));
    await tester.pump();
    await tester.pumpWidget(host(chart: false));
    expect(tester.takeException(), isNull);
    await tester.pump();
    expect(c.crosshair.value, isNull);
    expect(find.text('none'), findsOneWidget);
    c.dispose();
  });

  testWidgets('the default price format keeps 4 significant digits between 1 and 10', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final c = ChartController()..setBars(_bars(100, base: 1.2, step: 0.001));
    await tester.pumpWidget(_app(KChart(controller: c, theme: KLineTheme.light())));
    await tester.pump();
    expect(find.bySemanticsLabel(RegExp(c.bars.last.close.toStringAsFixed(3))), findsOneWidget);
    semantics.dispose();
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });

  testWidgets('a user jump elsewhere stops a running fling', (tester) async {
    final c = ChartController()..setBars(_bars(3000));
    final fling = AnimationController.unbounded(vsync: const TestVSync());
    final g = coordinator(c, fling);
    c.viewport.scroll(8000);
    g.onHPanEnd(DragEndDetails(velocity: const Velocity(pixelsPerSecond: Offset(3000, 0))));
    await tester.pump(const Duration(milliseconds: 50));
    expect(fling.isAnimating, isTrue);
    c.viewport.scrollToLatest();
    final r = c.viewport.rightIndex;
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));
    expect(fling.isAnimating, isFalse);
    expect(c.viewport.rightIndex, r);
    g.dispose();
    fling.dispose();
    c.dispose();
  });
}
