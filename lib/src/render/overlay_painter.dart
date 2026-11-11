import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import '../controller.dart';
import '../debug.dart';
import '../overlay/overlay_plugin.dart';
import 'context.dart';

/// Overlay plugins (price lines, drawings, etc.). One painter per layer (see
/// [OverlayPlugin.layerKey]); plugins repaint only when their own channel fires.
class OverlayPainter extends CustomPainter {
  OverlayPainter(this.controller, this.config, this.plugins)
    : super(
        repaint: Listenable.merge([
          for (final o in plugins) ...o.repaintOn(controller),
          // During range tweens, plugins anchored at (time, value) must repaint too, so this
          // hangs on the layer rather than being declared by each plugin.
          controller.rangeRevision,
          // Overlays must move when the panel layout changes.
          controller.indicators,
          config.theme,
          config.layoutRevision,
        ]),
      );

  final ChartController controller;
  final ChartConfig config;

  /// Plugins drawn in this layer, in declaration order (i.e. z-order).
  final List<OverlayPlugin> plugins;

  /// Splits plugins into layers by [OverlayPlugin.layerKey]: within the same [onTop] level,
  /// consecutive runs with the same key form a layer; no reordering.
  static List<OverlayPainter> split(
    ChartController controller,
    ChartConfig config, {
    required bool onTop,
  }) {
    final layers = <OverlayPainter>[];
    var run = <OverlayPlugin>[];
    String? runKey;
    void flush() {
      if (run.isNotEmpty) layers.add(OverlayPainter(controller, config, run));
    }

    for (final o in controller.overlays) {
      if (o.onTop != onTop) continue;
      if (runKey != o.layerKey) {
        flush();
        run = <OverlayPlugin>[];
        runKey = o.layerKey;
      }
      run.add(o);
    }
    flush();
    return layers;
  }

  /// Example: `L4top-base[CrosshairOverlay]`
  late final String debugLayerName =
      '${plugins.first.onTop ? 'L4top' : 'L3'}-${plugins.first.layerKey}'
      '[${plugins.map((o) => o.runtimeType).join(',')}]';

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

  void _paintLayer(Canvas canvas, Size size) {
    final ctx = controller.resolveLayout(size, config);
    if (ctx.isEmpty) return;
    canvas.clipRect(Offset.zero & size);
    ctx.usePanel(ctx.mainPanel);
    for (final overlay in plugins) {
      overlay.paint(canvas, ctx);
    }
  }

  @override
  bool shouldRepaint(covariant OverlayPainter oldDelegate) =>
      oldDelegate.controller != controller ||
      oldDelegate.config != config ||
      !identical(oldDelegate.plugins, plugins);
}
