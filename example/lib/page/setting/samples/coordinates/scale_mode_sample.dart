import 'package:flutter/material.dart';
import 'package:klinex/klinex.dart';

import '../../../../l10n/l10n.dart';
import '../../sample/sample_view.dart';
import '../../widgets/controls.dart';

/// Scale modes: log, percent, inverted.
class ScaleModeSample extends SampleView {
  const ScaleModeSample({super.key});
  @override
  State<ScaleModeSample> createState() => _ScaleModeSampleState();
}

class _ScaleModeSampleState extends SampleViewState<ScaleModeSample> {
  bool _log = false, _percent = false, _invert = false;

  @override
  Widget buildChart(BuildContext context) => frame(
    KChart(
      controller: controller,
      theme: chartTheme,
      labels: chartLabels,
      logScale: _log,
      percentScale: _percent,
      invertScale: _invert,
      yPan: YPanMode.axis,
    ),
  );

  @override
  List<Widget> buildSettings(BuildContext context) => [
    Toggle(S.current.scaleModeLog, _log, (v) => update(() => _log = v)),
    Toggle(S.current.scaleModePercent, _percent, (v) => update(() => _percent = v)),
    Toggle(S.current.scaleModeInvert, _invert, (v) => update(() => _invert = v)),
    Text(S.current.scaleModeHint),
    Text(S.current.scaleModeInvertHint),
  ];

  @override
  String code() => 'KChart(logScale: $_log, percentScale: $_percent, invertScale: $_invert, ...)';
}
