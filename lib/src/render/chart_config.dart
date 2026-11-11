import 'package:flutter/foundation.dart';

import '../theme/theme.dart';
import 'main_series.dart';
import 'time_ticks.dart';

/// Built-in main series styles (three in the free edition); other styles pass a [MainSeries]
/// instance directly instead of this enum
enum MainSeriesStyle { candle, line, area }

/// Whether this style's high/low contribute to the main chart range
extension MainSeriesStyleScale on MainSeriesStyle {
  bool get usesHighLow => MainSeries.fromStyle(this).usesHighLow;
}

/// Candle body: filled, or hollow for up / down; bodies narrower than ~3px fall back to filled
enum CandleFillMode { solid, hollowUp, hollowDown }

/// Y-axis tick position. inside overlays the chart's right side; outside reserves a yAxisWidth
/// strip on the right; left reserves a strip on the left;
/// both reserves a strip on each side, with ticks on both
enum YAxisPosition { inside, outside, left, both }

/// Default sub-chart number format: K / M / B
String defaultCompactFormat(double v) {
  final a = v.abs();
  if (a >= 1e9) return '${(v / 1e9).toStringAsFixed(2)}B';
  if (a >= 1e6) return '${(v / 1e6).toStringAsFixed(2)}M';
  if (a >= 1e3) return '${(v / 1e3).toStringAsFixed(2)}K';
  return v.toStringAsFixed(2);
}

/// Where single-finger vertical drags pan the main chart range
enum YPanMode {
  /// No panning: vertical drags go to the outer page scroll (except dividers)
  none,

  /// Pans only when dragging on the right tick strip; the chart area still yields to the outer
  /// scroll (use this when the chart is embedded in a scrollable page)
  axis,

  /// Dragging anywhere on the main chart pans (use for fullscreen or when the outer view doesn't
  /// scroll)
  chart,
}

/// How the crosshair snaps vertically (main chart only; sub-charts always follow the finger)
enum CrosshairSnap {
  /// Follows the finger
  free,

  /// Snaps to the bar's close
  close,

  /// Snaps to the bar's OHLC value nearest the finger
  ohlc,
}

/// Configuration of one KChart, shared with painters; painters read current values when painting
class ChartConfig {
  ChartConfig({
    required KLineTheme theme,
    required this.priceFormatter,
    required this.timeFormatter,
    this.subValueFormatter = defaultCompactFormat,
    this.volumeFormatter = defaultCompactFormat,
    this.volumeAxisFormatter = defaultCompactFormat,
    this.mainFlex = 3,
    this.subFlex = 1,
    this.timeAxisHeight = 22,
    this.devicePixelRatio = 1,
    this.logScale = false,
    this.percentScale = false,
    this.outlierClampRatio,
    MainSeriesStyle seriesStyle = MainSeriesStyle.candle,
    MainSeries? series,
    this.candleFill = CandleFillMode.solid,
    // Differs from KChart's default (outside): standalone ChartConfig starts with the plot area
    // filling the full width
    this.yAxisPosition = YAxisPosition.inside,
    this.yAxisWidth = 56,
    this.mainPaddingTop = 28,
    this.mainPaddingBottom = 10,
    this.panelResizable = false,
    this.yPan = YPanMode.none,
    this.yFitValues,
    this.crosshairSnap = CrosshairSnap.free,
    this.axisDragScale = false,
    this.showHighLow = false,
    this.tieredTimeAxis = false,
    this.invertScale = false,
    this.secondaryFormatter,
    this.utcOffset,
    this.tickFormatter,
    this.tickMinSpacing = 64,
  }) : theme = ValueNotifier(theme),
       series = series ?? MainSeries.fromStyle(seriesStyle);

  /// Theme lives in a notifier, so switching themes repaints without rebuilding widgets
  final ValueNotifier<KLineTheme> theme;

  /// Incremented when layout inputs outside the controller's channels change; all painters
  /// subscribe to it
  final ValueNotifier<int> layoutRevision = ValueNotifier(0);

  String Function(double) priceFormatter;
  String Function(int) timeFormatter;

  /// Sub-chart number format, defaults to K / M / B
  String Function(double) subValueFormatter;

  /// Volume format (volume bars, tooltip), defaults to K / M / B
  String Function(double) volumeFormatter;

  /// Volume ticks and crosshair label format, defaults to K / M / B
  String Function(double) volumeAxisFormatter;
  double mainFlex;
  double subFlex;
  double timeAxisHeight;
  double devicePixelRatio;

  /// Main chart log scale (falls back to linear when the visible range isn't all positive)
  bool logScale;

  /// Main chart percentage scale: labels show change relative to the first visible close. Display
  /// only, y mapping unchanged; call [bumpLayout] after changing
  bool percentScale;

  /// Spike clamping: high/low may exceed the visible close range by at most span * this factor
  /// (0.5~2 recommended); null disables
  double? outlierClampRatio;

  /// Main series style; call [bumpLayout] after changing (the range basis may change)
  MainSeries series;

  /// Sets the style from the built-in enum; no getter (custom styles have no enum value)
  set seriesStyle(MainSeriesStyle v) => series = MainSeries.fromStyle(v);

  /// Affects painting only; changing it also goes through [bumpLayout] to repaint
  CandleFillMode candleFill;

  /// Marks the visible high and low; affects painting only, changes go through [bumpLayout]
  bool showHighLow;

  /// Number format for the main chart's second value axis; null uses [priceFormatter]. Call
  /// [bumpLayout] after changing
  String Function(double)? secondaryFormatter;

  /// Main chart inverted scale: small values on top, large below (short-side view, spreads);
  /// vertical drag direction flips too. Call [bumpLayout] after changing
  bool invertScale;

  /// Tiered time axis: ticks and vertical grid lines land on bars at year / month / day / hour
  /// boundaries, higher tiers first, moving with the chart;
  /// false uses a fixed four-way grid labeled with the nearest bar's time. Affects painting only,
  /// changes go through [bumpLayout]
  bool tieredTimeAxis;

  /// Time zone for finding tiered tick boundaries and formatting text; null follows the device
  /// (each bar uses its own offset, correct across DST). Call [bumpLayout] after changing
  Duration? utcOffset;

  /// Tiered tick text; null uses [defaultTickLabel]. Receives the bar's raw UTC ms; do time zone
  /// conversion yourself. Call [bumpLayout] after changing
  String Function(int millis, TimeTier tier)? tickFormatter;

  /// Minimum pixel gap between tiered ticks. Call [bumpLayout] after changing
  double tickMinSpacing;

  /// Call [bumpLayout] after changing: the x mapping changes
  YAxisPosition yAxisPosition;
  double yAxisWidth;

  /// Width of the tick strip reserved on the left of the plot area
  double get leftAxisWidth =>
      yAxisPosition == YAxisPosition.left || yAxisPosition == YAxisPosition.both ? yAxisWidth : 0;

  /// Width of the tick strip reserved on the right of the plot area
  double get rightAxisWidth =>
      yAxisPosition == YAxisPosition.outside || yAxisPosition == YAxisPosition.both
      ? yAxisWidth
      : 0;

  /// Top/bottom padding of the main chart range (px)
  double mainPaddingTop;
  double mainPaddingBottom;

  /// Panel height weights (panel id to weight); unlisted panels use mainFlex / subFlex
  final Map<String, double> panelWeights = {};

  /// Whether dragging dividers resizes panels; off by default
  bool panelResizable;

  YPanMode yPan;

  CrosshairSnap crosshairSnap;

  /// Vertical drag on the price scale zooms y, horizontal drag on the time axis zooms x
  /// (TradingView style)
  bool axisDragScale;

  /// Price levels (orders, positions) that must fit when manually shrinking the y axis; the
  /// shrink limit is relaxed so they all stay in the main chart
  List<double> Function()? yFitValues;

  /// Weights mistakenly passed as 0 / negative / NaN would make panel heights negative, so they
  /// fall back to defaults
  double weightFor(String panelId, bool isMain) {
    final w = panelWeights[panelId] ?? (isMain ? mainFlex : subFlex);
    return w.isFinite && w > 0 ? w : (isMain ? 3.0 : 1.0);
  }

  void bumpLayout() => layoutRevision.value++;

  /// Called when KChart is disposed
  void dispose() {
    theme.dispose();
    layoutRevision.dispose();
  }

  /// Aligns to physical pixels so lines of width [strokeWidth] are crisp: odd physical widths land
  /// on pixel centers (+½), even ones on pixel edges.
  /// Always adding +½ would blur a 2px grid line across three physical pixels
  double snap(double v, {double strokeWidth = 1}) {
    final physical = (v * devicePixelRatio).floorToDouble();
    final w = (strokeWidth * devicePixelRatio).round();
    final half = w.isOdd || w == 0 ? 0.5 : 0.0;
    return (physical + half) / devicePixelRatio;
  }
}
