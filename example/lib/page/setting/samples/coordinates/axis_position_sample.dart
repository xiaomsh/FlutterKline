import 'package:flutter/material.dart';
import 'package:klinex/klinex.dart';

import '../../../../l10n/l10n.dart';
import '../../sample/sample_view.dart';
import '../../widgets/controls.dart';

/// Price axis position and width.
class AxisPositionSample extends SampleView {
  const AxisPositionSample({super.key});
  @override
  State<AxisPositionSample> createState() => _AxisPositionSampleState();
}

class _AxisPositionSampleState extends SampleViewState<AxisPositionSample> {
  YAxisPosition _position = YAxisPosition.outside;
  double _width = 56;

  @override
  Widget buildChart(BuildContext context) => frame(
    KChart(
      controller: controller,
      theme: chartTheme,
      labels: chartLabels,
      yAxisPosition: _position,
      yAxisWidth: _width,
    ),
  );

  @override
  List<Widget> buildSettings(BuildContext context) => [
    Choice(S.current.axisPositionLabel, _position, {
      YAxisPosition.outside: S.current.axisPositionOutside,
      YAxisPosition.inside: S.current.axisPositionInside,
      YAxisPosition.left: S.current.axisPositionLeft,
      YAxisPosition.both: S.current.axisPositionBoth,
    }, (v) => update(() => _position = v)),
    Slide(
      S.current.axisPositionWidth,
      _width,
      40,
      96,
      (v) => update(() => _width = v),
      divisions: 56,
    ),
    Text(S.current.axisPositionHint),
  ];

  @override
  String code() =>
      'KChart(yAxisPosition: YAxisPosition.${_position.name}, '
      'yAxisWidth: ${_width.round()}, ...)';
}
