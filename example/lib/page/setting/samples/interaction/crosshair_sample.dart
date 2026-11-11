import 'package:flutter/material.dart';
import 'package:klinex/klinex.dart';

import '../../../../l10n/l10n.dart';
import '../../sample/sample_view.dart';
import '../../widgets/controls.dart';

/// Crosshair snapping and tooltip.
class CrosshairSample extends SampleView {
  const CrosshairSample({super.key});
  @override
  State<CrosshairSample> createState() => _CrosshairSampleState();
}

class _CrosshairSampleState extends SampleViewState<CrosshairSample> {
  CrosshairSnap _snap = CrosshairSnap.close;
  KChartTooltipStyle _style = KChartTooltipStyle.inline;
  bool _tooltip = true, _custom = false;

  @override
  Widget buildChart(BuildContext context) => frame(
    KChart(
      controller: controller,
      theme: chartTheme,
      labels: chartLabels,
      crosshairSnap: _snap,
      showTooltip: _tooltip,
      tooltipStyle: _style,
      tooltipBuilder: _custom
          ? (context, snap) => Align(
              alignment: Alignment.topLeft,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    S.current.crosshairSampleCustomTooltip(
                      snap.index,
                      snap.bar.close.toStringAsFixed(2),
                    ),
                  ),
                ),
              ),
            )
          : null,
    ),
  );

  @override
  List<Widget> buildSettings(BuildContext context) => [
    Choice(S.current.crosshairSampleSnap, _snap, {
      CrosshairSnap.free: S.current.crosshairSampleSnapFree,
      CrosshairSnap.close: S.current.crosshairSampleSnapClose,
      CrosshairSnap.ohlc: S.current.crosshairSampleSnapOhlc,
    }, (v) => update(() => _snap = v)),
    Toggle(S.current.crosshairSampleShowTooltip, _tooltip, (v) => update(() => _tooltip = v)),
    Choice(S.current.crosshairSampleTooltipStyle, _style, {
      KChartTooltipStyle.inline: S.current.crosshairSampleStyleInline,
      KChartTooltipStyle.card: S.current.crosshairSampleStyleCard,
    }, (v) => update(() => _style = v)),
    Toggle(S.current.crosshairSampleCustomBuilder, _custom, (v) => update(() => _custom = v)),
    Text(S.current.crosshairSampleHint),
  ];

  @override
  String code() =>
      'KChart(\n'
      '  crosshairSnap: CrosshairSnap.${_snap.name},\n'
      '  showTooltip: $_tooltip,\n'
      '  tooltipStyle: KChartTooltipStyle.${_style.name},\n'
      '  tooltipBuilder: ${_custom ? '(context, snap) => Card(child: Text(\'\${snap.bar.close}\'))' : 'null'},\n'
      '  ...)';
}
