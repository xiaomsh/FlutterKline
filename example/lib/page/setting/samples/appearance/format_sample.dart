import 'package:flutter/material.dart';
import 'package:klinex/klinex.dart';

import '../../../../l10n/l10n.dart';
import '../../sample/sample_view.dart';
import '../../widgets/controls.dart';

/// Price / time formats, time zone and chart label language.
class FormatSample extends SampleView {
  const FormatSample({super.key});
  @override
  State<FormatSample> createState() => _FormatSampleState();
}

class _FormatSampleState extends SampleViewState<FormatSample> {
  int _decimals = 2, _timezone = 8;
  bool _customTime = false, _customLabels = false;

  static const _fullLabels = KChartLabels(
    open: 'Open',
    high: 'High',
    low: 'Low',
    close: 'Close',
    changePercent: 'Change',
    volume: 'Volume',
  );

  String _price(double v) => v.toStringAsFixed(_decimals);

  String _time(int millis) {
    final d = DateTime.fromMillisecondsSinceEpoch(
      millis,
      isUtc: true,
    ).add(Duration(hours: _timezone));
    return '${d.month}/${d.day} ${d.hour.toString().padLeft(2, '0')}:'
        '${d.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget buildChart(BuildContext context) => frame(
    KChart(
      controller: controller,
      theme: chartTheme,
      priceFormatter: _price,
      utcOffset: Duration(hours: _timezone),
      timeFormatter: _customTime ? _time : null,
      labels: _customLabels ? _fullLabels : chartLabels,
    ),
  );

  @override
  List<Widget> buildSettings(BuildContext context) => [
    Choice(S.current.formatSampleDecimals, _decimals, {
      for (final n in const [0, 2, 4, 6]) n: S.current.formatSampleDecimalsOption(n),
    }, (v) => update(() => _decimals = v)),
    Choice(S.current.formatSampleTimezone, _timezone, const {
      -5: 'UTC-5',
      0: 'UTC',
      8: 'UTC+8',
    }, (v) => update(() => _timezone = v)),
    Toggle(S.current.formatSampleCustomTime, _customTime, (v) => update(() => _customTime = v)),
    Toggle(
      S.current.formatSampleCustomLabels,
      _customLabels,
      (v) => update(() => _customLabels = v),
    ),
    Text(S.current.formatSampleHint),
  ];

  @override
  String code() {
    const date = r'${d.month}/${d.day}';
    const hour = r"${d.hour.toString().padLeft(2, '0')}";
    const minute = r"${d.minute.toString().padLeft(2, '0')}";
    final helper = _customTime
        ? 'String formatTime(int millis) {\n'
              '  final d = DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true)\n'
              '      .add(const Duration(hours: $_timezone));\n'
              '  return "$date $hour:$minute";\n}\n'
        : '';
    return '${helper}KChart(\n'
        '  priceFormatter: (v) => v.toStringAsFixed($_decimals),\n'
        '  utcOffset: const Duration(hours: $_timezone),\n'
        '  timeFormatter: ${_customTime ? 'formatTime' : 'null'},\n'
        '${_customLabels ? "  labels: const KChartLabels(open: 'Open', high: 'High', ...),\n" : ''}'
        '  ...)';
  }
}
