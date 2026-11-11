import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klinex/klinex.dart';
import 'package:klinex/src/render/series_painter.dart';

/// At extreme zoom-out (thousands of bars per screen, paint-time decimation) panning makes
/// the whole area "flash": bucket spacing is only one or two physical pixels while stroke width
/// stays at 1 logical pixel, so neighbors overlap; with antialiasing off each snaps to pixel
/// centers, and gaps and up/down colors flip while panning. Guards two invariants: stroke
/// width <= bucket spacing and AA on when dense; still crisp when bars are wide enough.

List<Bar> _bars(int n) => [
  for (var i = 0; i < n; i++)
    Bar(
      time: 1700000000000 + i * 60000,
      open: 100.0 + (i % 7),
      high: 108.0 + (i % 7),
      low: 92.0 + (i % 7),
      close: 100.0 + ((i + 3) % 7), // alternating up/down: worst case for overlap color flips
      vol: 100 + i % 5,
    ),
];

/// Fake canvas recording only stroke params (lines and paths both go through it).
class _ProbeCanvas implements Canvas {
  final List<({double width, bool antiAlias})> strokes = [];

  void _record(Paint p) => strokes.add((width: p.strokeWidth, antiAlias: p.isAntiAlias));

  @override
  void drawRawPoints(ui.PointMode mode, Float32List points, Paint paint) => _record(paint);

  @override
  void drawPath(Path path, Paint paint) => _record(paint);

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

ChartConfig _config(double dpr, MainSeriesStyle style) => ChartConfig(
  theme: KLineTheme.dark(),
  priceFormatter: (v) => v.toStringAsFixed(2),
  timeFormatter: (ms) => '$ms',
  seriesStyle: style,
)..devicePixelRatio = dpr;

/// Pins bar width to [barWidth], paints a frame, returns (bucket width, frame stroke params).
({double drawW, List<({double width, bool antiAlias})> strokes}) _paint(
  double barWidth,
  double dpr,
  MainSeriesStyle style, {
  Size size = const Size(400, 300),
}) {
  final c = ChartController()..setBars(_bars(4000));
  final cfg = _config(dpr, style);
  c.viewport
    ..minBarWidth = barWidth
    ..maxBarWidth = barWidth
    ..clampBarWidthBounds();
  final canvas = _ProbeCanvas();
  SeriesPainter(c, cfg).paint(canvas, size);
  final ctx = c.resolveLayout(size, cfg);
  return (drawW: ctx.barWidth * ctx.drawGroup, strokes: canvas.strokes);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Decimation floor is 2 physical px per bucket, only 0.67 logical px at dpr=3; the old
  // clamp(1.0, ...) drew lines 1.5x the bucket width, so every bar overlapped its neighbors.
  for (final dpr in [1.0, 2.0, 3.0]) {
    for (final style in [
      MainSeriesStyle.candle,
    ]) {
      test('stroke width <= bucket width at extreme zoom-out (dpr=$dpr, ${style.name})', () {
        final r = _paint(0.05, dpr, style);
        expect(r.strokes, isNotEmpty);
        for (final s in r.strokes) {
          expect(
            s.width,
            lessThanOrEqualTo(r.drawW + 1e-9),
            reason: 'stroke width ${s.width} > bucket width ${r.drawW}: neighbors overlap',
          );
          expect(s.antiAlias, isTrue, reason: 'AA must be on when dense, or panning flickers');
        }
      });
    }
  }

  test('wide bars still take the crisp non-antialiased path', () {
    final r = _paint(8, 2.0, MainSeriesStyle.candle);
    expect(r.drawW, 8);
    expect(r.strokes, isNotEmpty);
    expect(r.strokes.every((s) => !s.antiAlias), isTrue);
  });

  test('panning keeps bucketing stable: bucket and stroke width constant per frame', () {
    final c = ChartController()..setBars(_bars(4000));
    final cfg = _config(3, MainSeriesStyle.candle);
    c.viewport
      ..minBarWidth = 0.05
      ..maxBarWidth = 0.05
      ..clampBarWidthBounds();
    const size = Size(400, 300);
    List<double> widthsAfterScroll(double dx) {
      c.viewport.scroll(dx);
      final canvas = _ProbeCanvas();
      SeriesPainter(c, cfg).paint(canvas, size);
      return [for (final s in canvas.strokes) s.width];
    }

    final first = widthsAfterScroll(0);
    for (var i = 0; i < 20; i++) {
      // 0.37px: deliberately non-integer, so each frame lands on a different subpixel phase
      expect(widthsAfterScroll(0.37), first);
    }
  });
}
