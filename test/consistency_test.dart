import 'dart:math' as math;
import 'dart:ui' show Size;

import 'package:flutter_test/flutter_test.dart';
import 'package:klinex/klinex.dart';

/// The most important regression net (design doc §10): the same data fed as
/// one full batch vs. tick-by-tick increments must produce identical
/// indicator values，the incremental path is seed-exact by construction.

List<Bar> randomWalk(int n, {int seed = 42}) {
  final rnd = math.Random(seed);
  final bars = <Bar>[];
  var close = 100.0;
  const t0 = 1700000000000;
  for (var i = 0; i < n; i++) {
    final open = close;
    close = (open + (rnd.nextDouble() - 0.5) * 4).clamp(1.0, double.infinity);
    final high = math.max(open, close) + rnd.nextDouble() * 2;
    final low = math.min(open, close) - rnd.nextDouble() * 2;
    bars.add(
      Bar(
        time: t0 + i * 60000,
        open: open,
        high: high,
        low: math.max(low, 0.5),
        close: close,
        vol: 10 + rnd.nextDouble() * 1000,
      ),
    );
  }
  return bars;
}

List<Indicator> makeIndicators() => [
  Ma(periods: [5, 10, 30]),
  Ema(periods: [12, 26]),
  Boll(),
  Vol(),
  MaVol(periods: [5, 10]),
  Macd(),
  Kdj(),
  Rsi(periods: [6, 12, 24]),
  Wr(periods: [6, 10]),
];

void expectStoresEqual(ChartController a, ChartController b) {
  expect(a.bars.length, b.bars.length);
  final n = a.bars.length;
  for (var k = 0; k < a.indicators.list.length; k++) {
    final indA = a.indicators.list[k];
    final indB = b.indicators.list[k];
    expect(indA.id, indB.id);
    final sa = a.storeOf(indA);
    final sb = b.storeOf(indB);
    for (var i = 0; i < n; i++) {
      final va = sa.valuesAt(i);
      final vb = sb.valuesAt(i);
      expect(va.keys.toSet(), vb.keys.toSet(), reason: '${indA.id} series keys diverge at $i');
      for (final key in va.keys) {
        final x = va[key]!, y = vb[key]!;
        if (x.isNaN || y.isNaN) {
          expect(
            x.isNaN && y.isNaN,
            isTrue,
            reason: '${indA.id}.$key NaN mismatch at $i: $x vs $y',
          );
        } else {
          expect(y, closeTo(x, 1e-7), reason: '${indA.id}.$key differs at $i');
        }
      }
    }
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('incremental (applyTick with intra-bar ticks) == full recompute', () {
    final all = randomWalk(400);
    final a = ChartController(indicators: makeIndicators())..setBars(all);

    final b = ChartController(indicators: makeIndicators())..setBars(all.sublist(0, 60));
    for (var i = 60; i < all.length; i++) {
      final bar = all[i];
      final mid = (bar.open + bar.close) / 2;
      // three intra-bar ticks: append (partial), update, final
      b.applyTick(
        Bar(
          time: bar.time,
          open: bar.open,
          high: math.max(bar.open, mid),
          low: math.min(bar.open, mid),
          close: mid,
          vol: bar.vol / 2,
        ),
      );
      b.applyTick(bar.copyWith(close: mid, vol: bar.vol * 0.8));
      b.applyTick(bar);
    }

    expectStoresEqual(a, b);
    a.dispose();
    b.dispose();
  });

  test('out-of-order backfill (replaceAt) falls back to full recompute', () {
    final all = randomWalk(200, seed: 7);
    final b = ChartController(indicators: makeIndicators())..setBars(all);

    final fixedList = List<Bar>.of(all);
    final fixed = all[120].copyWith(close: all[120].close + 3, high: all[120].high + 3);
    fixedList[120] = fixed;

    b.applyTick(fixed); // old timestamp, so replace + full recompute
    final a = ChartController(indicators: makeIndicators())..setBars(fixedList);

    expectStoresEqual(a, b);
    a.dispose();
    b.dispose();
  });

  test('prependHistory == full batch, and viewport anchors', () {
    final all = randomWalk(300, seed: 11);
    final a = ChartController(indicators: makeIndicators())..setBars(all);

    final b = ChartController(indicators: makeIndicators())..setBars(all.sublist(150));
    b.viewport.attach(400);
    final rightBefore = b.viewport.rightIndex;
    b.prependHistory(all.sublist(0, 150));

    expect(
      b.viewport.rightIndex,
      rightBefore + 150,
      reason: 'prepend must shift the viewport by the inserted count',
    );
    expectStoresEqual(a, b);
    a.dispose();
    b.dispose();
  });

  test('zoom keeps the focal bar under the cursor', () {
    final c = ChartController()..setBars(randomWalk(500, seed: 3));
    final vp = c.viewport..attach(400);
    // scroll into the middle of history so boundary clamps don't kick in
    vp.scroll(2000);
    const focalX = 150.0;
    final before = vp.xToIndex(focalX);
    vp.zoomAt(focalX, 1.5);
    expect(vp.xToIndex(focalX), closeTo(before, 1e-6));
    vp.zoomAt(focalX, 0.5);
    expect(vp.xToIndex(focalX), closeTo(before, 1e-6));
    c.dispose();
  });

  test('zooming out at the newest edge clamps instead of overshooting', () {
    final c = ChartController()..setBars(randomWalk(500, seed: 3));
    final vp = c.viewport..attach(400);
    vp.zoomAt(390, 0.25);
    expect(vp.rightIndex, lessThanOrEqualTo(499 + vp.rightBlankBars + 1e-9));
    c.dispose();
  });

  test('right blank: initial lands at 2/3, drag limit reaches the last bar', () {
    final c = ChartController()..setBars(randomWalk(500, seed: 3));
    final vp = c.viewport..attach(400);
    // initial placement: newest bar at 2/3 (initial blank = 1/3 screen)
    expect(vp.indexToX(499), closeTo(400 * 2 / 3, 1e-6));
    // drag limit (default 1.0, TV semantics): the last bar can be pulled to the left edge
    vp.scroll(-10000); // drag fully left
    expect(
      vp.indexToX(499),
      closeTo(0, 1e-6),
      reason: 'the newest bar can be dragged to the left edge',
    );
    // set to 0: newest bar pinned whole at the right edge (index is the bar center, so half a
    // bar is kept); no more blank can be dragged in
    vp.rightBlankRatio = 0;
    vp.scroll(-10000);
    expect(vp.rightIndex, closeTo(499.5, 1e-9));
    expect(vp.indexToX(499) + vp.barWidth / 2, closeTo(400, 1e-6));
    c.dispose();
  });

  test('outside y axis: every right-edge boundary is the plot edge, not the screen', () {
    final c = ChartController()..setBars(randomWalk(500, seed: 3));
    final config = ChartConfig(
      theme: KLineTheme.light(),
      priceFormatter: (v) => v.toStringAsFixed(2),
      timeFormatter: (ms) => '$ms',
      yAxisPosition: YAxisPosition.outside,
      yAxisWidth: 60,
    );
    const size = Size(400, 400);
    final ctx = c.resolveLayout(size, config);

    expect(ctx.chartRect.right, 340, reason: 'plot ends left of the strip');
    expect(ctx.yAxisRect.left, 340);
    expect(ctx.yAxisRect.width, 60);
    expect(ctx.axisOutside, isTrue);
    expect(c.viewport.width, 340, reason: 'bars map over the plot width only');
    // initial placement: newest bar at 2/3 of the plot area (not the screen)
    expect(c.viewport.indexToX(499), closeTo(340 * 2 / 3, 1e-6));
    // drag limit: last bar to the plot area left edge; right blank also uses plot area width
    c.viewport.scroll(-10000);
    expect(c.viewport.indexToX(499), closeTo(0, 1e-6));
    c.dispose();
  });

  test('main autoscale pads in pixels: extremes sit exactly inside the panel', () {
    final c = ChartController()..setBars(randomWalk(300, seed: 21));
    final config = ChartConfig(
      theme: KLineTheme.light(),
      priceFormatter: (v) => v.toStringAsFixed(2),
      timeFormatter: (ms) => '$ms',
    );
    const size = Size(400, 400);
    final ctx = c.resolveLayout(size, config);
    var hi = double.negativeInfinity, lo = double.infinity;
    for (var i = ctx.start; i <= ctx.end; i++) {
      hi = math.max(hi, c.bars[i].high);
      lo = math.min(lo, c.bars[i].low);
    }
    final main = ctx.mainPanel;
    // whatever the visible span, highest/lowest points stay a fixed pixel distance from edges
    expect(main.yOf(hi), closeTo(main.rect.top + config.mainPaddingTop, 1e-6));
    expect(
      main.yOf(lo),
      closeTo(main.rect.bottom - config.mainPaddingBottom, 1e-6),
    );
    c.dispose();
  });

  test('y zoom scales the main range around its midpoint, sub panels stay auto', () {
    final c = ChartController(indicators: [Vol()])..setBars(randomWalk(300, seed: 13));
    final config = ChartConfig(
      theme: KLineTheme.light(),
      priceFormatter: (v) => v.toStringAsFixed(2),
      timeFormatter: (ms) => '$ms',
    );
    const size = Size(400, 400);
    final before = c.resolveLayout(size, config);
    final main0 = before.mainPanel.range;
    final sub0 = before.panels[1].range;

    c.viewport.zoomY(2); // zoom in 2x, span halves
    final after = c.resolveLayout(size, config);
    final main1 = after.mainPanel.range;
    expect(main1.span, closeTo(main0.span / 2, 1e-9));
    expect(
      (main1.min + main1.max) / 2,
      closeTo((main0.min + main0.max) / 2, 1e-9),
      reason: 'y zoom keeps the autoscaled midpoint',
    );
    expect(
      after.panels[1].range.span,
      closeTo(sub0.span, 1e-9),
      reason: 'sub panels are not affected by manual y zoom',
    );

    // clamps at both ends
    for (var i = 0; i < 20; i++) {
      c.viewport.zoomY(2);
    }
    expect(c.viewport.yScale, c.viewport.maxYScale);
    for (var i = 0; i < 40; i++) {
      c.viewport.zoomY(0.5);
    }
    expect(c.viewport.yScale, c.viewport.minYScale);

    // a fresh landing (setBars) goes back to pure autoscale
    c.viewport.zoomY(2);
    c.setBars(randomWalk(100, seed: 14));
    expect(c.viewport.yScale, 1.0);
    c.dispose();
  });

  test('y zoom scales around the midpoint; VolOverlay never touches price autoscale', () {
    final config = ChartConfig(
      theme: KLineTheme.light(),
      priceFormatter: (v) => v.toStringAsFixed(2),
      timeFormatter: (ms) => '$ms',
    );
    const size = Size(400, 400);
    final plain = ChartController()..setBars(randomWalk(300, seed: 33));
    final withVol = ChartController(indicators: [VolOverlay()])..setBars(randomWalk(300, seed: 33));

    // visible data extremes (same data and viewport for both charts)
    final ctx0 = plain.resolveLayout(size, config);
    var lo = double.infinity, hi = double.negativeInfinity;
    for (var i = ctx0.start; i <= ctx0.end; i++) {
      final b = plain.bars[i];
      if (b.low < lo) lo = b.low;
      if (b.high > hi) hi = b.high;
    }

    // no overlay: extremes sit at the default padding (top 28 / bottom 10 px)
    final p0 = ctx0.mainPanel;
    expect(p0.yOf(hi), closeTo(p0.rect.top + 28, 0.5));
    expect(p0.yOf(lo), closeTo(p0.rect.bottom - 10, 0.5));

    // VolOverlay: bottom reserve applies (0.2 + 0.04 buffer), candles stay out of volume area;
    // top unaffected (a single indicator does not grow the legend)
    final p1 = withVol.resolveLayout(size, config).mainPanel;
    expect(p1.yOf(hi), closeTo(p1.rect.top + 28, 0.5));
    expect(
      p1.yOf(lo),
      closeTo(p1.rect.bottom - p1.rect.height * 0.24, 0.5),
      reason: 'price autoscale must stop above the volume band',
    );

    // In-band indicators (VolOverlay) put their legend at their own band top, not in the top row
    // stack, so Ma + VolOverlay has one top legend row and the top padding stays default.
    final bandRow = ChartController(
      indicators: [
        Ma(periods: [7]),
        VolOverlay(),
      ],
    )..setBars(randomWalk(300, seed: 33));
    final p2 = bandRow.resolveLayout(size, config).mainPanel;
    expect(
      p2.yOf(hi),
      closeTo(p2.rect.top + 28, 0.5),
      reason: 'band legends must not grow the top padding',
    );
    bandRow.dispose();

    // two top legend rows (Ma + Ema; neither uses a bottom band or stretches the range past the
    // visible extremes): top padding grows automatically to 3 + 2*14 + 6
    final twoRows = ChartController(
      indicators: [
        Ma(periods: [7]),
        Ema(periods: [7]),
      ],
    )..setBars(randomWalk(300, seed: 33));
    final p3 = twoRows.resolveLayout(size, config).mainPanel;
    expect(
      p3.yOf(hi),
      closeTo(p3.rect.top + 37, 0.5),
      reason: 'top padding must grow with legend rows',
    );
    twoRows.dispose();

    // zoom: window shrinks around its midpoint, span halves; reset returns to pure auto
    final r0 = ctx0.mainPanel.range;
    plain.viewport.zoomY(2);
    final r2 = plain.resolveLayout(size, config).mainPanel.range;
    expect(r2.span, closeTo(r0.span / 2, 1e-9));
    plain.viewport.resetYScale();
    expect(plain.viewport.yScale, 1.0);
    final r3 = plain.resolveLayout(size, config).mainPanel.range;
    expect(r3.min, closeTo(r0.min, 1e-9));
    expect(r3.max, closeTo(r0.max, 1e-9));
    plain.dispose();
    withVol.dispose();
  });

  test('partial-window warm-up: lines reach bar 0 and match K-line (deriv/ta4j)', () {
    final all = randomWalk(50, seed: 5);
    final c = ChartController(
      indicators: [
        Ma(periods: [20]),
        Rsi(),
      ],
    )..setBars(all);
    final ma = c.storeOf(c.indicators.list[0]).series('ma20');
    final rsi = c.storeOf(c.indicators.list[1]).series('rsi14');
    // MA: partial window, has a value from bar 0 = mean of available bars (no leading NaN)
    for (var i = 0; i < 20; i++) {
      expect(ma[i].isNaN, isFalse, reason: 'ma20[$i] has a value from bar 0 (partial window)');
      var sum = 0.0;
      for (var j = 0; j <= i; j++) {
        sum += all[j].close;
      }
      expect(ma[i], closeTo(sum / (i + 1), 1e-9));
    }
    // RSI: undefined at bar 0 (no change); from bar 1 has values within 0..100
    expect(rsi[0].isNaN, isTrue);
    for (var i = 1; i < all.length; i++) {
      expect(rsi[i].isNaN, isFalse, reason: 'rsi14[$i] should have a value from bar 1');
      expect(rsi[i], inInclusiveRange(0, 100));
    }
    c.dispose();
  });
}
