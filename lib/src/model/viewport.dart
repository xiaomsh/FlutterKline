import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import 'min_max.dart';

/// Horizontal viewport: which (fractional) bar the right edge faces and logical pixels per bar.
/// Changes affecting the value range go only through notifications here or the data revision;
/// there is no third path.
class ChartViewport extends ChangeNotifier {
  double _barWidth = 8;
  double _rightIndex = 0; // Fractional index at the right edge
  int _barCount = 0;
  double _width = 0;

  /// Lower bound of [barWidth]; the widget sets it to 1/4 physical pixel, sub-pixel bars are
  /// handled by decimation.
  double minBarWidth = 1.0;

  /// Upper bound of [barWidth] (max zoom in).
  double maxBarWidth = defaultMaxBarWidth;

  static const double defaultMaxBarWidth = 48.0;

  /// Max blank space that can be dragged out to the right of the latest bar (fraction of width): 1
  /// reaches the left edge; 0 keeps the latest bar flush right (at least half a bar).
  /// Proportional, so it stays stable in pixels when zooming.
  double rightBlankRatio = 1.0;

  /// Right blank ratio on first landing (setBars, period switch, first layout); also at least half
  /// a bar.
  double initialRightBlankRatio = 1 / 3;

  /// Follow: when true and parked at the latest bar (scrolling away releases it), the viewport
  /// advances by as many bars as are appended. Off by default: appends do not move the x axis.
  bool autoFollow = false;

  /// Manual vertical zoom of the main range: 1 is fully auto, >1 zooms in. Only the span is scaled;
  /// the center stays auto.
  double _yScale = 1.0;

  /// Range of [yScale]. Layout adjusts the lower bound by yFitValues; when raised, [yScale] is
  /// clamped in immediately (effective the same frame).
  double get minYScale => _minYScale;
  double _minYScale = 0.2;

  set minYScale(double value) {
    _minYScale = value;
    if (_yScale < value) _yScale = clampSafe(_yScale, value, maxYScale);
  }

  double maxYScale = 5.0;

  double get yScale => _yScale;

  /// Manual vertical pan of the main panel, in fractions of the displayed span: 0 is centered, >0
  /// moves the range up (content follows the finger down).
  double _yOffset = 0;

  /// Max spans [yOffset] can deviate from center.
  double maxYOffset = 3.0;

  double get yOffset => _yOffset;

  /// [rightBlankRatio] converted to bars; 2 bars before the first layout provides a width.
  /// At least half a bar: indices are bar centers, so with 0 blank the latest bar would be half cut
  /// off by the right edge.
  double get rightBlankBars =>
      _width > 0 && _barWidth > 0 ? math.max(0.5, (_width * rightBlankRatio) / _barWidth) : 2.0;

  double get _initialBlankBars => _width > 0 && _barWidth > 0
      ? math.max(0.5, (_width * initialRightBlankRatio) / _barWidth)
      : 2.0;

  /// Incremented on every change; the layout cache key.
  int _generation = 0;

  int get generation => _generation;

  /// Incremented only on user gestures (scroll/zoom/sync mirroring): the range animation uses it to
  /// tell "gesture-driven" (instant, no tween) from "data-driven" (tweened) changes.
  int _userGeneration = 0;

  int get userGeneration => _userGeneration;

  /// Sticky "parked at latest bar" flag, written by gestures, sync mirroring, and first landing;
  /// realtime appends never move the x axis.
  bool _pinnedToLatest = true;

  int? _fixedSlots;

  /// Fixed slot count (intraday charts): the width is split into exactly this many slots, bar `i`
  /// sits in slot `i`, and scrolling / zooming become no-ops. Slots past the data stay empty.
  /// null (default) restores the free viewport at the latest bar.
  int? get fixedSlots => _fixedSlots;

  set fixedSlots(int? value) {
    assert(value == null || value > 0, 'fixedSlots must be positive');
    if (value == _fixedSlots) return;
    _fixedSlots = value;
    if (value == null) {
      _barWidth = clampSafe(_barWidth, minBarWidth, maxBarWidth);
      _rightIndex = math.max(0, _barCount - 1) + _initialBlankBars;
      _pinnedToLatest = true;
    }
    _clamp();
    _notify();
  }

  double get barWidth => _barWidth;

  double get rightIndex => _rightIndex;

  int get barCount => _barCount;

  double get width => _width;

  double get visibleBars => _width > 0 ? _width / _barWidth : 0;

  /// Fractional index of the bar at the left edge.
  double get leftIndex => _rightIndex - visibleBars;

  /// Whether the latest bar is at or dragged left of the right edge.
  bool get atLatest => _rightIndex >= _barCount - 1.001;

  bool get atBoundary {
    final b = _bounds();
    return _rightIndex <= b.$1 + 1e-9 || _rightIndex >= b.$2 - 1e-9;
  }

  // ---- Coordinate mapping ----

  double indexToX(num index) => _width - (_rightIndex - index) * _barWidth;

  double xToIndex(double x) => _rightIndex - (_width - x) / _barWidth;

  /// Visible bar indices (inclusive), extended by one on each side so lines connect across edges;
  /// (0, -1) when there is no data.
  (int, int) visibleRange() {
    if (_barCount == 0 || _width <= 0) return (0, -1);
    final start = (xToIndex(0).floor() - 1).clamp(0, _barCount - 1);
    final end = (xToIndex(_width).ceil() + 1).clamp(0, _barCount - 1);
    return (start, end);
  }

  // ---- Layout attach (silent: called during build / paint) ----

  void attach(double width) {
    if (width == _width) return;
    final firstLayout = _width <= 0;
    _width = width;
    if (firstLayout && _pinnedToLatest && _barCount > 0) {
      // First real width: land at the default position, latest bar at
      // width * (1 - initialRightBlankRatio), not flush right
      _rightIndex = (_barCount - 1) + _initialBlankBars;
    }
    _clamp();
    _generation++;
  }

  // ---- Data-driven (called by the controller) ----

  void setBarCount(int count, {bool jumpToLatest = false}) {
    final firstData = _barCount == 0 && count > 0;
    final dataBeforeLayout = _pinnedToLatest && count > _barCount && _width <= 0;
    final appended = count - _barCount;
    _barCount = count;
    if (jumpToLatest || firstData || dataBeforeLayout) {
      // Initial positioning (setBars, period switch, replay jump). This, the first landing in
      // attach, and autoFollow below are the viewport's only automatic moves
      _rightIndex = math.max(0, count - 1) + _initialBlankBars;
      _pinnedToLatest = true;
      _yScale = 1.0; // Relanding = auto range again
      _yOffset = 0;
    } else if (autoFollow && _pinnedToLatest && appended > 0 && _width > 0) {
      // Follow the latest bar: move by as many bars as appended
      _rightIndex += appended;
    }
    // Otherwise appends do not move the x axis: new bars fill the right blank or land past the
    // right edge
    _clamp();
    _notify();
  }

  /// Prepend ([count] positive) or trim from the front (negative): indices shift as a whole and the
  /// viewport moves in the same frame, so the view does not jump.
  void shiftBy(int count) {
    _barCount += count;
    _rightIndex += count;
    _clamp();
    _notify();
  }

  // ---- Gestures ----

  /// Positive [dxPixels] = finger moves right = view older data; a user action that updates the
  /// follow flag.
  void scroll(double dxPixels) {
    if (_barCount == 0) return;
    _rightIndex -= dxPixels / _barWidth;
    _clamp();
    _pinnedToLatest = atLatest;
    _userGeneration++;
    _notify();
  }

  /// Zooms by [factor] around [focalX], keeping the data point under the cursor fixed; a user
  /// action that updates the follow flag.
  void zoomAt(double focalX, double factor) {
    if (_barCount == 0 || factor == 1.0 || _width <= 0) return;
    final focalIndex = xToIndex(focalX);
    _barWidth = clampSafe(_barWidth * factor, minBarWidth, maxBarWidth);
    _rightIndex = focalIndex + (_width - focalX) / _barWidth;
    _clamp();
    _pinnedToLatest = atLatest;
    _userGeneration++;
    _notify();
  }

  /// Vertical pinch: multiplies [yScale] by [factor] (>1 zooms in); main panel only, sub-panels
  /// stay auto.
  void zoomY(double factor) {
    if (factor == 1.0 || !factor.isFinite || factor <= 0) return;
    final next = clampSafe(_yScale * factor, minYScale, maxYScale);
    if (next == _yScale) return;
    _yScale = next;
    _userGeneration++;
    _notify();
  }

  /// Vertical drag: pans the main range by [dyPixels] (panel height [panelHeight]); positive =
  /// finger down = view higher values.
  void panY(double dyPixels, double panelHeight) {
    if (dyPixels == 0 || !dyPixels.isFinite || panelHeight <= 0) return;
    final next = clampSafe(_yOffset + dyPixels / panelHeight, -maxYOffset, maxYOffset);
    if (next == _yOffset) return;
    _yOffset = next;
    _userGeneration++;
    _notify();
  }

  MinMax? _lockedY;

  /// Locked main range: when non-null the main panel no longer autoscales to the visible range;
  /// manual zoom / pan apply on top of it.
  MinMax? get lockedYRange => _lockedY;

  /// Locks the main range to [range] and clears manual zoom and pan ([range] is usually the current
  /// displayed range, so the view does not jump).
  void lockYRange(MinMax range) {
    if (range.isEmpty || !range.min.isFinite || !range.max.isFinite || range.span <= 0) return;
    _lockedY = range;
    _yScale = 1.0;
    _yOffset = 0;
    _notify();
  }

  /// Unlocks and returns to auto range. Manual zoom and pan while locked are relative to the locked
  /// range, so they are cleared too to avoid a jump on the auto range.
  void unlockYRange() {
    if (_lockedY == null) return;
    _lockedY = null;
    _yScale = 1.0;
    _yOffset = 0;
    _notify();
  }

  /// Returns to fully auto range (clears zoom and pan), also done on first landing; when locked,
  /// returns to the locked range.
  void resetYScale() {
    if (_yScale == 1.0 && _yOffset == 0) return;
    _yScale = 1.0;
    _yOffset = 0;
    _notify();
  }

  /// Re-clamps the current [barWidth] into its bounds: call after changing the bounds at runtime
  /// (bar width normally only changes during zoom gestures).
  void clampBarWidthBounds() {
    final next = clampSafe(_barWidth, minBarWidth, maxBarWidth);
    if (next == _barWidth) return;
    _barWidth = next;
    _clamp();
    _notify();
  }

  /// Restores saved zoom (bar width, y scale, y offset), all clamped to current bounds.
  void restoreScales({double? barWidth, double? yScale, double? yOffset}) {
    if (barWidth != null && barWidth.isFinite) {
      _barWidth = clampSafe(barWidth, minBarWidth, maxBarWidth);
    }
    if (yScale != null && yScale.isFinite) _yScale = clampSafe(yScale, minYScale, maxYScale);
    if (yOffset != null && yOffset.isFinite) _yOffset = clampSafe(yOffset, -maxYOffset, maxYOffset);
    _clamp();
    _notify();
  }

  /// User-initiated jump (keyboard Home / End, host "back to latest" button): clamps, updates the
  /// follow flag by where it lands,
  /// and resumes auto-follow if it lands on the latest bar.
  void jumpTo(double rightIndex) {
    if (_barCount == 0 || !rightIndex.isFinite) return;
    _rightIndex = rightIndex;
    _clamp();
    _pinnedToLatest = atLatest;
    _userGeneration++;
    _notify();
  }

  /// Returns to the latest bar and resumes auto-follow.
  void scrollToLatest() => jumpTo(math.max(0, _barCount - 1) + _initialBlankBars);

  /// Programmatic viewport move (replay step, animation frames); does not touch the follow flag.
  /// Use [jumpTo] for user-initiated jumps.
  void setRightIndex(double value) {
    if (!value.isFinite) return;
    _rightIndex = value;
    _clamp();
    _notify();
  }

  /// Mirrors another chart's viewport (sync), treated as a user gesture: clamps and updates the
  /// follow flag.
  void applySync({required double rightIndex, required double barWidth}) {
    _barWidth = clampSafe(barWidth, minBarWidth, maxBarWidth);
    _rightIndex = rightIndex;
    _clamp();
    _pinnedToLatest = atLatest;
    _userGeneration++;
    _notify();
  }

  // ---- Internals ----

  (double, double) _bounds() {
    if (_barCount == 0) return (0, 0);
    final upper = (_barCount - 1) + rightBlankBars;
    // Left bound: oldest bar at the left edge; when bars do not fill a screen, pin the latest bar
    // to the right
    final lower = math.min(
      (_barCount - 1).toDouble(),
      _width > 0 ? visibleBars - 1 : 0.0,
    );
    return (math.min(lower, upper), upper);
  }

  void _clamp() {
    final slots = _fixedSlots;
    if (slots != null) {
      if (_width > 0) _barWidth = _width / slots;
      _rightIndex = slots - 0.5;
      return;
    }
    final b = _bounds();
    _rightIndex = _rightIndex.clamp(b.$1, b.$2);
  }

  /// Merges multiple changes in [fn] into one notification (generation still increments per
  /// change). Otherwise sync peers would mirror the same update several times.
  void batch(void Function() fn) {
    _muted++;
    try {
      fn();
    } finally {
      _muted--;
      if (_muted == 0 && _pendingNotify) {
        _pendingNotify = false;
        notifyListeners();
      }
    }
  }

  int _muted = 0;
  bool _pendingNotify = false;

  void _notify() {
    _generation++;
    if (_muted > 0) {
      _pendingNotify = true;
      return;
    }
    notifyListeners();
  }
}
