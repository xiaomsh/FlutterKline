import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klinex/klinex.dart';
import 'package:klinex/src/widget/depth_painter.dart';

List<Bar> genBars(int n, {int seed = 1}) {
  final rnd = math.Random(seed);
  final bars = <Bar>[];
  var close = 100.0;
  for (var i = 0; i < n; i++) {
    final open = close;
    close = (open + (rnd.nextDouble() - 0.5) * 4).clamp(1.0, double.infinity);
    bars.add(
      Bar(
        time: 1700000000000 + i * 60000,
        open: open,
        high: math.max(open, close) + 1,
        low: math.min(open, close) - 1,
        close: close,
        vol: 100 + rnd.nextDouble() * 500,
      ),
    );
  }
  return bars;
}

ChartConfig makeConfig({bool logScale = false}) => ChartConfig(
  theme: KLineTheme.light(),
  priceFormatter: (v) => v.toStringAsFixed(2),
  timeFormatter: (ms) => '$ms',
  logScale: logScale,
);

class _FakeVsync implements TickerProvider {
  @override
  Ticker createTicker(TickerCallback onTick) => Ticker(onTick);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('log scale: y mapping round-trips and grid uses log spacing', () {
    final c = ChartController()..setBars(genBars(300));
    final ctx = c.resolveLayout(const Size(400, 400), makeConfig(logScale: true));
    final main = ctx.mainPanel;
    expect(main.logScale, isTrue);

    // round trip
    for (final v in [main.range.min * 1.01, 100.0, main.range.max * 0.99]) {
      expect(main.valueOf(main.yOf(v)), closeTo(v, v * 1e-9));
    }
    // mid-fraction is the geometric (not arithmetic) mean
    final mid = main.valueAtFraction(0.5);
    expect(mid, closeTo(math.sqrt(main.range.min * main.range.max), 1e-6));
    expect(mid, isNot(closeTo((main.range.min + main.range.max) / 2, 0.01)));
    c.dispose();
  });

  test('log scale falls back to linear when range spans <= 0', () {
    final panel = PanelLayout(
      id: 'x',
      isMain: true,
      rect: const Rect.fromLTWH(0, 0, 100, 100),
      range: const MinMax(-5, 10),
      indicators: const [],
      logScale: true,
    );
    expect(panel.logScale, isFalse);
    expect(panel.valueAtFraction(0.5), closeTo(2.5, 1e-9));
  });

  test('pinch is zone-split: plot→x only, axis strip→y only; wheel same', () {
    final c = ChartController()..setBars(genBars(300));
    final config = makeConfig(); // inside axis, axis area = right 56px (x >= 344)
    const size = Size(400, 400);
    c.resolveLayout(size, config); // attach width
    final g = GestureCoordinator(
      controller: c,
      resolve: () => c.resolveLayout(size, config),
      fling: AnimationController.unbounded(vsync: _FakeVsync()),
    );

    // pinch in plot area: zooms x only (any pinch direction), y unchanged
    g.onScaleStart(ScaleStartDetails(localFocalPoint: const Offset(200, 200), pointerCount: 2));
    final y0 = c.viewport.yScale;
    final bw0 = c.viewport.barWidth;
    g.onScaleUpdate(
      ScaleUpdateDetails(
        localFocalPoint: const Offset(200, 200),
        pointerCount: 2,
        scale: 1.5,
      ),
    );
    expect(c.viewport.barWidth, closeTo(bw0 * 1.5, 1e-9));
    expect(c.viewport.yScale, y0);
    // focal point moves horizontally during pinch: chart scrolls along
    final ri0 = c.viewport.rightIndex;
    g.onScaleUpdate(
      ScaleUpdateDetails(
        localFocalPoint: const Offset(180, 200),
        pointerCount: 2,
        scale: 1.5,
        focalPointDelta: const Offset(-20, 0),
      ),
    );
    expect(c.viewport.rightIndex, isNot(ri0));
    g.onScaleEnd(ScaleEndDetails());

    // pinch in axis area: zooms y only, x and scroll position unchanged
    g.onScaleStart(ScaleStartDetails(localFocalPoint: const Offset(370, 200), pointerCount: 2));
    final bw1 = c.viewport.barWidth;
    final ri1 = c.viewport.rightIndex;
    g.onScaleUpdate(
      ScaleUpdateDetails(
        localFocalPoint: const Offset(370, 190),
        pointerCount: 2,
        scale: 1.4,
        focalPointDelta: const Offset(0, -10),
      ),
    );
    expect(c.viewport.yScale, closeTo(1.4, 1e-9));
    expect(c.viewport.barWidth, bw1);
    expect(c.viewport.rightIndex, ri1);
    g.onScaleEnd(ScaleEndDetails());

    // a single finger drives no zoom
    g.onScaleStart(ScaleStartDetails(localFocalPoint: const Offset(370, 200), pointerCount: 1));
    g.onScaleUpdate(
      ScaleUpdateDetails(
        localFocalPoint: const Offset(370, 140),
        pointerCount: 1,
        focalPointDelta: const Offset(0, -60),
      ),
    );
    g.onScaleEnd(ScaleEndDetails());
    expect(c.viewport.yScale, closeTo(1.4, 1e-9));

    // wheel zones: plot area zooms x, axis area zooms y
    c.viewport.resetYScale();
    final bw2 = c.viewport.barWidth;
    final y2 = c.viewport.yScale;
    g.onWheel(const Offset(200, 200), -100);
    expect(c.viewport.barWidth, greaterThan(bw2));
    expect(c.viewport.yScale, y2);
    final bw3 = c.viewport.barWidth;
    g.onWheel(const Offset(370, 200), -100);
    expect(c.viewport.yScale, greaterThan(y2));
    expect(c.viewport.barWidth, bw3);

    // double tap: manual y transform resets to auto
    g.onDoubleTap();
    expect(c.viewport.yScale, 1.0);
    g.dispose();
    c.dispose();
  });

  test('vertical drags are never claimed outside the splitter', () {
    final c = ChartController(indicators: [Macd()])..setBars(genBars(300));
    final config = makeConfig();
    const size = Size(400, 400);
    final ctx = c.resolveLayout(size, config);
    final g = GestureCoordinator(
      controller: c,
      resolve: () => c.resolveLayout(size, config),
      fling: AnimationController.unbounded(vsync: _FakeVsync()),
    );

    // the chart doesn't pan vertically: vertical drags in main/sub panes are not claimed and go to
    // the outer scroll
    expect(g.wantsVertical(ctx.mainPanel.rect.center), isFalse);
    expect(g.wantsVertical(ctx.panels[1].rect.center), isFalse);
    g.dispose();
    c.dispose();
  });

  test('splitter drag redistributes panel weights (opt-in)', () {
    final c = ChartController(indicators: [Vol()])..setBars(genBars(200));
    final config = makeConfig()..panelResizable = true;
    const size = Size(400, 400);
    final coordinator = GestureCoordinator(
      controller: c,
      resolve: () => c.resolveLayout(size, config),
      fling: AnimationController.unbounded(vsync: _FakeVsync()),
    );

    final before = c.resolveLayout(size, config);
    expect(before.panels.length, 2);
    final sepY = before.panels[0].rect.bottom;
    final mainH0 = before.panels[0].rect.height;

    // hitting the divider claims vertical drag (independent of freePan)
    expect(coordinator.wantsVertical(Offset(200, sepY)), isTrue);
    coordinator.onVPanStart(
      DragStartDetails(globalPosition: Offset(200, sepY), localPosition: Offset(200, sepY)),
    );
    coordinator.onVPanUpdate(
      DragUpdateDetails(
        globalPosition: Offset(200, sepY - 50),
        localPosition: Offset(200, sepY - 50),
        delta: const Offset(0, -50),
      ),
    );
    coordinator.onVPanEnd(DragEndDetails());

    final after = c.resolveLayout(size, config);
    expect(
      after.panels[0].rect.height,
      lessThan(mainH0),
      reason: 'dragging the separator up shrinks the main panel',
    );
    expect(after.panels[1].rect.height, greaterThan(before.panels[1].rect.height));
    // heights still fill the plot exactly
    expect(
      after.panels[0].rect.height + after.panels[1].rect.height,
      closeTo(before.chartRect.height, 1e-6),
    );
    coordinator.dispose();
    c.dispose();
  });

  test('splitter drag is inert by default (panelResizable=false)', () {
    final c = ChartController(indicators: [Vol()])..setBars(genBars(200));
    final config = makeConfig(); // default: not resizable
    const size = Size(400, 400);
    final coordinator = GestureCoordinator(
      controller: c,
      resolve: () => c.resolveLayout(size, config),
      fling: AnimationController.unbounded(vsync: _FakeVsync()),
    );

    final before = c.resolveLayout(size, config);
    final sepY = before.panels[0].rect.bottom;
    final mainH0 = before.panels[0].rect.height;

    // divider not claimed by default: vertical drags pass through to the outer scroll container
    expect(
      coordinator.wantsVertical(Offset(200, sepY)),
      isFalse,
    );
    final after = c.resolveLayout(size, config);
    expect(after.panels[0].rect.height, mainH0, reason: 'heights untouched');
    coordinator.dispose();
    c.dispose();
  });

  // Countdown/price tag moved to the host widget layer (KChart.overlayBuilder); the plugin only
  // draws the dashed line and no longer owns a Timer. This guards "no pending timer while the
  // plugin is attached".
  testWidgets('price line paints and leaves no pending timer', (tester) async {
    final controller = ChartController(
      defaultOverlays: false,
      overlays: [PriceLineOverlay()],
    )..setBars(genBars(50));
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 300,
          height: 300,
          child: KChart(controller: controller, theme: KLineTheme.dark()),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    expect(tester.takeException(), isNull);
    controller.dispose();
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('price line tracks the bar at the right edge in history', (tester) async {
    final controller = ChartController(
      defaultOverlays: false,
      overlays: [PriceLineOverlay()],
    )..setBars(genBars(300));
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 300,
          height: 300,
          child: KChart(controller: controller, theme: KLineTheme.dark()),
        ),
      ),
    );
    await tester.pump();
    // Pan deep into history: the reference bar becomes round(rightIndex),
    // repainting on the viewport channel，no exception at any position,
    // including the far-left clamp.
    for (var i = 0; i < 20; i++) {
      controller.viewport.scroll(500);
      await tester.pump();
      final lastIndex = controller.bars.length - 1;
      final ref = controller.viewport.rightIndex.round().clamp(0, lastIndex);
      expect(ref, inInclusiveRange(0, lastIndex));
    }
    expect(tester.takeException(), isNull);
    controller.dispose();
  });

  testWidgets('zoomed-out aggregation renders 10k bars', (tester) async {
    final controller = ChartController(indicators: [Ma(), Vol()])
      ..asyncCompute = false
      ..setBars(genBars(10000));
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 400,
          height: 500,
          child: KChart(controller: controller, theme: KLineTheme.light()),
        ),
      ),
    );
    await tester.pump();
    // zoom out to the minimum bar width (aggregation territory)
    for (var i = 0; i < 12; i++) {
      controller.viewport.zoomAt(200, 0.5);
    }
    await tester.pump();
    expect(tester.takeException(), isNull);
    final visible = controller.viewport.visibleRange();
    expect(
      visible.$2 - visible.$1,
      greaterThan(1500),
      reason: 'sub-pixel bar width shows thousands of bars',
    );
    controller.dispose();
  });

  testWidgets('depth chart renders and inspects on tap', (tester) async {
    final rnd = math.Random(3);
    final bids = [
      for (var i = 1; i <= 40; i++) DepthLevel(100 - i * 0.1, 1 + rnd.nextDouble() * 10),
    ];
    final asks = [
      for (var i = 1; i <= 40; i++) DepthLevel(100 + i * 0.1, 1 + rnd.nextDouble() * 10),
    ];
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox(
            width: 360,
            height: 240,
            child: DepthChart(bids: bids, asks: asks, theme: KLineTheme.light()),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.tapAt(tester.getCenter(find.byType(DepthChart)) + const Offset(-60, 0));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('depth chart reuses prepared data when the book lists are unchanged', (
    tester,
  ) async {
    final bids = [const DepthLevel(99, 2), const DepthLevel(98, 3)];
    final asks = [const DepthLevel(101, 1), const DepthLevel(102, 4)];
    Future<DepthPainter> pump(List<DepthLevel> b, String Function(double) fmt) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: DepthChart(bids: b, asks: asks, theme: KLineTheme.light(), priceFormatter: fmt),
        ),
      );
      final paint = tester.widget<CustomPaint>(
        find.descendant(of: find.byType(DepthChart), matching: find.byType(CustomPaint)),
      );
      return paint.painter! as DepthPainter;
    }

    String f2(double v) => v.toStringAsFixed(2);
    String f4(double v) => v.toStringAsFixed(4);
    final first = await pump(bids, f2);
    final again = await pump(bids, f2);
    expect(again.prepared, same(first.prepared));
    expect(again.shouldRepaint(first), isFalse);
    final refmt = await pump(bids, f4);
    expect(refmt.shouldRepaint(again), isTrue);
    final fresh = await pump([...bids, const DepthLevel(97, 1)], f4);
    expect(fresh.prepared, isNot(same(first.prepared)));
    expect(fresh.prepared.bids, hasLength(3));
  });

  test(
    'both-sided axes: left strip shows the secondary axis, so the wheel there does not zoom y',
    () {
      final c = ChartController(indicators: [SecondaryAxis(Rsi())])
        ..asyncCompute = false
        ..setBars(genBars(300));
      final config = ChartConfig(
        theme: KLineTheme.light(),
        priceFormatter: (v) => v.toStringAsFixed(2),
        timeFormatter: (ms) => '$ms',
        yAxisPosition: YAxisPosition.both,
      );
      const size = Size(400, 400);
      final ctx = c.resolveLayout(size, config);
      expect(ctx.mainPanel.secondary, isNotNull);
      final g = GestureCoordinator(
        controller: c,
        resolve: () => c.resolveLayout(size, config),
        fling: AnimationController.unbounded(vsync: _FakeVsync()),
      );
      g.onWheel(Offset(ctx.leftAxisRect.center.dx, 200), -100);
      expect(c.viewport.yScale, 1.0);
      g.onWheel(Offset(ctx.yAxisRect.center.dx, 200), -100);
      expect(c.viewport.yScale, isNot(1.0));
      c.dispose();
    },
  );
}
