import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import '../controller.dart';
import '../debug.dart';
import '../model/min_max.dart';
import 'context.dart';
import 'time_ticks.dart';

/// Background, grid and axis labels. Repaints when viewport / data / indicators change, not
/// when dragging the crosshair. Labels inside the plot area (inside axis, secondary axis at
/// the plot edge) are drawn separately by the [plotLabels] instance above the indicator layer,
/// otherwise candles and indicator lines would cover them.
class GridPainter extends CustomPainter {
  // A dedicated paint with anti-aliasing off, leaving the pool's shared paint settings alone.
  final Paint _line = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1
    ..isAntiAlias = false;

  GridPainter(this.controller, this.config, {this.plotLabels = false})
    : super(
        repaint: Listenable.merge([
          controller.dataRevision,
          // Range tween: data is unchanged but the y mapping slides, so every layer repaints.
          controller.rangeRevision,
          controller.viewport,
          controller.indicators,
          config.theme,
          config.layoutRevision,
        ]),
      );

  final ChartController controller;
  final ChartConfig config;

  /// true: draws only the axis labels inside the plot area; false: draws everything else.
  final bool plotLabels;

  String get debugLayerName => plotLabels ? 'L3-plot-labels' : 'L1-grid';

  @override
  void paint(Canvas canvas, Size size) {
    if (!KlinexDebug.logPaint) {
      _paintLayer(canvas, size);
      return;
    }
    final sw = Stopwatch()..start();
    _paintLayer(canvas, size);
    KlinexDebug.paint(debugLayerName, sw.elapsedMicroseconds);
  }

  @override
  bool shouldRepaint(covariant GridPainter oldDelegate) =>
      oldDelegate.controller != controller ||
      oldDelegate.config != config ||
      oldDelegate.plotLabels != plotLabels;

  void _paintLayer(Canvas canvas, Size size) {
    // Axis labels wider than the axis must not draw outside the widget; RepaintBoundary
    // doesn't clip.
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    _paintClipped(canvas, size);
    canvas.restore();
  }

  void _paintClipped(Canvas canvas, Size size) {
    final theme = config.theme.value;
    if (plotLabels) {
      _paintValueLabels(canvas, controller.resolveLayout(size, config), plot: true);
      return;
    }
    canvas.drawRect(
      Offset.zero & size,
      controller.pool.fill..color = theme.background,
    );

    final ctx = controller.resolveLayout(size, config);
    final pool = controller.pool;

    // Vertical grid: the plot area is split into 4 equal columns; the theme's dash pattern is
    // [dash, gap].
    _line.color = theme.gridLine;
    _line.strokeWidth = theme.gridLineWidth;
    final gridDash = theme.gridLineDash;
    final dashLen = gridDash != null && gridDash.isNotEmpty ? gridDash[0] : 0.0;
    final gapLen = gridDash != null && gridDash.length > 1 ? gridDash[1] : dashLen;
    final dashed = dashLen > 0;
    const columns = 4;
    final plotW = ctx.chartRect.width;
    final plotL = ctx.chartRect.left;
    final offsetOf = _offsetFn(ctx);
    final ticks = config.tieredTimeAxis && !ctx.isEmpty
        ? pickTimeTicks(
            ctx.bars,
            ctx.start,
            ctx.end,
            (i) => ctx.xOf(i),
            config.tickMinSpacing,
            offsetOf: offsetOf,
          )
        : null;
    final gridXs = ticks == null
        ? [for (var j = 1; j < columns; j++) plotL + plotW * j / columns]
        : [
            for (final (i, _) in ticks)
              if (ctx.xOf(i) > plotL && ctx.xOf(i) < plotL + plotW) ctx.xOf(i),
          ];
    for (final gx in theme.showGrid ? gridXs : const <double>[]) {
      final x = config.snap(gx, strokeWidth: theme.gridLineWidth);
      if (dashed) {
        pool.drawDashedVLine(
          canvas,
          x,
          ctx.chartRect.top,
          ctx.chartRect.bottom,
          _line,
          dash: dashLen,
          gap: gapLen,
        );
      } else {
        canvas.drawLine(
          Offset(x, ctx.chartRect.top),
          Offset(x, ctx.chartRect.bottom),
          _line,
        );
      }
    }

    for (final panel in ctx.panels) {
      // Horizontal grid
      final rows = panel.isMain ? 4 : 2;
      for (var r = 1; theme.showGrid && r < rows; r++) {
        final y = config.snap(
          panel.rect.top + panel.rect.height * r / rows,
          strokeWidth: theme.gridLineWidth,
        );
        _line.color = theme.gridLine;
        _line.strokeWidth = theme.gridLineWidth;
        if (dashed) {
          pool.drawDashedHLine(
            canvas,
            y,
            panel.rect.left,
            panel.rect.right,
            _line,
            dash: dashLen,
            gap: gapLen,
          );
        } else {
          canvas.drawLine(Offset(panel.rect.left, y), Offset(panel.rect.right, y), _line);
        }
      }
      // Panel separator: fixed 1px solid line, extending across the axis strip.
      _line.color = theme.panelSeparator;
      _line.strokeWidth = 1;
      final sy = config.snap(panel.rect.bottom);
      canvas.drawLine(
        Offset(ctx.hasLeftAxis ? ctx.leftAxisRect.left : panel.rect.left, sy),
        Offset(ctx.axisOutside ? ctx.yAxisRect.right : panel.rect.right, sy),
        _line,
      );
    }

    _paintValueLabels(canvas, ctx, plot: false);

    // Outside axis: a border line between the plot area and the axis strip.
    _line.color = theme.panelSeparator;
    for (final edge in [
      if (ctx.axisOutside) ctx.yAxisRect.left,
      if (ctx.hasLeftAxis) ctx.leftAxisRect.right,
    ]) {
      final bx = config.snap(edge);
      canvas.drawLine(Offset(bx, ctx.chartRect.top), Offset(bx, ctx.chartRect.bottom), _line);
    }

    // Time labels show the nearest bar's own time (pixel interpolation would produce
    // nonexistent marks like 17:20), extrapolated by whole bars in the right padding. Labels
    // stay pinned to fixed grid lines rather than following bars; otherwise they'd jump back
    // every half bar while panning and jitter during fast scrolls.
    if (ticks != null) {
      _paintTieredLabels(canvas, ctx, ticks, offsetOf);
    } else if (!ctx.isEmpty) {
      final n = ctx.bars.length;
      for (var j = 1; j < columns; j++) {
        final gridX = plotL + plotW * j / columns;
        final i = ctx.indexAt(gridX).round();
        final onBar = i >= 0 && i < n;
        final tp = pool.text(
          ctx.formatTime(
            onBar ? ctx.bars[i].time : ctx.timeOfIndex(i.toDouble()).round(),
          ),
          theme.axisStyle,
        );
        tp.paint(
          canvas,
          Offset(
            gridX - tp.width / 2,
            ctx.timeAxisRect.top + (ctx.timeAxisRect.height - tp.height) / 2,
          ),
        );
      }
    }
  }

  /// Value labels. When [plot] is true, draws only those inside the plot area; when false, only
  /// those in the axis strips. Both passes use the same overlap-avoidance logic.
  void _paintValueLabels(Canvas canvas, RenderContext ctx, {required bool plot}) {
    final theme = config.theme.value;
    final pool = controller.pool;
    for (final panel in ctx.panels) {
      final rows = panel.isMain ? 4 : 2;
      var lastLabelBottom = double.negativeInfinity;
      for (var r = 0; r <= rows; r++) {
        final y = config.snap(
          panel.rect.top + panel.rect.height * r / rows,
          strokeWidth: theme.gridLineWidth,
        );
        final value = panel.valueAtFraction(r / rows);
        final tp = pool.text(ctx.formatAxisValue(panel, value), theme.axisStyle);
        final minTy = panel.rect.top + 2;
        final maxTy = panel.rect.bottom - tp.height - 2;
        // Panel shorter than the label: it won't fit and would spill into the adjacent panel.
        if (maxTy < minTy) break;
        final rawTy = r == 0 ? y + 2 : y - tp.height - 2;
        final ty = rawTy.clamp(minTy, maxTy);
        if (ty < lastLabelBottom + 2) continue;
        lastLabelBottom = ty + tp.height;
        final sec = panel.secondary;
        final rightAxis = ctx.axisOutside || ctx.axisInside;
        if (!plot) {
          if (ctx.axisOutside) tp.paint(canvas, Offset(ctx.yAxisRect.left + 4, ty));
          // With a secondary value axis: if both sides have axis strips it takes the left one,
          // otherwise it's labeled at the plot edge opposite the main axis.
          if (ctx.hasLeftAxis && (sec == null || !rightAxis)) {
            tp.paint(canvas, Offset(ctx.leftAxisRect.right - tp.width - 4, ty));
          }
        } else if (ctx.axisInside) {
          tp.paint(canvas, Offset(panel.rect.right - tp.width - 4, ty));
        }
        // When labeled at the plot's left edge, skip the first row: the legend is there.
        final secInPlot = !ctx.hasLeftAxis;
        if (sec == null || (secInPlot && r == 0 && panel.isMain)) continue;
        final inStrip = ctx.hasLeftAxis && rightAxis;
        if (inStrip == plot) continue;
        final st = pool.text(
          ctx.formatAxisValue(sec, sec.valueAtFraction(r / rows)),
          theme.axisStyle,
        );
        final sx = inStrip
            ? ctx.leftAxisRect.right - st.width - 4
            : ctx.hasLeftAxis
            ? panel.rect.right - st.width - 4
            : panel.rect.left + 4;
        st.paint(canvas, Offset(sx, ty));
      }
    }
  }

  /// Tiered tick time zone: a fixed value if utcOffset is set; when following the device, a
  /// constant if the offsets at both ends of the visible range match, otherwise (crossing DST)
  /// per bar, matching the crosshair's local-time readout.
  int Function(int) _offsetFn(RenderContext ctx) {
    final fixed = config.utcOffset?.inMilliseconds;
    if (fixed != null) return (_) => fixed;
    final bars = ctx.bars;
    if (bars.isEmpty) return (_) => 0;
    int device(int ms) => DateTime.fromMillisecondsSinceEpoch(ms).timeZoneOffset.inMilliseconds;
    final a = device(bars[(ctx.start - 1).clamp(0, bars.length - 1)].time);
    final b = device(bars[ctx.end.clamp(0, bars.length - 1)].time);
    return a == b ? (_) => a : device;
  }

  /// Tiered tick text: regular weight when only one tier is present; with mixed tiers, the
  /// highest is bold (day/month changes stand out at a glance).
  void _paintTieredLabels(
    Canvas canvas,
    RenderContext ctx,
    List<(int, TimeTier)> ticks,
    int Function(int) offsetOf,
  ) {
    if (ticks.isEmpty) return;
    final theme = config.theme.value;
    final plotL = ctx.chartRect.left, plotR = ctx.chartRect.right;
    // Only on-screen ticks: the bold tier is chosen from visible ticks, so it doesn't flicker
    // when panning across boundaries.
    final visible = [
      for (final (i, tier) in ticks)
        if (ctx.xOf(i) >= plotL && ctx.xOf(i) <= plotR) (i, tier),
    ];
    if (visible.isEmpty) return;
    var top = visible.first.$2, bottom = visible.first.$2;
    for (final (_, t) in visible) {
      if (t.index > top.index) top = t;
      if (t.index < bottom.index) bottom = t;
    }
    final bold = theme.axisStyle.copyWith(fontWeight: FontWeight.w600);
    final y = ctx.timeAxisRect.top;
    // Avoid overlap by actual text width: higher tiers claim space first; labels overlapping
    // claimed ones (including a 4px gap) are skipped.
    final order = [...visible]..sort((a, b) => b.$2.index.compareTo(a.$2.index));
    final taken = <(double, double)>[];
    for (final (i, tier) in order) {
      final ms = ctx.bars[i].time;
      final text =
          config.tickFormatter?.call(ms, tier) ??
          defaultTickLabel(ms, tier, offsetMs: offsetOf(ms));
      final tp = controller.pool.text(text, tier == top && top != bottom ? bold : theme.axisStyle);
      final left = clampSafe(ctx.xOf(i) - tp.width / 2, plotL, plotR - tp.width);
      final right = left + tp.width;
      if (taken.any((r) => left < r.$2 + 4 && right > r.$1 - 4)) continue;
      taken.add((left, right));
      tp.paint(canvas, Offset(left, y + (ctx.timeAxisRect.height - tp.height) / 2));
    }
  }
}
