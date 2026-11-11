import 'dart:math' as math;
import 'dart:ui';

import '../../model/bar.dart';
import '../../panel/panel.dart';
import '../indicator.dart';

/// Wilder RSI on its own sub-panel; multiple periods can be drawn together. Average gain/loss are
/// stored, so each incremental step is O(1) and exact.
class Rsi extends LineIndicator {
  final List<int> periods;
  final List<Color>? colors;
  final double lineWidth;

  /// Single period uses [period]/[color]; multiple periods use [periods]/[colors] (takes priority).
  Rsi({
    int period = 14,
    List<int>? periods,
    Color? color,
    List<Color>? colors,
    this.lineWidth = 1,
  }) : periods = periods ?? [period],
       colors = colors ?? (color == null ? null : [color]) {
    checkPositivePeriods(this.periods, 'periods');
  }

  @override
  late final List<String> seriesKeys = [for (final p in periods) 'rsi$p'];

  @override
  late final List<String> seriesLabels = [for (final p in periods) 'RSI($p)'];

  @override
  List<Color>? get seriesColors => colors;

  @override
  double get seriesLineWidth => lineWidth;

  @override
  String get id => 'rsi(${periods.join(',')})';

  @override
  PanelRef get target => const PanelRef.own();

  @override
  int get warmupBars => periods.fold(0, (a, b) => a > b ? a : b) + 2;

  /// Wilder smoothing (α=1/p, among the slowest-decaying kind).
  @override
  int? get prependSettleBars =>
      Indicator.settleForSmoothing(periods.fold(0, (a, b) => a > b ? a : b));

  @override
  void computeAt(List<Bar> bars, int i, IndicatorStore store) {
    for (final p in periods) {
      store.series('rsi$p')[i] = rsiStep(
        bars,
        i,
        p,
        store.series('rsi${p}_ag'),
        store.series('rsi${p}_al'),
      );
    }
  }
}

/// One Wilder RSI step: advances the average gain / loss chains [ag] / [al] to [i] and returns this
/// bar's RSI.
/// Bar 0 has nothing to compare, so it gets NaN (chains set to 0); bar 1 seeds with its own change,
/// so the line aligns with the bars from bar 1.
double rsiStep(
  List<Bar> bars,
  int i,
  int p,
  List<double> ag,
  List<double> al,
) {
  if (i == 0) {
    ag[0] = al[0] = 0;
    return double.nan;
  }
  final d = bars[i].close - bars[i - 1].close;
  final g = math.max(d, 0.0), l = math.max(-d, 0.0);
  final a = i == 1 ? g : (ag[i - 1] * (p - 1) + g) / p;
  final b = i == 1 ? l : (al[i - 1] * (p - 1) + l) / p;
  ag[i] = a;
  al[i] = b;
  return (a + b) == 0 ? 50.0 : 100 * a / (a + b);
}
