import 'dart:ui';

import '../model/bar.dart';
import '../model/min_max.dart';
import '../panel/panel.dart';
import '../render/context.dart';
import 'indicator_store.dart';

export 'indicator_store.dart';

void checkPositivePeriod(int value, String name) {
  if (value <= 0) {
    throw RangeError.value(value, name, 'period must be a positive integer');
  }
}

/// Validates a set of periods (e.g. multiple MA/EMA lines) one by one.
void checkPositivePeriods(List<int> values, String name) {
  if (values.isEmpty) {
    throw ArgumentError.value(values, name, 'at least one period is required');
  }
  for (final v in values) {
    checkPositivePeriod(v, name);
  }
}

/// Highest/lowest of the trailing [p] bars (partial window: with fewer than period bars, uses the
/// available min(p, i+1) bars,
/// so values start at bar 0). Shared by windowed indicators such as KDJ / Williams / Donchian.
(double lo, double hi) windowHighLow(List<Bar> bars, int i, int p) {
  var lo = double.infinity, hi = double.negativeInfinity;
  for (var j = i - p + 1 < 0 ? 0 : i - p + 1; j <= i; j++) {
    final b = bars[j];
    if (b.low < lo) lo = b.low;
    if (b.high > hi) hi = b.high;
  }
  return (lo, hi);
}

/// AF/coefficient params must be finite and positive (0 or negative degenerates or stalls the
/// recurrence).
void checkPositiveFinite(double value, String name) {
  if (!value.isFinite || value <= 0) {
    throw RangeError.value(value, name, 'must be a finite positive number');
  }
}

/// Indicator plugin interface: implement it and hand it to the controller
abstract class Indicator {
  /// Unique per instance, includes params (e.g. 'ma(7,25,99)'); a changed id triggers a full
  /// recompute
  String get id;

  /// Serialization type tag (IndicatorRegistry key); defaults to the param prefix of [id]
  /// (`ma(7,25)` has kind `ma`). Third-party indicators follow this convention or override it.
  String get kind {
    final i = id.indexOf('(');
    return i < 0 ? id : id.substring(0, i);
  }

  /// Which panel to paint in
  PanelRef get target;

  /// At least this many bars are needed for [computeLast] to be safe; otherwise the controller uses
  /// [computeAll]
  int get warmupBars => 0;

  /// Bottom reserved area declared by main-chart overlay indicators (fraction of panel height, TV
  /// scaleMargins semantics):
  /// price autoscale is compressed above it so candles don't overlap the placeholder. 0 = none.
  double get mainBottomReserveFraction => 0;

  /// After prepending history, the number of prefix bars besides the new ones expected to change;
  /// null (default) recomputes fully. Affects performance only: results are checked against old
  /// values and fall back to full recompute on mismatch.
  /// Windowed indicators return the max period, exponential smoothing uses
  /// [settleForSmoothing], state machines give an empirical value, cumulative ones (e.g. OBV)
  /// return null
  int? get prependSettleBars => null;

  /// Settling length for exponential smoothing: 40*period (Wilder α=1/p decays below double
  /// precision
  /// after ~34.5p; rounded up for margin).
  static int settleForSmoothing(int period) => period * 40;

  /// Full computation; outputs and recurrence state must both be written to [store]
  void computeAll(List<Bar> bars, IndicatorStore store);

  /// Incremental: computes only bar [index] (the last one), reading index-1 state from [store]
  void computeLast(List<Bar> bars, int index, IndicatorStore store);

  /// Paints on ctx.panel using ctx's coordinate mapping
  void paint(Canvas canvas, RenderContext ctx, IndicatorStore store);

  /// Value range over the visible bars (inclusive), for autoscale
  MinMax range(IndicatorStore store, int start, int end);

  /// Value-range entry actually called by layout, with an extra fractional index [rightIndex] at
  /// the screen's right edge (may exceed the data, landing in the right padding).
  /// Defaults to [range]; indicators drawn past the latest bar (e.g. Ichimoku's leading cloud)
  /// override it to compute only the on-screen part
  MinMax rangeInView(IndicatorStore store, int start, int end, double rightIndex) =>
      range(store, start, end);

  /// Legend for bar [index] (the crosshair bar, else the latest): "name:value" + color,
  /// skipping NaN
  void legendInto(
    List<LegendItem> out,
    RenderContext ctx,
    IndicatorStore store,
    int index,
  ) {}
}

/// Skeleton for line indicators: subclasses declare series keys / labels / colors and implement
/// per-bar [computeAt];
/// the rest (computeAll / computeLast / paint / range / legendInto) is provided here and can be
/// overridden
abstract class LineIndicator extends Indicator {
  /// Output series keys (match series names in store; order determines colors).
  List<String> get seriesKeys;

  /// Legend labels, one per [seriesKeys].
  List<String> get seriesLabels;

  /// Explicit line colors; null uses the theme palette (starting at [paletteOffset]).
  List<Color>? get seriesColors => null;

  double get seriesLineWidth => 1;

  int get paletteOffset => 0;

  /// Indicator name header on the first legend line (e.g. 'KDJ(9,3,3)'); null adds none.
  String? get legendHeader => null;

  /// Per-bar computation: writes bar [i] (may read persisted state of i-1).
  void computeAt(List<Bar> bars, int i, IndicatorStore store);

  @override
  void computeAll(List<Bar> bars, IndicatorStore store) {
    for (var i = 0; i < bars.length; i++) {
      computeAt(bars, i, store);
    }
  }

  @override
  void computeLast(List<Bar> bars, int index, IndicatorStore store) =>
      computeAt(bars, index, store);

  @override
  void paint(Canvas canvas, RenderContext ctx, IndicatorStore store) => paintSeriesLines(
    canvas,
    ctx,
    store,
    seriesKeys,
    colors: seriesColors,
    lineWidth: seriesLineWidth,
    paletteOffset: paletteOffset,
  );

  @override
  MinMax range(IndicatorStore store, int start, int end) =>
      seriesRange(store, seriesKeys, start, end);

  @override
  void legendInto(
    List<LegendItem> out,
    RenderContext ctx,
    IndicatorStore store,
    int index,
  ) {
    final header = legendHeader;
    if (header != null) out.add((header, ctx.theme.axisText));
    legendOfKeys(
      out,
      ctx,
      store,
      index,
      seriesLabels,
      seriesKeys,
      colors: seriesColors,
      paletteOffset: paletteOffset,
    );
  }
}

/// A colored legend entry: (text, color)
typedef LegendItem = (String, Color);

/// Color of series [j]: explicitly given, or taken from the theme palette by offset
Color seriesColor(
  RenderContext ctx,
  List<Color>? colors,
  int j, [
  int paletteOffset = 0,
]) => colors != null && j < colors.length ? colors[j] : ctx.theme.lineColor(j + paletteOffset);

// ---- Shared implementation for line indicators ----

/// One polyline per key; missing colors are taken from the theme palette starting at
/// [paletteOffset]
void paintSeriesLines(
  Canvas canvas,
  RenderContext ctx,
  IndicatorStore store,
  List<String> keys, {
  List<Color>? colors,
  double lineWidth = 1,
  int paletteOffset = 0,
}) {
  for (var j = 0; j < keys.length; j++) {
    final paint = ctx.pool.stroke
      ..color = seriesColor(ctx, colors, j, paletteOffset)
      ..strokeWidth = lineWidth;
    ctx.polyline(canvas, store.series(keys[j]), paint);
  }
}

/// One legend entry per (name, key), same color as the line, skipping NaN
void legendOfKeys(
  List<LegendItem> out,
  RenderContext ctx,
  IndicatorStore store,
  int index,
  List<String> labels,
  List<String> keys, {
  List<Color>? colors,
  int paletteOffset = 0,
}) {
  for (var j = 0; j < keys.length; j++) {
    final v = store.value(keys[j], index);
    if (v.isNaN) continue;
    out.add((
      '${labels[j]}:${ctx.formatValue(ctx.panel, v)}',
      seriesColor(ctx, colors, j, paletteOffset),
    ));
  }
}

/// Union of the visible value ranges of several series
MinMax seriesRange(
  IndicatorStore store,
  List<String> keys,
  int start,
  int end,
) {
  var mm = MinMax.empty;
  for (final k in keys) {
    mm = mm.union(store.rangeOf(k, start, end));
  }
  return mm;
}
