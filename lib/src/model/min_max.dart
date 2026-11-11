import 'dart:math' as math;

/// When bounds are inverted (panel shorter than the label), returns the lower bound instead of
/// throwing: num.clamp throws, and a throw during paint blanks the whole layer
double clampSafe(double v, double lo, double hi) => lo >= hi ? lo : v.clamp(lo, hi);

/// A value range. Empty (min > max) is treated as absent when merging
class MinMax {
  final double min, max;

  const MinMax(this.min, this.max);

  static const empty = MinMax(double.infinity, double.negativeInfinity);

  bool get isEmpty => min > max;

  double get span => max - min;

  MinMax union(MinMax other) {
    if (other.isEmpty) return this;
    if (isEmpty) return other;
    return MinMax(
      min < other.min ? min : other.min,
      max > other.max ? max : other.max,
    );
  }

  MinMax include(double v) {
    if (v.isNaN) return this;
    return MinMax(v < min ? v : min, v > max ? v : max);
  }

  /// Expands a zero-width/empty range so span > 0, avoiding division by zero in y mapping. A flat
  /// line uses
  /// 1% of the price (±1 near a price of 0).
  MinMax get _spread {
    if (isEmpty) return const MinMax(0, 1);
    if (span > 0) return this;
    final d = min.abs() > 1e-9 ? min.abs() * 0.01 : 1.0;
    return MinMax(min - d, max + d);
  }

  /// Pads by a fraction of the span ([bottom] defaults to [top]); pass bottom 0 to pin the baseline
  /// (volume panel)
  MinMax padded(double top, [double? bottom]) {
    if (isEmpty || span <= 0) return _spread;
    return MinMax(min - span * (bottom ?? top), max + span * top);
  }

  /// Pads in pixels: regardless of span, extremes sit exactly [top] / [bottom] px from the panel
  /// edge
  MinMax paddedPx(double height, double top, double bottom) {
    final m = _spread;
    final usable = height - top - bottom;
    if (isEmpty || usable <= 0) return m;
    final perPx = m.span / usable;
    return MinMax(m.min - bottom * perPx, m.max + top * perPx);
  }

  /// Pixel padding in log scale: linear padding would push the lower bound below 0, breaking log
  /// scale
  MinMax paddedPxLog(double height, double top, double bottom) {
    final m = _spread;
    if (isEmpty || m.min <= 0) return paddedPx(height, top, bottom);
    final p = MinMax(math.log(m.min), math.log(m.max)).paddedPx(height, top, bottom);
    return MinMax(math.exp(p.min), math.exp(p.max));
  }

  @override
  String toString() => 'MinMax($min, $max)';
}

/// Extremes of [values] over an index range (inclusive), skipping NaN. Called by every frame's
/// layout, allocating only one object per call
MinMax seriesMinMax(List<double> values, int start, int end) {
  var lo = double.infinity, hi = double.negativeInfinity;
  final n = values.length;
  for (var i = start < 0 ? 0 : start; i <= end && i < n; i++) {
    final v = values[i];
    if (v.isNaN) continue;
    if (v < lo) lo = v;
    if (v > hi) hi = v;
  }
  return lo > hi ? MinMax.empty : MinMax(lo, hi);
}
