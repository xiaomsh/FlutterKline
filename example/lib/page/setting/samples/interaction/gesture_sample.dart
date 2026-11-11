import 'package:flutter/material.dart';
import 'package:klinex/klinex.dart';

import '../../../../l10n/l10n.dart';
import '../../sample/sample_view.dart';
import '../../widgets/controls.dart';

/// Vertical pan, axis drag to zoom, tap a candle to pick its price.
class GestureSample extends SampleView {
  const GestureSample({super.key});
  @override
  State<GestureSample> createState() => _GestureSampleState();
}

class _GestureSampleState extends SampleViewState<GestureSample> {
  YPanMode _yPan = YPanMode.axis;
  bool _axisDrag = true, _barTap = true;
  Bar? _tapped;

  @override
  Widget buildChart(BuildContext context) => frame(
    KChart(
      controller: controller,
      theme: chartTheme,
      labels: chartLabels,
      yPan: _yPan,
      axisDragScale: _axisDrag,
      onBarTap: _barTap ? (bar) => update(() => _tapped = bar) : null,
      overlayBuilder: (_, ctx) {
        final bar = _tapped;
        if (!_barTap || bar == null) return const SizedBox.shrink();
        final formatPrice = ctx.config.priceFormatter;
        return Stack(
          children: [
            Positioned(
              left: ctx.chartRect.left + 8,
              top: ctx.chartRect.top + 24,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: ctx.theme.tooltipBg,
                    border: Border.all(color: ctx.theme.tooltipBorder),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Text(
                      S.current.gestureSampleOrderPrice(
                        formatPrice(bar.close),
                        ctx.config.timeFormatter(bar.time),
                      ),
                      style: TextStyle(fontSize: 12, color: ctx.theme.tooltipText),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    ),
  );

  @override
  List<Widget> buildSettings(BuildContext context) => [
    Choice(S.current.gestureSampleYPan, _yPan, {
      YPanMode.none: S.current.gestureSampleYPanNone,
      YPanMode.axis: S.current.gestureSampleYPanAxis,
      YPanMode.chart: S.current.gestureSampleYPanChart,
    }, (v) => update(() => _yPan = v)),
    Toggle(S.current.gestureSampleAxisDrag, _axisDrag, (v) => update(() => _axisDrag = v)),
    Text(S.current.gestureSampleAxisDragHint),
    Toggle(S.current.gestureSampleBarTap, _barTap, (v) => update(() => _barTap = v)),
    Text(S.current.gestureSampleBarTapHint),
    if (_barTap && _tapped != null)
      Text(
        S.current.gestureSampleTapped(
          _tapped!.open.toStringAsFixed(2),
          _tapped!.high.toStringAsFixed(2),
          _tapped!.low.toStringAsFixed(2),
          _tapped!.close.toStringAsFixed(2),
        ),
      ),
  ];

  @override
  String code() =>
      'KChart(yPan: YPanMode.${_yPan.name}, axisDragScale: $_axisDrag,\n'
      '${_barTap ? '  onBarTap: (bar) => priceInput.text = format(bar.close),\n' : ''}'
      '  ...)';
}
