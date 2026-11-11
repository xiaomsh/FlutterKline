import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:klinex/klinex.dart';

import 'live_style.dart';

/// "Back to latest" button at the bottom right: fades in when the chart scrolls away from the
/// latest bar, and eases back to the initial position on tap.
/// Returns a [Positioned], so put it in a [Stack] above KChart
class BackToLatestButton extends StatefulWidget {
  final ChartController controller;

  /// Right price axis width, same as KChart.yAxisWidth; the button sits to its left.
  final double axisWidth;

  /// Bottom time axis height, same as KChart.timeAxisHeight.
  final double timeAxisHeight;

  /// Initial right blank ratio, same as KChart.initialRightBlankRatio; decides where the latest
  /// bar stops after sliding back.
  final double initialRightBlankRatio;

  /// Follows the current theme when omitted.
  final Color? background;
  final Color? foreground;
  final Color? border;

  const BackToLatestButton({
    super.key,
    required this.controller,
    this.axisWidth = 56,
    this.timeAxisHeight = 22,
    this.initialRightBlankRatio = 0.1,
    this.background,
    this.foreground,
    this.border,
  });

  @override
  State<BackToLatestButton> createState() => _BackToLatestButtonState();
}

class _BackToLatestButtonState extends State<BackToLatestButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  double _from = 0, _to = 0;

  /// Only the "should show" bool goes to the UI: the viewport changes every frame,
  /// but the button's pixels only change when it reaches or leaves the latest bar
  final ValueNotifier<bool> _visible = ValueNotifier(false);

  ChartViewport get _vp => widget.controller.viewport;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..addListener(_tick);
    _vp.addListener(_syncVisible);
    _syncVisible();
  }

  void _syncVisible() {
    final show = _vp.barCount > 0 && !_vp.atLatest;
    if (show != _visible.value) _visible.value = show;
  }

  @override
  void didUpdateWidget(BackToLatestButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A new controller moves the listener to the new viewport, or the button keeps watching the
    // old chart
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.viewport.removeListener(_syncVisible);
      _anim.stop(); // The running slide belongs to the old viewport; don't drive the new one
      _vp.addListener(_syncVisible);
      _syncVisible();
    }
  }

  @override
  void dispose() {
    _vp.removeListener(_syncVisible);
    _visible.dispose();
    _anim.dispose();
    super.dispose();
  }

  /// Fractional right-edge index on first landing: latest bar + initial blank (converted by the
  /// current width / bar width).
  double _initialRightIndex() {
    final blankBars = _vp.width > 0 && _vp.barWidth > 0
        ? _vp.width * widget.initialRightBlankRatio / _vp.barWidth
        : 2.0;
    // At least half a bar like viewport.rightBlankBars, or a zero blank cuts the latest bar in half
    return math.max(0, _vp.barCount - 1) + math.max(0.5, blankBars);
  }

  void _tick() {
    final t = Curves.easeOutCubic.transform(_anim.value);
    // Land with jumpTo: returning to latest must restore auto-follow, which setRightIndex leaves
    // untouched
    if (_anim.value >= 1) {
      _vp.jumpTo(_to);
    } else {
      _vp.setRightIndex(_from + (_to - _from) * t);
    }
  }

  void _slideBack() {
    _anim.stop();
    // An in-place jumpTo counts as a user action: it stops any fling, which would otherwise fight
    // the slide animation for the viewport
    _vp.jumpTo(_vp.rightIndex);
    _from = _vp.rightIndex;
    _to = _initialRightIndex();
    if ((_to - _from).abs() < 0.01) {
      _vp.jumpTo(_to);
      return;
    }
    _anim.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final background = widget.background ?? LiveStyle.bgPrimary;
    final foreground = widget.foreground ?? LiveStyle.textPrimary;
    final border = widget.border ?? LiveStyle.divider;
    return Positioned(
      right: widget.axisWidth + 8,
      bottom: widget.timeAxisHeight + 10,
      child: RepaintBoundary(
        child: ValueListenableBuilder<bool>(
          valueListenable: _visible,
          // The round button is passed as child: built once and not rebuilt on visibility changes;
          // only the outer AnimatedOpacity / IgnorePointer flip.
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _slideBack,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: background,
                shape: BoxShape.circle,
                border: Border.all(color: border),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x22000000),
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: Icon(Icons.chevron_right, size: 22, color: foreground),
            ),
          ),
          builder: (context, show, child) => AnimatedOpacity(
            opacity: show ? 1 : 0,
            duration: const Duration(milliseconds: 150),
            child: IgnorePointer(ignoring: !show, child: child),
          ),
        ),
      ),
    );
  }
}
