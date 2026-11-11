import 'package:flutter/material.dart';
import 'package:klinex/klinex.dart';

import '../../../../l10n/l10n.dart';
import '../../sample/sample_data.dart';
import '../../sample/sample_view.dart';
import '../../widgets/controls.dart';

/// Indicator computation: background isolate and error callback.
class ComputeSample extends SampleView {
  const ComputeSample({super.key});
  @override
  State<ComputeSample> createState() => _ComputeSampleState();
}

class _ComputeSampleState extends SampleViewState<ComputeSample> {
  bool _async = false;
  String? _error;

  @override
  ChartController createController() {
    final c = ChartController(indicators: [Ma(), Boll(), Macd(), Kdj()])
      ..setBars(SampleData.bars(10000));
    c.onIndicatorError = (indicator, error, stack) {
      if (mounted) update(() => _error = '${indicator.id}: $error');
    };
    return c;
  }

  void _fail() {
    final list = List.of(controller.indicators.list);
    controller.indicators
      ..setAll([...list, _FailingIndicator()])
      ..setAll(list);
  }

  @override
  Widget buildChart(BuildContext context) => frame(
    ValueListenableBuilder(
      valueListenable: controller.computing,
      builder: (_, busy, chart) => Stack(
        children: [
          chart!,
          if (busy) Positioned(top: 8, left: 8, child: Text(S.current.computeSampleBusy)),
        ],
      ),
      child: KChart(controller: controller, theme: chartTheme, labels: chartLabels),
    ),
  );

  @override
  List<Widget> buildSettings(BuildContext context) => [
    Toggle(S.current.computeSampleAsync, _async, (v) {
      update(() => _async = v);
      controller.asyncCompute = v;
    }),
    Text(S.current.computeSampleHint),
    const SizedBox(height: 8),
    FilledButton(onPressed: _fail, child: Text(S.current.computeSampleTriggerError)),
    if (_error != null)
      SelectableText(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
  ];

  @override
  String code() =>
      'controller.asyncCompute = $_async;\n'
      'controller.onIndicatorError = (indicator, error, stack) {\n'
      '  debugPrint("\${indicator.id}: \$error\\n\$stack");\n'
      '};';
}

class _FailingIndicator extends Ma {
  @override
  String get id => 'sample-error';

  @override
  void computeAll(List<Bar> bars, IndicatorStore store) {
    throw StateError('Demo of onIndicatorError; this indicator is not drawn');
  }
}
