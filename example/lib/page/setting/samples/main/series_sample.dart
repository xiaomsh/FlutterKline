import 'package:flutter/material.dart';
import 'package:klinex/klinex.dart';

import '../../../../l10n/l10n.dart';
import '../../../../pro/live_pro.dart';
import '../../../../widget/pro_lock.dart';
import '../../sample/sample_view.dart';
import '../../widgets/controls.dart';

/// Main series: three free seriesStyle values, MainSeries instances in the full version.
class SeriesSample extends SampleView {
  const SeriesSample({super.key});
  @override
  State<SeriesSample> createState() => _SeriesSampleState();
}

class _SeriesSampleState extends SampleViewState<SeriesSample> {
  String _kind = 'candle';

  static Map<String, String> get _free => {
    'candle': S.current.seriesCandle,
    'line': S.current.seriesLine,
    'area': S.current.seriesArea,
  };

  MainSeriesStyle get _style => switch (_kind) {
    'line' => MainSeriesStyle.line,
    'area' => MainSeriesStyle.area,
    _ => MainSeriesStyle.candle,
  };

  @override
  Widget buildChart(BuildContext context) => frame(
    KChart(
      controller: controller,
      theme: chartTheme,
      labels: chartLabels,
      seriesStyle: _style,
      series: LivePro.seriesOf(_kind),
    ),
  );

  @override
  List<Widget> buildSettings(BuildContext context) => [
    Choice(
      S.current.seriesLabel,
      _kind,
      {
        ..._free,
        for (final item in LivePro.seriesNames.entries)
          item.key: LivePro.unlocked ? item.value : S.current.seriesProSuffix(item.value),
      },
      (v) {
        if (!_free.containsKey(v) && !LivePro.unlocked) {
          showProLock();
        } else {
          update(() => _kind = v);
        }
      },
    ),
    Text(S.current.seriesHint),
  ];

  @override
  String code() => _free.containsKey(_kind)
      ? 'KChart(seriesStyle: MainSeriesStyle.${_style.name}, ...)'
      : 'KChart(series: const ${LivePro.seriesOf(_kind).runtimeType}(), ...)';
}
