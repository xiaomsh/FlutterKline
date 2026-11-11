import 'dart:ui';

import '../../model/bar.dart';
import '../../panel/panel.dart';
import '../indicator.dart';

/// Williams %R (-100..0) in its own sub-panel; multiple periods can be drawn together. Each
/// period rescans its window, O(period).
class Wr extends LineIndicator {
  final List<int> periods;
  final List<Color>? colors;
  final double lineWidth;

  /// Use [period]/[color] for a single period, [periods]/[colors] (take precedence) for many.
  Wr({
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
  late final List<String> seriesKeys = [for (final p in periods) 'wr$p'];

  @override
  late final List<String> seriesLabels = [for (final p in periods) 'WR($p)'];

  @override
  List<Color>? get seriesColors => colors;

  @override
  double get seriesLineWidth => lineWidth;

  @override
  int get paletteOffset => 2;

  @override
  String get id => 'wr(${periods.join(',')})';

  @override
  PanelRef get target => const PanelRef.own();

  @override
  int get warmupBars => periods.fold(0, (a, b) => a > b ? a : b) + 1;

  /// Windowed: values depend only on the last period bars; anything older has exactly no
  /// effect.
  @override
  int? get prependSettleBars => warmupBars;

  @override
  void computeAt(List<Bar> bars, int i, IndicatorStore store) {
    for (final p in periods) {
      final s = store.series('wr$p');
      final (lo, hi) = windowHighLow(bars, i, p);
      s[i] = hi == lo ? -50.0 : -100.0 * (hi - bars[i].close) / (hi - lo);
    }
  }
}
