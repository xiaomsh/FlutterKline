import 'dart:ui';

import '../render/context.dart';

/// Pluggable interaction mode (browse, drawing, etc.). An on* returning true claims the event
/// exclusively, and the chart's own pan/zoom ignores it.
class InteractionMode {
  /// Injected by GestureCoordinator when attached, so the current layout is available outside
  /// gesture callbacks too; null before attaching.
  RenderContext Function()? resolveContext;

  /// When true, claims all chart gestures (except touch two-finger zoom), swallowing even drags
  /// that hit nothing; the wheel, web trackpad pinch, long press and keys other than Esc don't
  /// move the chart. Drawing mode turns this on when a tool or a drawing is selected.
  bool get exclusive => false;

  bool onTapDown(Offset p, RenderContext ctx) => false;

  /// Called only when the chart's own tap recognizer wins; "tap empty space to deselect"
  /// belongs here, not in [onTapDown].
  void onTapUp(Offset p, RenderContext ctx) {}

  bool onDragStart(Offset p, RenderContext ctx) => false;

  void onDragUpdate(Offset p, RenderContext ctx) {}

  void onDragEnd(RenderContext ctx) {}
}

/// Default mode: consumes nothing; the chart pans and zooms freely.
class BrowseMode extends InteractionMode {}
