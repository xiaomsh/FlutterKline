import 'package:flutter/rendering.dart';

import '../../render/context.dart';
import '../../render/main_series.dart';
import '../../render/series_paint_kit.dart';

/// Area chart (line + gradient fill).
class AreaSeries extends MainSeries {
  const AreaSeries();

  @override
  String get kind => 'area';

  /// Only plots close; wicks are excluded from the range (otherwise the line gets flattened).
  @override
  bool get usesHighLow => false;

  @override
  void paint(Canvas canvas, RenderContext ctx, SeriesPaintKit kit) {
    final path = kit.closePath(ctx);
    if (path == null) return;
    final main = ctx.mainPanel;
    final color = ctx.theme.seriesLine;
    final base = main.minEdge;
    final fillPath = Path.from(path)
      ..lineTo(kit.closeLastX, base)
      ..lineTo(kit.closeFirstX, base)
      ..close();
    final far = main.inverted ? main.rect.bottom : main.rect.top;
    final fill = ctx.pool.fill..shader = kit.verticalGradient(far, base, color);
    canvas.drawPath(fillPath, fill);
    // Pooled paints are shared, so the shader must not be left set.
    fill.shader = null;
    canvas.drawPath(
      path,
      ctx.pool.stroke
        ..color = ctx.theme.seriesLine
        ..strokeWidth = 1.6,
    );
  }
}
