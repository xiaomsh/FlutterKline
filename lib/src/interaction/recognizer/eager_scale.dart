import 'package:flutter/gestures.dart';

import '../../debug.dart';

/// Pinch that claims immediately when the second finger lands: otherwise, in nested scrolling pages
/// two-finger gestures lose the slop race to the outer vertical drag.
class EagerScaleRecognizer extends ScaleGestureRecognizer {
  int _pointers = 0;

  @override
  void addAllowedPointer(PointerDownEvent event) {
    super.addAllowedPointer(event);
    _pointers++;
    if (KlinexDebug.logGesture) KlinexDebug.arena('scale', 'enter, finger $_pointers');
    if (_pointers >= 2) {
      if (KlinexDebug.logGesture) KlinexDebug.arena('scale', 'second finger → claim now');
      resolve(GestureDisposition.accepted);
    }
  }

  @override
  void acceptGesture(int pointer) {
    if (KlinexDebug.logGesture) KlinexDebug.arena('scale', 'ACCEPT p$pointer');
    super.acceptGesture(pointer);
  }

  @override
  void rejectGesture(int pointer) {
    if (KlinexDebug.logGesture) KlinexDebug.arena('scale', 'REJECT p$pointer');
    super.rejectGesture(pointer);
  }

  @override
  void didStopTrackingLastPointer(int pointer) {
    _pointers = 0;
    super.didStopTrackingLastPointer(pointer);
  }
}
