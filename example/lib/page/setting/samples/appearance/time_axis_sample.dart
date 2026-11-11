import 'package:flutter/material.dart';
import 'package:klinex/klinex.dart';

import '../../../../l10n/l10n.dart';
import '../../sample/sample_data.dart';
import '../../sample/sample_view.dart';
import '../../widgets/controls.dart';

/// Tiered time axis: ticks land on year / month / day / hour boundaries.
class TimeAxisSample extends SampleView {
  const TimeAxisSample({super.key});
  @override
  State<TimeAxisSample> createState() => _TimeAxisSampleState();
}

class _TimeAxisSampleState extends SampleViewState<TimeAxisSample> {
  bool _tiered = true, _custom = false;
  int _timezone = 8;

  @override
  ChartController createController() =>
      ChartController(indicators: [Ma()])..setBars(SampleData.bars(3000));

  /// Receives raw milliseconds; apply the time zone yourself.
  String _tick(int millis, TimeTier tier) {
    final d = DateTime.fromMillisecondsSinceEpoch(
      millis,
      isUtc: true,
    ).add(Duration(hours: _timezone));
    return switch (tier) {
      TimeTier.year => S.current.timeAxisSampleTickYear(d.year),
      TimeTier.month => S.current.timeAxisSampleMonthNames.split(',')[d.month - 1],
      TimeTier.day => S.current.timeAxisSampleTickDay(d.day),
      _ => '${d.hour}:${d.minute.toString().padLeft(2, '0')}',
    };
  }

  @override
  Widget buildChart(BuildContext context) => frame(
    KChart(
      controller: controller,
      theme: chartTheme,
      labels: chartLabels,
      tieredTimeAxis: _tiered,
      utcOffset: Duration(hours: _timezone),
      tickFormatter: _custom ? _tick : null,
    ),
  );

  @override
  List<Widget> buildSettings(BuildContext context) => [
    Toggle(S.current.timeAxisSampleTiered, _tiered, (v) => update(() => _tiered = v)),
    Toggle(S.current.timeAxisSampleCustomTick, _custom, (v) => update(() => _custom = v)),
    Choice(S.current.timeAxisSampleTimezone, _timezone, const {
      0: 'UTC',
      8: 'UTC+8',
    }, (v) => update(() => _timezone = v)),
    Text(S.current.timeAxisSampleHint),
  ];

  @override
  String code() => _custom
      ? 'KChart(\n'
            '  tieredTimeAxis: $_tiered,\n'
            '  utcOffset: const Duration(hours: $_timezone),\n'
            '  // ms is the raw timestamp; apply the time zone yourself\n'
            '  tickFormatter: (ms, tier) => switch (tier) {\n'
            "    TimeTier.year => '\${d.year}',\n"
            '    TimeTier.month => DateFormat.MMM().format(d),\n'
            "    TimeTier.day => '\${d.day}',\n"
            "    _ => '\${d.hour}:\${d.minute}',\n"
            '  },\n'
            '  ...)'
      : 'KChart(tieredTimeAxis: $_tiered, utcOffset: const Duration(hours: $_timezone), ...)';
}
