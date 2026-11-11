import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:klinex/klinex.dart';

import '../../../../l10n/l10n.dart';
import '../../sample/sample_view.dart';

/// Save / restore everything: ChartController.saveState / restoreState,
/// KLineTheme.toJson / fromJson.
class StorageSample extends SampleView {
  const StorageSample({super.key});
  @override
  State<StorageSample> createState() => _StorageSampleState();
}

class _StorageSampleState extends SampleViewState<StorageSample> {
  final _text = TextEditingController();
  KLineTheme? _theme;
  bool _altIndicators = false;
  String Function()? _message;
  bool _error = false;

  KLineTheme get _current => _theme ?? chartTheme;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _save() => update(() {
    _text.text = const JsonEncoder.withIndent('  ').convert({
      'chart': controller.saveState(),
      'theme': _current.toJson(),
    });
    _message = () => S.current.storageSampleSaved;
    _error = false;
  });

  void _restore() {
    try {
      final value = jsonDecode(_text.text);
      if (value is! Map<String, dynamic> ||
          value['chart'] is! Map<String, dynamic> ||
          value['theme'] is! Map<String, dynamic>) {
        throw FormatException(S.current.storageSampleNeedChartTheme);
      }
      final chart = value['chart'] as Map<String, dynamic>;
      if (chart['indicators'] is! List) {
        throw FormatException(S.current.storageSampleIndicatorsNotList);
      }
      // Validate everything before touching the controller, so a failure leaves no partial state.
      IndicatorRegistry.fromJsonList(chart['indicators'] as List);
      final theme = KLineTheme.fromJson(value['theme'] as Map<String, dynamic>);
      controller.restoreState(chart);
      update(() {
        _theme = theme;
        _message = () => S.current.storageSampleRestored;
        _error = false;
      });
    } on Object catch (e) {
      update(() {
        _message = () => S.current.storageSampleRestoreFailed('$e');
        _error = true;
      });
    }
  }

  @override
  Widget buildChart(BuildContext context) => frame(
    KChart(controller: controller, theme: _current, labels: chartLabels, panelResizable: true),
    theme: _current,
  );

  @override
  List<Widget> buildSettings(BuildContext context) => [
    Text(S.current.storageSampleHint),
    const SizedBox(height: 8),
    Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        FilledButton(onPressed: _save, child: Text(S.current.commonSave)),
        FilledButton.tonal(onPressed: _restore, child: Text(S.current.storageSampleRestore)),
        OutlinedButton(
          onPressed: () {
            update(() => _altIndicators = !_altIndicators);
            controller.indicators.setAll(
              _altIndicators ? [Ema(), Boll(), Kdj()] : [Ma(), Macd()],
            );
          },
          child: Text(S.current.storageSampleSwapIndicators),
        ),
        OutlinedButton(
          onPressed: () => update(
            () => _theme = _current.background.computeLuminance() < 0.5
                ? KLineTheme.light()
                : KLineTheme.dark(),
          ),
          child: Text(S.current.storageSampleSwitchTheme),
        ),
      ],
    ),
    const SizedBox(height: 12),
    if (_message case final message?)
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          message(),
          style: TextStyle(color: _error ? Theme.of(context).colorScheme.error : null),
        ),
      ),
    TextField(
      controller: _text,
      minLines: 6,
      maxLines: 14,
      style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
      decoration: InputDecoration(
        border: const OutlineInputBorder(),
        hintText: S.current.storageSampleJsonHint,
      ),
    ),
  ];

  @override
  String code() =>
      'final saved = jsonEncode({\n'
      "  'chart': controller.saveState(),\n"
      "  'theme': theme.toJson(),\n"
      '});\n'
      '// Restore\n'
      'final map = jsonDecode(saved);\n'
      "controller.restoreState(map['chart']);\n"
      "theme = KLineTheme.fromJson(map['theme']);";
}
