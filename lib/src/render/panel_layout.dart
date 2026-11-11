import 'dart:math' as math;
import 'dart:ui';

import '../indicator/indicator.dart';
import '../model/min_max.dart';

/// A laid-out panel: its rect and the value-to-pixel mapping (linear or log).
class PanelLayout {
  PanelLayout({
    required this.id,
    required this.isMain,
    required this.rect,
    required this.range,
    required this.indicators,
    bool logScale = false,
    this.inverted = false,
    this.secondary,
    this.isSecondary = false,
  }) : logScale = logScale && range.min > 0,
       _lmin = logScale && range.min > 0 ? math.log(range.min) : 0,
       _lmax = logScale && range.min > 0 ? math.log(range.max) : 1;

  final String id;
  final bool isMain;
  final Rect rect;
  final MinMax range;
  final List<Indicator> indicators;

  /// Log mapping is only used when the whole range is positive.
  final bool logScale;

  /// Inverted coordinates: small values on top, large values at the bottom.
  final bool inverted;

  /// Secondary value axis of the main panel (same rect, independent linear range); null when
  /// nothing uses it.
  final PanelLayout? secondary;

  /// Whether this is itself some main panel's secondary value axis.
  final bool isSecondary;
  final double _lmin, _lmax;

  double yOf(double value) {
    final double f;
    if (!logScale) {
      f = (value - range.min) / range.span;
    } else {
      final lv = math.log(value < 1e-12 ? 1e-12 : value);
      f = (lv - _lmin) / (_lmax - _lmin);
    }
    return inverted ? rect.top + f * rect.height : rect.bottom - f * rect.height;
  }

  double valueOf(double y) {
    final f = inverted ? (y - rect.top) / rect.height : (rect.bottom - y) / rect.height;
    if (!logScale) return range.min + f * range.span;
    return math.exp(_lmin + (_lmax - _lmin) * f);
  }

  /// Value at a vertical fraction (0 top, 1 bottom): grid labels must interpolate in mapping space
  /// (possibly log), not value space.
  double valueAtFraction(double f) {
    final g = inverted ? 1 - f : f;
    if (!logScale) return range.max - range.span * g;
    return math.exp(_lmax - (_lmax - _lmin) * g);
  }

  /// Edge on the range-minimum side (area fill and bar baseline).
  double get minEdge => inverted ? rect.top : rect.bottom;
}
