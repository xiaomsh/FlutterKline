import 'package:flutter/rendering.dart';

import 'context.dart';
import 'series/area_series.dart';
import 'series/candle_series.dart';
import 'series/line_series.dart';
import 'series_paint_kit.dart';

/// Main series plugin (open extension point). Implementers declare the range basis [usesHighLow]
/// and paint in [paint]; the canvas is clipped to the main panel
abstract class MainSeries {
  const MainSeries();

  /// Stable identifier (for logs, persistence); built-in styles share names with [MainSeriesStyle]
  String get kind;

  /// true: high/low contribute to the main chart range; close-only styles must return false, or
  /// the line is flattened by a range stretched by wicks
  bool get usesHighLow => true;

  /// Use `ctx.xOf(i)` / `ctx.mainPanel.yOf(v)` for coordinates
  void paint(Canvas canvas, RenderContext ctx, SeriesPaintKit kit);

  /// Maps the built-in enum to an instance; other styles pass a [MainSeries] instance directly
  static MainSeries fromStyle(MainSeriesStyle style) => switch (style) {
    MainSeriesStyle.candle => const CandleSeries(),
    MainSeriesStyle.line => const LineSeries(),
    MainSeriesStyle.area => const AreaSeries(),
  };
}
