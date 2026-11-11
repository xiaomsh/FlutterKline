import 'package:flutter/painting.dart';

/// Colors and text styles. Switch themes by swapping the object: painters read it via a
/// notifier, no rebuild needed
class KLineTheme {
  final Color background;
  final Color gridLine;
  final Color panelSeparator;
  final Color up;
  final Color down;
  final Color axisText;
  final double axisTextSize;
  final Color crosshair;
  final Color crosshairLabelBg;
  final Color crosshairLabelText;
  final Color priceLine;
  final Color priceLabelBg;
  final Color priceLabelText;
  final Color tooltipBg;
  final Color tooltipText;
  final Color tooltipBorder;

  /// Default palette for indicator lines, used when the indicator constructor gives no color
  final List<Color> palette;

  /// Line color for line and area charts
  final Color seriesLine;

  /// Grid line width (horizontal and vertical; panel dividers are fixed at 1px)
  final double gridLineWidth;

  /// Grid dash pattern `[dash, gap]`; null (default) is solid
  final List<double>? gridLineDash;

  /// Crosshair dash pattern `[dash, gap]`; null (default) is solid
  final List<double>? crosshairDash;

  /// false skips grid lines (tick labels still drawn)
  final bool showGrid;

  /// Up / down wick color; null matches the body
  final Color? upWick;
  final Color? downWick;

  /// Up / down body 1px border color; null for no stroke; also used for hollow candle outlines
  final Color? upBorder;
  final Color? downBorder;

  /// Color of the visible high / low labels; null uses [axisText]
  final Color? highLowText;

  const KLineTheme({
    required this.background,
    required this.gridLine,
    required this.panelSeparator,
    required this.up,
    required this.down,
    required this.axisText,
    this.axisTextSize = 10,
    required this.crosshair,
    required this.crosshairLabelBg,
    required this.crosshairLabelText,
    required this.priceLine,
    required this.priceLabelBg,
    required this.priceLabelText,
    required this.tooltipBg,
    required this.tooltipText,
    required this.tooltipBorder,
    required this.palette,
    this.seriesLine = const Color(0xFF2962FF),
    this.gridLineWidth = 1,
    this.gridLineDash,
    this.crosshairDash,
    this.showGrid = true,
    this.upWick,
    this.downWick,
    this.upBorder,
    this.downBorder,
    this.highLowText,
  });

  Color lineColor(int i) => palette.isEmpty ? seriesLine : palette[i % palette.length];

  Color get upWickColor => upWick ?? up;
  Color get downWickColor => downWick ?? down;
  Color get highLowTextColor => highLowText ?? axisText;

  TextStyle get axisStyle => TextStyle(color: axisText, fontSize: axisTextSize);

  /// Copies this theme with a few fields changed
  KLineTheme copyWith({
    Color? background,
    Color? gridLine,
    Color? panelSeparator,
    Color? up,
    Color? down,
    Color? axisText,
    double? axisTextSize,
    Color? crosshair,
    Color? crosshairLabelBg,
    Color? crosshairLabelText,
    Color? priceLine,
    Color? priceLabelBg,
    Color? priceLabelText,
    Color? tooltipBg,
    Color? tooltipText,
    Color? tooltipBorder,
    List<Color>? palette,
    Color? seriesLine,
    double? gridLineWidth,
    List<double>? gridLineDash,
    List<double>? crosshairDash,
    bool? showGrid,
    Color? upWick,
    Color? downWick,
    Color? upBorder,
    Color? downBorder,
    Color? highLowText,
  }) {
    return KLineTheme(
      background: background ?? this.background,
      gridLine: gridLine ?? this.gridLine,
      panelSeparator: panelSeparator ?? this.panelSeparator,
      up: up ?? this.up,
      down: down ?? this.down,
      axisText: axisText ?? this.axisText,
      axisTextSize: axisTextSize ?? this.axisTextSize,
      crosshair: crosshair ?? this.crosshair,
      crosshairLabelBg: crosshairLabelBg ?? this.crosshairLabelBg,
      crosshairLabelText: crosshairLabelText ?? this.crosshairLabelText,
      priceLine: priceLine ?? this.priceLine,
      priceLabelBg: priceLabelBg ?? this.priceLabelBg,
      priceLabelText: priceLabelText ?? this.priceLabelText,
      tooltipBg: tooltipBg ?? this.tooltipBg,
      tooltipText: tooltipText ?? this.tooltipText,
      tooltipBorder: tooltipBorder ?? this.tooltipBorder,
      palette: palette ?? this.palette,
      seriesLine: seriesLine ?? this.seriesLine,
      gridLineWidth: gridLineWidth ?? this.gridLineWidth,
      gridLineDash: gridLineDash ?? this.gridLineDash,
      crosshairDash: crosshairDash ?? this.crosshairDash,
      showGrid: showGrid ?? this.showGrid,
      upWick: upWick ?? this.upWick,
      downWick: downWick ?? this.downWick,
      upBorder: upBorder ?? this.upBorder,
      downBorder: downBorder ?? this.downBorder,
      highLowText: highLowText ?? this.highLowText,
    );
  }

  /// Saves as JSON (colors as ARGB ints); the host decides where to store it
  Map<String, dynamic> toJson() => {
    'background': background.toARGB32(),
    'gridLine': gridLine.toARGB32(),
    'panelSeparator': panelSeparator.toARGB32(),
    'up': up.toARGB32(),
    'down': down.toARGB32(),
    'axisText': axisText.toARGB32(),
    'axisTextSize': axisTextSize,
    'crosshair': crosshair.toARGB32(),
    'crosshairLabelBg': crosshairLabelBg.toARGB32(),
    'crosshairLabelText': crosshairLabelText.toARGB32(),
    'priceLine': priceLine.toARGB32(),
    'priceLabelBg': priceLabelBg.toARGB32(),
    'priceLabelText': priceLabelText.toARGB32(),
    'tooltipBg': tooltipBg.toARGB32(),
    'tooltipText': tooltipText.toARGB32(),
    'tooltipBorder': tooltipBorder.toARGB32(),
    'palette': [for (final c in palette) c.toARGB32()],
    'seriesLine': seriesLine.toARGB32(),
    'gridLineWidth': gridLineWidth,
    'gridLineDash': ?gridLineDash,
    'crosshairDash': ?crosshairDash,
    'showGrid': showGrid,
    'upWick': ?upWick?.toARGB32(),
    'downWick': ?downWick?.toARGB32(),
    'upBorder': ?upBorder?.toARGB32(),
    'downBorder': ?downBorder?.toARGB32(),
    'highLowText': ?highLowText?.toARGB32(),
  };

  /// Restores from [toJson] output; missing fields come from [base] (default light theme)
  factory KLineTheme.fromJson(Map<String, dynamic> json, {KLineTheme? base}) {
    final b = base ?? KLineTheme.light();
    Color? c(String key) => json[key] is int ? Color(json[key] as int) : null;
    double? d(String key) => (json[key] as num?)?.toDouble();
    List<double>? dash(String key) {
      final v = json[key];
      return v is List ? [for (final x in v) (x as num).toDouble()] : null;
    }

    final palette = json['palette'];
    return b.copyWith(
      background: c('background'),
      gridLine: c('gridLine'),
      panelSeparator: c('panelSeparator'),
      up: c('up'),
      down: c('down'),
      axisText: c('axisText'),
      axisTextSize: d('axisTextSize'),
      crosshair: c('crosshair'),
      crosshairLabelBg: c('crosshairLabelBg'),
      crosshairLabelText: c('crosshairLabelText'),
      priceLine: c('priceLine'),
      priceLabelBg: c('priceLabelBg'),
      priceLabelText: c('priceLabelText'),
      tooltipBg: c('tooltipBg'),
      tooltipText: c('tooltipText'),
      tooltipBorder: c('tooltipBorder'),
      palette: palette is List ? [for (final x in palette) Color(x as int)] : null,
      seriesLine: c('seriesLine'),
      gridLineWidth: d('gridLineWidth'),
      gridLineDash: dash('gridLineDash'),
      crosshairDash: dash('crosshairDash'),
      showGrid: json['showGrid'] is bool ? json['showGrid'] as bool : null,
      upWick: c('upWick'),
      downWick: c('downWick'),
      upBorder: c('upBorder'),
      downBorder: c('downBorder'),
      highLowText: c('highLowText'),
    );
  }

  factory KLineTheme.light() => const KLineTheme(
    background: Color(0xFFFFFFFF),
    gridLine: Color(0xFFEDEDED),
    panelSeparator: Color(0xffffffff),
    up: Color(0xFF26A69A),
    down: Color(0xFFEF5350),
    axisText: Color(0xFF888888),
    crosshair: Color(0xFF666666),
    crosshairLabelBg: Color(0xFF505050),
    crosshairLabelText: Color(0xFFFFFFFF),
    priceLine: Color(0xFF9AA0B0),
    priceLabelBg: Color(0xFF707888),
    priceLabelText: Color(0xFFFFFFFF),
    tooltipBg: Color(0xF2FFFFFF),
    tooltipText: Color(0xFF333333),
    tooltipBorder: Color(0xFFDDDDDD),
    palette: [
      Color(0xFFF0A732),
      Color(0xFF4A90E2),
      Color(0xFFB569D4),
      Color(0xFF50B7C1),
      Color(0xFFE2668C),
      Color(0xFF8CBF5A),
    ],
  );

  factory KLineTheme.dark() => const KLineTheme(
    background: Color(0xFF141822),
    gridLine: Color(0xFF232834),
    panelSeparator: Color(0xFF2C3341),
    up: Color(0xFF26A69A),
    down: Color(0xFFEF5350),
    axisText: Color(0xFF8A93A6),
    crosshair: Color(0xFFB0B8C8),
    crosshairLabelBg: Color(0xFF3A4152),
    crosshairLabelText: Color(0xFFE8ECF4),
    priceLine: Color(0xFF6A7286),
    priceLabelBg: Color(0xFF4A5266),
    priceLabelText: Color(0xFFE8ECF4),
    tooltipBg: Color(0xF21C212E),
    tooltipText: Color(0xFFD8DEEA),
    tooltipBorder: Color(0xFF394052),
    palette: [
      Color(0xFFF0A732),
      Color(0xFF5B9BE8),
      Color(0xFFBF7ADE),
      Color(0xFF58C4CF),
      Color(0xFFE87698),
      Color(0xFF98CC66),
    ],
  );
}
