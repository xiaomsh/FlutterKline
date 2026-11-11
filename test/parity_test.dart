import 'dart:math' as math;
import 'dart:ui' show PictureRecorder;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klinex/klinex.dart';

// Painter classes are not exported; in-package tests import src directly.
import 'package:klinex/src/render/series_painter.dart';

/// Behavior tests for flutter_app integration parity (Phase 0): SAR / StochRSI / hollow candles.
/// Seed-exact incremental == full is covered by the generic harness in consistency_test
/// (both indicators added to makeIndicators).

List<Bar> trendBars(int n, {double slope = 1.0, int t0 = 1700000000000}) => [
  for (var i = 0; i < n; i++)
    Bar(
      time: t0 + i * 60000,
      open: 100 + i * slope,
      high: 101.5 + i * slope,
      low: 99.5 + i * slope,
      close: 101 + i * slope,
      vol: 100,
    ),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('hollow candles render without touching autoscale', () {
    final bars = trendBars(100, slope: 0.3);
    final c = ChartController()..setBars(bars);
    ChartConfig makeConfig(CandleFillMode fill) => ChartConfig(
      theme: KLineTheme.light(),
      priceFormatter: (v) => v.toStringAsFixed(2),
      timeFormatter: (ms) => '$ms',
      candleFill: fill,
    );
    const size = Size(400, 300);

    for (final fill in CandleFillMode.values) {
      final config = makeConfig(fill);
      final painter = SeriesPainter(c, config);
      final rec = PictureRecorder();
      painter.paint(Canvas(rec), size); // passes if no throw (path building/painting works)
      rec.endRecording().dispose();
      // fill mode is purely a paint param, does not affect the layout range
      final ctx = c.resolveLayout(size, config);
      expect(ctx.mainPanel.range.isEmpty, isFalse);
    }
    c.dispose();
  });

  // ---- Tier-1 indicators (TV parity): values/edges on known shapes ----
  // linear uptrend bars: o=100+i h=101.5+i l=99.5+i c=101+i, TR is always 2

  test('all MainSeriesStyle variants render without exceptions', () {
    final c = ChartController(indicators: [Ma(), Vol()])..setBars(trendBars(150));
    const size = Size(400, 300);
    for (final style in MainSeriesStyle.values) {
      final config = ChartConfig(
        theme: KLineTheme.dark(),
        priceFormatter: (v) => v.toStringAsFixed(2),
        timeFormatter: (ms) => '$ms',
        seriesStyle: style,
      );
      final painter = SeriesPainter(c, config);
      final rec = PictureRecorder();
      painter.paint(Canvas(rec), size);
      rec.endRecording().dispose();
      final ctx = c.resolveLayout(size, config);
      expect(ctx.mainPanel.range.isEmpty, isFalse, reason: 'style=$style');
    }
    c.dispose();
  });

  test('percent scale: axis labels relative to first visible close', () {
    final c = ChartController()..setBars(trendBars(100));
    final config = ChartConfig(
      theme: KLineTheme.light(),
      priceFormatter: (v) => v.toStringAsFixed(2),
      timeFormatter: (ms) => '$ms',
      percentScale: true,
    );
    final ctx = c.resolveLayout(const Size(400, 300), config);
    // baseline is the bar at the screen left edge, not ctx.start, which extends one bar further
    // left so the line connects across the edge; using it would shift the whole axis by one bar.
    final firstVisible = ctx.indexAt(ctx.chartRect.left).ceil();
    expect(
      firstVisible,
      greaterThan(ctx.start),
      reason: 'ctx.start really is left of the first visible bar, otherwise this case is pointless',
    );
    final base = c.bars[firstVisible].close;
    expect(ctx.formatAxisValue(ctx.mainPanel, base * 1.05), '+5.00%');
    expect(ctx.formatAxisValue(ctx.mainPanel, base * 0.9), '-10.00%');
    // legend/tooltip basis unchanged (absolute price)
    expect(ctx.formatValue(ctx.mainPanel, base), base.toStringAsFixed(2));
    c.dispose();
  });

  testWidgets('animatePrice: tick tweens the display close, then settles', (tester) async {
    final controller = ChartController()..setBars(trendBars(100));
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 400,
          height: 300,
          child: KChart(
            controller: controller,
            theme: KLineTheme.light(),
            animatePrice: true,
          ),
        ),
      ),
    );
    await tester.pump();

    final last = controller.bars.last;
    controller.applyTick(
      Bar(
        time: last.time,
        open: last.open,
        high: last.high + 5,
        low: last.low,
        close: last.close + 5,
        vol: last.vol,
      ),
    );
    await tester.pump(); // frame 1: dataRevision fires, animation starts at t=0
    await tester.pump(const Duration(milliseconds: 100)); // advance to halfway
    final mid = controller.animatedLastClose.value;
    expect(mid, isNotNull, reason: 'animating: displayed value is interpolated');
    expect(mid, lessThan(last.close + 5));
    expect(mid, greaterThan(last.close));
    await tester.pumpAndSettle();
    expect(controller.animatedLastClose.value, isNull, reason: 'animation over: real value');

    // symbol switch (setBars): whole dataset replaced, no cross-series interpolation
    controller.setBars([
      for (var i = 0; i < 50; i++)
        Bar(
          time: 1800000000000 + i * 60000,
          open: 500,
          high: 505,
          low: 495,
          close: 500.0 + i,
          vol: 10,
        ),
    ]);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    expect(controller.animatedLastClose.value, isNull, reason: 'new symbol: snap, no animation');
    controller.dispose();
  });

  test('outlier clamp: spike wick clipped, genuine move untouched', () {
    // slow-moving market + one spike (h far beyond window volatility, o/c/l normal)
    final bars = trendBars(100, slope: 0.1);
    final spike = Bar(
      time: bars[90].time,
      open: bars[90].open,
      high: bars[90].high + 30, // far beyond the span*0.5 band (and in the first visible window)
      low: bars[90].low,
      close: bars[90].close,
      vol: 100,
    );
    final withSpike = [...bars]..[90] = spike;

    ChartConfig cfg({double? clamp}) => ChartConfig(
      theme: KLineTheme.light(),
      priceFormatter: (v) => v.toStringAsFixed(2),
      timeFormatter: (ms) => '$ms',
      outlierClampRatio: clamp,
      mainPaddingTop: 0,
      mainPaddingBottom: 0,
    );

    final c = ChartController()..setBars(withSpike);
    // without clamping: the spike stretches the range
    final raw = c.resolveLayout(const Size(400, 300), cfg()).mainPanel.range;
    expect(raw.max, closeTo(spike.high, 1e-9));
    // with clamping: upper bound back above normal wicks and below the spike; lower bound unchanged
    final clamped = c.resolveLayout(const Size(400, 300), cfg(clamp: 0.5)).mainPanel.range;
    expect(clamped.max, lessThan(spike.high - 20), reason: 'spike clipped');
    expect(clamped.max, greaterThan(bars[99].high), reason: 'normal wicks kept');
    expect(clamped.min, closeTo(raw.min, 1e-9), reason: 'lower bound normal, unchanged');

    // reproduces real user magnitudes: closes ~65200-65500, spike to 68756 (about +4.9%,
    // which the old price-percentage formula just missed)
    final rnd = math.Random(3);
    final real = [
      for (var i = 0; i < 60; i++)
        Bar(
          time: 1700000000000 + i * 60000,
          open: 65300.0 + rnd.nextDouble() * 200,
          high: 65400.0 + rnd.nextDouble() * 120,
          low: 65200.0 - rnd.nextDouble() * 40,
          close: 65250.0 + rnd.nextDouble() * 250,
          vol: 1,
        ),
    ];
    final spiked = [...real];
    spiked[55] = Bar(
      time: real[55].time,
      open: real[55].open,
      high: 68756.875,
      low: real[55].low,
      close: real[55].close,
      vol: 70,
    );
    final c2 = ChartController()..setBars(spiked);
    final r2 = c2.resolveLayout(const Size(400, 300), cfg(clamp: 0.5)).mainPanel.range;
    expect(r2.max, lessThan(66500), reason: '4.9% spike must be clamped too, chart not flattened');
    expect(r2.max, greaterThan(65520), reason: 'normal wicks unaffected');

    // real move: close rises too, span grows, no false clamping
    final rally = [
      for (var i = 0; i < 100; i++)
        Bar(
          time: 1700000000000 + i * 60000,
          open: 100.0 + i * 2,
          high: 102.0 + i * 2,
          low: 99.0 + i * 2,
          close: 101.0 + i * 2,
          vol: 100,
        ),
    ];
    final c3 = ChartController()..setBars(rally);
    final r3 = c3.resolveLayout(const Size(400, 300), cfg(clamp: 0.5)).mainPanel.range;
    expect(r3.max, closeTo(102.0 + 99 * 2, 1e-9), reason: 'all highs kept in a real move');
    c.dispose();
    c2.dispose();
    c3.dispose();
  });
}
