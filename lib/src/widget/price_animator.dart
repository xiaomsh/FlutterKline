import 'package:flutter/widgets.dart';

import '../controller.dart';

/// Last-price animation: on a tick, the last bar's close and the last-price line slide to the new
/// value over about 200ms. Display only; written to animatedLastClose.
class PriceAnimator {
  PriceAnimator(TickerProvider vsync, this.controller, {required this.enabled}) {
    _anim = AnimationController(vsync: vsync, duration: const Duration(milliseconds: 200))
      ..addListener(_onTick);
  }

  ChartController controller;

  /// A function, so the widget's current toggle is read when data changes.
  final bool Function() enabled;

  late final AnimationController _anim;
  double _from = double.nan;
  double _to = double.nan;
  double _seenClose = double.nan;
  int _seenEpoch = -1;

  /// Controller replaced or just attached: start tracking from the current data, no animation.
  void attach(ChartController c) {
    controller = c;
    _seenClose = c.bars.isEmpty ? double.nan : c.bars.last.close;
    _seenEpoch = c.dataEpoch;
  }

  /// Attached to dataRevision.
  void onData() {
    final bars = controller.bars;
    if (!enabled()) {
      // Remember the latest close even when off, or re-enabling would slide from a stale price
      _seenEpoch = controller.dataEpoch;
      _seenClose = bars.isEmpty ? double.nan : bars.last.close;
      if (controller.animatedLastClose.value != null) {
        _anim.stop();
        controller.animatedLastClose.value = null;
      }
      return;
    }
    // New data set: snap to the new value, no interpolation across series
    if (controller.dataEpoch != _seenEpoch) {
      _seenEpoch = controller.dataEpoch;
      _seenClose = bars.isEmpty ? double.nan : bars.last.close;
      _anim.stop();
      controller.animatedLastClose.value = null;
      return;
    }
    if (bars.isEmpty) {
      _seenClose = double.nan;
      controller.animatedLastClose.value = null;
      return;
    }
    final c = bars.last.close;
    if (_seenClose.isNaN || c == _seenClose) {
      _seenClose = c;
      return;
    }
    // Slide from the current displayed value (possibly mid-animation) to the new close
    _from = controller.animatedLastClose.value ?? _seenClose;
    _to = c;
    _seenClose = c;
    _anim
      ..stop()
      ..value = 0
      ..forward();
  }

  void stop() => _anim.stop();

  void dispose() => _anim.dispose();

  void _onTick() {
    if (controller.isDisposed) {
      _anim.stop();
      return;
    }
    if (_from.isNaN) return;
    if (_anim.isCompleted) {
      controller.animatedLastClose.value = null;
      return;
    }
    final t = Curves.easeOut.transform(_anim.value);
    controller.animatedLastClose.value = _from + (_to - _from) * t;
  }
}
