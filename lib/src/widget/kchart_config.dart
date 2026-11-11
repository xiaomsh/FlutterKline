import 'package:flutter/foundation.dart';

import '../render/context.dart';
import '../render/main_series.dart';
import 'kchart.dart';

/// Builds a ChartConfig from widget parameters.
ChartConfig buildChartConfig(KChart w, TimeFormatter timeFormatter) {
  return ChartConfig(
    theme: w.theme,
    priceFormatter: w.priceFormatter,
    subValueFormatter: w.subValueFormatter ?? defaultCompactFormat,
    volumeFormatter: w.volumeFormatter ?? defaultCompactFormat,
    volumeAxisFormatter: w.volumeAxisFormatter ?? defaultCompactFormat,
    secondaryFormatter: w.secondaryFormatter,
    timeFormatter: timeFormatter,
    mainFlex: w.mainFlex,
    subFlex: w.subFlex,
    logScale: w.logScale,
    percentScale: w.percentScale,
    percentBase: w.percentBase,
    percentRightOnly: w.percentRightOnly,
    mainRange: w.mainRange,
    slotAxis: w.slotAxis,
    outlierClampRatio: w.outlierClampRatio,
    seriesStyle: w.seriesStyle,
    series: w.series,
    candleFill: w.candleFill,
    showHighLow: w.showHighLow,
    tieredTimeAxis: w.tieredTimeAxis,
    invertScale: w.invertScale,
    utcOffset: w.utcOffset,
    tickFormatter: w.tickFormatter,
    tickMinSpacing: w.tickMinSpacing,
    yAxisPosition: w.yAxisPosition,
    yAxisWidth: w.yAxisWidth,
    mainPaddingTop: w.mainPaddingTop,
    mainPaddingBottom: w.mainPaddingBottom,
    panelResizable: w.panelResizable,
    yPan: w.yPan,
    yFitValues: w.yFitValues,
    crosshairSnap: w.crosshairSnap,
    axisDragScale: w.axisDragScale,
    timeAxisHeight: w.timeAxisHeight,
  );
}

/// Syncs changed widget parameters into [c]; layout-affecting changes bump layoutRevision
/// once.
void syncChartConfig(ChartConfig c, KChart w, KChart old, TimeFormatter timeFormatter) {
  c
    ..priceFormatter = w.priceFormatter
    ..subValueFormatter = w.subValueFormatter ?? defaultCompactFormat
    ..volumeFormatter = w.volumeFormatter ?? defaultCompactFormat
    ..volumeAxisFormatter = w.volumeAxisFormatter ?? defaultCompactFormat
    ..secondaryFormatter = w.secondaryFormatter
    ..timeFormatter = timeFormatter;
  // These are only read when gestures happen; no recompute needed.
  c.panelResizable = w.panelResizable;
  c.yPan = w.yPan;
  c.yFitValues = w.yFitValues;
  c.crosshairSnap = w.crosshairSnap;
  c.axisDragScale = w.axisDragScale;

  // The following aren't in the layout cache key; on change, bump layoutRevision once so the
  // layers recompute and repaint.
  var relayout = false;
  if (w.mainFlex != old.mainFlex || w.subFlex != old.subFlex) {
    c
      ..mainFlex = w.mainFlex
      ..subFlex = w.subFlex;
    relayout = true;
  }
  if (w.logScale != old.logScale) {
    c.logScale = w.logScale;
    relayout = true;
  }
  if (w.percentScale != old.percentScale ||
      w.percentBase != old.percentBase ||
      w.percentRightOnly != old.percentRightOnly ||
      w.mainRange != old.mainRange ||
      w.slotAxis != old.slotAxis) {
    c
      ..percentScale = w.percentScale
      ..percentBase = w.percentBase
      ..percentRightOnly = w.percentRightOnly
      ..mainRange = w.mainRange
      ..slotAxis = w.slotAxis;
    relayout = true;
  }
  if (w.outlierClampRatio != old.outlierClampRatio) {
    c.outlierClampRatio = w.outlierClampRatio;
    relayout = true;
  }
  if (w.series != old.series || w.seriesStyle != old.seriesStyle) {
    c.series = w.series ?? MainSeries.fromStyle(w.seriesStyle);
    relayout = true;
  }
  if (w.candleFill != old.candleFill) {
    c.candleFill = w.candleFill;
    relayout = true;
  }
  if (w.showHighLow != old.showHighLow) {
    c.showHighLow = w.showHighLow;
    relayout = true;
  }
  if (w.invertScale != old.invertScale) {
    c.invertScale = w.invertScale;
    relayout = true;
  }
  if (w.tieredTimeAxis != old.tieredTimeAxis ||
      w.utcOffset != old.utcOffset ||
      w.tickFormatter != old.tickFormatter ||
      w.tickMinSpacing != old.tickMinSpacing) {
    c
      ..tieredTimeAxis = w.tieredTimeAxis
      ..utcOffset = w.utcOffset
      ..tickFormatter = w.tickFormatter
      ..tickMinSpacing = w.tickMinSpacing;
    relayout = true;
  }
  if (w.yAxisPosition != old.yAxisPosition || w.yAxisWidth != old.yAxisWidth) {
    c
      ..yAxisPosition = w.yAxisPosition
      ..yAxisWidth = w.yAxisWidth;
    relayout = true;
  }
  if (w.timeAxisHeight != old.timeAxisHeight) {
    c.timeAxisHeight = w.timeAxisHeight;
    relayout = true;
  }
  if (w.mainPaddingTop != old.mainPaddingTop || w.mainPaddingBottom != old.mainPaddingBottom) {
    c
      ..mainPaddingTop = w.mainPaddingTop
      ..mainPaddingBottom = w.mainPaddingBottom;
    relayout = true;
  }
  if (w.utcOffset != old.utcOffset ||
      w.timeFormatter != old.timeFormatter ||
      w.priceFormatter != old.priceFormatter ||
      w.subValueFormatter != old.subValueFormatter ||
      w.volumeFormatter != old.volumeFormatter ||
      w.volumeAxisFormatter != old.volumeAxisFormatter ||
      w.secondaryFormatter != old.secondaryFormatter) {
    relayout = true;
  }
  // Compare by content: a parent building an identical new map each build isn't a change, so
  // heights the user set by dragging splitters aren't wiped.
  if (!mapEquals(w.panelWeights, old.panelWeights)) {
    c.panelWeights
      ..clear()
      ..addAll(w.panelWeights ?? const {});
    relayout = true;
  }
  if (relayout) c.bumpLayout();
}
