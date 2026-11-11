import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import '../controller.dart';
import '../debug.dart';
import 'context.dart';

/// Indicator lines and bars for all panels. Separate from the main chart because the last-price
/// animation only slides the main chart's last bar: this layer doesn't subscribe to
/// animatedLastClose,
/// so it doesn't repaint during the animation; painted above the main chart, below the overlay
class IndicatorPainter extends CustomPainter {
  IndicatorPainter(this.controller, this.config)
    : super(
        repaint: Listenable.merge([
          controller.dataRevision,
          // Range tween: data unchanged but y mapping is sliding, so every layer must repaint
          controller.rangeRevision,
          controller.viewport,
          controller.indicators,
          config.theme,
          config.layoutRevision,
        ]),
      );

  final ChartController controller;
  final ChartConfig config;

  String get debugLayerName => 'L2-indicator';

  @override
  void paint(Canvas canvas, Size size) {
    if (!KlinexDebug.logPaint) {
      _paintLayer(canvas, size);
      return;
    }
    final sw = Stopwatch()..start();
    _paintLayer(canvas, size);
    KlinexDebug.paint(debugLayerName, sw.elapsedMicroseconds);
  }

  @override
  bool shouldRepaint(covariant IndicatorPainter oldDelegate) =>
      oldDelegate.controller != controller || oldDelegate.config != config;

  void _paintLayer(Canvas canvas, Size size) {
    final ctx = controller.resolveLayout(size, config);
    if (ctx.isEmpty) return;
    for (final panel in ctx.panels) {
      if (panel.indicators.isEmpty) continue;
      canvas.save();
      canvas.clipRect(panel.rect);
      ctx.usePanel(panel);
      final secondary = panel.secondary;
      for (final ind in panel.indicators) {
        // Skip when the second axis has no range (all NaN visible), so 0~100 values don't land on
        // price coordinates
        if (ind.target.isSecondaryAxis && secondary == null) continue;
        ctx.usePanel(ind.target.isSecondaryAxis ? secondary! : panel);
        ind.paint(canvas, ctx, controller.storeOf(ind));
      }
      canvas.restore();
    }
    ctx.usePanel(ctx.mainPanel);
  }
}
