import 'dart:math' as math;
import 'dart:ui' show PictureRecorder;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klinex/klinex.dart';

// Painter classes are the internal render layer (not exported); in-package tests import src.
import 'package:klinex/src/render/grid_painter.dart';
import 'package:klinex/src/render/overlay_painter.dart';
import 'package:klinex/src/render/series_painter.dart';

/// Phase 3 performance gate: 10k bars + high-frequency ticks. Thresholds
/// are deliberately generous (CI machines vary)，the point is catching
/// order-of-magnitude regressions, not micro-benchmarks.

List<Bar> genBars(int n, {int seed = 21}) {
  final rnd = math.Random(seed);
  final bars = <Bar>[];
  var close = 100.0;
  for (var i = 0; i < n; i++) {
    final open = close;
    close = (open + (rnd.nextDouble() - 0.5) * 4).clamp(1.0, double.infinity);
    bars.add(
      Bar(
        time: 1600000000000 + i * 60000,
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

List<Indicator> fullSet() => [
  Ma(periods: [7, 25, 99]),
  Ema(periods: [12, 26]),
  Boll(),
  Vol(),
  MaVol(),
  Macd(),
  Kdj(),
  Rsi(),
  Wr(),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('perf: 10k bars full compute (11 indicators)', () {
    final bars = genBars(10000);
    final c = ChartController(indicators: fullSet())..asyncCompute = false;
    final sw = Stopwatch()..start();
    c.setBars(bars);
    sw.stop();
    debugPrint('setBars(10k, 11 indicators): ${sw.elapsedMilliseconds}ms');
    expect(sw.elapsedMilliseconds, lessThan(3000));
    c.dispose();
  });

  test('perf: 2000 high-frequency ticks are incremental', () {
    final c = ChartController(indicators: fullSet())
      ..asyncCompute = false
      ..setBars(genBars(10000));
    final last = c.bars.last;
    final rnd = math.Random(5);
    final sw = Stopwatch()..start();
    for (var i = 0; i < 2000; i++) {
      final price = last.close + (rnd.nextDouble() - 0.5);
      c.applyTick(
        last.copyWith(
          close: price,
          high: math.max(last.high, price),
          low: math.min(last.low, price),
          vol: last.vol + i,
        ),
      );
    }
    sw.stop();
    final perTick = sw.elapsedMicroseconds / 2000;
    debugPrint(
      '2000 updateLast ticks on 10k bars: '
      '${sw.elapsedMilliseconds}ms (${perTick.toStringAsFixed(1)}µs/tick)',
    );
    expect(sw.elapsedMilliseconds, lessThan(1500), reason: 'ticks must stay O(period), not O(N)');
    c.dispose();
  });

  test('perf: layout resolution while panning 10k bars', () {
    final c = ChartController(indicators: fullSet())
      ..asyncCompute = false
      ..setBars(genBars(10000));
    final config = ChartConfig(
      theme: KLineTheme.light(),
      priceFormatter: (v) => v.toStringAsFixed(2),
      timeFormatter: (ms) => '$ms',
    );
    const size = Size(800, 600);
    c.resolveLayout(size, config); // warm up
    final sw = Stopwatch()..start();
    for (var i = 0; i < 200; i++) {
      c.viewport.scroll(15); // invalidates the layout cache every frame
      c.resolveLayout(size, config);
    }
    sw.stop();
    debugPrint(
      '200 pan-frame layouts on 10k bars: '
      '${sw.elapsedMilliseconds}ms',
    );
    expect(
      sw.elapsedMilliseconds,
      lessThan(500),
      reason: 'visible-window rescan must stay O(visible), not O(N)',
    );
    c.dispose();
  });

  test('perf: full three-layer paint per pan frame (grid+series+overlays)', () {
    // Covers the paint side: full-frame recording cost of batched candles, indicator lines,
    // grid/axis labels, and built-in overlays (idle crosshair channel, price tag, legend).
    final c = ChartController(indicators: fullSet())
      ..asyncCompute = false
      ..setBars(genBars(10000));
    final config = ChartConfig(
      theme: KLineTheme.light(),
      priceFormatter: (v) => v.toStringAsFixed(2),
      timeFormatter: (ms) => '$ms',
    );
    const size = Size(800, 600);
    final grid = GridPainter(c, config);
    final series = SeriesPainter(c, config);
    final overlays = OverlayPainter.split(c, config, onTop: false);

    void paintFrame() {
      final rec = PictureRecorder();
      final canvas = Canvas(rec);
      grid.paint(canvas, size);
      series.paint(canvas, size);
      for (final o in overlays) {
        o.paint(canvas, size);
      }
      rec.endRecording().dispose();
    }

    paintFrame(); // warm up (text cache, layout)
    final sw = Stopwatch()..start();
    for (var i = 0; i < 100; i++) {
      c.viewport.scroll(15);
      paintFrame();
    }
    sw.stop();
    debugPrint(
      '100 pan-frame paints (3 layers, 11 indicators): '
      '${sw.elapsedMilliseconds}ms '
      '(${(sw.elapsedMicroseconds / 100 / 1000).toStringAsFixed(2)}ms/frame)',
    );
    expect(
      sw.elapsedMilliseconds,
      lessThan(2000),
      reason: 'a pan frame must stay well under the 16ms budget',
    );
    c.dispose();
  });

  test('perf: extreme zoom-out paint (all 10k bars visible) is decimated', () {
    // Scenario seen on a real 120Hz device: at minimum barWidth over ten thousand bars are visible;
    // without drawGroup downsampling of indicator lines/volume bars, path segments per frame are
    // O(visible bars) and frames blow the budget.
    final c = ChartController(indicators: fullSet())
      ..asyncCompute = false
      ..setBars(genBars(10000));
    final config = ChartConfig(
      theme: KLineTheme.light(),
      priceFormatter: (v) => v.toStringAsFixed(2),
      timeFormatter: (ms) => '$ms',
    );
    const size = Size(800, 600);
    final grid = GridPainter(c, config);
    final series = SeriesPainter(c, config);
    final overlays = OverlayPainter.split(c, config, onTop: false);

    void paintFrame() {
      final rec = PictureRecorder();
      final canvas = Canvas(rec);
      grid.paint(canvas, size);
      series.paint(canvas, size);
      for (final o in overlays) {
        o.paint(canvas, size);
      }
      rec.endRecording().dispose();
    }

    paintFrame(); // warm up + attach width (zoomAt is a no-op when width=0)
    c.viewport
      ..minBarWidth =
          0.08 // ≈ 0.25 physical px @dpr3 (KChart's lower bound)
      ..zoomAt(400, 1e-9); // clamp to minimum: all 10k bars visible
    expect(c.viewport.visibleBars, greaterThan(9000));
    paintFrame(); // warm one more frame at extreme zoom
    final sw = Stopwatch()..start();
    for (var i = 0; i < 100; i++) {
      c.viewport.scroll(i.isEven ? 3 : -3); // pan back and forth near the edge
      paintFrame();
    }
    sw.stop();
    debugPrint(
      '100 extreme-zoom-out paints (10k visible, 11 indicators): '
      '${sw.elapsedMilliseconds}ms '
      '(${(sw.elapsedMicroseconds / 100 / 1000).toStringAsFixed(2)}ms/frame)',
    );
    expect(
      sw.elapsedMilliseconds,
      lessThan(3000),
      reason: 'decimation must keep worst-case zoom-out well inside budget',
    );
    c.dispose();
  });

  test('perf: ticks outside the visible window reuse the cached layout', () {
    final c = ChartController(indicators: fullSet())
      ..asyncCompute = false
      ..setBars(genBars(10000));
    final config = ChartConfig(
      theme: KLineTheme.light(),
      priceFormatter: (v) => v.toStringAsFixed(2),
      timeFormatter: (ms) => '$ms',
    );
    const size = Size(800, 600);
    c.viewport.attach(size.width);
    c.viewport.scroll(5000 * 8.0); // far back into history
    final ctx1 = c.resolveLayout(size, config);
    final last = c.bars.last;
    c.updateLast(last.copyWith(close: last.close + 1, high: last.high + 2));
    final ctx2 = c.resolveLayout(size, config);
    expect(
      identical(ctx1, ctx2),
      isTrue,
      reason: 'a tick beyond the visible range must not rebuild layout',
    );
    c.dispose();
  });

  test('legend paints in its own layer, apart from the price line', () {
    final c = ChartController();
    final config = ChartConfig(
      theme: KLineTheme.light(),
      priceFormatter: (v) => '$v',
      timeFormatter: (ms) => '$ms',
    );
    final layers = OverlayPainter.split(c, config, onTop: false);
    final legend = layers.singleWhere((l) => l.plugins.any((o) => o is IndicatorLegendOverlay));
    expect(legend.plugins, hasLength(1));
    expect(legend.plugins.single.repaintOn(c), contains(c.crosshair));
    final price = layers.singleWhere((l) => l.plugins.any((o) => o is PriceLineOverlay));
    expect(price.plugins.single.repaintOn(c), isNot(contains(c.crosshair)));
    c.dispose();
  });
}
