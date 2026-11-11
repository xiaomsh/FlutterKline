import 'dart:ui';

import 'package:flutter/foundation.dart';

import '../controller.dart';
import '../model/min_max.dart';
import '../render/context.dart';

/// Layer plugin beyond indicators (crosshair, price line, legend, etc.); implement it and give it
/// to the controller.
abstract class OverlayPlugin {
  /// Repaint channel, merged into the overlay layer's listeners.
  List<Listenable> repaintOn(ChartController controller);

  /// Draws on the overlay layer; `ctx.panel` defaults to the main panel.
  void paint(Canvas canvas, RenderContext ctx);

  /// Draws on the top canvas above the host overlayBuilder (crosshair); otherwise on the same layer
  /// as other plugins.
  bool get onTop => false;

  /// Layer key: adjacent plugins with the same key within the same [onTop] level share one
  /// RepaintBoundary. Repaint signals of same-layer plugins are unioned,
  /// so give heavy plugins (drawings, trade markers) their own key to avoid rebuilding while the
  /// crosshair drags; only adjacent ones merge, preserving declaration order as z-order.
  String get layerKey => 'base';

  /// Range merged into the main secondary value axis range (visible [start]..[end]); none by
  /// default. Call [ChartController.relayout] when the underlying data changes so the layout cache
  /// recomputes.
  MinMax secondaryRange(ChartController controller, int start, int end) => MinMax.empty;

  /// Plugins that should be saved with [ChartController.saveState] provide a stable key; null is
  /// not saved.
  String? get stateKey => null;

  /// The plugin's own state; JSON-serializable values only.
  Map<String, dynamic>? saveState() => null;

  void restoreState(Map<String, dynamic> state) {}

  /// Releases the plugin's own resources; called on ChartController.dispose.
  void dispose() {}
}
