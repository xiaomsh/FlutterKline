import 'dart:ui';

import 'package:flutter/foundation.dart';

import '../render/context.dart';

/// A horizontal price line that can be dragged up and down: limit orders, take profit, stop
/// loss, etc.
class DraggableLevel {
  const DraggableLevel({required this.id, required this.price});

  final String id;
  final double price;
}

/// Drags price lines to change prices. Only tracks which line is held, the dragged price, and
/// release; the host draws the line and label from [draggingId] / [previewPrice]. A press
/// within [hitSlop] of a line owns the whole gesture; yields to exclusive drawing mode.
/// Dragging out of the main panel, releasing at an unchanged price, or a system cancel
/// (incoming call, host intercept) all count as cancel and don't call [onDrop].
class LevelDragController extends ChangeNotifier {
  LevelDragController({this.onDrop, this.snap, this.passThrough, this.pick, this.hitSlop = 10});

  /// Released with a changed price: the host shows a confirmation and sends the order change.
  void Function(DraggableLevel level, double price)? onDrop;

  /// Price rounding (by the symbol's price precision); null = no rounding.
  double Function(double price)? snap;

  /// How close (px) a finger must be to a line to grab it.
  double hitSlop;

  /// Host buttons on the line (cancel-order * and the like): presses on these don't claim the
  /// gesture so the buttons stay tappable. A press on a line claims the gesture on touch-down,
  /// so without yielding, no button on the line could be tapped.
  bool Function(Offset p, RenderContext ctx)? passThrough;

  /// Host-defined drag start, asked before [passThrough] and line hits: returning a line starts
  /// dragging it. Used to pull a not-yet-existing line out of a button on a line (drag out take
  /// profit / stop loss).
  DraggableLevel? Function(Offset p, RenderContext ctx)? pick;

  List<DraggableLevel> _levels = const [];

  /// Lines currently draggable. Leave out one being submitted, so dragging it twice doesn't
  /// send two order changes.
  List<DraggableLevel> get levels => _levels;

  set levels(List<DraggableLevel> v) {
    _levels = v;
    // The dragged line is gone (cancelled, filled), so this drag is void; a line pulled out
    // of a button was never in the list.
    if (_dragging != null && !_picked && !v.any((l) => l.id == _dragging!.id)) cancel();
  }

  DraggableLevel? _dragging;
  double? _preview;
  bool _outside = false;
  bool _picked = false;

  /// Vertical offset between finger and line at press: the line follows the finger's movement
  /// rather than jumping under it (the finger may be several pixels off the line).
  double _grabOffset = 0;

  bool get isDragging => _dragging != null;

  String? get draggingId => _dragging?.id;

  /// Price at which the dragged line should be drawn now; reverts to the original price when
  /// dragged out of the main panel, meaning release will cancel.
  double? get previewPrice => _outside ? _dragging?.price : _preview;

  /// Returns the line [p] lands on; the nearest wins.
  DraggableLevel? hitTest(Offset p, RenderContext ctx) {
    if (ctx.isEmpty) return null;
    final picked = pick?.call(p, ctx);
    if (picked != null) return picked;
    if (_levels.isEmpty || (passThrough?.call(p, ctx) ?? false)) return null;
    final panel = ctx.mainPanel;
    if (p.dy < panel.rect.top - hitSlop || p.dy > panel.rect.bottom + hitSlop) return null;
    DraggableLevel? best;
    var bestDist = hitSlop;
    for (final l in _levels) {
      // Lines priced outside the scale aren't drawn and can't be hit.
      if (l.price < panel.range.min || l.price > panel.range.max) continue;
      final d = (panel.yOf(l.price) - p.dy).abs();
      if (d <= bestDist) {
        bestDist = d;
        best = l;
      }
    }
    return best;
  }

  /// Press: starts dragging if on a line and returns true.
  bool begin(Offset p, RenderContext ctx) {
    final hit = hitTest(p, ctx);
    if (hit == null) return false;
    _picked = !_levels.any((l) => l.id == hit.id);
    _dragging = hit;
    _preview = hit.price;
    _outside = false;
    _grabOffset = p.dy - ctx.mainPanel.yOf(hit.price);
    notifyListeners();
    return true;
  }

  void update(Offset p, RenderContext ctx) {
    if (_dragging == null || ctx.isEmpty) return;
    final rect = ctx.mainPanel.rect;
    _outside = p.dy < rect.top || p.dy > rect.bottom;
    if (!_outside) {
      final y = (p.dy - _grabOffset).clamp(rect.top, rect.bottom);
      final price = ctx.mainPanel.valueOf(y);
      _preview = snap?.call(price) ?? price;
    }
    notifyListeners();
  }

  /// Release: calls [onDrop] only if the price changed.
  void end() {
    final level = _dragging, price = previewPrice;
    _reset();
    if (level == null || price == null || price == level.price) return;
    onDrop?.call(level, price);
  }

  void cancel() => _reset();

  void _reset() {
    if (_dragging == null) return;
    _dragging = null;
    _preview = null;
    _outside = false;
    _picked = false;
    notifyListeners();
  }
}
