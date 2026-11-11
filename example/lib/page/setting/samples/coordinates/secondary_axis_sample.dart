import 'package:flutter/material.dart';
import 'package:klinex/klinex.dart';

import '../../../../l10n/l10n.dart';
import '../../sample/sample_view.dart';
import '../../widgets/controls.dart';

/// A second value axis on the main chart: SecondaryAxis wraps any indicator.
class SecondaryAxisSample extends SampleView {
  const SecondaryAxisSample({super.key});
  @override
  State<SecondaryAxisSample> createState() => _SecondaryAxisSampleState();
}

class _SecondaryAxisSampleState extends SampleViewState<SecondaryAxisSample> {
  String _kind = 'RSI';
  bool _percentLabel = true;
  YAxisPosition _position = YAxisPosition.outside;

  static Map<String, String> get _options => {
    'RSI': 'RSI(14)',
    'WR': 'WR(14)',
    'OFF': S.current.secondaryAxisNone,
  };

  @override
  ChartController createController() => super.createController()..indicators.setAll(_indicators);

  List<Indicator> get _indicators => [
    Ma(),
    if (_kind == 'RSI') SecondaryAxis(Rsi()),
    if (_kind == 'WR') SecondaryAxis(Wr()),
  ];

  @override
  Widget buildChart(BuildContext context) => frame(
    KChart(
      controller: controller,
      theme: chartTheme,
      labels: chartLabels,
      yAxisPosition: _position,
      secondaryFormatter: _percentLabel ? (v) => '${v.toStringAsFixed(0)}%' : null,
    ),
  );

  @override
  List<Widget> buildSettings(BuildContext context) => [
    Choice(S.current.secondaryAxisOverlay, _kind, _options, (v) {
      update(() => _kind = v);
      controller.indicators.setAll(_indicators);
    }),
    Choice(S.current.axisPositionLabel, _position, {
      YAxisPosition.outside: S.current.secondaryAxisRight,
      YAxisPosition.both: S.current.secondaryAxisBoth,
    }, (v) => update(() => _position = v)),
    Toggle(S.current.secondaryAxisPercent, _percentLabel, (v) => update(() => _percentLabel = v)),
    Text(S.current.secondaryAxisHint),
  ];

  @override
  String code() {
    final inner = switch (_kind) {
      'RSI' => 'Rsi()',
      'WR' => 'Wr()',
      _ => null,
    };
    return 'controller.indicators.setAll([\n'
        '  Ma(),\n'
        '${inner == null ? '' : '  SecondaryAxis($inner),\n'}'
        ']);\n'
        'KChart(\n'
        '  yAxisPosition: YAxisPosition.${_position.name},\n'
        "  secondaryFormatter: ${_percentLabel ? r"(v) => '${v.toStringAsFixed(0)}%'" : 'null'},\n"
        '  ...)';
  }
}
