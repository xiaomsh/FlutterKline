import 'dart:async';

import 'package:flutter/material.dart';
import 'package:klinex/klinex.dart';

import '../l10n/l10n.dart';
import 'axis_price_tag_layout.dart';

/// Best bid / best ask; a null side is not drawn.
typedef BookPrice = ({double? bid, double? ask});

/// Y-axis tag column: last price, countdown, book bid/ask, and the reference price while
/// browsing history. Each tag sits at its price's y; when crowded, tags sort by printed price
/// high to low, with ties ordered ask -> last -> bid.
/// Colors come from the chart theme ([RenderContext.theme]); shared by samples and the live page.
class AxisPriceTags extends StatefulWidget {
  const AxisPriceTags({
    super.key,
    required this.ctx,
    this.showPrice = true,
    this.showCountdown = true,
    this.periodMs,
    this.calendarMonths,
    this.book,
    this.askLabel,
    this.bidLabel,
    this.now,
  });

  /// Coordinate mapping of the current frame (passed by KChart.overlayBuilder).
  final RenderContext ctx;

  final bool showPrice;
  final bool showCountdown;

  /// Period in ms; null uses the average data period (same as PriceLineOverlay).
  final int? periodMs;

  /// Calendar-month periods such as monthly: months per bar (opening at the UTC month start).
  /// When set, close time is computed by calendar instead of [periodMs].
  final int? calendarMonths;

  /// Best bid / best ask; null draws no book tags.
  final BookPrice? book;
  final String? askLabel;
  final String? bidLabel;

  /// "Now" for the countdown (ms, same timeline as bar time). Defaults to system time;
  /// offline demo data isn't current, so pass a simulated clock.
  final int Function()? now;

  @override
  State<AxisPriceTags> createState() => _AxisPriceTagsState();
}

/// Vertical order for equal prices: ask on top, last in the middle, bid at the bottom.
enum _Kind { ask, latest, bid }

class _AxisPriceTagsState extends State<AxisPriceTags> {
  Timer? _timer;

  static const _rowH = 15.0; // Price / countdown row height.
  static const _bookH = 16.0; // Bid/ask tag height.
  static const _fs = 10.0;

  /// Width of the bid / ask side label left of the book tags.
  static const _sideW = 18.0;

  /// Schedules the next whole-second tick from the remaining ms. Timer.periodic(1s) is out of
  /// phase with the remainder, so a number may hold two seconds or get skipped. No remainder
  /// (countdown hidden) schedules nothing; the rebuild on a new bar schedules again.
  void _armTimer(int? remainMs) {
    _timer?.cancel();
    if (remainMs == null) {
      _timer = null;
      return;
    }
    final delay = remainMs % 1000 + 1;
    _timer = Timer(Duration(milliseconds: delay < 16 ? 16 : delay), () {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctx = widget.ctx;
    // Check bars too: ctx.isEmpty doesn't guarantee non-empty bars, and with no data
    // clamp(0, -1) below throws and bars[lastIndex] is out of range.
    if (ctx.isEmpty || ctx.bars.isEmpty) return const SizedBox.shrink();
    final theme = ctx.theme;
    final bars = ctx.bars;
    final lastIndex = bars.length - 1;
    // Same reference bar as PriceLineOverlay: the bar at the right edge (follows into history).
    final refIndex = ctx.rightIndex.round().clamp(0, lastIndex);
    final ref = bars[refIndex];
    final isLatest = refIndex == lastIndex;
    final panel = ctx.mainPanel;
    final formatPrice = ctx.config.priceFormatter;

    // Axis strip geometry: with an inner axis, a strip of the same width at the plot's right edge
    // (width follows config, the same yAxisWidth the library uses for gestures/labels).
    final axisLeft = ctx.axisOutside ? ctx.yAxisRect.left : ctx.size.width - ctx.config.yAxisWidth;
    final axisW = ctx.axisOutside ? ctx.yAxisRect.width : ctx.config.yAxisWidth;

    final latestBar = bars[lastIndex];
    final latestClose =
        (isLatest ? ctx.controller.animatedLastClose.value : null) ?? latestBar.close;
    final remainMs = widget.showCountdown
        ? _remainMs(latestBar.time, _periodOf(latestBar.time))
        : null;
    _armTimer(remainMs);
    final countdown = remainMs == null ? null : _format(remainMs);
    final showLatest = widget.showPrice || countdown != null;
    final latestH = (widget.showPrice ? _rowH : 0.0) + (countdown != null ? _rowH : 0.0) + 6.0;

    final tags = <PriceTagLayout>[];
    void add(double price, double height, _Kind kind, Widget Function(double top) builder) =>
        tags.add(
          PriceTagLayout(
            preferredCenter: panel.yOf(price),
            height: height,
            price: displayPrice(price, formatPrice),
            tieBreak: kind.index,
            builder: builder,
          ),
        );

    if (showLatest) {
      add(
        latestClose,
        latestH,
        _Kind.latest,
        (top) => Positioned(
          left: axisLeft,
          width: axisW,
          top: top,
          height: latestH,
          child: Container(
            decoration: BoxDecoration(
              color: theme.background,
              border: Border.all(color: theme.tooltipBorder),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.showPrice)
                  Text(
                    formatPrice(latestClose),
                    maxLines: 1,
                    softWrap: false,
                    style: TextStyle(
                      fontSize: _fs,
                      color: theme.tooltipText,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                if (countdown != null)
                  Text(
                    countdown,
                    maxLines: 1,
                    softWrap: false,
                    style: TextStyle(fontSize: _fs, color: theme.axisText),
                  ),
              ],
            ),
          ),
        ),
      );
    }
    if (!isLatest) {
      final color = ref.isUp ? theme.up : theme.down;
      add(
        ref.close,
        _rowH + 6,
        _Kind.latest,
        (top) => Positioned(
          left: axisLeft,
          width: axisW,
          top: top,
          height: _rowH + 6,
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: theme.background,
              border: Border.all(color: color),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
              formatPrice(ref.close),
              maxLines: 1,
              softWrap: false,
              style: TextStyle(fontSize: _fs, color: color, fontWeight: FontWeight.w500),
            ),
          ),
        ),
      );
    }
    final ask = widget.book?.ask, bid = widget.book?.bid;
    Widget bookTag(double top, double price, String label, Color color) => Positioned(
      left: axisLeft - _sideW,
      width: axisW + _sideW,
      top: top,
      height: _bookH,
      child: Row(
        children: [
          SizedBox(
            width: _sideW,
            child: Text(
              label,
              maxLines: 1,
              softWrap: false,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: _fs, color: color, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
              child: Text(
                formatPrice(price),
                maxLines: 1,
                softWrap: false,
                style: const TextStyle(fontSize: _fs, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
    final askLabel = widget.askLabel ?? S.current.axisTagAsk;
    final bidLabel = widget.bidLabel ?? S.current.axisTagBid;
    if (ask != null) {
      add(ask, _bookH, _Kind.ask, (top) => bookTag(top, ask, askLabel, theme.down));
    }
    if (bid != null) {
      add(bid, _bookH, _Kind.bid, (top) => bookTag(top, bid, bidLabel, theme.up));
    }

    if (tags.isEmpty) return const SizedBox.shrink();

    tags.sort(byDisplayedPriceDesc);
    final tops = stackNonOverlapping(
      items: [for (final t in tags) (center: t.preferredCenter, height: t.height)],
      top: panel.rect.top,
      bottom: panel.rect.bottom,
    );
    return IgnorePointer(
      child: Stack(
        clipBehavior: Clip.none,
        children: [for (var i = 0; i < tags.length; i++) tags[i].builder(tops[i])],
      ),
    );
  }

  /// Hidden once due (like TradingView): the new bar only arrives with the period's first trade,
  /// and showing 00:00 or restarting from 59 in that gap wouldn't match the bar on the chart.
  int _periodOf(int startMs) {
    final months = widget.calendarMonths;
    if (months == null) return widget.periodMs ?? widget.ctx.avgPeriodMs.round();
    final d = DateTime.fromMillisecondsSinceEpoch(startMs, isUtc: true);
    return DateTime.utc(d.year, d.month + months).millisecondsSinceEpoch - startMs;
  }

  int? _remainMs(int startMs, int periodMs) {
    if (periodMs <= 0) return null;
    final now = widget.now?.call() ?? DateTime.now().millisecondsSinceEpoch;
    final remain = startMs + periodMs - now;
    if (remain > periodMs) return periodMs;
    return remain > 0 ? remain : null;
  }

  static String _format(int ms) {
    final s = (ms + 999) ~/ 1000; // Round up: under 1s left shows 00:01, hidden when due.
    String p2(int n) => n.toString().padLeft(2, '0');
    if (s >= 3600) return '${s ~/ 3600}:${p2(s % 3600 ~/ 60)}:${p2(s % 60)}';
    return '${p2(s ~/ 60)}:${p2(s % 60)}';
  }
}
