import 'package:flutter/material.dart';
import 'package:klinex/klinex.dart';

import '../../../../l10n/l10n.dart';
import '../../sample/sample_view.dart';
import '../../widgets/controls.dart';

/// Watermark: underlayBuilder paints below the candles.
class WatermarkSample extends SampleView {
  const WatermarkSample({super.key});
  @override
  State<WatermarkSample> createState() => _WatermarkSampleState();
}

class _WatermarkSampleState extends SampleViewState<WatermarkSample> {
  bool _show = true;
  double _size = 38;

  @override
  Widget buildChart(BuildContext context) => frame(
    KChart(
      controller: controller,
      theme: chartTheme,
      labels: chartLabels,
      underlayBuilder: _show
          ? (context, ctx) => Stack(
              children: [
                Positioned.fromRect(
                  rect: ctx.mainPanel.rect,
                  child: Center(
                    child: Text(
                      'KLINEX',
                      style: TextStyle(
                        color: ctx.theme.axisText.withValues(alpha: 0.12),
                        fontSize: _size,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            )
          : null,
    ),
  );

  @override
  List<Widget> buildSettings(BuildContext context) => [
    Toggle(S.current.watermarkSampleShow, _show, (v) => update(() => _show = v)),
    Slide(
      S.current.watermarkSampleSize,
      _size,
      16,
      72,
      (v) => update(() => _size = v),
      divisions: 56,
    ),
    Text(S.current.watermarkSampleHint),
  ];

  @override
  String code() => _show
      ? 'KChart(\n'
            '  underlayBuilder: (context, ctx) => Stack(children: [\n'
            '    Positioned.fromRect(\n'
            '      rect: ctx.mainPanel.rect,\n'
            "      child: Center(child: Text('KLINEX', style: TextStyle(fontSize: ${_size.round()}))),\n"
            '    ),\n'
            '  ]),\n'
            '  ...)'
      : 'KChart(underlayBuilder: null, ...)';
}
