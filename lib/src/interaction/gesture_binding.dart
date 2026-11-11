import 'dart:math' as math;

import 'package:flutter/animation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/physics.dart';

import '../controller.dart';
import '../debug.dart';
import '../model/bar.dart';
import '../model/crosshair_state.dart';
import '../model/min_max.dart';
import '../render/context.dart';
import 'interaction_mode.dart';
import 'level_drag.dart';

export 'recognizer/double_tap.dart';
export 'recognizer/eager_scale.dart';
export 'recognizer/horizontal_drag.dart';
export 'recognizer/long_press.dart';
export 'recognizer/pan_drag.dart';
export 'recognizer/vertical_drag.dart';

/// Turns raw gestures into viewport and crosshair updates. Horizontal drag = pan + fling;
/// vertical only handles splitters, y pan and axis-strip scaling (the rest goes to the outer
/// scrollable); in exclusive drawing mode or while dragging a price level, all directions go
/// to them. Pinch, wheel and web trackpad pinch are zoned by position: the plot area scales
/// x, the y-axis zone scales y.
class GestureCoordinator {
  final ChartController controller;
  final RenderContext Function() resolve;
  final AnimationController fling;

  /// Called when a tap lands on a bar (not fired in exclusive drawing mode or when consumed
  /// by a drawing, nor on spots without a bar such as the right padding after the latest
  /// bar); left mouse clicks go through here too.
  final void Function(Bar bar)? onBarTap;

  InteractionMode _mode;

  InteractionMode get mode => _mode;

  /// Drags price lines to change prices; null = no draggable lines.
  LevelDragController? levelDrag;

  /// Whether the current drag was handed to [levelDrag].
  bool _levelDragging = false;

  PointerDownEvent? _claimEvent;
  bool _claimed = false;

  /// Whether the press is on a host button on a price line (see
  /// [LevelDragController.passThrough]): the double-tap recognizer stays out, otherwise the
  /// button would wait for the 300ms double-tap timeout before responding.
  bool onHostButton(PointerDownEvent e) =>
      levelDrag?.passThrough?.call(e.localPosition, resolve()) ?? false;

  /// Whether this press lands on a draggable price line (not in exclusive drawing mode).
  /// Several recognizers ask with the same down event, so the result is cached per event to
  /// keep them consistent.
  bool claimsLevel(PointerDownEvent e) {
    if (identical(e, _claimEvent)) return _claimed;
    _claimEvent = e;
    final drag = levelDrag;
    _claimed = drag != null && !mode.exclusive && drag.hitTest(e.localPosition, resolve()) != null;
    if (KlinexDebug.logGesture && _claimed) {
      KlinexDebug.gesture('level.claim', '${e.localPosition}');
    }
    return _claimed;
  }

  set mode(InteractionMode m) {
    _mode = m;
    m.resolveContext = resolve;
  }

  double _lastFlingValue = 0;
  double _lastScale = 1;
  bool _modeOwnsTap = false;
  int _splitterIndex = -1;

  GestureCoordinator({
    required this.controller,
    required this.resolve,
    required this.fling,
    this.onBarTap,
    InteractionMode? mode,
  }) : _mode = mode ?? BrowseMode() {
    _mode.resolveContext = resolve;
    fling.addListener(_onFlingTick);
  }

  /// Data set at fling start: if the host switches interval / symbol mid-fling, the remaining
  /// momentum must not drag the new data away from the latest bar.
  int _flingEpoch = 0;

  /// Viewport user-operation generation after the last fling step: a mismatch means something
  /// else (a "back to latest" button, keyboard End, wheel) moved the viewport, and the remaining
  /// momentum would push it off that spot, so stop.
  int _flingUserGen = 0;

  void _onFlingTick() {
    final vp = controller.viewport;
    if (controller.isDisposed ||
        controller.dataEpoch != _flingEpoch ||
        vp.userGeneration != _flingUserGen) {
      fling.stop();
      return;
    }
    vp.scroll(fling.value - _lastFlingValue);
    _flingUserGen = vp.userGeneration;
    _lastFlingValue = fling.value;
    if (vp.atBoundary) fling.stop();
  }

  /// Whether a pointer in this gesture was cancelled by the system. Once a drag has won the
  /// arena, cancellation reaches the recognizer as onEnd rather than onCancel, so end callbacks
  /// use this to tell them apart: a cancelled drag neither changes orders nor flings.
  bool _cancelled = false;

  /// A drag is in progress: taps / long presses / double taps from another finger don't count.
  bool _dragActive = false;

  /// Active pointers on screen (real count at the Listener layer); used to unlatch the pinch
  /// zone without relying on ScaleEndDetails' pointerCount semantics.
  int _activePointers = 0;

  /// Any pointer down stops the fling (touch-to-stop): a light tap can hold a moving chart
  /// without waiting for a drag recognizer to win the arena.
  void onPointerDown({PointerDeviceKind kind = PointerDeviceKind.touch}) {
    _activePointers++;
    if (_activePointers == 1) {
      _cancelled = false;
      // If the recognizer is swapped mid-drag (e.g. the host toggled keyboard), no end callback
      // arrives; start the new gesture from a clean state.
      _dragActive = false;
    }
    if (KlinexDebug.logGesture) {
      KlinexDebug.gesture('pointerDown', 'active=$_activePointers fling=${fling.isAnimating}');
    }

    if (fling.isAnimating) fling.stop();
    // The long-press end callback never comes if it was stolen or cancelled by the host, leaving
    // the crosshair behind; clear it on the next press as a fallback (a long press sets it
    // again). Mouse crosshairs follow hover and only return after the mouse moves, so don't
    // clear those.
    if (_activePointers == 1 &&
        kind != PointerDeviceKind.mouse &&
        controller.crosshair.value != null) {
      controller.crosshair.value = null;
    }
  }

  /// Pointer up/cancel; the pinch zone unlatches only once all pointers leave the screen
  /// (adding/removing fingers mid-pinch doesn't change it).
  void onPointerUp() {
    if (_activePointers > 0) _activePointers--;
    if (KlinexDebug.logGesture) KlinexDebug.gesture('pointerUp', 'active=$_activePointers');

    if (_activePointers == 0) _pinchLatched = false;
  }

  /// Pointer cancelled externally (host Android intercepts after detecting a vertical swipe):
  /// also clear the crosshair, since later events are intercepted entirely and no gesture
  /// will ever come to clear it.
  void onPointerCancelled() {
    if (KlinexDebug.logGesture) KlinexDebug.gesture('pointerCANCEL', 'cancelled → clear crosshair');
    _cancelled = true;
    onPointerUp();
    controller.crosshair.value = null;
  }

  /// Whether the point is in the y-axis strip (outside: the reserved strip; inside: the strip
  /// at the plot's right edge). Only x is compared, so vertical position never misses. When
  /// both sides have scales and the main panel has a secondary axis, the left strip shows the
  /// secondary axis (auto-fit, not manually scalable) and doesn't count.
  bool _inYAxisZone(Offset p) {
    final ctx = resolve();
    if (ctx.hasLeftAxis && p.dx <= ctx.leftAxisRect.right) {
      final leftIsSecondary =
          ctx.mainPanel.secondary != null && (ctx.axisOutside || ctx.axisInside);
      return !leftIsSecondary;
    }
    if (ctx.axisOutside) return p.dx >= ctx.yAxisRect.left;
    return ctx.axisInside && p.dx >= ctx.chartRect.right - ctx.config.yAxisWidth;
  }

  // ---- Single-finger horizontal: chart x pan + fling ----

  /// Whether this horizontal drag scales x on the time axis ([ChartConfig.axisDragScale]).
  bool _scalingX = false;

  void onHPanStart(DragStartDetails d) {
    if (KlinexDebug.logGesture) {
      KlinexDebug.gesture('hPan.start', '@${d.localPosition} exclusive=${mode.exclusive}');
    }
    fling.stop();
    _dragActive = true;
    _cancelled = false;
    controller.crosshair.value = null;
    final ctx = resolve();
    _scalingX = ctx.config.axisDragScale && d.localPosition.dy >= ctx.timeAxisRect.top;
  }

  void onHPanUpdate(DragUpdateDetails d) {
    // Entered exclusive mode mid-gesture (e.g. a drawing got selected while held): this drag
    // is void, the chart stays frozen, and editing starts with the next gesture.
    if (KlinexDebug.logGesture) {
      KlinexDebug.gesture(
        'hPan.update',
        'dx=${d.delta.dx.toStringAsFixed(1)} exclusive=${mode.exclusive}',
      );
    }
    if (mode.exclusive) return;
    if (_scalingX) {
      // Dragging right zooms in, anchored at the plot's right edge.
      controller.viewport.zoomAt(resolve().chartRect.width, math.exp(d.delta.dx * 0.01));
      return;
    }
    if (d.delta.dx != 0) controller.viewport.scroll(d.delta.dx);
  }

  void onHPanEnd(DragEndDetails d) {
    if (KlinexDebug.logGesture) {
      KlinexDebug.gesture('hPan.end', 'vx=${d.velocity.pixelsPerSecond.dx.toStringAsFixed(0)}');
    }
    _dragActive = false;
    if (mode.exclusive) return;
    if (_scalingX) {
      _scalingX = false;
      return;
    }
    if (_cancelled) return;
    final vx = d.velocity.pixelsPerSecond.dx;
    if (vx.abs() < 100) return;
    _lastFlingValue = 0;
    _flingEpoch = controller.dataEpoch;
    _flingUserGen = controller.viewport.userGeneration;
    fling.value = 0;
    // The default velocity tolerance of 0.001px/s keeps repainting a sub-pixel tail every frame
    // for the last few seconds.
    fling.animateWith(FrictionSimulation(0.135, 0, vx, tolerance: const Tolerance(velocity: 5)));
  }

  // ---- Single-finger vertical: splitter drag only (other vertical drags go to the outer
  // scrollable) ----

  /// Splitter hit recorded at press time (on accept, the recognizer's start position already
  /// includes the pre-accept slop, so the ±8px band can't be re-hit in onVPanStart).
  int _downSplitter = -1;

  /// Decided at press time: "this vertical drag pans the main panel's value range" (see
  /// [YPanMode]).
  bool _downPanY = false;
  bool _panningY = false;

  /// Decided at press time: "this vertical drag scales y on the price axis"; takes precedence
  /// over panning.
  bool _downScaleY = false;
  bool _scalingY = false;

  /// Whether the vertical drag belongs to the chart: a splitter hit, or a press in an area
  /// where [YPanMode] allows panning. When false, the recognizer stays out and the outer
  /// scrollable scrolls normally.
  bool wantsVertical(Offset p) {
    _downSplitter = _hitSplitter(p);
    _downScaleY = _downSplitter < 0 && _wantsScaleY(p);
    _downPanY = _downSplitter < 0 && !_downScaleY && _wantsPanY(p);
    if (KlinexDebug.logGesture) {
      KlinexDebug.gesture(
        'wantsVertical',
        '$p → splitter=$_downSplitter panY=$_downPanY '
            '(${_downSplitter >= 0 || _downPanY ? 'chart claims' : 'left to outer scroll'})',
      );
    }
    return _downSplitter >= 0 || _downScaleY || _downPanY;
  }

  bool _wantsScaleY(Offset p) {
    final ctx = resolve();
    if (ctx.isEmpty || !ctx.config.axisDragScale) return false;
    final main = ctx.mainPanel.rect;
    return p.dy >= main.top && p.dy <= main.bottom && _inYAxisZone(p);
  }

  /// Only the main panel's height range counts: sub-panels have no panning, so presses there
  /// still go to the outer scrollable.
  bool _wantsPanY(Offset p) {
    final ctx = resolve();
    if (ctx.isEmpty) return false;
    final main = ctx.mainPanel.rect;
    if (p.dy < main.top || p.dy > main.bottom) return false;
    return switch (ctx.config.yPan) {
      YPanMode.none => false,
      YPanMode.axis => _inYAxisZone(p),
      YPanMode.chart => true,
    };
  }

  void onVPanStart(DragStartDetails d) {
    if (KlinexDebug.logGesture) KlinexDebug.gesture('vPan.start', 'splitter=$_downSplitter');
    fling.stop();
    _dragActive = true;
    controller.crosshair.value = null;
    _splitterIndex = _downSplitter;
    _panningY = _downPanY;
    _scalingY = _downScaleY;
  }

  void onVPanUpdate(DragUpdateDetails d) {
    if (KlinexDebug.logGesture) {
      KlinexDebug.gesture('vPan.update', 'dy=${d.delta.dy.toStringAsFixed(1)}');
    }
    if (mode.exclusive) return;
    if (_splitterIndex >= 0 && d.delta.dy != 0) {
      _dragSplitter(d.delta.dy);
    } else if (_scalingY) {
      // Dragging down zooms out (wider value range), dragging up zooms in.
      controller.viewport.zoomY(math.exp(-d.delta.dy * 0.01));
    } else if (_panningY) {
      final main = resolve().mainPanel;
      // With inverted coordinates, content follows the finger in the opposite direction.
      controller.viewport.panY(main.inverted ? -d.delta.dy : d.delta.dy, main.rect.height);
    }
  }

  void onVPanEnd(DragEndDetails d) {
    _dragActive = false;
    _splitterIndex = -1;
    _panningY = false;
    _scalingY = false;
    _downSplitter = -1;
    _downPanY = false;
    _downScaleY = false;
  }

  // ---- Exclusive drawing / price-line drag: drags in all directions go to them (the
  // recognizer only claims in these two cases) ----

  void onModePanStart(DragStartDetails d) {
    if (KlinexDebug.logGesture) {
      KlinexDebug.gesture('modePan.start', '@${d.localPosition} mode=${mode.runtimeType}');
    }
    fling.stop();
    _dragActive = true;
    _cancelled = false;
    controller.crosshair.value = null;
    final ctx = resolve();
    _levelDragging = !mode.exclusive && (levelDrag?.begin(d.localPosition, ctx) ?? false);
    if (!_levelDragging) mode.onDragStart(d.localPosition, ctx);
  }

  void onModePanUpdate(DragUpdateDetails d) {
    if (_levelDragging) {
      levelDrag?.update(d.localPosition, resolve());
    } else {
      mode.onDragUpdate(d.localPosition, resolve());
    }
  }

  void onModePanEnd(DragEndDetails d) {
    _dragActive = false;
    if (_levelDragging) {
      _levelDragging = false;
      if (_cancelled) {
        levelDrag?.cancel();
      } else {
        levelDrag?.end();
      }
    } else {
      mode.onDragEnd(resolve());
    }
  }

  /// Drag cancelled by the system (incoming call, host intercept): the price line abandons
  /// this drag without changing the order.
  void onModePanCancel() {
    _dragActive = false;
    if (!_levelDragging) {
      // A drawing drag cancelled midway still needs wrapping up, otherwise the interaction
      // mode stays stuck mid-drag.
      mode.onDragEnd(resolve());
      return;
    }
    _levelDragging = false;
    levelDrag?.cancel();
  }

  // ---- Two-finger pinch: zoned by position; the plot area scales x only, the y-axis zone
  // scales y only ----

  /// Pinch zone, latched when two fingers first come down. Adding/removing fingers makes
  /// Flutter re-send onStart; [_pinchLatched] keeps the decision fixed within one pinch
  /// (lifting and re-placing a finger doesn't switch axes).
  bool _pinchInAxis = false;
  bool _pinchLatched = false;

  void onScaleStart(ScaleStartDetails d) {
    if (KlinexDebug.logGesture) {
      KlinexDebug.gesture('scale.start', 'pointers=${d.pointerCount} focal=${d.localFocalPoint}');
    }
    if (d.pointerCount < 2) return;
    fling.stop();
    controller.crosshair.value = null;
    _lastScale = 1;
    if (!_pinchLatched) {
      _pinchInAxis = _inYAxisZone(d.localFocalPoint);
      _pinchLatched = true;
    }
  }

  void onScaleUpdate(ScaleUpdateDetails d) {
    if (d.pointerCount < 2) return;
    final s = d.scale;
    if (s > 0 && s != _lastScale) {
      // Clamp the incremental ratio per event to avoid single-frame jumps.
      final f = (s / _lastScale).clamp(2 / 3, 1.5);
      if (_pinchInAxis) {
        controller.viewport.zoomY(f);
      } else {
        controller.viewport.zoomAt(d.localFocalPoint.dx - resolve().chartRect.left, f);
      }
      _lastScale = s;
    }
    // In the plot area, horizontal focal movement follows the fingers (the zoom anchor doesn't
    // drift); pinching in the axis zone doesn't move the chart.
    if (!_pinchInAxis && d.focalPointDelta.dx != 0) {
      controller.viewport.scroll(d.focalPointDelta.dx);
    }
  }

  void onScaleEnd(ScaleEndDetails d) {
    if (KlinexDebug.logGesture) KlinexDebug.gesture('scale.end', 'active=$_activePointers');
    // Stay latched while fingers remain (lifting one mid-pinch triggers end + start), so the
    // axis doesn't change within one pinch. Hosts without the Listener count and unit tests
    // always have _activePointers == 0, so unlatch directly.
    if (_activePointers == 0) _pinchLatched = false;
  }

  int _hitSplitter(Offset p) {
    final ctx = resolve();
    if (!ctx.config.panelResizable) return -1;
    for (var i = 0; i < ctx.panels.length - 1; i++) {
      if ((p.dy - ctx.panels[i].rect.bottom).abs() <= 8) return i;
    }
    return -1;
  }

  void _dragSplitter(double dy) {
    final ctx = resolve();
    final panels = ctx.panels;
    final i = _splitterIndex;
    if (i < 0 || i + 1 >= panels.length) return;
    final config = ctx.config;
    var totalFlex = 0.0;
    for (final p in panels) {
      totalFlex += config.weightFor(p.id, p.isMain);
    }
    final chartH = ctx.chartRect.height;
    if (chartH <= 0) return;
    final dw = dy * totalFlex / chartH;
    final a = panels[i], b = panels[i + 1];
    final wa = config.weightFor(a.id, a.isMain);
    final wb = config.weightFor(b.id, b.isMain);
    const minW = 0.3;
    // Stop adjusting once either weight is below the minimum (otherwise clamp's bounds invert
    // and it throws).
    if (wa < minW || wb < minW) return;
    final applied = dw.clamp(minW - wa, wb - minW);
    if (applied == 0) return;
    config.panelWeights[a.id] = wa + applied;
    config.panelWeights[b.id] = wb - applied;
    config.bumpLayout();
  }

  // ---- Tap / long press and crosshair: long press shows, drags, and clears on release; a
  // touch tap only clears leftovers, never creates; desktop uses hover, mouse clicks don't
  // clear ----

  void onTapDown(TapDownDetails d) {
    if (_dragActive) {
      _modeOwnsTap = false;
      return;
    }
    _modeOwnsTap = mode.onTapDown(d.localPosition, resolve());
    if (KlinexDebug.logGesture) {
      KlinexDebug.gesture('tap.down', '@${d.localPosition} modeOwns=$_modeOwnsTap');
    }
  }

  /// Press turned into a drag / was taken by another recognizer: clear the "mode consumed
  /// this tap" flag, otherwise it lingers until the next real tap and swallows the crosshair
  /// clear.
  void onTapCancel() {
    if (KlinexDebug.logGesture) KlinexDebug.gesture('tap.cancel', 'became drag / taken over');
    _modeOwnsTap = false;
  }

  void onTapUp(TapUpDetails d) {
    if (KlinexDebug.logGesture) KlinexDebug.gesture('tap.up', '@${d.localPosition}');
    if (_dragActive) return;
    // Only reached when the chart wins the gesture arena (not for taps on overlay widgets),
    // so "tap empty space to deselect" happens in the up phase.
    mode.onTapUp(d.localPosition, resolve());
    if (_modeOwnsTap) {
      _modeOwnsTap = false;
      return;
    }
    if (d.kind != PointerDeviceKind.mouse && controller.crosshair.value != null) {
      controller.crosshair.value = null;
    }
    final cb = onBarTap;
    if (cb == null || mode.exclusive) return;
    final ctx = resolve();
    final dx = d.localPosition.dx;
    if (ctx.isEmpty || dx > ctx.chartRect.right || dx < ctx.chartRect.left) return;
    final i = ctx.barIndexAt(dx);
    // Padding right of the latest bar and empty space left of the oldest don't count as a bar.
    if ((ctx.indexAt(dx) - i).abs() > 0.5) return;
    cb(controller.bars[i]);
  }

  /// Double tap: clears manual y-axis scale / pan and returns to the auto range (or the
  /// locked range when locked).
  void onDoubleTap() {
    if (KlinexDebug.logGesture) KlinexDebug.gesture('doubleTap', '');
    if (mode.exclusive || _dragActive) return;
    controller.viewport.resetYScale();
  }

  void onLongPressStart(LongPressStartDetails d) {
    if (KlinexDebug.logGesture) {
      KlinexDebug.gesture('longPress.start', '@${d.localPosition} exclusive=${mode.exclusive}');
    }
    if (mode.exclusive || _dragActive) return;
    fling.stop();
    setCrosshair(d.localPosition);
  }

  void onLongPressMove(LongPressMoveUpdateDetails d) {
    if (KlinexDebug.logGesture) KlinexDebug.gesture('longPress.move', '@${d.localPosition}');
    if (mode.exclusive || _dragActive) return;
    setCrosshair(d.localPosition);
  }

  void onLongPressEnd(LongPressEndDetails d) {
    if (KlinexDebug.logGesture) KlinexDebug.gesture('longPress.end', '→ clear crosshair');
    controller.crosshair.value = null;
  }

  // ---- Desktop / web ----

  void onHover(Offset p) {
    if (KlinexDebug.logGesture) KlinexDebug.gesture('hover', '$p');
    setCrosshair(p);
  }

  void onHoverExit() {
    if (KlinexDebug.logGesture) KlinexDebug.gesture('hoverExit', '');
    controller.crosshair.value = null;
  }

  /// Mouse wheel: scales y over the y-axis strip, elsewhere scales x around the cursor;
  /// horizontal scrolling (trackpad swipe, Shift+wheel) pans.
  void onWheel(Offset p, double scrollDeltaY, {double scrollDeltaX = 0}) {
    if (KlinexDebug.logGesture) {
      KlinexDebug.gesture('wheel', '$p dx=$scrollDeltaX dy=$scrollDeltaY');
    }
    if (mode.exclusive) return;
    if (scrollDeltaX.abs() > scrollDeltaY.abs()) {
      controller.viewport.scroll(-scrollDeltaX);
      return;
    }
    final factor = math.exp(-scrollDeltaY * 0.0015);
    if (_inYAxisZone(p)) {
      controller.viewport.zoomY(factor);
    } else {
      controller.viewport.zoomAt(p.dx - resolve().chartRect.left, factor);
    }
  }

  /// Trackpad pinch delivered as a pointer signal (web): like the wheel, scales y over the
  /// y-axis strip, elsewhere scales x around the cursor.
  void onPointerScale(Offset p, double scale) {
    if (mode.exclusive || !scale.isFinite || scale <= 0 || scale == 1) return;
    if (_inYAxisZone(p)) {
      controller.viewport.zoomY(scale);
    } else {
      controller.viewport.zoomAt(p.dx - resolve().chartRect.left, scale);
    }
  }

  void setCrosshair(Offset p) {
    final ctx = resolve();
    if (ctx.isEmpty) return;
    // Snap horizontally to the nearest real bar and store its timestamp, so crosshairIndex()
    // follows automatically after prepends and replacements.
    final bar = controller.bars[ctx.barIndexAt(p.dx)];
    controller.crosshair.value = CrosshairState(time: bar.time, position: _snapY(p, bar, ctx));
  }

  /// Snaps vertically per [ChartConfig.crosshairSnap], only while the finger is in the main
  /// panel.
  Offset _snapY(Offset p, Bar bar, RenderContext ctx) {
    final snap = ctx.config.crosshairSnap;
    final panel = ctx.mainPanel;
    if (snap == CrosshairSnap.free || p.dy < panel.rect.top || p.dy > panel.rect.bottom) return p;
    // After manual y scaling the snap point may lie outside the main panel; without clamping,
    // the crosshair would land in a sub-panel and read its value.
    Offset at(double y) => Offset(p.dx, clampSafe(y, panel.rect.top, panel.rect.bottom));
    if (snap == CrosshairSnap.close) return at(panel.yOf(bar.close));
    var best = panel.yOf(bar.open);
    for (final v in [bar.high, bar.low, bar.close]) {
      final y = panel.yOf(v);
      if ((y - p.dy).abs() < (best - p.dy).abs()) best = y;
    }
    return at(best);
  }

  void dispose() {
    fling.removeListener(_onFlingTick);
  }
}
