import 'package:flutter/gestures.dart';

import '../../debug.dart';

/// Horizontal drag: claims immediately once |dx| exceeds the threshold and horizontal dominates,
/// reliably beating outer same-axis scrolls (TabBarView / PageView);
/// mostly-vertical moves are not claimed and go to the outer vertical scroll. [enabled] is checked
/// on pointer down; a second finger landing before winning yields to two-finger pinch
class CondHorizontalDragRecognizer extends HorizontalDragGestureRecognizer {
  CondHorizontalDragRecognizer(this.enabled, {this.panZoomEnabled}) {
    // Measured from pointer down: the start excludes the ~18px pre-accept offset so the first drag
    // segment isn't swallowed
    dragStartBehavior = DragStartBehavior.down;
  }

  final bool Function(PointerDownEvent event) enabled;

  /// Whether trackpad two-finger scrolls enter (they bypass [enabled]); null = enter
  final bool Function()? panZoomEnabled;

  @override
  void addAllowedPointerPanZoom(PointerPanZoomStartEvent event) {
    if (panZoomEnabled?.call() ?? true) super.addAllowedPointerPanZoom(event);
  }

  /// Claim threshold = device slop * this factor. Waiting for the full slop measured ~350ms from
  /// press to chart movement,
  /// which feels laggy; vertical has its own divider check, so a lower threshold won't steal outer
  /// vertical scrolls
  static const double claimSlopFactor = 0.6;

  /// Yields only when clearly vertical (|dy| > |dx| / 0.8): on slow drags finger jitter accumulates
  /// dy, and a strict |dx| > |dy| would hand slightly diagonal drags to the outer scroll
  static const double claimDirectionTolerance = 0.8;

  bool _tracking = false;
  bool _won = false;
  Offset? _down;
  bool _claimed = false;

  /// Taken from the same source as the outer Scrollable, not hard-coded kTouchSlop: Android device
  /// slop is ~8, so stopping at 18 would always lose the race
  double _slop = kTouchSlop;

  double get _claimSlop => _slop * claimSlopFactor;

  @override
  void addAllowedPointer(PointerDownEvent event) {
    _down = event.position;
    _claimed = false;
    _slop = computeHitSlop(event.kind, gestureSettings);
    // Check multi-touch first: the second finger skips enabled so its side effects don't clobber
    // the first finger's state
    if (_tracking) {
      if (!_won) {
        if (KlinexDebug.logGesture) {
          KlinexDebug.arena('hDrag', '2nd finger down, first not won → reject, yield to pinch');
        }
        resolve(GestureDisposition.rejected);
      } else if (KlinexDebug.logGesture) {
        KlinexDebug.arena('hDrag', 'second finger down while dragging → continue');
      }
      return;
    }
    if (!enabled(event)) {
      if (KlinexDebug.logGesture) KlinexDebug.arena('hDrag', 'enabled=false → skip (outer)');
      return;
    }
    if (KlinexDebug.logGesture) {
      KlinexDebug.arena('hDrag', 'enter p${event.pointer} @${event.localPosition}');
    }
    _tracking = true;
    super.addAllowedPointer(event);
  }

  @override
  void handleEvent(PointerEvent event) {
    if (!_claimed && !_won && _down != null && event is PointerMoveEvent) {
      final d = event.position - _down!;
      final dx = d.dx.abs(), dy = d.dy.abs();
      if (dx > _claimSlop && dx > dy * claimDirectionTolerance) {
        _claimed = true;
        if (KlinexDebug.logGesture) {
          KlinexDebug.arena(
            'hDrag',
            'horizontal dominates → claim '
                'dx=${dx.toStringAsFixed(1)} dy=${dy.toStringAsFixed(1)} '
                'claimSlop=${_claimSlop.toStringAsFixed(1)}(device slop '
                '${_slop.toStringAsFixed(1)}×$claimSlopFactor) '
                'direction tolerance=$claimDirectionTolerance',
          );
        }
        resolve(GestureDisposition.accepted);
      } else if (KlinexDebug.logGesture && (dx > _claimSlop || dy > _claimSlop)) {
        KlinexDebug.arena(
          'hDrag',
          'past threshold but clearly vertical → no claim '
              'dx=${dx.toStringAsFixed(1)} dy=${dy.toStringAsFixed(1)} '
              'claimSlop=${_claimSlop.toStringAsFixed(1)}',
        );
      }
    }
    super.handleEvent(event);
  }

  @override
  void acceptGesture(int pointer) {
    if (KlinexDebug.logGesture) KlinexDebug.arena('hDrag', 'ACCEPT p$pointer ← won arena');
    _won = true;
    super.acceptGesture(pointer);
  }

  @override
  void rejectGesture(int pointer) {
    if (KlinexDebug.logGesture) KlinexDebug.arena('hDrag', 'REJECT p$pointer ← lost arena');
    super.rejectGesture(pointer);
  }

  @override
  void didStopTrackingLastPointer(int pointer) {
    _down = null;
    _claimed = false;
    if (KlinexDebug.logGesture) KlinexDebug.arena('hDrag', 'cleanup p$pointer');
    _tracking = false;
    _won = false;
    super.didStopTrackingLastPointer(pointer);
  }
}
