import 'dart:math' as math;
import 'dart:ui';

import '../../model/bar.dart';
import '../../model/min_max.dart';
import '../../panel/panel.dart';
import '../indicator.dart';

/// Bollinger Bands (mid = SMA, upper/lower = mid ± k·σ, population std dev), overlaid on
/// the main panel.
class Boll extends LineIndicator {
  final int period;
  final double k;
  final List<Color>? colors; // [mid, up, dn]
  final double lineWidth;

  Boll({this.period = 20, this.k = 2, this.colors, this.lineWidth = 1}) {
    checkPositivePeriod(period, 'period');
    checkPositiveFinite(k, 'k');
  }

  @override
  List<String> get seriesKeys => const ['boll_mid', 'boll_up', 'boll_dn'];

  @override
  List<String> get seriesLabels => const ['BOLL', 'UB', 'LB'];

  @override
  List<Color>? get seriesColors => colors;

  @override
  double get seriesLineWidth => lineWidth;

  @override
  String get id => 'boll($period,$k)';

  @override
  PanelRef get target => PanelRef.main;

  @override
  int get warmupBars => period + 1;

  /// Windowed: values depend only on the last period bars; anything older has exactly no
  /// effect.
  @override
  int? get prependSettleBars => warmupBars;

  @override
  void computeAt(List<Bar> bars, int i, IndicatorStore store) {
    final mid = store.series('boll_mid');
    final up = store.series('boll_up');
    final dn = store.series('boll_dn');
    // Partial window: before a full period, use the available min(period, i+1) bars, so
    // values start at bar 0 (at i=0, σ=0 and the bands coincide with the mid at the close,
    // widening as the window fills).
    final count = math.min(period, i + 1);
    var sum = 0.0;
    for (var j = i - count + 1; j <= i; j++) {
      sum += bars[j].close;
    }
    final m = sum / count;
    var sq = 0.0;
    for (var j = i - count + 1; j <= i; j++) {
      final d = bars[j].close - m;
      sq += d * d;
    }
    final sd = math.sqrt(sq / count);
    mid[i] = m;
    up[i] = m + k * sd;
    dn[i] = m - k * sd;
  }

  /// Autoscale only considers the upper/lower bands (the mid always lies between them).
  @override
  MinMax range(IndicatorStore store, int start, int end) =>
      seriesRange(store, const ['boll_up', 'boll_dn'], start, end);
}
