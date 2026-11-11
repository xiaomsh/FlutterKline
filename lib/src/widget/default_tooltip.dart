import 'package:flutter/widgets.dart';

import '../theme/theme.dart';
import 'crosshair_snapshot.dart';

/// Built-in OHLCV tooltip; docks right when the selection is in the left half, left when in
/// the right half.
class DefaultTooltip extends StatelessWidget {
  const DefaultTooltip({
    super.key,
    required this.snapshot,
    required this.theme,
    required this.priceFormatter,
    required this.timeFormatter,
    required this.volumeFormatter,
    required this.labels,
    required this.chartWidth,
  });

  final CrosshairSnapshot snapshot;
  final KLineTheme theme;
  final PriceFormatter priceFormatter;
  final TimeFormatter timeFormatter;

  /// Volume uses the same format as the volume-bar axis (K/M/B by default); price decimals
  /// can't be used to print seven-digit volumes.
  final PriceFormatter volumeFormatter;
  final KChartLabels labels;
  final double chartWidth;

  @override
  Widget build(BuildContext context) {
    final b = snapshot.bar;
    final change = b.close - b.open;
    final pct = b.open == 0 ? 0.0 : change / b.open * 100;
    final changeColor = change >= 0 ? theme.up : theme.down;
    final onLeft = snapshot.position.dx > chartWidth / 2;
    final labelStyle = TextStyle(color: theme.axisText, fontSize: 11);
    final valueStyle = TextStyle(color: theme.tooltipText, fontSize: 11);
    final changeStyle = TextStyle(color: changeColor, fontSize: 11);

    return Align(
      alignment: onLeft ? Alignment.topLeft : Alignment.topRight,
      child: Container(
        margin: const EdgeInsets.all(8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: theme.tooltipBg,
          border: Border.all(color: theme.tooltipBorder),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _TooltipRow(labels.time, timeFormatter(b.time), labelStyle, valueStyle),
            _TooltipRow(labels.open, priceFormatter(b.open), labelStyle, valueStyle),
            _TooltipRow(labels.high, priceFormatter(b.high), labelStyle, valueStyle),
            _TooltipRow(labels.low, priceFormatter(b.low), labelStyle, valueStyle),
            _TooltipRow(labels.close, priceFormatter(b.close), labelStyle, changeStyle),
            _TooltipRow(
              labels.changePercent,
              '${pct >= 0 ? '+' : ''}${pct.toStringAsFixed(2)}%',
              labelStyle,
              changeStyle,
            ),
            _TooltipRow(labels.volume, volumeFormatter(b.vol), labelStyle, valueStyle),
          ],
        ),
      ),
    );
  }
}

class _TooltipRow extends StatelessWidget {
  const _TooltipRow(this.label, this.value, this.labelStyle, this.valueStyle);

  final String label;
  final String value;
  final TextStyle labelStyle;
  final TextStyle valueStyle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: labelStyle),
          const SizedBox(width: 16),
          Text(value, style: valueStyle),
        ],
      ),
    );
  }
}
