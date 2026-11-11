import 'package:flutter/widgets.dart';

import '../model/bar.dart';

typedef PriceFormatter = String Function(double value);
typedef TimeFormatter = String Function(int millis);
typedef TooltipBuilder = Widget Function(BuildContext context, CrosshairSnapshot snapshot);

/// Crosshair selection info used by the tooltip
class CrosshairSnapshot {
  CrosshairSnapshot.lazy({
    required this.index,
    required this.bar,
    required this.position,
    required this.indicatorValuesLoader,
  });

  final int index;
  final Bar bar;
  final Offset position;
  final Map<String, Map<String, double>> Function() indicatorValuesLoader;

  /// `{indicator id: {series key: value}}` for bar [index]. Computed on demand: the built-in
  /// tooltip doesn't read it, saving nested maps while dragging the crosshair
  late final Map<String, Map<String, double>> indicatorValues = indicatorValuesLoader();
}

/// Built-in tooltip text, English by default; other languages are passed in by the host. Unused
/// when tooltipBuilder is customized
class KChartLabels {
  const KChartLabels({
    this.time = 'Time',
    this.open = 'O',
    this.high = 'H',
    this.low = 'L',
    this.close = 'C',
    this.changePercent = 'Chg%',
    this.volume = 'Vol',
    this.chart = 'Candlestick chart',
    this.rangeTo = 'to',
    this.latest = 'last price',
    this.separator = ', ',
  });

  final String time, open, high, low, close, changePercent, volume;

  /// For the accessibility description: "Candlestick chart, start to end, last price x"
  final String chart, rangeTo, latest, separator;
}
