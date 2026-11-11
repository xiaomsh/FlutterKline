import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';

import '../controller.dart';
import 'context.dart';

/// Grow-only segment buffer drawn with a single drawRawPoints. Obtain via
/// [SeriesPaintKit.batch]; reused across frames, don't keep it beyond paint.
class SegmentBatch {
  Float32List _data = Float32List(512);
  int _n = 0;

  void add(double x0, double y0, double x1, double y1) {
    if (_n + 4 > _data.length) {
      final grown = Float32List(_data.length * 2);
      grown.setRange(0, _n, _data);
      _data = grown;
    }
    _data[_n++] = x0;
    _data[_n++] = y0;
    _data[_n++] = x1;
    _data[_n++] = y1;
  }

  bool get isEmpty => _n == 0;

  Float32List get view => Float32List.sublistView(_data, 0, _n);

  void reset() => _n = 0;
}

/// Shared toolkit for painting the main series: decimation buckets, batched segments and
/// latest-price interpolation. Internal slots are reused across frames (reset at the start of
/// each frame); objects obtained are valid only within the current `MainSeries.paint`.
class SeriesPaintKit {
  final ChartController controller;

  SeriesPaintKit(this.controller);

  final List<SegmentBatch> _batches = [];
  final List<Path> _paths = [];
  final List<List<double>> _scratch = [];

  /// Shared stroke paint for axis-aligned primitives. Anti-aliasing is decided per frame by
  /// [beginFrame] based on density (see the comment there); no need to restore after use, but
  /// don't cache it.
  final Paint crispStroke = Paint()..style = PaintingStyle.stroke;

  /// Anti-aliasing turns on below this bucket width (logical px): a bar's width and spacing are
  /// down to one or two physical pixels, so "crisp" is meaningless while rounding jumps are
  /// costly.
  static const double _antiAliasBelow = 3.0;

  /// Clears all slots at the start of each frame (called by SeriesPainter).
  void beginFrame(RenderContext ctx) {
    for (final b in _batches) {
      b.reset();
    }
    for (final p in _paths) {
      p.reset();
    }
    // Anti-aliasing is required when decimating: bucket spacing is one or two physical pixels,
    // and without it each bar rounds independently, so while panning bars jump cells one after
    // another and up/down colors overdraw each other, making the whole area flicker. Turn it
    // off when bars are wide enough for the crisp path.
    crispStroke.isAntiAlias = ctx.drawWidth < _antiAliasBelow;
  }

  /// Returns segment batch [slot] (already cleared this frame); use a fixed slot per purpose.
  SegmentBatch batch(int slot) {
    while (_batches.length <= slot) {
      _batches.add(SegmentBatch());
    }
    return _batches[slot];
  }

  /// Returns Path [slot] (already reset this frame): accumulate one per color, then a single
  /// drawPath.
  Path path(int slot) {
    while (_paths.length <= slot) {
      _paths.add(Path());
    }
    return _paths[slot];
  }

  /// Returns reusable double buffer [slot] (already cleared this frame).
  List<double> scratch(int slot) {
    while (_scratch.length <= slot) {
      _scratch.add(<double>[]);
    }
    return _scratch[slot]..clear();
  }

  /// Vertical linear gradient ([color] fading from [alphaTop] at [y0] to [alphaBottom] at
  /// [y1]), cached by params: area and baseline series need it every frame, but the params only
  /// change with range, size or theme.
  Shader verticalGradient(
    double y0,
    double y1,
    Color color, {
    double alphaTop = 0.25,
    double alphaBottom = 0.02,
  }) {
    final key = (y0, y1, color.toARGB32(), alphaTop, alphaBottom);
    final hit = _gradients[key];
    if (hit != null) return hit;
    if (_gradients.length >= 8) _gradients.clear();
    return _gradients[key] = ui.Gradient.linear(
      Offset(0, y0),
      Offset(0, y1),
      [color.withValues(alpha: alphaTop), color.withValues(alpha: alphaBottom)],
    );
  }

  final Map<(double, double, int, double, double), Shader> _gradients = {};

  /// Displayed close of the last bar: the interpolated value while the latest-price animation
  /// runs, otherwise the real value.
  double displayClose(RenderContext ctx, int i) {
    final anim = controller.animatedLastClose.value;
    return anim != null && i == ctx.bars.length - 1 ? anim : ctx.bars[i].close;
  }

  /// Paint-time aggregation: when bars are narrower than about 2 physical pixels, merges
  /// [RenderContext.drawGroup] bars into one OHLC bucket (aligned by absolute index, so panning
  /// doesn't jitter) and calls back once per bucket.
  void forEachBucket(
    RenderContext ctx,
    void Function(double x, double o, double h, double l, double c) emit,
  ) {
    final bars = ctx.bars;
    final g = ctx.drawGroup;
    if (g == 1) {
      for (var i = ctx.start; i <= ctx.end; i++) {
        final b = bars[i];
        final c = displayClose(ctx, i);
        emit(ctx.xOf(i), b.open, math.max(b.high, c), math.min(b.low, c), c);
      }
    } else {
      for (var b0 = (ctx.start ~/ g) * g; b0 <= ctx.end; b0 += g) {
        final i0 = math.max(b0, ctx.start);
        final i1 = math.min(b0 + g - 1, ctx.end);
        final c = displayClose(ctx, i1);
        var high = math.max(bars[i0].high, c), low = math.min(bars[i0].low, c);
        for (var i = i0 + 1; i <= i1; i++) {
          high = math.max(high, bars[i].high);
          low = math.min(low, bars[i].low);
        }
        emit(ctx.xOf((i0 + i1) / 2), bars[i0].open, high, low, c);
      }
    }
  }

  /// Draws the whole segment batch with a single drawRawPoints.
  void drawSegments(Canvas canvas, SegmentBatch b, Color color, double width) {
    if (b.isEmpty) return;
    crispStroke
      ..color = color
      ..strokeWidth = width;
    canvas.drawRawPoints(ui.PointMode.lines, b.view, crispStroke);
  }

  /// First/last x of the line drawn by [closePath] (bucket centers when decimating); needed to
  /// close the fill, otherwise the fill overflows the stroke.
  double closeFirstX = 0;
  double closeLastX = 0;

  /// Close-price line; [stepped] draws a step line (merged into a plain line when decimating at
  /// extreme zoom-out). Returns null if there are no bars in view.
  Path? closePath(RenderContext ctx, {bool stepped = false}) {
    final bars = ctx.bars;
    final main = ctx.mainPanel;
    final path = ctx.pool.scratchPath..reset();
    var started = false;
    var firstX = 0.0, lastX = 0.0;
    final g = ctx.drawGroup;
    if (g == 1) {
      var prevY = double.nan;
      for (var i = ctx.start; i <= ctx.end; i++) {
        final x = ctx.xOf(i);
        final y = main.yOf(displayClose(ctx, i));
        lastX = x;
        if (!started) firstX = x;
        if (started) {
          if (stepped) path.lineTo(x, prevY);
          path.lineTo(x, y);
        } else {
          path.moveTo(x, y);
          started = true;
        }
        prevY = y;
      }
    } else {
      // Same M4 decimation as RenderContext.polyline, but on close prices.
      for (var b0 = (ctx.start ~/ g) * g; b0 <= ctx.end; b0 += g) {
        final i0 = math.max(b0, ctx.start);
        final i1 = math.min(b0 + g - 1, ctx.end);
        var lo = bars[i0].close, hi = lo;
        for (var i = i0 + 1; i <= i1; i++) {
          final v = bars[i].close;
          if (v < lo) lo = v;
          if (v > hi) hi = v;
        }
        final x = ctx.xOf((i0 + i1) / 2);
        lastX = x;
        if (!started) firstX = x;
        started = _addPoint(path, x, main.yOf(bars[i0].close), started);
        if (hi > lo) {
          started = _addPoint(path, x, main.yOf(lo), started);
          started = _addPoint(path, x, main.yOf(hi), started);
        }
        started = _addPoint(path, x, main.yOf(displayClose(ctx, i1)), started);
      }
    }
    if (!started) return null;
    closeFirstX = firstX;
    closeLastX = lastX;
    return path;
  }

  bool _addPoint(Path path, double x, double y, bool started) {
    if (started) {
      path.lineTo(x, y);
    } else {
      path.moveTo(x, y);
    }
    return true;
  }
}
