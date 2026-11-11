import 'package:flutter/gestures.dart';

import '../../debug.dart';

/// Doesn't enter when [enabled] is false: when holding still 500ms during exclusive drawing, long
/// press would win the arena at the deadline,
/// swallowing all subsequent drags and confirming taps
class CondLongPressRecognizer extends LongPressGestureRecognizer {
  CondLongPressRecognizer(this.enabled);

  final bool Function(PointerDownEvent event) enabled;

  @override
  void addAllowedPointer(PointerDownEvent event) {
    if (!enabled(event)) {
      if (KlinexDebug.logGesture) KlinexDebug.arena('longPress', 'enabled=false → skip');
      return;
    }
    super.addAllowedPointer(event);
  }
}
