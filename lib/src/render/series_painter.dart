import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import '../controller.dart';
import '../debug.dart';
import '../model/min_max.dart';
import 'context.dart';
import 'main_series.dart';
import 'series_paint_kit.dart';

/// Main series ([MainSeries]). Subscribes to animatedLastClose to animate the last price; animation
/// frames do not repaint indicators, and dragging the crosshair does not touch this layer.
class SeriesPainter extends CustomPainter {
  SeriesPainter(this.controller, this.config)
    : super(
        repaint: Listenable.merge([
          controller.dataRevision,
          // Range tween: data unchanged but the y mapping is sliding, so every layer must repaint
          controller.rangeRevision,
          controller.viewport,
          controller.indicators,
          config.theme,
          config.layoutRevision,
          controller.animatedLastClose,
        ]),
      );

  late final SeriesPaintKit _kit = SeriesPaintKit(controller);

  final ChartController controller;
  final ChartConfig config;

  String get debugLayerName => 'L2-series';

  @override
  void paint(Canvas canvas, Size size) {
    if (!KlinexDebug.logPaint) {
      _paintLayer(canvas, size);
      return;
    }
    final sw = Stopwatch()..start();
    _paintLayer(canvas, size);
    KlinexDebug.paint(debugLayerName, sw.elapsedMicroseconds);
  }

  @override
  bool shouldRepaint(covariant SeriesPainter oldDelegate) =>
      oldDelegate.controller != controller || oldDelegate.config != config;

  void _paintLayer(Canvas canvas, Size size) {
    final ctx = controller.resolveLayout(size, config);
    if (ctx.isEmpty) return;

    _kit.beginFrame(ctx);
    canvas.save();
    canvas.clipRect(ctx.mainPanel.rect);
    config.series.paint(canvas, ctx, _kit);
    if (config.showHighLow) _paintHighLow(canvas, ctx);
    canvas.restore();
  }

  /// Visible high and low: draws a short horizontal line from that bar's center to the value;
  /// labels in the right half point left to avoid going out of bounds.
  void _paintHighLow(Canvas canvas, RenderContext ctx) {
    final bars = ctx.bars;
    final useHL = config.series.usesHighLow;
    var hiI = -1, loI = -1;
    var hi = double.negativeInfinity, lo = double.infinity;
    final from = ctx.start < 0 ? 0 : ctx.start;
    final to = ctx.end >= bars.length ? bars.length - 1 : ctx.end;
    for (var i = from; i <= to; i++) {
      final b = bars[i];
      final h = useHL ? b.high : b.close, l = useHL ? b.low : b.close;
      if (h > hi) {
        hi = h;
        hiI = i;
      }
      if (l < lo) {
        lo = l;
        loI = i;
      }
    }
    if (hiI < 0 || loI < 0) return;
    final theme = ctx.theme;
    final main = ctx.mainPanel;
    final paint = controller.pool.stroke
      ..color = theme.highLowTextColor
      ..strokeWidth = 1;
    final style = theme.axisStyle.copyWith(color: theme.highLowTextColor);
    void mark(int index, double value) {
      final x = ctx.xOf(index);
      final y = main.yOf(value);
      final tp = controller.pool.text(config.priceFormatter(value), style);
      final toLeft = x > main.rect.center.dx;
      const arm = 10.0;
      final endX = toLeft ? x - arm : x + arm;
      canvas.drawLine(Offset(x, y), Offset(endX, y), paint);
      final tx = toLeft ? endX - tp.width - 2 : endX + 2;
      final ty = clampSafe(y - tp.height / 2, main.rect.top, main.rect.bottom - tp.height);
      tp.paint(canvas, Offset(tx, ty));
    }

    mark(hiI, hi);
    if (loI != hiI || lo != hi) mark(loI, lo);
  }
}
