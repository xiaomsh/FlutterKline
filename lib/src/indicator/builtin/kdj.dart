import 'dart:ui';

import '../../model/bar.dart';
import '../../panel/panel.dart';
import '../indicator.dart';

/// KDJ on its own sub-panel. K / D chains are stored; incremental updates only rescan the RSV
/// window (O(n)).
class Kdj extends LineIndicator {
  final int n, m1, m2;
  final List<Color>? colors; // [k, d, j]
  final double lineWidth;

  Kdj({this.n = 9, this.m1 = 3, this.m2 = 3, this.colors, this.lineWidth = 1}) {
    checkPositivePeriod(n, 'n');
    checkPositivePeriod(m1, 'm1');
    checkPositivePeriod(m2, 'm2');
  }

  @override
  String get id => 'kdj($n,$m1,$m2)';

  @override
  PanelRef get target => const PanelRef.own();

  @override
  int get warmupBars => n + 2;

  /// RSV is windowed; K/D are recursive smoothing.
  @override
  int? get prependSettleBars => Indicator.settleForSmoothing(n);

  @override
  List<String> get seriesKeys => const ['kdj_k', 'kdj_d', 'kdj_j'];

  @override
  List<String> get seriesLabels => const ['K', 'D', 'J'];

  @override
  List<Color>? get seriesColors => colors;

  @override
  double get seriesLineWidth => lineWidth;

  @override
  late final String? legendHeader = 'KDJ($n,$m1,$m2)';

  @override
  void computeAt(List<Bar> bars, int i, IndicatorStore store) {
    final ks = store.series('kdj_k');
    final ds = store.series('kdj_d');
    final js = store.series('kdj_j');
    final (lo, hi) = windowHighLow(bars, i, n);
    final rsv = hi == lo ? 50.0 : (bars[i].close - lo) / (hi - lo) * 100;
    final kPrev = i == 0 ? 50.0 : ks[i - 1];
    final dPrev = i == 0 ? 50.0 : ds[i - 1];
    final k = (kPrev * (m1 - 1) + rsv) / m1;
    final d = (dPrev * (m2 - 1) + k) / m2;
    ks[i] = k;
    ds[i] = d;
    js[i] = 3 * k - 2 * d;
  }
}
