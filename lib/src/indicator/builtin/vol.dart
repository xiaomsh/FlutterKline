import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import '../../model/bar.dart';
import '../../model/min_max.dart';
import '../../panel/panel.dart';
import '../../render/context.dart';
import '../indicator.dart';

/// Volume bars drawn on the shared 'vol' sub-panel, colored by up/down. Volumes are copied into the
/// store, so range() does not read bars.
class Vol extends Indicator {
  Vol();

  @override
  String get id => 'vol';

  @override
  PanelRef get target => const PanelRef.named('vol');

  @override
  void computeAll(List<Bar> bars, IndicatorStore store) {
    final s = store.series('vol');
    for (var i = 0; i < bars.length; i++) {
      s[i] = bars[i].vol;
    }
  }

  @override
  void computeLast(List<Bar> bars, int index, IndicatorStore store) {
    store.series('vol')[index] = bars[index].vol;
  }

  @override
  void paint(Canvas canvas, RenderContext ctx, IndicatorStore store) {
    final vols = store.series('vol');
    final bars = ctx.bars;
    final up = ctx.pool.stroke..color = ctx.theme.up;
    ctx.vbars(canvas, vols, 0, up, (i, v) => bars[i].isUp);
    final down = ctx.pool.stroke..color = ctx.theme.down;
    ctx.vbars(canvas, vols, 0, down, (i, v) => !bars[i].isUp);
  }

  @override
  MinMax range(IndicatorStore store, int start, int end) {
    final mm = store.rangeOf('vol', start, end);
    return mm.isEmpty ? MinMax.empty : MinMax(0, mm.max);
  }

  @override
  void legendInto(
    List<LegendItem> out,
    RenderContext ctx,
    IndicatorStore store,
    int index,
  ) {
    final v = store.value('vol', index);
    if (v.isNaN) return;
    out.add(('VOL:${ctx.formatValue(ctx.panel, v)}', ctx.theme.axisText));
  }
}

/// Translucent volume bars at the bottom of the main panel, with their own hidden scale; range() is
/// empty, so volume never stretches the price scale.
class VolOverlay extends Indicator {
  VolOverlay({this.heightFraction = 0.2, this.opacity = 0.35});

  /// Fraction of the main panel height taken by the tallest visible bar.
  final double heightFraction;

  final double opacity;

  @override
  String get id => 'vol-overlay';

  @override
  PanelRef get target => PanelRef.main;

  /// Volume bar height + buffer: price autoscale stays out of the volume area (TV scaleMargins
  /// recipe).
  @override
  double get mainBottomReserveFraction => heightFraction + 0.04;

  @override
  void computeAll(List<Bar> bars, IndicatorStore store) {
    final s = store.series('vol');
    for (var i = 0; i < bars.length; i++) {
      s[i] = bars[i].vol;
    }
  }

  @override
  void computeLast(List<Bar> bars, int index, IndicatorStore store) {
    store.series('vol')[index] = bars[index].vol;
  }

  @override
  void paint(Canvas canvas, RenderContext ctx, IndicatorStore store) {
    final vols = store.series('vol');
    final n = vols.length;
    // Block cache speeds up the maxVol query: O(visible/64+128) instead of O(visible)
    final mm = store.rangeOf('vol', ctx.start, math.min(ctx.end, n - 1));
    final maxV = mm.isEmpty ? 0.0 : mm.max;
    if (maxV <= 0) return;

    final rect = ctx.mainPanel.rect;
    final baseY = rect.bottom;
    final scale = rect.height * heightFraction / maxV;
    // Decimate: one bar per bucket, taking the max volume in the bucket
    final g = ctx.drawGroup;
    final last = math.min(ctx.end, n - 1);
    final b00 = (ctx.start ~/ g) * g;
    void group(Color color, bool Function(int) include) {
      double maxOf(int i0, int i1) {
        var best = double.nan;
        for (var i = i0; i <= i1; i++) {
          final v = vols[i];
          if (v.isNaN || !include(i)) continue;
          if (best.isNaN || v > best) best = v;
        }
        return best;
      }

      // Single-pass write (buffer sized by the bucket count upper bound, take the prefix after):
      // previously it counted once and filled once, calling the include closure twice
      final buckets = (last - b00) ~/ g + 1;
      if (buckets <= 0) return;
      final pts = ctx.pool.floats(buckets * 4);
      var j = 0;
      for (var b0 = b00; b0 <= last; b0 += g) {
        final i0 = math.max(b0, ctx.start), i1 = math.min(b0 + g - 1, last);
        final v = maxOf(i0, i1);
        if (v.isNaN) continue;
        final x = ctx.xOf((i0 + i1) / 2);
        pts[j++] = x;
        pts[j++] = baseY;
        pts[j++] = x;
        pts[j++] = baseY - clampSafe(v * scale, 1.0, rect.height);
      }
      if (j == 0) return;
      final paint = ctx.pool.stroke
        ..color = color.withValues(alpha: opacity)
        ..strokeWidth = ctx.barStrokeWidth();
      canvas.drawRawPoints(
        PointMode.lines,
        j == pts.length ? pts : Float32List.sublistView(pts, 0, j),
        paint,
      );
    }

    final bars = ctx.bars;
    group(ctx.theme.up, (i) => bars[i].isUp);
    group(ctx.theme.down, (i) => !bars[i].isUp);
  }

  @override
  MinMax range(IndicatorStore store, int start, int end) => MinMax.empty;

  @override
  void legendInto(
    List<LegendItem> out,
    RenderContext ctx,
    IndicatorStore store,
    int index,
  ) {
    final v = store.value('vol', index);
    if (v.isNaN) return;
    // Sub-panel values use compact format, not price format
    out.add(('VOL:${ctx.config.volumeFormatter(v)}', ctx.theme.axisText));
  }
}

/// Volume moving average, drawn on the shared 'vol' sub-panel.
class MaVol extends LineIndicator {
  final List<int> periods;
  final List<Color>? colors;
  final double lineWidth;

  MaVol({this.periods = const [5, 10], this.colors, this.lineWidth = 1}) {
    checkPositivePeriods(periods, 'periods');
  }

  @override
  String get id => 'mavol(${periods.join(',')})';

  @override
  PanelRef get target => const PanelRef.named('vol');

  @override
  int get warmupBars => periods.fold(0, (a, b) => a > b ? a : b) + 1;

  /// Windowed: values depend only on the last period bars and are exactly independent of older
  /// ones.
  @override
  int? get prependSettleBars => warmupBars;

  @override
  late final List<String> seriesKeys = [for (final p in periods) 'mavol$p'];

  @override
  late final List<String> seriesLabels = [for (final p in periods) 'MA$p'];

  @override
  List<Color>? get seriesColors => colors;

  @override
  double get seriesLineWidth => lineWidth;

  static double _sma(List<Bar> bars, int i, int p) {
    // Partial window: before a full period, use the available min(p, i+1) bars, emitting from bar
    // 0.
    final count = math.min(p, i + 1);
    var sum = 0.0;
    for (var k = i - count + 1; k <= i; k++) {
      sum += bars[k].vol;
    }
    return sum / count;
  }

  @override
  void computeAt(List<Bar> bars, int i, IndicatorStore store) {
    for (final p in periods) {
      store.series('mavol$p')[i] = _sma(bars, i, p);
    }
  }
}
