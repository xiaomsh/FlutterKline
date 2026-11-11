import 'dart:math' as math;

import 'package:flutter/animation.dart' show Curves;
import 'package:flutter/scheduler.dart';

import '../model/min_max.dart';

/// Range tween state for one panel
class _PanelAnim {
  MinMax? shown;
  MinMax? from, to;
  double t = 1;
  bool active = false;

  MinMax snapTo(MinMax target) {
    shown = target;
    to = target;
    active = false;
    return target;
  }
}

/// Tween for value-range changes (250ms, display only). One each for the main chart and every
/// sub-chart: when panning, new extremes enter the window,
/// so the range target jumps within a frame; without tweening the whole screen of lines bounces
class RangeAnimator {
  RangeAnimator(this.onFrame);

  /// The tween advanced a frame: the range is sliding but data hasn't changed
  final void Function() onFrame;

  bool disposed = false;

  /// Increments each advanced frame; the layout cache uses it to know when to recompute
  int generation = 0;

  static const Duration _duration = Duration(milliseconds: 250);

  /// Boundary between small drift and large jumps (relative to the current span). Pulls against
  /// [_followMaxT];
  /// run the four scenarios in range_animation_test before changing it
  static const double _followThreshold = 0.60;

  /// Max fraction of the gap covered per frame during small drift; no cap means no damping, and a
  /// new extreme entering the window jumps within one frame
  static const double _followMaxT = 0.08;

  final Map<String, _PanelAnim> _anims = {};
  bool _scheduled = false;
  Duration? _lastTs;

  bool get isActive {
    for (final a in _anims.values) {
      if (a.active) return true;
    }
    return false;
  }

  /// Drops unclaimed state when panels go away, so it doesn't grow unbounded as indicators are
  /// added and removed
  void prune(List<String> panelIds) {
    if (_anims.length <= panelIds.length) return;
    _anims.removeWhere((id, _) => !panelIds.contains(id));
  }

  /// [target] is this frame's range target; returns intermediate values while tweening. Jumps
  /// straight to the target when [enabled] is false, [eligible] is false
  /// (y zoom, layout, theme, size or symbol changed and must follow immediately), or it doesn't
  /// overlap the currently displayed range
  MinMax smooth(
    String panelId,
    MinMax target, {
    required bool enabled,
    required bool eligible,
    required bool logSpace,
  }) {
    final a = _anims.putIfAbsent(panelId, _PanelAnim.new);
    if (!enabled || target.isEmpty) return a.snapTo(target);
    final shown = a.shown;
    if (!eligible ||
        shown == null ||
        shown.isEmpty ||
        target.min > shown.max ||
        target.max < shown.min) {
      return a.snapTo(target);
    }
    if (a.to == null || !_sameRange(a.to!, target)) {
      // Small drift (extremes swapping in and out bar by bar while panning) continues the previous
      // segment; resetting progress would pin the displayed value in place;
      // large jumps (volume spikes in/out, extreme zoom-out) start a new segment, holding the old
      // range for the first frame and tweening from there
      final span = shown.span.abs();
      final delta = math.max((target.min - shown.min).abs(), (target.max - shown.max).abs());
      final jump = span <= 0 || delta > span * _followThreshold;
      a
        ..from = shown
        ..to = target
        ..active = true;
      _scheduleTick();
      if (jump) {
        a.t = 0;
        return shown;
      }
      a.t = math.min(a.t, _followMaxT);
    }
    if (!a.active) {
      a.shown = target;
      return target;
    }
    final e = Curves.easeOut.transform(a.t);
    final f = a.from!;
    MinMax mid;
    if (logSpace && f.min > 0 && target.min > 0) {
      final lmin = math.log(f.min) + (math.log(target.min) - math.log(f.min)) * e;
      final lmax = math.log(f.max) + (math.log(target.max) - math.log(f.max)) * e;
      mid = MinMax(math.exp(lmin), math.exp(lmax));
    } else {
      mid = MinMax(f.min + (target.min - f.min) * e, f.max + (target.max - f.max) * e);
    }
    a.shown = mid;
    return mid;
  }

  void _scheduleTick() {
    if (_scheduled) return;
    _scheduled = true;
    final scheduler = SchedulerBinding.instance;
    scheduler.scheduleFrameCallback((ts) {
      _scheduled = false;
      if (disposed) return;
      final last = _lastTs;
      _lastTs = ts;
      final dtMs = last == null ? 16.0 : (ts - last).inMicroseconds / 1000.0;
      final step = dtMs / _duration.inMilliseconds;
      var running = false;
      for (final a in _anims.values) {
        if (!a.active) continue;
        a.t = (a.t + step).clamp(0.0, 1.0);
        if (a.t >= 1.0) {
          a.active = false;
        } else {
          running = true;
        }
      }
      generation++;
      onFrame();
      if (running) {
        _scheduleTick();
      } else {
        _lastTs = null;
      }
    });
    scheduler.scheduleFrame();
  }

  static bool _sameRange(MinMax a, MinMax b) {
    final eps = math.max(1e-12, (a.span.abs() + b.span.abs()) * 1e-9);
    return (a.min - b.min).abs() <= eps && (a.max - b.max).abs() <= eps;
  }
}
