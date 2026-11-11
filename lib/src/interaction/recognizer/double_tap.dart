import 'package:flutter/gestures.dart';

import '../../debug.dart';

/// Does not enter the arena when [enabled] is false: during exclusive drawing, holding the arena
/// would delay placement taps by about 300ms, and two quick anchor taps would be swallowed as a
/// double tap.
class CondDoubleTapRecognizer extends DoubleTapGestureRecognizer {
  CondDoubleTapRecognizer(this.enabled);

  final bool Function(PointerDownEvent event) enabled;

  @override
  void addAllowedPointer(PointerDownEvent event) {
    if (!enabled(event)) {
      if (KlinexDebug.logGesture) KlinexDebug.arena('dblTap', 'enabled=false → skip');
      return;
    }
    if (KlinexDebug.logGesture) KlinexDebug.arena('dblTap', 'enter p${event.pointer}');
    super.addAllowedPointer(event);
  }
}
