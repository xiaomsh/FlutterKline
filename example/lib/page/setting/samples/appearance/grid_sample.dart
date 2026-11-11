import 'package:flutter/material.dart';
import 'package:klinex/klinex.dart';

import '../../../../l10n/l10n.dart';
import '../../sample/sample_view.dart';
import '../../widgets/controls.dart';

/// Grid and axis text.
class GridSample extends SampleView {
  const GridSample({super.key});
  @override
  State<GridSample> createState() => _GridSampleState();
}

class _GridSampleState extends SampleViewState<GridSample> {
  bool _show = true, _dash = false;
  double _text = 10, _width = 1;

  @override
  Widget buildChart(BuildContext context) {
    final theme = chartTheme.copyWith(
      showGrid: _show,
      gridLineDash: _dash ? const [3, 5] : const [],
      axisTextSize: _text,
      gridLineWidth: _width,
    );
    return frame(
      KChart(controller: controller, theme: theme, labels: chartLabels),
      theme: theme,
    );
  }

  @override
  List<Widget> buildSettings(BuildContext context) => [
    Toggle(S.current.gridSampleShowGrid, _show, (v) => update(() => _show = v)),
    Toggle(S.current.gridSampleDash, _dash, (v) => update(() => _dash = v)),
    Slide(S.current.gridSampleTextSize, _text, 8, 18, (v) => update(() => _text = v)),
    Slide(S.current.gridSampleLineWidth, _width, 0.5, 3, (v) => update(() => _width = v)),
  ];

  @override
  String code() =>
      'theme.copyWith(\n'
      '  showGrid: $_show,\n'
      '  gridLineDash: ${_dash ? 'const [3, 5]' : 'const []'},\n'
      '  axisTextSize: ${_text.toStringAsFixed(1)},\n'
      '  gridLineWidth: ${_width.toStringAsFixed(1)},\n'
      ')';
}
