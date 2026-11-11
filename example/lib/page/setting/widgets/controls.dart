import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../l10n/l10n.dart';

class Toggle extends StatelessWidget {
  const Toggle(this.label, this.value, this.onChanged, {super.key});
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => SwitchListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(label),
    value: value,
    onChanged: onChanged,
  );
}

class Slide extends StatelessWidget {
  const Slide(
    this.label,
    this.value,
    this.min,
    this.max,
    this.onChanged, {
    super.key,
    this.divisions,
  });
  final String label;
  final double value, min, max;
  final ValueChanged<double> onChanged;
  final int? divisions;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(S.current.controlsSliderValue(label, value.toStringAsFixed(divisions == null ? 1 : 0))),
      Slider(
        semanticFormatterCallback: (v) => '$label $v',
        value: value.clamp(min, max),
        min: min,
        max: max,
        divisions: divisions,
        onChanged: onChanged,
      ),
    ],
  );
}

class Choice<T> extends StatelessWidget {
  const Choice(this.label, this.value, this.options, this.onChanged, {super.key});
  final String label;
  final T value;
  final Map<T, String> options;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: InputDecorator(
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isDense: true,
          isExpanded: true,
          items: [
            // Show the current value even if it is not an option (e.g. a restored custom value),
            // otherwise the dropdown asserts
            if (!options.containsKey(value)) DropdownMenuItem(value: value, child: Text('$value')),
            for (final item in options.entries)
              DropdownMenuItem(value: item.key, child: Text(item.value)),
          ],
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    ),
  );
}

class CodeBlock extends StatelessWidget {
  const CodeBlock(this.code, {super.key});
  final String code;

  @override
  Widget build(BuildContext context) => ExpansionTile(
    tilePadding: EdgeInsets.zero,
    title: Text(S.current.controlsEquivalentCode),
    children: [
      Align(alignment: Alignment.centerLeft, child: SelectableText(code)),
      TextButton.icon(
        icon: const Icon(Icons.copy),
        label: Text(S.current.controlsCopyCode),
        onPressed: () async {
          await Clipboard.setData(ClipboardData(text: code));
          if (context.mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(S.current.controlsCodeCopied)));
          }
        },
      ),
    ],
  );
}
