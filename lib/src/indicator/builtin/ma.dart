import 'dart:math' as math;
import 'dart:ui';

import '../../model/bar.dart';
import '../../panel/panel.dart';
import '../indicator.dart';

/// Simple moving average of close, overlaid on the main chart
class Ma extends LineIndicator {
  final List<int> periods;
  final List<Color>? colors;
  final double lineWidth;

  Ma({this.periods = const [7, 25, 99], this.colors, this.lineWidth = 1}) {
    checkPositivePeriods(periods, 'periods');
  }

  @override
  late final List<String> seriesKeys = [for (final p in periods) 'ma$p'];

  @override
  late final List<String> seriesLabels = [for (final p in periods) 'MA$p'];

  @override
  List<Color>? get seriesColors => colors;

  @override
  double get seriesLineWidth => lineWidth;

  @override
  String get id => 'ma(${periods.join(',')})';

  @override
  PanelRef get target => PanelRef.main;

  @override
  int get warmupBars => periods.reduce(math.max) + 1;

  /// Windowed: values depend only on the last period bars; anything beyond period is irrelevant.
  @override
  int? get prependSettleBars => warmupBars;

  static double _sma(List<Bar> bars, int i, int p) {
    // Partial window (same as deriv/ta4j): with fewer than period bars, use the available
    // min(p, i+1) bars,
    // so values start at bar 0 and the indicator line aligns with the left end of the candles.
    final count = math.min(p, i + 1);
    var sum = 0.0;
    for (var k = i - count + 1; k <= i; k++) {
      sum += bars[k].close;
    }
    return sum / count;
  }

  @override
  void computeAt(List<Bar> bars, int i, IndicatorStore store) {
    for (final p in periods) {
      store.series('ma$p')[i] = _sma(bars, i, p);
    }
  }
}
