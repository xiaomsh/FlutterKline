import 'package:flutter/gestures.dart';

import '../../debug.dart';

/// Omnidirectional drag, used for exclusive drawing and dragging price lines. [enabled] is
/// checked on pointer down; a second finger landing before winning yields to two-finger pinch.
class CondPanRecognizer extends PanGestureRecognizer {
  CondPanRecognizer(this.enabled, {this.eager, this.claimAtSlop}) {
    // The first drawing anchor must land on the real touch point, without the slop offset
    dragStartBehavior = DragStartBehavior.down;
  }

  final bool Function(PointerDownEvent event) enabled;

  /// If true when the first finger lands, claims immediately (pressed on a price line);
  /// otherwise an outer vertical scroll passes slop first and steals it
  final bool Function(PointerDownEvent event)? eager;

  /// If true when the first finger lands, claims once movement exceeds the device slop. By default
  /// acceptance waits for 2x slop,
  /// while an outer scroll (TabBarView / ListView) accepts at 1x slop and would steal drawing drags
  final bool Function(PointerDownEvent event)? claimAtSlop;

  bool _tracking = false;
  bool _won = false;
  Offset? _down;
  double _slop = kTouchSlop;

  @override
  void addAllowedPointerPanZoom(PointerPanZoomStartEvent event) {}

  @override
  void handleEvent(PointerEvent event) {
    final down = _down;
    if (down != null && !_won && event is PointerMoveEvent) {
      if ((event.position - down).distance > _slop) {
        _down = null;
        if (KlinexDebug.logGesture) KlinexDebug.arena('modePan', 'past slop → claim');
        resolve(GestureDisposition.accepted);
      }
    }
    super.handleEvent(event);
  }

  @override
  void addAllowedPointer(PointerDownEvent event) {
    final grab = !_tracking && (eager?.call(event) ?? false);
    _admit(event);
    if (grab) {
      if (KlinexDebug.logGesture) KlinexDebug.arena('modePan', 'pressed on price line → claim now');
      resolve(GestureDisposition.accepted);
    }
  }

  void _admit(PointerDownEvent event) {
    // Check multi-touch first: the second finger skips enabled so its side effects don't clobber
    // the first finger's state
    if (_tracking) {
      if (!_won) {
        if (KlinexDebug.logGesture) {
          KlinexDebug.arena('modePan', '2nd finger down, first not won → reject, yield to pinch');
        }
        resolve(GestureDisposition.rejected);
      } else if (KlinexDebug.logGesture) {
        KlinexDebug.arena('modePan', 'second finger down while dragging → continue');
      }
      return;
    }
    if (!enabled(event)) {
      if (KlinexDebug.logGesture) {
        KlinexDebug.arena('modePan', 'enabled=false → skip (outer)');
      }
      return;
    }
    if (KlinexDebug.logGesture) {
      KlinexDebug.arena('modePan', 'enter p${event.pointer} @${event.localPosition}');
    }
    _tracking = true;
    // Mouse hit slop is only 1px, so a shaky click to place an anchor becomes a drag; mouse drags
    // don't scroll the outer view either, so no need to claim
    if (event.kind != PointerDeviceKind.mouse && (claimAtSlop?.call(event) ?? false)) {
      _down = event.position;
      _slop = computeHitSlop(event.kind, gestureSettings);
    }
    super.addAllowedPointer(event);
  }

  @override
  void acceptGesture(int pointer) {
    if (KlinexDebug.logGesture) KlinexDebug.arena('modePan', 'ACCEPT p$pointer ← won arena');
    _won = true;
    super.acceptGesture(pointer);
  }

  @override
  void rejectGesture(int pointer) {
    if (KlinexDebug.logGesture) KlinexDebug.arena('modePan', 'REJECT p$pointer ← lost arena');
    super.rejectGesture(pointer);
  }

  @override
  void didStopTrackingLastPointer(int pointer) {
    if (KlinexDebug.logGesture) KlinexDebug.arena('modePan', 'cleanup p$pointer');
    _tracking = false;
    _won = false;
    _down = null;
    super.didStopTrackingLastPointer(pointer);
  }
}
