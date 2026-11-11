import 'package:flutter/rendering.dart';

import '../../render/context.dart';
import '../../render/main_series.dart';
import '../../render/series_paint_kit.dart';

/// Line chart (close-price polyline)
class LineSeries extends MainSeries {
  const LineSeries();

  @override
  String get kind => 'line';

  /// Draws close only; wicks don't affect the range (otherwise the line gets flattened)
  @override
  bool get usesHighLow => false;

  @override
  void paint(Canvas canvas, RenderContext ctx, SeriesPaintKit kit) {
    final path = kit.closePath(ctx);
    if (path == null) return;
    canvas.drawPath(
      path,
      ctx.pool.stroke
        ..color = ctx.theme.seriesLine
        ..strokeWidth = 1.6,
    );
  }
}
