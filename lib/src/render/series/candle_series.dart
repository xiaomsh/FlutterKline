import 'dart:math' as math;

import 'package:flutter/rendering.dart';

import '../../render/context.dart';
import '../../render/main_series.dart';
import '../../render/series_paint_kit.dart';

/// Candlestick chart. Body fill mode reads [ChartConfig.candleFill]; when bodies are too narrow
/// to see the outline,
/// hollow falls back to filled.
class CandleSeries extends MainSeries {
  const CandleSeries();

  @override
  String get kind => 'candle';

  @override
  void paint(Canvas canvas, RenderContext ctx, SeriesPaintKit kit) {
    final theme = ctx.theme;
    final main = ctx.mainPanel;
    final wickUp = kit.batch(0), wickDown = kit.batch(1);
    final bodyUp = kit.batch(2), bodyDown = kit.batch(3);
    final hollowUpPath = kit.path(0), hollowDownPath = kit.path(1);
    final borderUpPath = kit.path(2), borderDownPath = kit.path(3);

    final drawW = ctx.drawWidth;
    final minW = ctx.minStrokeWidth;
    final wickW = (drawW * 0.12).clamp(minW, 2.0);
    // Same width as volume bars: narrow bars keep at least a 1px gap, or adjacent bodies merge
    final bodyW = ctx.barStrokeWidth();
    // Hollow only when bodies are wide enough to see the outline; falls back to filled under
    // subpixel aggregation.
    final fill = ctx.config.candleFill;
    final hollowUp = fill == CandleFillMode.hollowUp && bodyW > 3.0;
    final hollowDown = fill == CandleFillMode.hollowDown && bodyW > 3.0;
    // Same for borders: on too-narrow bodies the stroke would cover the fill
    final borderUp = theme.upBorder != null && !hollowUp && bodyW > 3.0;
    final borderDown = theme.downBorder != null && !hollowDown && bodyW > 3.0;

    kit.forEachBucket(ctx, (x, o, h, l, c) {
      final yH = main.yOf(h);
      final yL = main.yOf(l);
      final yO = main.yOf(o);
      var yC = main.yOf(c);
      if ((yO - yC).abs() < 1) yC = yO + 1; // Doji: keep a visible body
      final up = c >= o;
      final wick = up ? wickUp : wickDown;
      if (up ? hollowUp : hollowDown) {
        final top = math.min(yO, yC), bottom = math.max(yO, yC);
        // Wicks draw only the two segments outside the body, not through the hollow rect
        // With an inverted scale high is below, so use screen top/bottom
        final wTop = math.min(yH, yL), wBottom = math.max(yH, yL);
        if (wTop < top) wick.add(x, wTop, x, top);
        if (wBottom > bottom) wick.add(x, bottom, x, wBottom);
        (up ? hollowUpPath : hollowDownPath).addRect(
          Rect.fromLTRB(x - bodyW / 2, top, x + bodyW / 2, bottom),
        );
      } else {
        wick.add(x, yH, x, yL);
        (up ? bodyUp : bodyDown).add(x, yO, x, yC);
        if (up ? borderUp : borderDown) {
          (up ? borderUpPath : borderDownPath).addRect(
            Rect.fromLTRB(x - bodyW / 2, math.min(yO, yC), x + bodyW / 2, math.max(yO, yC)),
          );
        }
      }
    });

    kit.drawSegments(canvas, wickUp, theme.upWickColor, wickW);
    kit.drawSegments(canvas, wickDown, theme.downWickColor, wickW);
    kit.drawSegments(canvas, bodyUp, theme.up, bodyW);
    kit.drawSegments(canvas, bodyDown, theme.down, bodyW);
    void stroke(Path path, Color color) {
      if (path.getBounds().isEmpty) return;
      canvas.drawPath(
        path,
        kit.crispStroke
          ..color = color
          ..strokeWidth = 1,
      );
    }

    stroke(hollowUpPath, theme.upBorder ?? theme.up);
    stroke(hollowDownPath, theme.downBorder ?? theme.down);
    if (borderUp) stroke(borderUpPath, theme.upBorder!);
    if (borderDown) stroke(borderDownPath, theme.downBorder!);
  }
}
