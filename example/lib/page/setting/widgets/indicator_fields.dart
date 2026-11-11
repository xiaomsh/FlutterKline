import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../../../widget/indicator_configs.dart';
import '../../../widget/indicator_detail_sheets.dart';
import '../../../widget/indicator_line_cfg.dart';
import 'parameter_input.dart';

class IndicatorFields extends StatelessWidget {
  const IndicatorFields({
    super.key,
    required this.onChanged,
    this.params = const [],
    this.colors = const [],
    this.lines,
  });
  final VoidCallback onChanged;
  final List<ParamSpec> params;
  final List<ColorSpec> colors;
  final List<LineCfg>? lines;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (final p in params) ParameterInput(p, onChanged, key: ValueKey(p.label)),
      for (final c in colors)
        _color(context, c.label, c.get(), (v) {
          c.set(v);
          onChanged();
        }),
      if (lines != null)
        for (final (i, line) in lines!.indexed)
          Column(
            children: [
              CheckboxListTile(
                title: Text(S.current.indicatorFieldsLine(i + 1)),
                value: line.on,
                onChanged: (v) {
                  line.on = v ?? false;
                  line.period ??= 20;
                  onChanged();
                },
              ),
              if (line.on) ...[
                IndicatorFields(
                  params: [
                    ParamSpec(
                      S.current.indicatorFieldsPeriod(i + 1),
                      () => line.period ?? 20,
                      (v) => line.period = v.toInt(),
                    ),
                  ],
                  onChanged: onChanged,
                ),
                _color(context, S.current.indicatorFieldsLineColor(i + 1), line.color, (v) {
                  line.color = v;
                  onChanged();
                }),
              ],
            ],
          ),
    ],
  );

  Widget _color(BuildContext context, String label, Color value, ValueChanged<Color> update) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: DropdownButtonFormField<Color>(
          key: ValueKey((label, value)),
          initialValue: value,
          decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
          items: [
            for (final color in {value, ...kIndicatorPalette})
              DropdownMenuItem(
                value: color,
                child: Row(
                  children: [
                    Container(width: 20, height: 20, color: color),
                    const SizedBox(width: 8),
                    Text('#${color.toARGB32().toRadixString(16).toUpperCase()}'),
                  ],
                ),
              ),
          ],
          onChanged: (v) {
            if (v != null) update(v);
          },
        ),
      );
}
