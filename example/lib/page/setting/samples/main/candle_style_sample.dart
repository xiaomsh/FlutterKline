import 'package:flutter/material.dart';
import 'package:klinex/klinex.dart';

import '../../../../l10n/l10n.dart';
import '../../sample/sample_view.dart';
import '../../widgets/controls.dart';

/// Candle style: hollow / solid, separate wick and border colors.
class CandleStyleSample extends SampleView {
  const CandleStyleSample({super.key});
  @override
  State<CandleStyleSample> createState() => _CandleStyleSampleState();
}

class _CandleStyleSampleState extends SampleViewState<CandleStyleSample> {
  CandleFillMode _fill = CandleFillMode.solid;
  bool _wick = false, _border = false;

  static const _grey = Color(0xFF8A93A6);

  @override
  Widget buildChart(BuildContext context) {
    final base = chartTheme;
    final border = base.axisText;
    return frame(
      KChart(
        controller: controller,
        theme: base.copyWith(
          upWick: _wick ? _grey : null,
          downWick: _wick ? _grey : null,
          upBorder: _border ? border : null,
          downBorder: _border ? border : null,
        ),
        labels: chartLabels,
        candleFill: _fill,
      ),
    );
  }

  @override
  List<Widget> buildSettings(BuildContext context) => [
    Choice(S.current.candleFill, _fill, {
      CandleFillMode.solid: S.current.candleFillSolid,
      CandleFillMode.hollowUp: S.current.candleFillHollowUp,
      CandleFillMode.hollowDown: S.current.candleFillHollowDown,
    }, (v) => update(() => _fill = v)),
    Toggle(S.current.candleWickColor, _wick, (v) => update(() => _wick = v)),
    Toggle(S.current.candleBorder, _border, (v) => update(() => _border = v)),
  ];

  @override
  String code() =>
      'KChart(\n'
      '  candleFill: CandleFillMode.${_fill.name},\n'
      '  theme: theme.copyWith(\n'
      '    upWick: ${_wick ? 'grey' : 'null'}, downWick: ${_wick ? 'grey' : 'null'},\n'
      '    upBorder: ${_border ? 'borderColor' : 'null'}, downBorder: ${_border ? 'borderColor' : 'null'},\n'
      '  ),\n'
      '  ...)';
}
