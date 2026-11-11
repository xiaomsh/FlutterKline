import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';

import '../controller.dart';
import '../model/bar.dart';
import '../model/time_map.dart';
import '../theme/theme.dart';
import 'chart_config.dart';
import 'paint_pool.dart';
import 'panel_layout.dart';

export 'chart_config.dart';
export 'panel_layout.dart';

/// Layout and coordinate snapshot for one frame, passed to every painter, indicator and overlay
/// plugin; built and cached by the controller
class RenderContext {
  final ChartController controller;
  final KLineTheme theme;
  final ChartConfig config;
  final Size size;

  /// Plot area of all panels, excluding the time axis and outside y axes; every right edge is its
  /// right
  final Rect chartRect;
  final Rect timeAxisRect;

  /// Strip of the right outside y axis; width 0 when absent
  final Rect yAxisRect;

  /// Strip of the left y axis ([YAxisPosition.left] / [YAxisPosition.both]); width 0 when absent
  final Rect leftAxisRect;
  final List<PanelLayout> panels;

  /// Visible bar indices (inclusive); empty when end < start
  final int start, end;

  // Viewport snapshot; mapping is constant within a frame
  final double barWidth;
  final double rightIndex;

  RenderContext({
    required this.controller,
    required this.theme,
    required this.config,
    required this.size,
    required this.chartRect,
    required this.timeAxisRect,
    required this.yAxisRect,
    this.leftAxisRect = Rect.zero,
    required this.panels,
    required this.start,
    required this.end,
    required this.barWidth,
    required this.rightIndex,
  });

  bool get isEmpty => end < start || panels.isEmpty;

  /// Has an outside tick strip on the right
  bool get axisOutside => yAxisRect.width > 0;

  /// Has a tick strip on the left
  bool get hasLeftAxis => leftAxisRect.width > 0;

  /// Ticks overlay only the plot area's right edge ([YAxisPosition.inside])
  bool get axisInside => !axisOutside && !hasLeftAxis;

  List<Bar> get bars => controller.bars;

  PaintPool get pool => controller.pool;

  PanelLayout get mainPanel => panels.first;

  /// Panel the indicator / overlay is currently painting on; set with [usePanel] before each panel
  PanelLayout get panel => _panel ?? mainPanel;
  PanelLayout? _panel;

  // ignore: use_setters_to_change_properties
  void usePanel(PanelLayout p) => _panel = p;

  // ---- Coordinate mapping ----

  /// Center x of bar 0, aligned to physical pixels: unaligned, fractional bar widths after zoom
  /// give bars different subpixel phases,
  /// so as inertia tails off moving a fraction of a pixel per frame, bars jump cells one after
  /// another and the screen flickers (pixel_stability_test)
  late final double _xBase = config.snap(chartRect.right - rightIndex * barWidth);

  double xOf(num index) => _xBase + index * barWidth;

  double indexAt(double x) => (x - _xBase) / barWidth;

  /// Nearest bar at screen [x]
  int barIndexAt(double x) => indexAt(x).round().clamp(0, bars.length - 1);

  PanelLayout? panelAt(Offset p) {
    for (final panel in panels) {
      if (p.dy >= panel.rect.top && p.dy <= panel.rect.bottom) return panel;
    }
    return null;
  }

  // ---- Time and coordinates: drawings anchor on (time, value), so prepending history doesn't
  // shift them ----

  /// Average interval (ms), used for extrapolation and countdown
  double get avgPeriodMs => avgPeriodMsOf(bars);

  /// Fractional index for a timestamp (extrapolated beyond the data range)
  double indexOfTime(num time) => timeToIndex(bars, time);

  double timeOfIndex(double index) => indexToTime(bars, index);

  double xOfTime(num time) => xOf(indexOfTime(time));

  double timeAtX(double x) => timeOfIndex(indexAt(x));

  static const int _valueFormatCacheCap = 128;
  static const int _axisFormatCacheCap = 128;
  static const int _timeFormatCacheCap = 64;
  final Map<_PanelValueKey, String> _valueFormatCache = <_PanelValueKey, String>{};
  final Map<_PanelValueKey, String> _axisFormatCache = <_PanelValueKey, String>{};
  final Map<int, String> _timeFormatCache = <int, String>{};

  void _cacheStore<K>(Map<K, String> cache, K key, String value, int cap) {
    if (cache.length >= cap) cache.clear();
    cache[key] = value;
  }

  String formatValue(PanelLayout p, double v) {
    if (!v.isFinite) return _formatterOf(p)(v);
    final key = _PanelValueKey(p.id, v);
    final hit = _valueFormatCache[key];
    if (hit != null) return hit;
    final text = _formatterOf(p)(v);
    _cacheStore(_valueFormatCache, key, text, _valueFormatCacheCap);
    return text;
  }

  bool _isVolPanel(PanelLayout p) => !p.isMain && p.indicators.any((i) => i.id == 'vol');

  String Function(double) _formatterOf(PanelLayout p) {
    if (p.isSecondary) return config.secondaryFormatter ?? config.priceFormatter;
    if (p.isMain) return config.priceFormatter;
    if (_isVolPanel(p)) return config.volumeFormatter;
    return config.subValueFormatter;
  }

  /// Base for percentage scale: close of the bar at the screen's left edge. Can't use [start],
  /// which extends one extra bar left (so lines connect across the edge)
  late final double _percentBase = () {
    if (isEmpty) return double.nan;
    final i = indexAt(chartRect.left).ceil().clamp(start, end);
    return bars[i].close;
  }();

  /// For ticks and crosshair: shows percent change on the main chart when percentage scale is on;
  /// legend and tooltip still use [formatValue] (absolute price)
  String formatAxisValue(PanelLayout p, double v) {
    if (!v.isFinite) return formatValue(p, v);
    final key = _PanelValueKey(p.id, v);
    final hit = _axisFormatCache[key];
    if (hit != null) return hit;
    String text;
    if (p.isMain && !p.isSecondary && config.percentScale && !isEmpty) {
      final base = _percentBase;
      if (base > 0) {
        final pct = (v / base - 1) * 100;
        text = '${pct >= 0 ? '+' : ''}${pct.toStringAsFixed(2)}%';
        _cacheStore(_axisFormatCache, key, text, _axisFormatCacheCap);
        return text;
      }
    }
    text = _isVolPanel(p) ? config.volumeAxisFormatter(v) : formatValue(p, v);
    _cacheStore(_axisFormatCache, key, text, _axisFormatCacheCap);
    return text;
  }

  /// Cached time format shared by grid and crosshair labels
  String formatTime(int millis) {
    final hit = _timeFormatCache[millis];
    if (hit != null) return hit;
    final text = config.timeFormatter(millis);
    _cacheStore(_timeFormatCache, millis, text, _timeFormatCacheCap);
    return text;
  }

  // ---- Drawing utilities ----

  /// Bars merged into one draw unit: normally 1; when bar width is under 2 physical pixels,
  /// bucketed by integer multiples of absolute index (stable while panning)
  int get drawGroup {
    final minDrawW = 2.0 / config.devicePixelRatio;
    return barWidth >= minDrawW ? 1 : (minDrawW / barWidth).ceil();
  }

  /// Bucket width (px): width of one draw unit after decimation
  double get drawWidth => barWidth * drawGroup;

  /// Stroke width floor of 1 logical pixel, but not above the bucket width: at dpr>=3 buckets are
  /// under 1, and sticking to 1 makes adjacent bars overlap so up/down colors flip while panning
  double get minStrokeWidth => math.min(1.0, drawWidth);

  /// Bar stroke width: 80% of bucket width, capped to leave a 1px gap, floored at [minStrokeWidth]
  double barStrokeWidth() =>
      (drawWidth * 0.8).clamp(minStrokeWidth, math.max(minStrokeWidth, drawWidth - 1));

  /// Draws a polyline over the visible range, breaking at NaN (indicator warm-up); when decimating,
  /// takes first / low / high / last per bucket (M4)
  void polyline(Canvas canvas, List<double> values, Paint paint) {
    final path = pool.scratchPath..reset();
    var started = false;
    final n = values.length;
    final g = drawGroup;
    if (g == 1) {
      for (var i = start; i <= end && i < n; i++) {
        final v = values[i];
        if (v.isNaN) {
          started = false;
          continue;
        }
        final x = xOf(i);
        final y = panel.yOf(v);
        if (started) {
          path.lineTo(x, y);
        } else {
          path.moveTo(x, y);
          started = true;
        }
      }
    } else {
      final last = math.min(end, n - 1);
      for (var b0 = (start ~/ g) * g; b0 <= last; b0 += g) {
        final i0 = math.max(b0, start), i1 = math.min(b0 + g - 1, last);
        var first = double.nan, lastV = double.nan;
        var lo = double.infinity, hi = double.negativeInfinity;
        for (var i = i0; i <= i1; i++) {
          final v = values[i];
          if (v.isNaN) continue;
          if (first.isNaN) first = v;
          lastV = v;
          if (v < lo) lo = v;
          if (v > hi) hi = v;
        }
        if (first.isNaN) {
          started = false;
          continue;
        }
        final x = xOf((i0 + i1) / 2);
        void pt(double v) {
          final y = panel.yOf(v);
          if (started) {
            path.lineTo(x, y);
          } else {
            path.moveTo(x, y);
            started = true;
          }
        }

        pt(first);
        if (hi > lo) {
          pt(lo);
          pt(hi);
        }
        pt(lastV);
      }
    }
    canvas.drawPath(path, paint);
  }

  /// Batch-draws vertical bars (volume, MACD histogram), [include] picks this color group's; when
  /// decimating, draws the one farthest from the baseline per bucket
  void vbars(
    Canvas canvas,
    List<double> values,
    double baselineValue,
    Paint paint,
    bool Function(int index, double value) include,
  ) {
    final n = values.length;
    final g = drawGroup;
    final last = math.min(end, n - 1);
    if (last < start) return;

    double extremeOf(int i0, int i1) {
      var best = double.nan;
      for (var i = i0; i <= i1; i++) {
        final v = values[i];
        if (v.isNaN || !include(i, v)) continue;
        if (best.isNaN || (v - baselineValue).abs() > (best - baselineValue).abs()) {
          best = v;
        }
      }
      return best;
    }

    final b00 = (start ~/ g) * g;
    final buckets = (last - b00) ~/ g + 1;
    if (buckets <= 0) return;
    final baseY = panel.yOf(baselineValue);
    final pts = pool.floats(buckets * 4);
    var j = 0;
    for (var b0 = b00; b0 <= last; b0 += g) {
      final i0 = math.max(b0, start), i1 = math.min(b0 + g - 1, last);
      final v = extremeOf(i0, i1);
      if (v.isNaN) continue;
      final x = xOf((i0 + i1) / 2);
      var y = panel.yOf(v);
      if ((y - baseY).abs() < 1) y = baseY - (v >= baselineValue ? 1 : -1);
      pts[j++] = x;
      pts[j++] = baseY;
      pts[j++] = x;
      pts[j++] = y;
    }
    if (j == 0) return;
    paint.strokeWidth = barStrokeWidth();
    canvas.drawRawPoints(
      PointMode.lines,
      j == pts.length ? pts : Float32List.sublistView(pts, 0, j),
      paint,
    );
  }
}

class _PanelValueKey {
  const _PanelValueKey(this.panelId, this.value);

  final String panelId;
  final double value;

  @override
  bool operator ==(Object other) =>
      other is _PanelValueKey && other.panelId == panelId && other.value == value;

  @override
  int get hashCode => Object.hash(panelId, value);
}
