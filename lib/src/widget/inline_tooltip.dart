import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../theme/theme.dart';
import 'crosshair_snapshot.dart';

/// Built-in one-line tooltip: one row of "open high low close change (change %)" at the main
/// panel's top-left above the indicator legend, fixed in place, not following the finger.
/// Reports its measured height to [onHeight]; the main legend moves down by it while the crosshair
/// is shown.
class InlineTooltip extends StatelessWidget {
  const InlineTooltip({
    super.key,
    required this.snapshot,
    required this.theme,
    required this.priceFormatter,
    required this.labels,
    required this.onHeight,
    this.left = 0,
  });

  final CrosshairSnapshot snapshot;
  final KLineTheme theme;
  final PriceFormatter priceFormatter;
  final KChartLabels labels;
  final ValueChanged<double> onHeight;

  /// Left edge of the main plot area (non-zero when there is a left scale strip).
  final double left;

  @override
  Widget build(BuildContext context) {
    final b = snapshot.bar;
    final change = b.close - b.open;
    final pct = b.open == 0 ? 0.0 : change / b.open * 100;
    final sign = change >= 0 ? '+' : '';
    final labelStyle = TextStyle(fontSize: 11, color: theme.axisText);
    final valueStyle = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      color: change >= 0 ? theme.up : theme.down,
    );
    List<InlineSpan> pair(String label, double v) => [
      TextSpan(text: '$label ', style: labelStyle),
      TextSpan(text: '${priceFormatter(v)}  ', style: valueStyle),
    ];
    return Align(
      alignment: Alignment.topLeft,
      child: Padding(
        padding: EdgeInsets.only(left: left + 6, top: 3, right: 70),
        child: _SizeReporter(
          onHeight: (h) => onHeight(h + 2),
          child: Text.rich(
            TextSpan(
              children: [
                ...pair(labels.open, b.open),
                ...pair(labels.high, b.high),
                ...pair(labels.low, b.low),
                ...pair(labels.close, b.close),
                TextSpan(
                  text: '$sign${priceFormatter(change)} ($sign${pct.toStringAsFixed(2)}%)',
                  style: valueStyle,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Reports (on the next frame) when the height changes after layout.
class _SizeReporter extends SingleChildRenderObjectWidget {
  const _SizeReporter({required this.onHeight, super.child});

  final ValueChanged<double> onHeight;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderSizeReporter(onHeight);

  @override
  void updateRenderObject(BuildContext context, _RenderSizeReporter renderObject) =>
      renderObject.onHeight = onHeight;
}

class _RenderSizeReporter extends RenderProxyBox {
  _RenderSizeReporter(this.onHeight);

  ValueChanged<double> onHeight;
  double? _last;

  @override
  void performLayout() {
    super.performLayout();
    final h = size.height;
    if (h == _last) return;
    _last = h;
    WidgetsBinding.instance.addPostFrameCallback((_) => onHeight(h));
  }
}
