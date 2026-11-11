import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import '../../controller.dart';
import '../../model/min_max.dart';
import '../../render/context.dart';
import '../overlay_plugin.dart';

/// Built-in crosshair plugin; repaints only the overlay layer
class CrosshairOverlay extends OverlayPlugin {
  /// Price labels must sit above the host's last-price/countdown on the y axis, or the value is
  /// unreadable while pressing.
  @override
  bool get onTop => true;

  @override
  List<Listenable> repaintOn(ChartController controller) => [
    controller.crosshair,
    controller.viewport,
    // When data changes the value range may change too, so the price label at the same y must
    // repaint
    controller.dataRevision,
  ];

  @override
  void paint(Canvas canvas, RenderContext ctx) {
    final state = ctx.controller.crosshair.value;
    if (state == null || ctx.isEmpty) return;

    final theme = ctx.theme;
    final bars = ctx.bars;
    final index = ctx.controller.crosshairIndex();
    if (index < 0) return;
    final x = ctx.xOf(index);
    if (x < ctx.chartRect.left - ctx.barWidth || x > ctx.chartRect.right + ctx.barWidth) {
      return; // The selected bar has scrolled off screen
    }

    final line = ctx.pool.stroke
      ..color = theme.crosshair
      ..strokeWidth = 0.8;
    // Solid/dashed is decided by the host theme (like gridLineDash), not hard-coded in the library.
    final dash = theme.crosshairDash;
    final dashLen = dash != null && dash.isNotEmpty ? dash[0] : 0.0;
    final gapLen = dash != null && dash.length > 1 ? dash[1] : dashLen;

    // The selected bar may be half outside the plot area; the vertical line must not cover y-axis
    // labels
    canvas.save();
    canvas.clipRect(ctx.chartRect);
    if (dashLen > 0) {
      ctx.pool.drawDashedVLine(
        canvas,
        x,
        ctx.chartRect.top,
        ctx.chartRect.bottom,
        line,
        dash: dashLen,
        gap: gapLen,
      );
    } else {
      canvas.drawLine(Offset(x, ctx.chartRect.top), Offset(x, ctx.chartRect.bottom), line);
    }
    canvas.restore();

    final labelStyle = TextStyle(
      color: theme.crosshairLabelText,
      fontSize: theme.axisTextSize,
    );

    // Synced crosshair: another chart's y is meaningless here
    if (!state.timeOnly) {
      final panel = ctx.panelAt(state.position) ?? ctx.mainPanel;
      final y = state.position.dy.clamp(panel.rect.top, panel.rect.bottom);
      if (dashLen > 0) {
        ctx.pool.drawDashedHLine(
          canvas,
          y,
          ctx.chartRect.left,
          ctx.chartRect.right,
          line,
          dash: dashLen,
          gap: gapLen,
        );
      } else {
        canvas.drawLine(Offset(ctx.chartRect.left, y), Offset(ctx.chartRect.right, y), line);
      }

      final valueText = ctx.formatAxisValue(panel, panel.valueOf(y));
      final vh = ctx.pool.text(valueText, labelStyle).height + 4;
      final ly = clampSafe(y - vh / 2, panel.rect.top, panel.rect.bottom - vh);
      void label(double x, bool alignRight, [String? text]) => ctx.pool.drawBoxedLabel(
        canvas,
        text ?? valueText,
        labelStyle,
        Offset(x, ly),
        theme.crosshairLabelBg,
        alignRight: alignRight,
      );
      final sec = panel.secondary;
      final rightAxis = ctx.axisOutside || ctx.axisInside;
      if (ctx.axisOutside) label(ctx.yAxisRect.left, false);
      if (ctx.hasLeftAxis && (sec == null || !rightAxis)) {
        label(
          ctx.leftAxisRect.right,
          true,
          ctx.formatAxisValue(panel, panel.valueOf(y), left: true),
        );
      }
      if (ctx.axisInside) label(ctx.chartRect.right, true);
      // Second value axis readout goes on its tick side, same position as grid labels
      if (sec != null) {
        final secText = ctx.formatAxisValue(sec, sec.valueOf(y));
        final (double sx, bool right) = ctx.hasLeftAxis && rightAxis
            ? (ctx.leftAxisRect.right, true)
            : ctx.hasLeftAxis
            ? (ctx.chartRect.right, true)
            : (ctx.chartRect.left, false);
        ctx.pool.drawBoxedLabel(
          canvas,
          secText,
          labelStyle,
          Offset(sx, ly),
          theme.crosshairLabelBg,
          alignRight: right,
        );
      }
    }

    // The time label is centered on the selected bar, but at the leftmost/rightmost bar it would
    // draw outside the widget,
    // so the anchor is clamped into view by half the label width (price labels were already
    // clamped; this one was missed).
    final timeText = ctx.formatTime(bars[index].time);
    const labelHPad = 4.0;
    final halfW = ctx.pool.text(timeText, labelStyle).width / 2 + labelHPad;
    ctx.pool.drawBoxedLabel(
      canvas,
      timeText,
      labelStyle,
      Offset(clampSafe(x, halfW, ctx.size.width - halfW), ctx.timeAxisRect.top + 1),
      theme.crosshairLabelBg,
      centerX: true,
    );
  }
}
