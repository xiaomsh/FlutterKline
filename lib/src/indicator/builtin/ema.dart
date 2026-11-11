import 'dart:ui';

import '../../model/bar.dart';
import '../../panel/panel.dart';
import '../indicator.dart';

/// One exponential smoothing step: α = 2/(p+1). When [prev] is NaN (first bar, unseeded),
/// seeds with [value]. Shared recurrence for EMA, MACD and TRIX.
double emaStep(double prev, double value, int p) =>
    prev.isNaN ? value : (value - prev) * (2 / (p + 1)) + prev;

/// Exponential moving average of close, overlaid on the main panel. Seeded with close[0];
/// the recurrence chain is stored, so each incremental step is O(1) and exact.
class Ema extends LineIndicator {
  final List<int> periods;
  final List<Color>? colors;
  final double lineWidth;

  Ema({this.periods = const [12, 26], this.colors, this.lineWidth = 1}) {
    checkPositivePeriods(periods, 'periods');
  }

  @override
  late final List<String> seriesKeys = [for (final p in periods) 'ema$p'];

  @override
  late final List<String> seriesLabels = [for (final p in periods) 'EMA$p'];

  @override
  List<Color>? get seriesColors => colors;

  @override
  double get seriesLineWidth => lineWidth;

  @override
  int get paletteOffset => 3;

  @override
  String get id => 'ema(${periods.join(',')})';

  @override
  PanelRef get target => PanelRef.main;

  @override
  int get warmupBars => 2;

  /// Exponential smoothing: old state decays by (1-α)^m and falls below double precision
  /// after 40 * period bars.
  @override
  int? get prependSettleBars =>
      Indicator.settleForSmoothing(periods.fold(0, (a, b) => a > b ? a : b));

  @override
  void computeAt(List<Bar> bars, int i, IndicatorStore store) {
    for (final p in periods) {
      final s = store.series('ema$p');
      s[i] = emaStep(i == 0 ? double.nan : s[i - 1], bars[i].close, p);
    }
  }
}
