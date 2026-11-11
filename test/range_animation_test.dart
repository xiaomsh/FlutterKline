import 'dart:math' as math;
import 'dart:ui' show Size;

import 'package:flutter_test/flutter_test.dart';
import 'package:klinex/klinex.dart';

/// Value-range transition animation: data-driven autoscale changes are tweened via animateRange
/// (first frame holds, then midpoint, then end); horizontal panning is always damped (without
/// damping at extreme zoom-out the whole screen bounces up and down); y zoom / symbol switch
/// apply immediately; with the switch off, data-driven changes match the old version frame by
/// frame.

List<Bar> walk(int n, {int seed = 5}) {
  final rnd = math.Random(seed);
  var close = 100.0;
  return [
    for (var i = 0; i < n; i++)
      Bar(
        time: 1700000000000 + i * 60000,
        open: close,
        high: (close = (close + (rnd.nextDouble() - 0.5) * 2).clamp(1, 1e9)) + 1,
        low: close - 1,
        close: close,
        vol: 10,
      ),
  ];
}

ChartConfig makeConfig() => ChartConfig(
  theme: KLineTheme.light(),
  priceFormatter: (v) => v.toStringAsFixed(2),
  timeFormatter: (ms) => '$ms',
);

void main() {
  testWidgets('range tween uses rangeRevision, no longer posing as dataRevision', (tester) async {
    // The tween is display-only: no candle changed, only the y mapping slides toward the target.
    // It used to notify via dataRevision, once per frame during horizontal gestures, drowning the
    // "data changed" meaning in 60fps false positives (host misjudgment, last-price
    // interpolation animation woken every frame, misleading logs).
    final c = ChartController()
      ..asyncCompute = false
      ..setBars(walk(400));
    final config = makeConfig();
    const size = Size(400, 400);

    await tester.pump(); // let setBars' _bump land
    c.resolveLayout(size, config);
    final dataAt0 = c.dataRevision.value;
    final rangeAt0 = c.rangeRevision.value;

    // horizontal pan: autoscale target jumps this frame, tween starts
    c.viewport.scroll(-120);
    c.resolveLayout(size, config);
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      c.resolveLayout(size, config);
    }

    expect(
      c.rangeRevision.value,
      greaterThan(rangeAt0),
      reason: 'tween progress must go through rangeRevision',
    );
    expect(
      c.dataRevision.value,
      dataAt0,
      reason: 'no candle changed, dataRevision must not move',
    );
    c.dispose();
  });

  const size = Size(400, 300);

  testWidgets('data-driven range change tweens; ends at the exact target', (tester) async {
    final bars = walk(200);
    final c = ChartController()
      ..animateRange = true
      ..setBars(bars);
    c.viewport.attach(400);
    final config = makeConfig();
    final r0 = c.resolveLayout(size, config).mainPanel.range;

    // last bar makes a new high far above the old range (still overlapping it, so tweened)
    final last = c.bars.last;
    c.updateLast(last.copyWith(high: last.high + 30));

    // reference end: same data, animation off
    final ref = ChartController()..setBars(List.of(c.bars));
    ref.viewport.attach(400);
    final target = ref.resolveLayout(size, makeConfig()).mainPanel.range;
    expect(target.max, greaterThan(r0.max + 20));

    // tween start: this frame keeps the old range
    final rStart = c.resolveLayout(size, config).mainPanel.range;
    expect(rStart.max, closeTo(r0.max, 1e-9));

    // midway: strictly between start and end
    await tester.pump(const Duration(milliseconds: 80));
    final rMid = c.resolveLayout(size, config).mainPanel.range;
    expect(rMid.max, greaterThan(r0.max + 1e-9));
    expect(rMid.max, lessThan(target.max - 1e-9));

    // finished: lands exactly on target
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    final rEnd = c.resolveLayout(size, config).mainPanel.range;
    expect(rEnd.min, closeTo(target.min, math.max(1e-9, target.span * 1e-9)));
    expect(rEnd.max, closeTo(target.max, math.max(1e-9, target.span * 1e-9)));

    c.dispose();
    ref.dispose();
  });

  testWidgets('y zoom applies at once (the finger is dragging the y mapping)', (tester) async {
    final c = ChartController()
      ..animateRange = true
      ..setBars(walk(500, seed: 9));
    c.viewport.attach(400);
    final config = makeConfig();
    final r0 = c.resolveLayout(size, config).mainPanel.range;

    c.viewport.zoomY(2);
    final r1 = c.resolveLayout(size, config).mainPanel.range;
    expect(r1.span, lessThan(r0.span * 0.6), reason: 'y pinch must apply within the same frame');
    await tester.pump(const Duration(milliseconds: 100));
    final r2 = c.resolveLayout(size, config).mainPanel.range;
    expect(r2.min, r1.min);
    expect(r2.max, r1.max);
    c.dispose();
  });

  testWidgets('damped pan: no frame jump, exact autoscale target after release', (tester) async {
    // Extreme zoom-out (8 bars per pixel): one frame of drag brings in dozens of bars, and new
    // extremes make the autoscale target jump 20%+ in one frame. Snapping directly makes every
    // line on screen bounce, which is the "flicker when panning after zooming out".
    final bars = walk(20000, seed: 3);
    final c = ChartController()..setBars(bars); // note: animateRange is off
    final config = makeConfig();
    c.viewport
      ..minBarWidth = 0.125
      ..maxBarWidth = 0.125
      ..attach(400)
      ..clampBarWidthBounds()
      ..setRightIndex(12000);

    // observable: per-frame displacement of the on-screen y of a fixed price
    var main = c.resolveLayout(size, config).mainPanel;
    final probe = (main.range.min + main.range.max) / 2;
    var lastY = main.yOf(probe);
    var worst = 0.0;
    for (var f = 0; f < 40; f++) {
      c.viewport.scroll(6); // 6px per frame is about 48 bars
      await tester.pump(const Duration(milliseconds: 16));
      main = c.resolveLayout(size, config).mainPanel;
      final y = main.yOf(probe);
      worst = math.max(worst, (y - lastY).abs());
      lastY = y;
    }
    // measured: 10.7px before damping (this data) / up to 46px on real market data, 1.8px after
    expect(worst, lessThan(4), reason: 'y step ${worst.toStringAsFixed(1)}px: range is jumping');

    // release: the tween must converge to the real autoscale target (not stop halfway)
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    final shown = c.resolveLayout(size, config).mainPanel.range;
    final ref = ChartController()..setBars(bars);
    ref.viewport
      ..minBarWidth = 0.125
      ..maxBarWidth = 0.125
      ..attach(400)
      ..clampBarWidthBounds()
      ..setRightIndex(c.viewport.rightIndex);
    final target = ref.resolveLayout(size, makeConfig()).mainPanel.range;
    expect(shown.min, closeTo(target.min, target.span * 1e-6));
    expect(shown.max, closeTo(target.max, target.span * 1e-6));
    c.dispose();
    ref.dispose();
  });

  testWidgets('trending market fling ending: range neither freezes nor hard-jumps', (tester) async {
    // A one-way trend + narrow span (the most common case in real markets) was the old
    // implementation's blind spot: the target changed every frame, so tween progress reset every
    // frame and shown never moved, frozen until the target left the band entirely and the
    // non-overlap guard hard-snapped it back. Measured frozen 63/79 frames, then a 298px jump:
    // the "flicker just as a fling stops". Once fixed it should move every frame with no big
    // single-frame jump.
    final rnd = math.Random(7);
    var close = 100.0;
    final bars = [
      for (var i = 0; i < 600; i++)
        Bar(
          time: 1700000000000 + i * 60000,
          open: close,
          high: (close = close + 0.6 + (rnd.nextDouble() - 0.5) * 3).clamp(1, 1e9) + 1,
          low: close - 1,
          close: close,
          vol: 10 + rnd.nextInt(50).toDouble(),
        ),
    ];
    final c = ChartController()
      ..asyncCompute = false
      ..setBars(bars);
    final config = makeConfig();
    const s4 = Size(400, 400);
    await tester.pump();
    c.resolveLayout(s4, config);

    // replicate the per-frame displacement of FrictionSimulation(0.135, 0, vx)
    var v = 2400.0;
    double? probe;
    var lastY = 0.0, worst = 0.0, frozen = 0;
    for (var f = 0; f < 80; f++) {
      c.viewport.scroll(v / 60);
      v *= math.pow(0.135, 1 / 60).toDouble();
      final main = c.resolveLayout(s4, config).mainPanel;
      probe ??= (main.range.min + main.range.max) / 2;
      final y = main.yOf(probe);
      if (f > 0) {
        final d = (y - lastY).abs();
        worst = math.max(worst, d);
        if (d < 0.01) frozen++;
      }
      lastY = y;
      await tester.pump(const Duration(milliseconds: 16));
    }
    // measured: before the fix worst=298.4px / 63 frozen frames, after 18.1px / 0 frames
    expect(worst, lessThan(60), reason: 'y jump ${worst.toStringAsFixed(1)}px: range hard-jumps');
    expect(frozen, lessThan(8), reason: 'frozen $frozen/79 frames: range lags, will hard-jump');
    c.dispose();
  });

  testWidgets('sub-pane damped too: volume spikes no longer double it in a frame', (tester) async {
    // Volume autoscale jumps more than the main pane: the tallest volume bar in the window sets
    // the whole scale, so it entering/leaving the window is a multiple-fold rescale. Panning after
    // a slight zoom-out hits this repeatedly.
    final rnd = math.Random(11);
    var close = 100.0;
    final bars = [
      for (var i = 0; i < 5000; i++)
        Bar(
          time: 1700000000000 + i * 60000,
          open: close,
          high: (close = close + (rnd.nextDouble() - 0.5) * 2) + 1,
          low: close - 1,
          close: close,
          // 3% chance of a 10~40x volume spike (normal in real markets)
          vol: rnd.nextDouble() < 0.03 ? 5000 + rnd.nextDouble() * 20000 : 500,
        ),
    ];
    final c = ChartController(indicators: [Vol()])
      ..asyncCompute = false
      ..setBars(bars);
    final config = makeConfig();
    c.viewport
      ..minBarWidth =
          4 // just a "slight zoom-out", downsampling not even triggered
      ..maxBarWidth = 4
      ..attach(400)
      ..clampBarWidthBounds()
      ..setRightIndex(3000);

    var vol = c.resolveLayout(size, config).panels.last;
    expect(vol.id, 'vol');
    final probe = vol.range.max / 2;
    var lastY = vol.yOf(probe);
    var worst = 0.0;
    for (var f = 0; f < 60; f++) {
      c.viewport.scroll(20); // fast fling: 5 bars per frame
      await tester.pump(const Duration(milliseconds: 16));
      vol = c.resolveLayout(size, config).panels.last;
      final y = vol.yOf(probe);
      worst = math.max(worst, (y - lastY).abs());
      lastY = y;
    }
    // measured: 1623px single-frame shift before damping (volume scale differs by an order of
    // magnitude between frames, bars jump between "barely visible" and "filling the pane"),
    // 0.7px after
    expect(worst, lessThan(2), reason: 'volume pane frame shift ${worst.toStringAsFixed(1)}px');

    // must also converge to the real target
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    final shown = c.resolveLayout(size, config).panels.last.range;
    final ref = ChartController(indicators: [Vol()])
      ..asyncCompute = false
      ..setBars(bars);
    ref.viewport
      ..minBarWidth = 4
      ..maxBarWidth = 4
      ..attach(400)
      ..clampBarWidthBounds()
      ..setRightIndex(c.viewport.rightIndex);
    final target = ref.resolveLayout(size, makeConfig()).panels.last.range;
    expect(shown.max, closeTo(target.max, math.max(1e-9, target.span * 1e-6)));
    c.dispose();
    ref.dispose();
  });

  testWidgets('switch symbol (setBars) snaps — no cross-series tween', (tester) async {
    final c = ChartController()
      ..animateRange = true
      ..setBars(walk(200));
    c.viewport.attach(400);
    final config = makeConfig();
    c.resolveLayout(size, config);

    // completely non-overlapping price range (like a symbol switch): must snap directly
    final shifted = [
      for (final b in walk(200, seed: 77))
        Bar(
          time: b.time,
          open: b.open + 5000,
          high: b.high + 5000,
          low: b.low + 5000,
          close: b.close + 5000,
          vol: b.vol,
        ),
    ];
    c.setBars(shifted);
    final ref = ChartController()..setBars(List.of(shifted));
    ref.viewport.attach(400);
    final target = ref.resolveLayout(size, makeConfig()).mainPanel.range;

    final r = c.resolveLayout(size, config).mainPanel.range;
    expect(r.min, closeTo(target.min, 1e-6));
    expect(r.max, closeTo(target.max, 1e-6));
    c.dispose();
    ref.dispose();
  });

  testWidgets('animateRange off keeps legacy per-frame behavior', (tester) async {
    final c = ChartController()..setBars(walk(200));
    c.viewport.attach(400);
    final config = makeConfig();
    c.resolveLayout(size, config);

    final last = c.bars.last;
    c.updateLast(last.copyWith(high: last.high + 30));
    final ref = ChartController()..setBars(List.of(c.bars));
    ref.viewport.attach(400);
    final target = ref.resolveLayout(size, makeConfig()).mainPanel.range;

    final r = c.resolveLayout(size, config).mainPanel.range;
    expect(r.max, closeTo(target.max, 1e-9), reason: 'animation off must apply immediately');
    c.dispose();
    ref.dispose();
  });
}
