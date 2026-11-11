import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart' show HardwareKeyboard;
import 'package:flutter/widgets.dart';

import '../interaction/gesture_binding.dart';

/// Chart gesture layer: drags use per-direction recognizers (horizontal pans; vertical only handles
/// dividers, y pan, and scale-strip zoom; all directions during exclusive drawing and price-line
/// drags), long press does not enter during exclusive drawing; pinch, wheel (horizontal /
/// Shift+wheel pans), and web trackpad pinch are zoned by position (plot area zooms x, y-axis area
/// zooms y), and trackpad two-finger vertical scrolls go to the outer page. All handling lives in
/// [gesture].
class ChartGestures extends StatelessWidget {
  const ChartGestures({
    super.key,
    required this.gesture,
    required this.hasBarTap,
    required this.child,
  });

  final GestureCoordinator gesture;

  /// When the host handles bar taps, disable double-tap reset: the double-tap recognizer makes taps
  /// wait 300ms and swallows rapid taps.
  /// A function: recognizers are built once and must read the current value at event time.
  final bool Function() hasBarTap;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Device gesture settings must be passed to each recognizer, or they fall back to an 18px slop
    // and always lose to outer scrolling inside tabs (Android is about 8px)
    final gestureSettings = MediaQuery.maybeGestureSettingsOf(context);
    return Listener(
      onPointerDown: (e) => gesture.onPointerDown(kind: e.kind),
      onPointerUp: (_) => gesture.onPointerUp(),
      onPointerCancel: (_) => gesture.onPointerCancelled(),
      onPointerSignal: (e) {
        // Do not claim the wheel during exclusive drawing: the chart does not zoom, the page
        // scrolls
        if (e is PointerScrollEvent && !gesture.mode.exclusive && e.scrollDelta != Offset.zero) {
          // Compete via PointerSignalResolver, so it does not respond together with an outer
          // Scrollable
          GestureBinding.instance.pointerSignalResolver.register(e, (event) {
            var d = (event as PointerScrollEvent).scrollDelta;
            // On Windows / Linux Shift+wheel still arrives vertical; the receiver swaps axes (like
            // Scrollable)
            if (d.dx == 0 && HardwareKeyboard.instance.isShiftPressed) d = Offset(d.dy, 0);
            gesture.onWheel(event.localPosition, d.dy, scrollDeltaX: d.dx);
          });
        } else if (e is PointerScaleEvent && !gesture.mode.exclusive) {
          GestureBinding.instance.pointerSignalResolver.register(e, (event) {
            final s = event as PointerScaleEvent;
            gesture.onPointerScale(s.localPosition, s.scale);
          });
        }
      },
      child: MouseRegion(
        onHover: (e) => gesture.onHover(e.localPosition),
        onExit: (_) => gesture.onHoverExit(),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: gesture.onTapDown,
          onTapUp: gesture.onTapUp,
          onTapCancel: gesture.onTapCancel,
          child: RawGestureDetector(
            behavior: HitTestBehavior.opaque,
            gestures: {
              CondHorizontalDragRecognizer:
                  GestureRecognizerFactoryWithHandlers<CondHorizontalDragRecognizer>(
                    () => CondHorizontalDragRecognizer(
                      (e) => !gesture.mode.exclusive && !gesture.claimsLevel(e),
                      panZoomEnabled: () => !gesture.mode.exclusive,
                    ),
                    (r) => r
                      ..gestureSettings = gestureSettings
                      ..onStart = gesture.onHPanStart
                      ..onUpdate = gesture.onHPanUpdate
                      ..onEnd = gesture.onHPanEnd,
                  ),
              CondVerticalDragRecognizer:
                  GestureRecognizerFactoryWithHandlers<CondVerticalDragRecognizer>(
                    () => CondVerticalDragRecognizer(
                      (e) =>
                          !gesture.mode.exclusive &&
                          !gesture.claimsLevel(e) &&
                          gesture.wantsVertical(e.localPosition),
                    ),
                    (r) => r
                      ..gestureSettings = gestureSettings
                      ..onStart = gesture.onVPanStart
                      ..onUpdate = gesture.onVPanUpdate
                      ..onEnd = gesture.onVPanEnd,
                  ),
              CondPanRecognizer: GestureRecognizerFactoryWithHandlers<CondPanRecognizer>(
                () => CondPanRecognizer(
                  (e) => gesture.mode.exclusive || gesture.claimsLevel(e),
                  eager: gesture.claimsLevel,
                  claimAtSlop: (_) => gesture.mode.exclusive,
                ),
                (r) => r
                  ..gestureSettings = gestureSettings
                  ..onStart = gesture.onModePanStart
                  ..onUpdate = gesture.onModePanUpdate
                  ..onEnd = gesture.onModePanEnd
                  ..onCancel = gesture.onModePanCancel,
              ),
              // Does not enter during exclusive drawing, see [CondLongPressRecognizer]
              CondLongPressRecognizer:
                  GestureRecognizerFactoryWithHandlers<CondLongPressRecognizer>(
                    () => CondLongPressRecognizer((_) => !gesture.mode.exclusive),
                    (r) => r
                      ..gestureSettings = gestureSettings
                      ..onLongPressStart = gesture.onLongPressStart
                      ..onLongPressMoveUpdate = gesture.onLongPressMove
                      ..onLongPressEnd = gesture.onLongPressEnd,
                  ),
              // Claim when the second finger lands, so two-finger gestures beat the outer vertical
              // drag
              EagerScaleRecognizer: GestureRecognizerFactoryWithHandlers<EagerScaleRecognizer>(
                EagerScaleRecognizer.new,
                (r) => r
                  ..gestureSettings = gestureSettings
                  ..onStart = gesture.onScaleStart
                  ..onUpdate = gesture.onScaleUpdate
                  ..onEnd = gesture.onScaleEnd,
              ),
              // Double tap resets y; does not enter during exclusive drawing, when bar taps are
              // handled, or when pressing a host button
              CondDoubleTapRecognizer:
                  GestureRecognizerFactoryWithHandlers<CondDoubleTapRecognizer>(
                    () => CondDoubleTapRecognizer(
                      (e) => !gesture.mode.exclusive && !hasBarTap() && !gesture.onHostButton(e),
                    ),
                    (r) => r
                      ..gestureSettings = gestureSettings
                      ..onDoubleTap = gesture.onDoubleTap,
                  ),
            },
            child: child,
          ),
        ),
      ),
    );
  }
}
