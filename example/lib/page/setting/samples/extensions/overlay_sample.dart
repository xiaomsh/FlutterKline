import 'package:flutter/material.dart';
import 'package:klinex/klinex.dart';

import '../../../../l10n/l10n.dart';
import '../../sample/sample_view.dart';
import '../../widgets/controls.dart';

/// Custom overlay: overlayBuilder draws plain widgets on the chart.
class OverlaySample extends SampleView {
  const OverlaySample({super.key});
  @override
  State<OverlaySample> createState() => _OverlaySampleState();
}

class _OverlaySampleState extends SampleViewState<OverlaySample> {
  bool _status = true, _lastBadge = true;

  @override
  Widget buildChart(BuildContext context) => frame(
    KChart(
      controller: controller,
      theme: chartTheme,
      labels: chartLabels,
      overlayBuilder: (context, ctx) {
        final last = ctx.bars.length - 1;
        final lastX = ctx.xOf(last);
        return Stack(
          children: [
            if (_status)
              Positioned(
                left: 8,
                bottom: ctx.size.height - ctx.mainPanel.rect.bottom + 4,
                child: Text(
                  S.current.overlaySampleVisibleRange(ctx.start, ctx.end),
                  style: TextStyle(color: ctx.theme.axisText, fontSize: 10),
                ),
              ),
            if (_lastBadge && last >= 0 && lastX <= ctx.chartRect.right)
              Positioned(
                left: lastX - 14,
                top: ctx.mainPanel.yOf(ctx.bars[last].high) - 26,
                child: Chip(
                  label: Text(S.current.overlaySampleLatest),
                  visualDensity: VisualDensity.compact,
                ),
              ),
          ],
        );
      },
    ),
  );

  @override
  List<Widget> buildSettings(BuildContext context) => [
    Toggle(S.current.overlaySampleRangeBadge, _status, (v) => update(() => _status = v)),
    Toggle(S.current.overlaySampleLastBadge, _lastBadge, (v) => update(() => _lastBadge = v)),
    Text(S.current.overlaySampleHint),
  ];

  @override
  String code() =>
      'KChart(\n'
      '  overlayBuilder: (context, ctx) {\n'
      '    final last = ctx.bars.length - 1;\n'
      '    return Stack(children: [\n'
      '${_status ? "      Positioned(left: 8, child: Text('Visible \${ctx.start} - \${ctx.end}')),\n" : ''}'
      '${_lastBadge ? '      Positioned(\n'
                '        left: ctx.xOf(last) - 14,\n'
                '        top: ctx.mainPanel.yOf(ctx.bars[last].high) - 26,\n'
                "        child: const Chip(label: Text('Latest')),\n"
                '      ),\n' : ''}'
      '    ]);\n'
      '  },\n'
      '  ...)';
}
