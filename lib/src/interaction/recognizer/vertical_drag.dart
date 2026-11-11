import 'package:flutter/gestures.dart';

import '../../debug.dart';

/// Vertical drag (only for dividers and y panning). [enabled] is checked on pointer down; unclaimed
/// gestures are left to the outer scroll;
/// a second finger landing before winning yields to two-finger pinch; if already dragging,
/// continues
class CondVerticalDragRecognizer extends VerticalDragGestureRecognizer {
  CondVerticalDragRecognizer(this.enabled) {
    dragStartBehavior = DragStartBehavior.down;
  }

  final bool Function(PointerDownEvent event) enabled;

  bool _tracking = false;
  bool _won = false;

  @override
  void addAllowedPointer(PointerDownEvent event) {
    // Check multi-touch first: the second finger skips enabled so its side effects don't clobber
    // the first finger's state
    if (_tracking) {
      if (!_won) {
        if (KlinexDebug.logGesture) {
          KlinexDebug.arena('vDrag', '2nd finger down, first not won → reject, yield to pinch');
        }
        resolve(GestureDisposition.rejected);
      } else if (KlinexDebug.logGesture) {
        KlinexDebug.arena('vDrag', 'second finger down while dragging → continue');
      }
      return;
    }
    if (!enabled(event)) {
      if (KlinexDebug.logGesture) KlinexDebug.arena('vDrag', 'enabled=false → skip (outer)');
      return;
    }
    if (KlinexDebug.logGesture) {
      KlinexDebug.arena('vDrag', 'enter p${event.pointer} @${event.localPosition}');
    }
    _tracking = true;
    super.addAllowedPointer(event);
  }

  /// Trackpad two-finger scrolls don't enter: they bypass [enabled], so the down flag is stale and
  /// entering would keep dragging the divider,
  /// and it would beat the outer scroll, leaving the page unscrollable
  @override
  void addAllowedPointerPanZoom(PointerPanZoomStartEvent event) {}

  @override
  void acceptGesture(int pointer) {
    if (KlinexDebug.logGesture) KlinexDebug.arena('vDrag', 'ACCEPT p$pointer ← won arena');
    _won = true;
    super.acceptGesture(pointer);
  }

  @override
  void rejectGesture(int pointer) {
    if (KlinexDebug.logGesture) KlinexDebug.arena('vDrag', 'REJECT p$pointer ← lost arena');
    super.rejectGesture(pointer);
  }

  @override
  void didStopTrackingLastPointer(int pointer) {
    if (KlinexDebug.logGesture) KlinexDebug.arena('vDrag', 'cleanup p$pointer');
    _tracking = false;
    _won = false;
    super.didStopTrackingLastPointer(pointer);
  }
}
