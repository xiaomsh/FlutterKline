import 'package:flutter/material.dart';
import 'package:klinex/klinex.dart';

import '../../../../l10n/l10n.dart';
import '../../sample/sample_data.dart';
import '../../sample/sample_view.dart';
import '../../widgets/controls.dart';

/// Panel heights: mainFlex / subFlex / panelResizable.
class PanelsSample extends SampleView {
  const PanelsSample({super.key});
  @override
  State<PanelsSample> createState() => _PanelsSampleState();
}

class _PanelsSampleState extends SampleViewState<PanelsSample> {
  double _main = 3, _sub = 1;
  bool _resizable = true;

  @override
  ChartController createController() =>
      ChartController(indicators: [Ma(), Macd(), Kdj(), Rsi()])..setBars(SampleData.bars());

  @override
  Widget buildChart(BuildContext context) => frame(
    KChart(
      controller: controller,
      theme: chartTheme,
      labels: chartLabels,
      mainFlex: _main,
      subFlex: _sub,
      panelResizable: _resizable,
    ),
  );

  @override
  List<Widget> buildSettings(BuildContext context) => [
    Slide(S.current.panelsSampleMainFlex, _main, 1, 8, (v) => update(() => _main = v)),
    Slide(S.current.panelsSampleSubFlex, _sub, 0.5, 4, (v) => update(() => _sub = v)),
    Toggle(S.current.panelsSampleResizable, _resizable, (v) => update(() => _resizable = v)),
    Text(S.current.panelsSampleHint),
  ];

  @override
  String code() =>
      'KChart(mainFlex: ${_main.toStringAsFixed(1)}, subFlex: ${_sub.toStringAsFixed(1)},\n'
      '  panelResizable: $_resizable, ...)';
}
