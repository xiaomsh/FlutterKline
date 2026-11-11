import 'package:flutter/widgets.dart';

import '../render/paint_pool.dart';
import '../theme/theme.dart';
import 'depth_painter.dart';

/// One order book level
class DepthLevel {
  final double price;
  final double amount;

  const DepthLevel(this.price, this.amount);

  @override
  bool operator ==(Object other) =>
      other is DepthLevel && other.price == price && other.amount == amount;

  @override
  int get hashCode => Object.hash(price, amount);
}

/// Depth chart: stepped areas of cumulative bid/ask volume; tap / drag to inspect a level. A
/// standalone widget whose x axis is price, not time
class DepthChart extends StatefulWidget {
  /// Bid/ask changes are detected by list instance: order book updates must pass a new list;
  /// mutating the same list in place won't recompute
  final List<DepthLevel> bids;
  final List<DepthLevel> asks;
  final KLineTheme theme;
  final String Function(double) priceFormatter;
  final String Function(double) amountFormatter;

  static String _defFmt(double v) => v.toStringAsFixed(2);

  const DepthChart({
    super.key,
    required this.bids,
    required this.asks,
    required this.theme,
    this.priceFormatter = _defFmt,
    this.amountFormatter = _defFmt,
  });

  @override
  State<DepthChart> createState() => _DepthChartState();
}

class _DepthChartState extends State<DepthChart> {
  final ValueNotifier<Offset?> _touch = ValueNotifier(null);

  // The pool outlives the painter, so the TextPainter cache survives rebuilds
  final PaintPool _pool = PaintPool();
  late DepthPainter _painter;
  late PreparedDepthData _prepared;

  @override
  void initState() {
    super.initState();
    _prepared = PreparedDepthData.fromWidget(widget);
    _painter = DepthPainter(widget, _prepared, _touch, _pool);
  }

  @override
  void didUpdateWidget(DepthChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(widget.bids, oldWidget.bids) || !identical(widget.asks, oldWidget.asks)) {
      _prepared = PreparedDepthData.fromWidget(widget);
    }
    _painter = DepthPainter(widget, _prepared, _touch, _pool);
  }

  @override
  void dispose() {
    _touch.dispose();
    _pool.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (d) => _touch.value = d.localPosition,
      onHorizontalDragUpdate: (d) => _touch.value = d.localPosition,
      onTapUp: (_) => _touch.value = null,
      onHorizontalDragEnd: (_) => _touch.value = null,
      // Inside a scrolling page the outer view may steal the gesture (cancel): the crosshair must
      // be cleared too
      onTapCancel: () => _touch.value = null,
      onHorizontalDragCancel: () => _touch.value = null,
      child: RepaintBoundary(
        child: CustomPaint(painter: _painter, size: Size.infinite),
      ),
    );
  }
}
