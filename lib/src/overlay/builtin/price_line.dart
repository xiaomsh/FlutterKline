import 'dart:ui';

import 'package:flutter/foundation.dart';

import '../../controller.dart';
import '../../model/min_max.dart';
import '../../render/context.dart';
import '../overlay_plugin.dart';

/// Dashed close-price line on the main panel, drawn from the reference bar to the plot's right
/// edge (reference = latest bar, or the right-edge bar when panned past it). Draws only the
/// line, not the label: the label must avoid the countdown and best bid/ask and follow the
/// theme, so the host draws it in overlayBuilder.
class PriceLineOverlay extends OverlayPlugin {
  PriceLineOverlay({this._showPrice = true});

  final ValueNotifier<int> _rev = ValueNotifier(0);
  bool _showPrice;
  bool _disposed = false;

  bool get showPrice => _showPrice;

  set showPrice(bool v) {
    if (v == _showPrice || _disposed) return;
    _showPrice = v;
    _rev.value++;
  }

  @override
  List<Listenable> repaintOn(ChartController controller) => [
    _rev,
    controller.dataRevision,
    controller.viewport,
    controller.animatedLastClose,
  ];

  @override
  void paint(Canvas canvas, RenderContext ctx) {
    if (ctx.isEmpty || !_showPrice) return;
    final lastIndex = ctx.bars.length - 1;
    // A bar's cell is [i-0.5, i+0.5), so round(rightIndex) is the right-edge bar.
    final refIndex = ctx.rightIndex.round().clamp(0, lastIndex);
    final isLatest = refIndex == lastIndex;
    // Latest-price interpolation animation: the line slides with the displayed value.
    final refClose =
        (isLatest ? ctx.controller.animatedLastClose.value : null) ?? ctx.bars[refIndex].close;
    final panel = ctx.mainPanel;
    // Clamp the line inside the panel when the price drifts out of range.
    final y = clampSafe(panel.yOf(refClose), panel.rect.top + 1, panel.rect.bottom - 1);
    ctx.pool.drawDashedHLine(
      canvas,
      y,
      ctx.xOf(refIndex).clamp(ctx.chartRect.left, ctx.chartRect.right),
      ctx.chartRect.right,
      ctx.pool.stroke
        ..color = ctx.theme.priceLine
        ..strokeWidth = 0.8,
    );
  }

  @override
  void dispose() {
    _disposed = true;
    _rev.dispose();
  }
}
