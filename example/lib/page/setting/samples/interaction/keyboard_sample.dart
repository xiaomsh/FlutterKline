import 'package:flutter/material.dart';
import 'package:klinex/klinex.dart';

import '../../../../l10n/l10n.dart';
import '../../sample/sample_view.dart';
import '../../widgets/controls.dart';

/// Keyboard controls.
class KeyboardSample extends SampleView {
  const KeyboardSample({super.key});
  @override
  State<KeyboardSample> createState() => _KeyboardSampleState();
}

class _KeyboardSampleState extends SampleViewState<KeyboardSample> {
  bool _keyboard = true;

  @override
  Widget buildChart(BuildContext context) => frame(
    KChart(
      controller: controller,
      theme: chartTheme,
      labels: chartLabels,
      keyboard: _keyboard,
    ),
  );

  @override
  List<Widget> buildSettings(BuildContext context) => [
    Toggle(S.current.keyboardSampleEnable, _keyboard, (v) => update(() => _keyboard = v)),
    Text(S.current.keyboardSampleFocusHint),
    const SizedBox(height: 12),
    Text(S.current.keyboardSampleShortcuts),
  ];

  @override
  String code() => 'KChart(keyboard: $_keyboard, ...)';
}
