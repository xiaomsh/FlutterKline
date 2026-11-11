import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../controller.dart';

/// Desktop and web keyboard controls: left/right pans (hold Shift for 10% of the width), up/down or
/// +/- zooms,
/// Home / End jumps to oldest / latest (End also resumes auto-follow), Esc hides the crosshair.
/// Combos with Ctrl / Cmd / Alt are left to the system and browser;
/// when [exclusive] (exclusive drawing) only Esc responds, and like the wheel it does not move the
/// viewport.
KeyEventResult handleChartKey(
  KeyEvent event,
  ChartController controller, {
  bool exclusive = false,
}) {
  if (event is KeyUpEvent) return KeyEventResult.ignored;
  final kb = HardwareKeyboard.instance;
  if (kb.isControlPressed || kb.isMetaPressed || kb.isAltPressed) return KeyEventResult.ignored;
  if (event.logicalKey == LogicalKeyboardKey.escape && controller.crosshair.value != null) {
    controller.crosshair.value = null;
    return KeyEventResult.handled;
  }
  if (exclusive) return KeyEventResult.ignored;
  final vp = controller.viewport;
  if (vp.barCount == 0 || vp.width <= 0) return KeyEventResult.ignored;
  final key = event.logicalKey;
  final shift = kb.isShiftPressed;
  final step = shift ? vp.width * 0.1 : vp.barWidth;
  if (key == LogicalKeyboardKey.arrowLeft) {
    vp.scroll(step);
    return KeyEventResult.handled;
  }
  if (key == LogicalKeyboardKey.arrowRight) {
    vp.scroll(-step);
    return KeyEventResult.handled;
  }
  if (key == LogicalKeyboardKey.arrowUp ||
      key == LogicalKeyboardKey.equal ||
      key == LogicalKeyboardKey.add ||
      key == LogicalKeyboardKey.numpadAdd) {
    vp.zoomAt(vp.width, 1.1);
    return KeyEventResult.handled;
  }
  if (key == LogicalKeyboardKey.arrowDown ||
      key == LogicalKeyboardKey.minus ||
      key == LogicalKeyboardKey.numpadSubtract) {
    vp.zoomAt(vp.width, 1 / 1.1);
    return KeyEventResult.handled;
  }
  if (key == LogicalKeyboardKey.home) {
    vp.jumpTo(math.max(0, vp.visibleBars - 1));
    return KeyEventResult.handled;
  }
  if (key == LogicalKeyboardKey.end) {
    vp.scrollToLatest();
    return KeyEventResult.handled;
  }
  return KeyEventResult.ignored;
}
