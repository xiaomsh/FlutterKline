import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:klinex/klinex.dart';

import '../../../../l10n/l10n.dart';
import '../../../../widget/indicator_configs.dart';
import '../../sample/sample_view.dart';

/// Indicator switches: controller.indicators.setAll.
class IndicatorSwitchSample extends SampleView {
  const IndicatorSwitchSample({super.key});
  @override
  State<IndicatorSwitchSample> createState() => _IndicatorSwitchSampleState();
}

class _IndicatorSwitchSampleState extends SampleViewState<IndicatorSwitchSample> {
  final _config = IndicatorConfigs();
  final _main = <String>{'MA'}, _sub = <String>{'VOL', 'MACD'};

  static const mainNames = ['MA', 'EMA', 'BOLL'];
  static const subNames = ['VOL', 'MACD', 'KDJ', 'RSI', 'WR'];

  @override
  ChartController createController() => super.createController()..indicators.setAll(_build());

  List<Indicator> _build() => _config.build(_main, _sub);

  void _toggle(Set<String> set, String name, bool on) {
    update(() => on ? set.add(name) : set.remove(name));
    controller.indicators.setAll(_build());
  }

  @override
  Widget buildChart(BuildContext context) =>
      frame(KChart(controller: controller, theme: chartTheme, labels: chartLabels));

  @override
  List<Widget> buildSettings(BuildContext context) => [
    for (final (title, names, set) in [
      (S.current.indicatorSwitchSampleMain, mainNames, _main),
      (S.current.indicatorSwitchSampleSub, subNames, _sub),
    ]) ...[
      Text(title, style: Theme.of(context).textTheme.labelLarge),
      for (final name in names)
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          title: Text(name),
          value: set.contains(name),
          onChanged: (v) => _toggle(set, name, v ?? false),
        ),
    ],
    Text(S.current.indicatorSwitchSampleHint),
  ];

  @override
  String code() {
    final lines = [
      for (final i in controller.indicators.list)
        if (IndicatorRegistry.isSerializable(i.kind))
          '  IndicatorRegistry.fromJson(${jsonEncode(IndicatorRegistry.toJson(i))})!,'
        else
          '  ${i.runtimeType}(),',
    ];
    return 'controller.indicators.setAll([\n${lines.join('\n')}\n]);';
  }
}
