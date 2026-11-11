import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../debug.dart';
import '../model/min_max.dart';
import '../render/paint_pool.dart';
import 'depth_chart.dart';

class DepthPainter extends CustomPainter {
  final DepthChart widget;
  final PreparedDepthData prepared;
  final ValueNotifier<Offset?> touch;
  final PaintPool _pool;

  DepthPainter(this.widget, this.prepared, this.touch, this._pool) : super(repaint: touch);

  @override
  void paint(Canvas canvas, Size size) {
    if (!KlinexDebug.logPaint) return _paint(canvas, size);
    final sw = Stopwatch()..start();
    _paint(canvas, size);
    KlinexDebug.paint('depth', sw.elapsedMicroseconds);
  }

  void _paint(Canvas canvas, Size size) {
    final theme = widget.theme;
    canvas.drawRect(Offset.zero & size, _pool.fill..color = theme.background);
    final style = theme.axisStyle;
    // Axis height uses the measured line height: hard-coded 18 cut off label bottoms at larger font
    // sizes (iOS h6=11).
    final axisH = _pool.text('0', style).height + 5;
    // When even the axis area does not fit, plot height goes negative and the whole mapping breaks.
    if (size.height <= axisH) return;
    if (!prepared.isDrawable) return;

    final plot = Rect.fromLTWH(0, 0, size.width, size.height - axisH);
    double xOf(double p) =>
        plot.left + (p - prepared.pMin) / (prepared.pMax - prepared.pMin) * plot.width;
    double yOf(double cum) => plot.bottom - cum / prepared.maxCum * plot.height * 0.92;

    _side(canvas, plot, prepared.bids, prepared.bidCum, xOf, yOf, theme.up);
    _side(canvas, plot, prepared.asks, prepared.askCum, xOf, yOf, theme.down);

    // Price strings can be long (up to 18 decimals), so the 4 evenly spaced labels may overlap;
    // skip any that overlap the previous one, better to draw one fewer than a smudge.
    var drawnRight = double.negativeInfinity;
    for (var i = 0; i <= 3; i++) {
      final p = prepared.pMin + (prepared.pMax - prepared.pMin) * i / 3;
      final tp = _pool.text(widget.priceFormatter(p), style);
      final x = clampSafe(xOf(p) - tp.width / 2, 0, size.width - tp.width);
      if (x < drawnRight) continue;
      tp.paint(canvas, Offset(x, plot.bottom + 2));
      drawnRight = x + tp.width + 4;
    }

    _paintTouch(
      canvas,
      plot,
      prepared.bids,
      prepared.bidCum,
      prepared.asks,
      prepared.askCum,
      xOf,
      yOf,
    );
  }

  void _side(
    Canvas canvas,
    Rect plot,
    List<DepthLevel> levels,
    List<double> cum,
    double Function(double) xOf,
    double Function(double) yOf,
    Color color,
  ) {
    if (levels.isEmpty) return;
    // Steps: cumulative volume is constant until the next price level; slopes would suggest orders
    // between levels
    final path = Path()..moveTo(xOf(levels.first.price), plot.bottom);
    final line = Path()..moveTo(xOf(levels.first.price), yOf(cum.first));
    path.lineTo(xOf(levels.first.price), yOf(cum.first));
    for (var i = 1; i < levels.length; i++) {
      final x = xOf(levels[i].price);
      final y0 = yOf(cum[i - 1]), y = yOf(cum[i]);
      path
        ..lineTo(x, y0)
        ..lineTo(x, y);
      line
        ..lineTo(x, y0)
        ..lineTo(x, y);
    }
    path.lineTo(xOf(levels.last.price), plot.bottom);
    path.close();
    canvas.drawPath(path, _pool.fill..color = color.withValues(alpha: 0.15));
    canvas.drawPath(
      line,
      _pool.stroke
        ..color = color
        ..strokeWidth = 1.5,
    );
  }

  void _paintTouch(
    Canvas canvas,
    Rect plot,
    List<DepthLevel> bids,
    List<double> bidCum,
    List<DepthLevel> asks,
    List<double> askCum,
    double Function(double) xOf,
    double Function(double) yOf,
  ) {
    final t = touch.value;
    if (t == null) return;
    // On whichever side the finger is, find the nearest level by x on that side
    DepthLevel? best;
    double? bestCum;
    var bestDx = double.infinity;
    void scan(List<DepthLevel> levels, List<double> cum) {
      for (var i = 0; i < levels.length; i++) {
        final dx = (xOf(levels[i].price) - t.dx).abs();
        if (dx < bestDx) {
          bestDx = dx;
          best = levels[i];
          bestCum = cum[i];
        }
      }
    }

    scan(bids, bidCum);
    scan(asks, askCum);
    final sel = best;
    if (sel == null) return;

    final theme = widget.theme;
    final x = xOf(sel.price), y = yOf(bestCum!);
    final line = _pool.stroke
      ..color = theme.crosshair
      ..strokeWidth = 0.8;
    final dash = theme.crosshairDash;
    final dashLen = dash != null && dash.isNotEmpty ? dash[0] : 0.0;
    if (dashLen > 0) {
      _pool.drawDashedVLine(
        canvas,
        x,
        plot.top,
        plot.bottom,
        line,
        dash: dashLen,
        gap: dash!.length > 1 ? dash[1] : dashLen,
      );
    } else {
      canvas.drawLine(Offset(x, plot.top), Offset(x, plot.bottom), line);
    }
    canvas.drawCircle(Offset(x, y), 3.5, _pool.fill..color = theme.crosshair);
    final style = TextStyle(
      color: theme.crosshairLabelText,
      fontSize: theme.axisTextSize,
    );
    final label = '${widget.priceFormatter(sel.price)} / ${widget.amountFormatter(bestCum!)}';
    // The label is centered on the selected price, so at the leftmost/rightmost level it would
    // spill outside the widget; clamp the anchor into view by half the label width (same handling
    // as the main crosshair time label).
    const labelHPad = 4.0;
    final halfW = _pool.text(label, style).width / 2 + labelHPad;
    _pool.drawBoxedLabel(
      canvas,
      label,
      style,
      Offset(clampSafe(x, halfW, plot.width - halfW), plot.top + 4),
      theme.crosshairLabelBg,
      centerX: true,
    );
  }

  @override
  bool shouldRepaint(covariant DepthPainter oldDelegate) =>
      oldDelegate.prepared != prepared ||
      oldDelegate.widget.theme != widget.theme ||
      oldDelegate.widget.priceFormatter != widget.priceFormatter ||
      oldDelegate.widget.amountFormatter != widget.amountFormatter;
}

class PreparedDepthData {
  const PreparedDepthData({
    required this.bids,
    required this.asks,
    required this.bidCum,
    required this.askCum,
    required this.maxCum,
    required this.pMin,
    required this.pMax,
    required this.isDrawable,
  });

  final List<DepthLevel> bids;
  final List<DepthLevel> asks;
  final List<double> bidCum;
  final List<double> askCum;
  final double maxCum;
  final double pMin;
  final double pMax;
  final bool isDrawable;

  static bool _validLevel(DepthLevel l) =>
      l.price.isFinite && l.price > 0 && l.amount.isFinite && l.amount >= 0;

  static List<double> _cumulate(List<DepthLevel> levels) {
    var sum = 0.0;
    return [for (final l in levels) sum += l.amount];
  }

  factory PreparedDepthData.fromWidget(DepthChart widget) {
    final bids = widget.bids.where(_validLevel).toList()
      ..sort((a, b) => b.price.compareTo(a.price));
    final asks = widget.asks.where(_validLevel).toList()
      ..sort((a, b) => a.price.compareTo(b.price));
    if (bids.isEmpty && asks.isEmpty) {
      return const PreparedDepthData(
        bids: [],
        asks: [],
        bidCum: [],
        askCum: [],
        maxCum: 0,
        pMin: 0,
        pMax: 0,
        isDrawable: false,
      );
    }

    final bidCum = _cumulate(bids);
    final askCum = _cumulate(asks);
    final maxCum = math
        .max(
          bidCum.isEmpty ? 0 : bidCum.last,
          askCum.isEmpty ? 0 : askCum.last,
        )
        .toDouble();
    final pMin = bids.isEmpty ? asks.first.price : bids.last.price;
    final pMax = asks.isEmpty ? bids.first.price : asks.last.price;
    return PreparedDepthData(
      bids: bids,
      asks: asks,
      bidCum: bidCum,
      askCum: askCum,
      maxCum: maxCum,
      pMin: pMin,
      pMax: pMax,
      isDrawable: maxCum > 0 && pMax > pMin,
    );
  }
}
