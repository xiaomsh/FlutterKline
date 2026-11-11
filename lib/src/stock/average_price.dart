import 'dart:ui';

import '../indicator/indicator.dart';
import '../model/bar.dart';
import '../panel/panel.dart';
import 'trading_session.dart';

/// Intraday average price (VWAP since the open), overlaid on the main panel:
/// Σamount / Σ(vol × [volumeUnit]). Bars without [Bar.amount] use close × vol × [volumeUnit].
/// Resets at each new trading day of [session] (null never resets). [volumeUnit] converts [Bar.vol]
/// into shares (A-share volumes are in lots of 100).
class AveragePrice extends LineIndicator {
  AveragePrice({
    this.session,
    this.volumeUnit = 1,
    this.color = const Color(0xFFF0A732),
    this.label = 'Avg',
    this.lineWidth = 1,
  }) : assert(volumeUnit > 0, 'volumeUnit must be positive');

  final TradingSession? session;
  final double volumeUnit;
  final Color color;
  final String label;
  final double lineWidth;

  @override
  String get id => 'avgprice($volumeUnit,${session?.name ?? ''})';

  @override
  List<String> get seriesKeys => const ['avg'];

  @override
  List<String> get seriesLabels => [label];

  @override
  List<Color> get seriesColors => [color];

  @override
  double get seriesLineWidth => lineWidth;

  @override
  PanelRef get target => PanelRef.main;

  @override
  int get warmupBars => 2;

  bool _newDay(List<Bar> bars, int i) {
    if (i == 0) return true;
    final s = session;
    return s != null && s.dayOf(bars[i].time) != s.dayOf(bars[i - 1].time);
  }

  @override
  void computeAt(List<Bar> bars, int i, IndicatorStore store) {
    final avg = store.series('avg');
    final cumAmount = store.series('_amount');
    final cumVol = store.series('_vol');
    final b = bars[i];
    final reset = _newDay(bars, i);
    final shares = b.vol * volumeUnit;
    final amount = (reset ? 0.0 : cumAmount[i - 1]) + (b.amount ?? b.close * shares);
    final vol = (reset ? 0.0 : cumVol[i - 1]) + shares;
    cumAmount[i] = amount;
    cumVol[i] = vol;
    avg[i] = vol > 0 ? amount / vol : (reset ? b.close : avg[i - 1]);
  }
}
