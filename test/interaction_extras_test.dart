import 'dart:convert';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klinex/klinex.dart';

/// Crosshair snapping, axis-strip drag zoom, keyboard, full state save/restore

const t0 = 1700000000000;

List<Bar> bars(int n) => [
  for (var i = 0; i < n; i++)
    Bar(
      time: t0 + i * 60000,
      open: 100.0 + i % 7,
      high: 110.0 + i % 7,
      low: 90.0 + i % 5,
      close: 102.0 + i % 9,
      vol: 10,
    ),
];

ChartConfig config({CrosshairSnap snap = CrosshairSnap.free, bool axisDragScale = false}) =>
    ChartConfig(
      theme: KLineTheme.light(),
      priceFormatter: (v) => '$v',
      timeFormatter: (ms) => '$ms',
      yAxisPosition: YAxisPosition.outside,
      crosshairSnap: snap,
      axisDragScale: axisDragScale,
    );

class _Gestures {
  _Gestures(this.cfg) {
    c = ChartController(defaultOverlays: false)..setBars(bars(200));
    fling = AnimationController.unbounded(vsync: const TestVSync());
    g = GestureCoordinator(controller: c, resolve: () => ctx, fling: fling);
  }

  final ChartConfig cfg;
  late final ChartController c;
  late final AnimationController fling;
  late final GestureCoordinator g;

  RenderContext get ctx => c.resolveLayout(const Size(456, 322), cfg);

  void dispose() {
    g.dispose();
    fling.dispose();
    c.dispose();
  }
}

class _Memo extends OverlayPlugin {
  String note = '';

  @override
  String? get stateKey => 'memo';

  @override
  Map<String, dynamic>? saveState() => {'note': note};

  @override
  void restoreState(Map<String, dynamic> state) => note = state['note'] as String;

  @override
  List<Listenable> repaintOn(ChartController controller) => const [];

  @override
  void paint(Canvas canvas, RenderContext ctx) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('crosshair snap: follow finger / close / nearest OHLC', () {
    for (final snap in CrosshairSnap.values) {
      final t = _Gestures(config(snap: snap));
      final ctx = t.ctx;
      final p = Offset(200, ctx.mainPanel.rect.top + 30);
      t.g.setCrosshair(p);
      final bar = t.c.bars[ctx.barIndexAt(p.dx)];
      final y = t.c.crosshair.value!.position.dy;
      switch (snap) {
        case CrosshairSnap.free:
          expect(y, p.dy);
        case CrosshairSnap.close:
          expect(y, ctx.mainPanel.yOf(bar.close));
        case CrosshairSnap.ohlc:
          final ys = [bar.open, bar.high, bar.low, bar.close].map(ctx.mainPanel.yOf);
          final nearest = ys.reduce((a, b) => (a - p.dy).abs() <= (b - p.dy).abs() ? a : b);
          expect(y, nearest);
      }
      t.dispose();
    }
  });

  test('snapping only applies to the main pane: on the time axis it still follows the finger', () {
    final t = _Gestures(config(snap: CrosshairSnap.close));
    final p = Offset(200, t.ctx.timeAxisRect.top + 5);
    t.g.setCrosshair(p);
    expect(t.c.crosshair.value!.position, p);
    t.dispose();
  });

  test('vertical drag on the price axis zooms y; not claimed when disabled', () {
    final on = _Gestures(config(axisDragScale: true));
    final p = Offset(on.ctx.yAxisRect.left + 10, on.ctx.mainPanel.rect.center.dy);
    expect(on.g.wantsVertical(p), isTrue);
    on.g.onVPanStart(DragStartDetails(localPosition: p));
    on.g.onVPanUpdate(DragUpdateDetails(globalPosition: p, delta: const Offset(0, -40)));
    expect(on.c.viewport.yScale, greaterThan(1));
    on.dispose();

    final off = _Gestures(config());
    expect(off.g.wantsVertical(p), isFalse);
    off.dispose();
  });

  test('horizontal drag on the time axis zooms x, without panning or flinging', () {
    final t = _Gestures(config(axisDragScale: true));
    final before = t.c.viewport.barWidth;
    final p = Offset(200, t.ctx.timeAxisRect.top + 5);
    t.g.onHPanStart(DragStartDetails(localPosition: p));
    t.g.onHPanUpdate(DragUpdateDetails(globalPosition: p, delta: const Offset(30, 0)));
    expect(t.c.viewport.barWidth, greaterThan(before));
    t.g.onHPanEnd(DragEndDetails(velocity: const Velocity(pixelsPerSecond: Offset(3000, 0))));
    expect(t.fling.isAnimating, isFalse);
    t.dispose();
  });

  testWidgets('after a mouse click, keys pan, zoom, and dismiss the crosshair', (tester) async {
    final c = ChartController()..setBars(bars(300));
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox(
            width: 400,
            height: 300,
            child: KChart(controller: c, theme: KLineTheme.light()),
          ),
        ),
      ),
    );
    final center = tester.getCenter(find.byType(KChart));
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: center);
    await gesture.down(center);
    await gesture.up();
    await tester.pump();

    final right = c.viewport.rightIndex;
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    expect(c.viewport.rightIndex, lessThan(right));

    final width = c.viewport.barWidth;
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    expect(c.viewport.barWidth, greaterThan(width));

    c.crosshair.value = CrosshairState(time: c.bars[100].time, position: Offset.zero);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    expect(c.crosshair.value, isNull);
    await gesture.removePointer();
    await tester.pump(const Duration(milliseconds: 500));
    c.dispose();
  });

  test('full state save/restore: indicators, zoom, maxBars, plugin state', () {
    final memo = _Memo()..note = 'hello';
    final a =
        ChartController(
            indicators: [
              Ma(periods: [5, 10]),
              Macd(short: 6),
            ],
            overlays: [memo],
          )
          ..setBars(bars(300))
          ..maxBars = 250;
    a.viewport
      ..attach(400)
      ..zoomAt(400, 1.5)
      ..zoomY(2);
    final json = jsonDecode(jsonEncode(a.saveState())) as Map<String, dynamic>;

    final memo2 = _Memo();
    final b = ChartController(overlays: [memo2])..setBars(bars(300));
    b.viewport.attach(400);
    b.restoreState(json);
    expect([for (final i in b.indicators.list) i.id], [for (final i in a.indicators.list) i.id]);
    expect(b.viewport.barWidth, a.viewport.barWidth);
    expect(b.viewport.yScale, 2);
    expect(b.maxBars, 250);
    expect(b.bars.length, 250);
    expect(memo2.note, 'hello');
    a.dispose();
    b.dispose();
  });

  test('theme save/restore round trip loses no fields', () {
    final theme = KLineTheme.dark().copyWith(gridLineDash: [3, 2], axisTextSize: 12);
    final back = KLineTheme.fromJson(
      jsonDecode(jsonEncode(theme.toJson())) as Map<String, dynamic>,
    );
    expect(back.toJson(), theme.toJson());
  });
}
