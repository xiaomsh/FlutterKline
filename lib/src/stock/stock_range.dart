import 'package:flutter/foundation.dart';

import '../model/min_max.dart';
import '../render/range_adjust.dart';

/// Main-range adjustment for stock charts (`KChart.mainRange`, applied to the padded range):
/// - the range always contains [include] (limit prices, levels), plus [margin] × span beyond
///   those outside the data;
/// - with [symmetricAround] (usually the previous close) it is widened to be symmetric around
///   that price, which then sits exactly in the middle as on intraday charts; ignored when null
///   or not positive;
/// - [minSpanRatio] keeps a flat day from collapsing (default ±0.1% of the base).
@immutable
class StockRange extends RangeAdjust {
  const StockRange({
    this.symmetricAround,
    this.include = const [],
    this.minSpanRatio = 0.001,
    this.margin = 0.03,
  });

  final double? symmetricAround;
  final List<double> include;
  final double minSpanRatio;
  final double margin;

  @override
  MinMax apply(MinMax range) {
    var out = range;
    var levels = MinMax.empty;
    for (final v in include) {
      if (v.isFinite) levels = levels.include(v);
    }
    if (!levels.isEmpty) {
      final pad = out.union(levels).span * margin;
      out = MinMax(
        levels.min < out.min ? levels.min - pad : out.min,
        levels.max > out.max ? levels.max + pad : out.max,
      );
    }
    final base = symmetricAround;
    if (base == null || !base.isFinite || base <= 0) return out;
    out = out.include(base);
    var d = (out.max - base).abs();
    final low = (base - out.min).abs();
    if (low > d) d = low;
    final floor = base * minSpanRatio;
    if (d < floor) d = floor;
    return MinMax(base - d, base + d);
  }

  @override
  bool operator ==(Object other) =>
      other is StockRange &&
      other.symmetricAround == symmetricAround &&
      listEquals(other.include, include) &&
      other.minSpanRatio == minSpanRatio &&
      other.margin == margin;

  @override
  int get hashCode => Object.hash(symmetricAround, Object.hashAll(include), minSpanRatio, margin);

  @override
  String toString() => 'StockRange(around: $symmetricAround, include: $include)';
}
