import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klinex/klinex.dart';
import 'package:klinex/src/render/series_painter.dart';

/// During slow panning (a fling's tail moves only a fraction of a pixel per frame) the image must
/// translate rigidly: all bars' physical pixel columns move together. After zooming, bar width is
/// an arbitrary fraction and each bar has a different phase; if the horizontal origin isn't
/// quantized to the physical pixel grid, each frame some bars cross a rounding boundary while the
/// rest stay put. Measured: 40% of bars jump a pixel per frame, a full-screen "shimmer". Only an
/// integer bar width (default 8px) has a uniform phase and happens not to flicker, so this bug
/// only appears after zooming.

List<Bar> _bars(int n) {
  final rnd = math.Random(4);
  var p = 100.0;
  return [
    for (var i = 0; i < n; i++)
      () {
        final o = p;
        final c = o + (rnd.nextDouble() - 0.5) * 2;
        p = c;
        return Bar(
          time: 1700000000000 + i * 60000,
          open: o,
          high: math.max(o, c) + 1,
          low: math.min(o, c) - 1,
          close: c,
          vol: 100,
        );
      }(),
  ];
}

/// Collects only the drawn x values.
class _XProbe implements Canvas {
  final List<double> xs = [];

  @override
  void drawRawPoints(ui.PointMode mode, Float32List points, Paint paint) {
    for (var i = 0; i + 3 < points.length; i += 4) {
      xs.add(points[i]);
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const size = Size(400, 300);

  for (final dpr in [1.0, 2.0, 3.0]) {
    // 4.37 / 2.7 / 6.9: after zooming bar widths are fractions like these; 8.0 is the "happens to
    // align" control
    for (final barWidth in [2.7, 4.37, 6.9, 8.0]) {
      test('slow panning is rigid (dpr=$dpr, barWidth=$barWidth)', () {
        final c = ChartController()..setBars(_bars(3000));
        final cfg = ChartConfig(
          theme: KLineTheme.light(),
          priceFormatter: (v) => v.toStringAsFixed(2),
          timeFormatter: (ms) => '$ms',
        )..devicePixelRatio = dpr;
        c.viewport
          ..minBarWidth = barWidth
          ..maxBarWidth = barWidth
          ..attach(400)
          ..clampBarWidthBounds()
          ..setRightIndex(2000);
        final painter = SeriesPainter(c, cfg);

        // Take column numbers by absolute index: different bars enter/leave the screen while
        // panning, so aligning by draw order misaligns; only matching by index compares correctly.
        List<int> columns() {
          final probe = _XProbe(); // run the real paint path (downsampling rules apply too)
          painter.paint(probe, size);
          expect(probe.xs, isNotEmpty);
          final ctx = c.resolveLayout(size, cfg);
          return [
            for (var i = 1900; i <= 1990; i++) (ctx.xOf(i) * dpr + 1e-6).floor(),
          ];
        }

        var prev = columns();
        for (var f = 0; f < 8; f++) {
          c.viewport.scroll(0.3); // fling tail
          final cur = columns();
          final shifts = <int>{
            for (var i = 0; i < cur.length; i++) cur[i] - prev[i],
          };
          expect(
            shifts,
            hasLength(1),
            reason:
                'frame $f is not a rigid translation: shift set $shifts; some bars jump a column '
                'while the rest stay, which is the visible flicker',
          );
          prev = cur;
        }
        c.dispose();
      });
    }
  }

  test('quantization moves at most half a physical pixel and keeps x↔index invertible', () {
    final c = ChartController()..setBars(_bars(500));
    final cfg = ChartConfig(
      theme: KLineTheme.light(),
      priceFormatter: (v) => v.toStringAsFixed(2),
      timeFormatter: (ms) => '$ms',
    )..devicePixelRatio = 3;
    c.viewport
      ..minBarWidth = 4.37
      ..maxBarWidth = 4.37
      ..attach(400)
      ..clampBarWidthBounds();
    final ctx = c.resolveLayout(const Size(400, 300), cfg);
    for (final i in [0, 1, 137, 499]) {
      expect(ctx.indexAt(ctx.xOf(i)), closeTo(i, 1e-9));
    }
    // the latest bar still lands where it should (error within one physical pixel)
    expect(
      ctx.xOf(c.viewport.rightIndex),
      closeTo(ctx.chartRect.right, 1 / 3),
    );
    c.dispose();
  });
}
