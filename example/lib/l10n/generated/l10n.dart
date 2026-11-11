// GENERATED CODE - DO NOT MODIFY BY HAND
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'intl/messages_all.dart';

// **************************************************************************
// Generator: Flutter Intl IDE plugin
// Made by Localizely
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, lines_longer_than_80_chars
// ignore_for_file: join_return_with_assignment, prefer_final_in_for_each
// ignore_for_file: avoid_redundant_argument_values, avoid_escaping_inner_quotes

class S {
  S();

  static S? _current;

  static S get current {
    assert(
      _current != null,
      'No instance of S was loaded. Try to initialize the S delegate before accessing S.current.',
    );
    return _current!;
  }

  static const AppLocalizationDelegate delegate = AppLocalizationDelegate();

  static Future<S> load(Locale locale) {
    final name = (locale.countryCode?.isEmpty ?? false) ? locale.languageCode : locale.toString();
    final localeName = Intl.canonicalizedLocale(name);
    return initializeMessages(localeName).then((_) {
      Intl.defaultLocale = localeName;
      final instance = S();
      S._current = instance;

      return instance;
    });
  }

  static S of(BuildContext context) {
    final instance = S.maybeOf(context);
    assert(
      instance != null,
      'No instance of S present in the widget tree. Did you add S.delegate in localizationsDelegates?',
    );
    return instance!;
  }

  static S? maybeOf(BuildContext context) {
    return Localizations.of<S>(context, S);
  }

  /// `中文`
  String get language {
    return Intl.message(
      '中文',
      name: 'language',
      desc: 'Label of the language switch: the language it switches to',
      args: [],
    );
  }

  /// `Samples`
  String get homeSamples {
    return Intl.message('Samples', name: 'homeSamples', desc: '', args: []);
  }

  /// `Live market`
  String get homeLive {
    return Intl.message('Live market', name: 'homeLive', desc: '', args: []);
  }

  /// `Time`
  String get chartTime {
    return Intl.message('Time', name: 'chartTime', desc: '', args: []);
  }

  /// `O`
  String get chartOpen {
    return Intl.message('O', name: 'chartOpen', desc: '', args: []);
  }

  /// `H`
  String get chartHigh {
    return Intl.message('H', name: 'chartHigh', desc: '', args: []);
  }

  /// `L`
  String get chartLow {
    return Intl.message('L', name: 'chartLow', desc: '', args: []);
  }

  /// `C`
  String get chartClose {
    return Intl.message('C', name: 'chartClose', desc: '', args: []);
  }

  /// `Chg%`
  String get chartChange {
    return Intl.message('Chg%', name: 'chartChange', desc: '', args: []);
  }

  /// `Vol`
  String get chartVolume {
    return Intl.message('Vol', name: 'chartVolume', desc: '', args: []);
  }

  /// `Candlestick chart`
  String get chartName {
    return Intl.message(
      'Candlestick chart',
      name: 'chartName',
      desc: '',
      args: [],
    );
  }

  /// `to`
  String get chartRangeTo {
    return Intl.message('to', name: 'chartRangeTo', desc: '', args: []);
  }

  /// `last price`
  String get chartLatest {
    return Intl.message('last price', name: 'chartLatest', desc: '', args: []);
  }

  /// `, `
  String get chartSeparator {
    return Intl.message(', ', name: 'chartSeparator', desc: '', args: []);
  }

  /// `Data`
  String get sampleCategoryData {
    return Intl.message('Data', name: 'sampleCategoryData', desc: '', args: []);
  }

  /// `Main chart`
  String get sampleCategoryMain {
    return Intl.message(
      'Main chart',
      name: 'sampleCategoryMain',
      desc: '',
      args: [],
    );
  }

  /// `Coordinates`
  String get sampleCategoryCoordinates {
    return Intl.message(
      'Coordinates',
      name: 'sampleCategoryCoordinates',
      desc: '',
      args: [],
    );
  }

  /// `Indicators`
  String get sampleCategoryIndicators {
    return Intl.message(
      'Indicators',
      name: 'sampleCategoryIndicators',
      desc: '',
      args: [],
    );
  }

  /// `Interaction`
  String get sampleCategoryInteraction {
    return Intl.message(
      'Interaction',
      name: 'sampleCategoryInteraction',
      desc: '',
      args: [],
    );
  }

  /// `Appearance`
  String get sampleCategoryAppearance {
    return Intl.message(
      'Appearance',
      name: 'sampleCategoryAppearance',
      desc: '',
      args: [],
    );
  }

  /// `Extensions`
  String get sampleCategoryExtensions {
    return Intl.message(
      'Extensions',
      name: 'sampleCategoryExtensions',
      desc: '',
      args: [],
    );
  }

  /// `Pro`
  String get sampleCategoryPro {
    return Intl.message('Pro', name: 'sampleCategoryPro', desc: '', args: []);
  }

  /// `Storage`
  String get sampleCategoryStorage {
    return Intl.message(
      'Storage',
      name: 'sampleCategoryStorage',
      desc: '',
      args: [],
    );
  }

  /// `Pro feature`
  String get sampleLockedDescription {
    return Intl.message(
      'Pro feature',
      name: 'sampleLockedDescription',
      desc: '',
      args: [],
    );
  }

  /// `Data size and limit`
  String get sampleDataLimitTitle {
    return Intl.message(
      'Data size and limit',
      name: 'sampleDataLimitTitle',
      desc: '',
      args: [],
    );
  }

  /// `Load the whole series with setBars; maxBars drops the oldest bars when exceeded.`
  String get sampleDataLimitDesc {
    return Intl.message(
      'Load the whole series with setBars; maxBars drops the oldest bars when exceeded.',
      name: 'sampleDataLimitDesc',
      desc: '',
      args: [],
    );
  }

  /// `Real-time push`
  String get sampleRealtimeTitle {
    return Intl.message(
      'Real-time push',
      name: 'sampleRealtimeTitle',
      desc: '',
      args: [],
    );
  }

  /// `applyTick updates the last bar on the same timestamp and appends on a new one; autoFollow sticks to the latest.`
  String get sampleRealtimeDesc {
    return Intl.message(
      'applyTick updates the last bar on the same timestamp and appends on a new one; autoFollow sticks to the latest.',
      name: 'sampleRealtimeDesc',
      desc: '',
      args: [],
    );
  }

  /// `History pagination`
  String get sampleHistoryTitle {
    return Intl.message(
      'History pagination',
      name: 'sampleHistoryTitle',
      desc: '',
      args: [],
    );
  }

  /// `Scrolling to the left triggers onLoadMore, prependHistory adds older data, and the viewport does not jump.`
  String get sampleHistoryDesc {
    return Intl.message(
      'Scrolling to the left triggers onLoadMore, prependHistory adds older data, and the viewport does not jump.',
      name: 'sampleHistoryDesc',
      desc: '',
      args: [],
    );
  }

  /// `Main series`
  String get sampleSeriesTitle {
    return Intl.message(
      'Main series',
      name: 'sampleSeriesTitle',
      desc: '',
      args: [],
    );
  }

  /// `Three free seriesStyle values, plus MainSeries instances in Pro.`
  String get sampleSeriesDesc {
    return Intl.message(
      'Three free seriesStyle values, plus MainSeries instances in Pro.',
      name: 'sampleSeriesDesc',
      desc: '',
      args: [],
    );
  }

  /// `Candle style`
  String get sampleCandleTitle {
    return Intl.message(
      'Candle style',
      name: 'sampleCandleTitle',
      desc: '',
      args: [],
    );
  }

  /// `Solid / hollow, with separate wick and border colors.`
  String get sampleCandleDesc {
    return Intl.message(
      'Solid / hollow, with separate wick and border colors.',
      name: 'sampleCandleDesc',
      desc: '',
      args: [],
    );
  }

  /// `Price line`
  String get samplePriceTitle {
    return Intl.message(
      'Price line',
      name: 'samplePriceTitle',
      desc: '',
      args: [],
    );
  }

  /// `Last price line and tag, close countdown, bid / ask, mark price hint, price animation, and visible high / low labels.`
  String get samplePriceDesc {
    return Intl.message(
      'Last price line and tag, close countdown, bid / ask, mark price hint, price animation, and visible high / low labels.',
      name: 'samplePriceDesc',
      desc: '',
      args: [],
    );
  }

  /// `countdown order book mark price`
  String get samplePriceSearchTerms {
    return Intl.message(
      'countdown order book mark price',
      name: 'samplePriceSearchTerms',
      desc: '',
      args: [],
    );
  }

  /// `Log / percent / inverted`
  String get sampleScaleTitle {
    return Intl.message(
      'Log / percent / inverted',
      name: 'sampleScaleTitle',
      desc: '',
      args: [],
    );
  }

  /// `The three scale modes can be combined.`
  String get sampleScaleDesc {
    return Intl.message(
      'The three scale modes can be combined.',
      name: 'sampleScaleDesc',
      desc: '',
      args: [],
    );
  }

  /// `Lock range`
  String get sampleLockRangeTitle {
    return Intl.message(
      'Lock range',
      name: 'sampleLockRangeTitle',
      desc: '',
      args: [],
    );
  }

  /// `Pin the main chart range to the current one; panning and pushes no longer rescale it.`
  String get sampleLockRangeDesc {
    return Intl.message(
      'Pin the main chart range to the current one; panning and pushes no longer rescale it.',
      name: 'sampleLockRangeDesc',
      desc: '',
      args: [],
    );
  }

  /// `Secondary axis`
  String get sampleSecondaryAxisTitle {
    return Intl.message(
      'Secondary axis',
      name: 'sampleSecondaryAxisTitle',
      desc: '',
      args: [],
    );
  }

  /// `Overlay indicators of a different scale on the main chart with their own range.`
  String get sampleSecondaryAxisDesc {
    return Intl.message(
      'Overlay indicators of a different scale on the main chart with their own range.',
      name: 'sampleSecondaryAxisDesc',
      desc: '',
      args: [],
    );
  }

  /// `Price axis position`
  String get sampleAxisPositionTitle {
    return Intl.message(
      'Price axis position',
      name: 'sampleAxisPositionTitle',
      desc: '',
      args: [],
    );
  }

  /// `Right inside / outside, left, both sides, and axis width.`
  String get sampleAxisPositionDesc {
    return Intl.message(
      'Right inside / outside, left, both sides, and axis width.',
      name: 'sampleAxisPositionDesc',
      desc: '',
      args: [],
    );
  }

  /// `Indicator switches`
  String get sampleIndicatorsTitle {
    return Intl.message(
      'Indicator switches',
      name: 'sampleIndicatorsTitle',
      desc: '',
      args: [],
    );
  }

  /// `Combine the 8 built-in indicators.`
  String get sampleIndicatorsDesc {
    return Intl.message(
      'Combine the 8 built-in indicators.',
      name: 'sampleIndicatorsDesc',
      desc: '',
      args: [],
    );
  }

  /// `{name} parameters`
  String sampleIndicatorParamTitle(String name) {
    return Intl.message(
      '$name parameters',
      name: 'sampleIndicatorParamTitle',
      desc: '',
      args: [name],
    );
  }

  /// `Change parameters and colors; the indicator recomputes immediately.`
  String get sampleIndicatorParamDesc {
    return Intl.message(
      'Change parameters and colors; the indicator recomputes immediately.',
      name: 'sampleIndicatorParamDesc',
      desc: '',
      args: [],
    );
  }

  /// `Panel height`
  String get samplePanelsTitle {
    return Intl.message(
      'Panel height',
      name: 'samplePanelsTitle',
      desc: '',
      args: [],
    );
  }

  /// `Main / sub panel weights; drag the divider to resize.`
  String get samplePanelsDesc {
    return Intl.message(
      'Main / sub panel weights; drag the divider to resize.',
      name: 'samplePanelsDesc',
      desc: '',
      args: [],
    );
  }

  /// `Compute and errors`
  String get sampleComputeTitle {
    return Intl.message(
      'Compute and errors',
      name: 'sampleComputeTitle',
      desc: '',
      args: [],
    );
  }

  /// `Large data is computed in a background isolate; indicator errors are reported via a callback without affecting other indicators.`
  String get sampleComputeDesc {
    return Intl.message(
      'Large data is computed in a background isolate; indicator errors are reported via a callback without affecting other indicators.',
      name: 'sampleComputeDesc',
      desc: '',
      args: [],
    );
  }

  /// `Crosshair`
  String get sampleCrosshairTitle {
    return Intl.message(
      'Crosshair',
      name: 'sampleCrosshairTitle',
      desc: '',
      args: [],
    );
  }

  /// `Snap mode, tooltip toggle and custom tooltip.`
  String get sampleCrosshairDesc {
    return Intl.message(
      'Snap mode, tooltip toggle and custom tooltip.',
      name: 'sampleCrosshairDesc',
      desc: '',
      args: [],
    );
  }

  /// `Gestures`
  String get sampleGesturesTitle {
    return Intl.message(
      'Gestures',
      name: 'sampleGesturesTitle',
      desc: '',
      args: [],
    );
  }

  /// `Vertical pan area, axis drag to scale, and tap a bar to read its price.`
  String get sampleGesturesDesc {
    return Intl.message(
      'Vertical pan area, axis drag to scale, and tap a bar to read its price.',
      name: 'sampleGesturesDesc',
      desc: '',
      args: [],
    );
  }

  /// `Keyboard`
  String get sampleKeyboardTitle {
    return Intl.message(
      'Keyboard',
      name: 'sampleKeyboardTitle',
      desc: '',
      args: [],
    );
  }

  /// `Arrow keys pan and zoom; Home / End jump to either end.`
  String get sampleKeyboardDesc {
    return Intl.message(
      'Arrow keys pan and zoom; Home / End jump to either end.',
      name: 'sampleKeyboardDesc',
      desc: '',
      args: [],
    );
  }

  /// `Theme`
  String get sampleThemeTitle {
    return Intl.message('Theme', name: 'sampleThemeTitle', desc: '', args: []);
  }

  /// `Light / dark background, up / down colors, and indicator palette.`
  String get sampleThemeDesc {
    return Intl.message(
      'Light / dark background, up / down colors, and indicator palette.',
      name: 'sampleThemeDesc',
      desc: '',
      args: [],
    );
  }

  /// `Grid and text`
  String get sampleGridTitle {
    return Intl.message(
      'Grid and text',
      name: 'sampleGridTitle',
      desc: '',
      args: [],
    );
  }

  /// `Grid visibility, dashes, line width, and axis font size.`
  String get sampleGridDesc {
    return Intl.message(
      'Grid visibility, dashes, line width, and axis font size.',
      name: 'sampleGridDesc',
      desc: '',
      args: [],
    );
  }

  /// `Formatting`
  String get sampleFormatTitle {
    return Intl.message(
      'Formatting',
      name: 'sampleFormatTitle',
      desc: '',
      args: [],
    );
  }

  /// `Price decimals, time zone, custom time format, and chart label language.`
  String get sampleFormatDesc {
    return Intl.message(
      'Price decimals, time zone, custom time format, and chart label language.',
      name: 'sampleFormatDesc',
      desc: '',
      args: [],
    );
  }

  /// `Tiered time axis`
  String get sampleTimeAxisTitle {
    return Intl.message(
      'Tiered time axis',
      name: 'sampleTimeAxisTitle',
      desc: '',
      args: [],
    );
  }

  /// `Ticks land on year / month / day / hour boundaries.`
  String get sampleTimeAxisDesc {
    return Intl.message(
      'Ticks land on year / month / day / hour boundaries.',
      name: 'sampleTimeAxisDesc',
      desc: '',
      args: [],
    );
  }

  /// `Watermark`
  String get sampleWatermarkTitle {
    return Intl.message(
      'Watermark',
      name: 'sampleWatermarkTitle',
      desc: '',
      args: [],
    );
  }

  /// `underlayBuilder paints below the candles.`
  String get sampleWatermarkDesc {
    return Intl.message(
      'underlayBuilder paints below the candles.',
      name: 'sampleWatermarkDesc',
      desc: '',
      args: [],
    );
  }

  /// `Custom overlay`
  String get sampleOverlayTitle {
    return Intl.message(
      'Custom overlay',
      name: 'sampleOverlayTitle',
      desc: '',
      args: [],
    );
  }

  /// `overlayBuilder paints plain widgets on the chart that follow panning and zooming.`
  String get sampleOverlayDesc {
    return Intl.message(
      'overlayBuilder paints plain widgets on the chart that follow panning and zooming.',
      name: 'sampleOverlayDesc',
      desc: '',
      args: [],
    );
  }

  /// `Custom main series`
  String get sampleCustomSeriesTitle {
    return Intl.message(
      'Custom main series',
      name: 'sampleCustomSeriesTitle',
      desc: '',
      args: [],
    );
  }

  /// `Implement MainSeries.paint without changing the library source.`
  String get sampleCustomSeriesDesc {
    return Intl.message(
      'Implement MainSeries.paint without changing the library source.',
      name: 'sampleCustomSeriesDesc',
      desc: '',
      args: [],
    );
  }

  /// `Depth chart`
  String get sampleDepthTitle {
    return Intl.message(
      'Depth chart',
      name: 'sampleDepthTitle',
      desc: '',
      args: [],
    );
  }

  /// `DepthChart has its own price axis and works alone or next to the candles.`
  String get sampleDepthDesc {
    return Intl.message(
      'DepthChart has its own price axis and works alone or next to the candles.',
      name: 'sampleDepthDesc',
      desc: '',
      args: [],
    );
  }

  /// `Save and restore`
  String get sampleStorageTitle {
    return Intl.message(
      'Save and restore',
      name: 'sampleStorageTitle',
      desc: '',
      args: [],
    );
  }

  /// `saveState / restoreState and KLineTheme.toJson / fromJson.`
  String get sampleStorageDesc {
    return Intl.message(
      'saveState / restoreState and KLineTheme.toJson / fromJson.',
      name: 'sampleStorageDesc',
      desc: '',
      args: [],
    );
  }

  /// `Reset this page`
  String get sampleResetPage {
    return Intl.message(
      'Reset this page',
      name: 'sampleResetPage',
      desc: '',
      args: [],
    );
  }

  /// `KLINEX · Offline synthetic data · {count} bars`
  String sampleFrameStatus(int count) {
    return Intl.message(
      'KLINEX · Offline synthetic data · $count bars',
      name: 'sampleFrameStatus',
      desc: '',
      args: [count],
    );
  }

  /// `Back to latest`
  String get sampleBackToLatest {
    return Intl.message(
      'Back to latest',
      name: 'sampleBackToLatest',
      desc: '',
      args: [],
    );
  }

  /// `Auto push`
  String get sampleAutoPush {
    return Intl.message(
      'Auto push',
      name: 'sampleAutoPush',
      desc: '',
      args: [],
    );
  }

  /// `Klinex Samples`
  String get settingPageTitle {
    return Intl.message(
      'Klinex Samples',
      name: 'settingPageTitle',
      desc: '',
      args: [],
    );
  }

  /// `Light`
  String get settingLightMode {
    return Intl.message('Light', name: 'settingLightMode', desc: '', args: []);
  }

  /// `Dark`
  String get settingDarkMode {
    return Intl.message('Dark', name: 'settingDarkMode', desc: '', args: []);
  }

  /// `Sample not found. Choose one from the menu.`
  String get settingSampleNotFound {
    return Intl.message(
      'Sample not found. Choose one from the menu.',
      name: 'settingSampleNotFound',
      desc: '',
      args: [],
    );
  }

  /// `Search features or APIs`
  String get settingMenuSearchHint {
    return Intl.message(
      'Search features or APIs',
      name: 'settingMenuSearchHint',
      desc: '',
      args: [],
    );
  }

  /// `{label}: {value}`
  String controlsSliderValue(String label, String value) {
    return Intl.message(
      '$label: $value',
      name: 'controlsSliderValue',
      desc: '',
      args: [label, value],
    );
  }

  /// `Equivalent code`
  String get controlsEquivalentCode {
    return Intl.message(
      'Equivalent code',
      name: 'controlsEquivalentCode',
      desc: '',
      args: [],
    );
  }

  /// `Copy code`
  String get controlsCopyCode {
    return Intl.message(
      'Copy code',
      name: 'controlsCopyCode',
      desc: '',
      args: [],
    );
  }

  /// `Code copied`
  String get controlsCodeCopied {
    return Intl.message(
      'Code copied',
      name: 'controlsCodeCopied',
      desc: '',
      args: [],
    );
  }

  /// `Line {index}`
  String indicatorFieldsLine(int index) {
    return Intl.message(
      'Line $index',
      name: 'indicatorFieldsLine',
      desc: '',
      args: [index],
    );
  }

  /// `Period {index}`
  String indicatorFieldsPeriod(int index) {
    return Intl.message(
      'Period $index',
      name: 'indicatorFieldsPeriod',
      desc: '',
      args: [index],
    );
  }

  /// `Line {index} color`
  String indicatorFieldsLineColor(int index) {
    return Intl.message(
      'Line $index color',
      name: 'indicatorFieldsLineColor',
      desc: '',
      args: [index],
    );
  }

  /// `Enter a finite positive integer, at most 100000`
  String get paramInputIntError {
    return Intl.message(
      'Enter a finite positive integer, at most 100000',
      name: 'paramInputIntError',
      desc: '',
      args: [],
    );
  }

  /// `Enter a finite positive number, at most 100000`
  String get paramInputNumberError {
    return Intl.message(
      'Enter a finite positive number, at most 100000',
      name: 'paramInputNumberError',
      desc: '',
      args: [],
    );
  }

  /// `Price axis position`
  String get axisPositionLabel {
    return Intl.message(
      'Price axis position',
      name: 'axisPositionLabel',
      desc: '',
      args: [],
    );
  }

  /// `Right, outside`
  String get axisPositionOutside {
    return Intl.message(
      'Right, outside',
      name: 'axisPositionOutside',
      desc: '',
      args: [],
    );
  }

  /// `Right, inside`
  String get axisPositionInside {
    return Intl.message(
      'Right, inside',
      name: 'axisPositionInside',
      desc: '',
      args: [],
    );
  }

  /// `Left`
  String get axisPositionLeft {
    return Intl.message('Left', name: 'axisPositionLeft', desc: '', args: []);
  }

  /// `Both sides`
  String get axisPositionBoth {
    return Intl.message(
      'Both sides',
      name: 'axisPositionBoth',
      desc: '',
      args: [],
    );
  }

  /// `Axis width`
  String get axisPositionWidth {
    return Intl.message(
      'Axis width',
      name: 'axisPositionWidth',
      desc: '',
      args: [],
    );
  }

  /// `Inside mode takes no width and draws ticks over the candles; outside / left / both reserve an axis strip.`
  String get axisPositionHint {
    return Intl.message(
      'Inside mode takes no width and draws ticks over the candles; outside / left / both reserve an axis strip.',
      name: 'axisPositionHint',
      desc: '',
      args: [],
    );
  }

  /// `Lock current price range`
  String get lockRangeLock {
    return Intl.message(
      'Lock current price range',
      name: 'lockRangeLock',
      desc: '',
      args: [],
    );
  }

  /// `Locked at {min} ~ {max}`
  String lockRangeLockedAt(String min, String max) {
    return Intl.message(
      'Locked at $min ~ $max',
      name: 'lockRangeLockedAt',
      desc: '',
      args: [min, max],
    );
  }

  /// `Once locked, panning and new data no longer rescale prices; dragging the price axis to scale / pan still applies on top of the locked range.`
  String get lockRangeHint {
    return Intl.message(
      'Once locked, panning and new data no longer rescale prices; dragging the price axis to scale / pan still applies on top of the locked range.',
      name: 'lockRangeHint',
      desc: '',
      args: [],
    );
  }

  /// `Saved with saveState; setBars unlocks automatically.`
  String get lockRangeStorageHint {
    return Intl.message(
      'Saved with saveState; setBars unlocks automatically.',
      name: 'lockRangeStorageHint',
      desc: '',
      args: [],
    );
  }

  /// `Log scale logScale`
  String get scaleModeLog {
    return Intl.message(
      'Log scale logScale',
      name: 'scaleModeLog',
      desc: '',
      args: [],
    );
  }

  /// `Percent scale percentScale`
  String get scaleModePercent {
    return Intl.message(
      'Percent scale percentScale',
      name: 'scaleModePercent',
      desc: '',
      args: [],
    );
  }

  /// `Inverted scale invertScale`
  String get scaleModeInvert {
    return Intl.message(
      'Inverted scale invertScale',
      name: 'scaleModeInvert',
      desc: '',
      args: [],
    );
  }

  /// `Log scale falls back to linear when the range is not positive; percent only changes tick labels (the leftmost visible close is 0%).`
  String get scaleModeHint {
    return Intl.message(
      'Log scale falls back to linear when the range is not positive; percent only changes tick labels (the leftmost visible close is 0%).',
      name: 'scaleModeHint',
      desc: '',
      args: [],
    );
  }

  /// `Inversion only affects the main chart: small values on top, and dragging the price axis is reversed too.`
  String get scaleModeInvertHint {
    return Intl.message(
      'Inversion only affects the main chart: small values on top, and dragging the price axis is reversed too.',
      name: 'scaleModeInvertHint',
      desc: '',
      args: [],
    );
  }

  /// `None`
  String get secondaryAxisNone {
    return Intl.message('None', name: 'secondaryAxisNone', desc: '', args: []);
  }

  /// `Overlay on secondary axis`
  String get secondaryAxisOverlay {
    return Intl.message(
      'Overlay on secondary axis',
      name: 'secondaryAxisOverlay',
      desc: '',
      args: [],
    );
  }

  /// `Right (secondary labels inside the left edge)`
  String get secondaryAxisRight {
    return Intl.message(
      'Right (secondary labels inside the left edge)',
      name: 'secondaryAxisRight',
      desc: '',
      args: [],
    );
  }

  /// `Both sides (secondary axis uses the left strip)`
  String get secondaryAxisBoth {
    return Intl.message(
      'Both sides (secondary axis uses the left strip)',
      name: 'secondaryAxisBoth',
      desc: '',
      args: [],
    );
  }

  /// `Secondary axis in % format secondaryFormatter`
  String get secondaryAxisPercent {
    return Intl.message(
      'Secondary axis in % format secondaryFormatter',
      name: 'secondaryAxisPercent',
      desc: '',
      args: [],
    );
  }

  /// `The secondary axis has its own range and does not squeeze prices; the crosshair shows both readings.`
  String get secondaryAxisHint {
    return Intl.message(
      'The secondary axis has its own range and does not squeeze prices; the crosshair shows both readings.',
      name: 'secondaryAxisHint',
      desc: '',
      args: [],
    );
  }

  /// `Initial bars`
  String get dataLimitInitial {
    return Intl.message(
      'Initial bars',
      name: 'dataLimitInitial',
      desc: '',
      args: [],
    );
  }

  /// `History limit maxBars`
  String get dataLimitMaxBars {
    return Intl.message(
      'History limit maxBars',
      name: 'dataLimitMaxBars',
      desc: '',
      args: [],
    );
  }

  /// `Unlimited`
  String get dataLimitUnlimited {
    return Intl.message(
      'Unlimited',
      name: 'dataLimitUnlimited',
      desc: '',
      args: [],
    );
  }

  /// `Regenerate`
  String get dataLimitRegenerate {
    return Intl.message(
      'Regenerate',
      name: 'dataLimitRegenerate',
      desc: '',
      args: [],
    );
  }

  /// `{count} bars now; synthetic data needs no network.`
  String dataLimitCurrent(int count) {
    return Intl.message(
      '$count bars now; synthetic data needs no network.',
      name: 'dataLimitCurrent',
      desc: '',
      args: [count],
    );
  }

  /// `Auto-load when scrolled to the left`
  String get historyAutoLoad {
    return Intl.message(
      'Auto-load when scrolled to the left',
      name: 'historyAutoLoad',
      desc: '',
      args: [],
    );
  }

  /// `Load {count} older bars`
  String historyLoadButton(int count) {
    return Intl.message(
      'Load $count older bars',
      name: 'historyLoadButton',
      desc: '',
      args: [count],
    );
  }

  /// `Loaded {pages} pages, {count} bars in total.`
  String historyStatus(int pages, int count) {
    return Intl.message(
      'Loaded $pages pages, $count bars in total.',
      name: 'historyStatus',
      desc: '',
      args: [pages, count],
    );
  }

  /// `Drag toward history before loading and watch that the viewport does not jump.`
  String get historyHint {
    return Intl.message(
      'Drag toward history before loading and watch that the viewport does not jump.',
      name: 'historyHint',
      desc: '',
      args: [],
    );
  }

  /// `Auto push (append a bar every 5 pushes)`
  String get realtimeAutoPush {
    return Intl.message(
      'Auto push (append a bar every 5 pushes)',
      name: 'realtimeAutoPush',
      desc: '',
      args: [],
    );
  }

  /// `Push interval`
  String get realtimeInterval {
    return Intl.message(
      'Push interval',
      name: 'realtimeInterval',
      desc: '',
      args: [],
    );
  }

  /// `{ms} ms`
  String realtimeMillis(int ms) {
    return Intl.message('$ms ms', name: 'realtimeMillis', desc: '', args: [ms]);
  }

  /// `1 s`
  String get realtimeOneSecond {
    return Intl.message('1 s', name: 'realtimeOneSecond', desc: '', args: []);
  }

  /// `Follow latest autoFollow`
  String get realtimeFollow {
    return Intl.message(
      'Follow latest autoFollow',
      name: 'realtimeFollow',
      desc: '',
      args: [],
    );
  }

  /// `Append a bar`
  String get realtimeAppend {
    return Intl.message(
      'Append a bar',
      name: 'realtimeAppend',
      desc: '',
      args: [],
    );
  }

  /// `Update last price`
  String get realtimeUpdateLast {
    return Intl.message(
      'Update last price',
      name: 'realtimeUpdateLast',
      desc: '',
      args: [],
    );
  }

  /// `With follow off, drag left a bit: pushes will not pull the viewport back to the latest.`
  String get realtimeHint {
    return Intl.message(
      'With follow off, drag left a bit: pushes will not pull the viewport back to the latest.',
      name: 'realtimeHint',
      desc: '',
      args: [],
    );
  }

  /// `Fill`
  String get candleFill {
    return Intl.message('Fill', name: 'candleFill', desc: '', args: []);
  }

  /// `Solid`
  String get candleFillSolid {
    return Intl.message('Solid', name: 'candleFillSolid', desc: '', args: []);
  }

  /// `Hollow up`
  String get candleFillHollowUp {
    return Intl.message(
      'Hollow up',
      name: 'candleFillHollowUp',
      desc: '',
      args: [],
    );
  }

  /// `Hollow down`
  String get candleFillHollowDown {
    return Intl.message(
      'Hollow down',
      name: 'candleFillHollowDown',
      desc: '',
      args: [],
    );
  }

  /// `Separate wick color (grey)`
  String get candleWickColor {
    return Intl.message(
      'Separate wick color (grey)',
      name: 'candleWickColor',
      desc: '',
      args: [],
    );
  }

  /// `Candle border`
  String get candleBorder {
    return Intl.message(
      'Candle border',
      name: 'candleBorder',
      desc: '',
      args: [],
    );
  }

  /// `Last price line + tag`
  String get priceLineShowPrice {
    return Intl.message(
      'Last price line + tag',
      name: 'priceLineShowPrice',
      desc: '',
      args: [],
    );
  }

  /// `Countdown`
  String get priceLineCountdown {
    return Intl.message(
      'Countdown',
      name: 'priceLineCountdown',
      desc: '',
      args: [],
    );
  }

  /// `Bid / ask`
  String get priceLineBook {
    return Intl.message('Bid / ask', name: 'priceLineBook', desc: '', args: []);
  }

  /// `Candle price type`
  String get priceLinePriceType {
    return Intl.message(
      'Candle price type',
      name: 'priceLinePriceType',
      desc: '',
      args: [],
    );
  }

  /// `Futures can draw candles by mark or index price; a hint then shows in the lower left so it is not confused with the last trade price (only the hint changes here, not the data).`
  String get priceLinePriceTypeHint {
    return Intl.message(
      'Futures can draw candles by mark or index price; a hint then shows in the lower left so it is not confused with the last trade price (only the hint changes here, not the data).',
      name: 'priceLinePriceTypeHint',
      desc: '',
      args: [],
    );
  }

  /// `Price animation animatePrice`
  String get priceLineAnimatePrice {
    return Intl.message(
      'Price animation animatePrice',
      name: 'priceLineAnimatePrice',
      desc: '',
      args: [],
    );
  }

  /// `Range animation animateRange`
  String get priceLineAnimateRange {
    return Intl.message(
      'Range animation animateRange',
      name: 'priceLineAnimateRange',
      desc: '',
      args: [],
    );
  }

  /// `High / low labels showHighLow`
  String get priceLineHighLow {
    return Intl.message(
      'High / low labels showHighLow',
      name: 'priceLineHighLow',
      desc: '',
      args: [],
    );
  }

  /// `The library's PriceLineOverlay only draws the dashed line.`
  String get priceLineOverlayHint {
    return Intl.message(
      'The library\'s PriceLineOverlay only draws the dashed line.',
      name: 'priceLineOverlayHint',
      desc: '',
      args: [],
    );
  }

  /// `Price tags, close countdown and best bid / ask on the y axis are drawn by overlayBuilder (the demo's AxisPriceTags).`
  String get priceLineTagsHint {
    return Intl.message(
      'Price tags, close countdown and best bid / ask on the y axis are drawn by overlayBuilder (the demo\'s AxisPriceTags).',
      name: 'priceLineTagsHint',
      desc: '',
      args: [],
    );
  }

  /// `Crowded tags are ordered by price from high to low, ask → last → bid at equal prices; scrolling into history adds a reference tag.`
  String get priceLineStackHint {
    return Intl.message(
      'Crowded tags are ordered by price from high to low, ask → last → bid at equal prices; scrolling into history adds a reference tag.',
      name: 'priceLineStackHint',
      desc: '',
      args: [],
    );
  }

  /// `The synthetic data here makes one bar every 3 seconds, the countdown follows that pace, and the order book is simulated.`
  String get priceLineDataHint {
    return Intl.message(
      'The synthetic data here makes one bar every 3 seconds, the countdown follows that pace, and the order book is simulated.',
      name: 'priceLineDataHint',
      desc: '',
      args: [],
    );
  }

  /// `Price animation slides the last close and price line to the new value in about 200 ms; display only.`
  String get priceLineAnimateHint {
    return Intl.message(
      'Price animation slides the last close and price line to the new value in about 200 ms; display only.',
      name: 'priceLineAnimateHint',
      desc: '',
      args: [],
    );
  }

  /// `Last price`
  String get priceLineTypeLast {
    return Intl.message(
      'Last price',
      name: 'priceLineTypeLast',
      desc: '',
      args: [],
    );
  }

  /// `Mark price`
  String get priceLineTypeMark {
    return Intl.message(
      'Mark price',
      name: 'priceLineTypeMark',
      desc: '',
      args: [],
    );
  }

  /// `Index price`
  String get priceLineTypeIndex {
    return Intl.message(
      'Index price',
      name: 'priceLineTypeIndex',
      desc: '',
      args: [],
    );
  }

  /// `Showing mark price candles`
  String get priceLineTipMark {
    return Intl.message(
      'Showing mark price candles',
      name: 'priceLineTipMark',
      desc: '',
      args: [],
    );
  }

  /// `Showing index price candles`
  String get priceLineTipIndex {
    return Intl.message(
      'Showing index price candles',
      name: 'priceLineTipIndex',
      desc: '',
      args: [],
    );
  }

  /// `Main series`
  String get seriesLabel {
    return Intl.message('Main series', name: 'seriesLabel', desc: '', args: []);
  }

  /// `Candles`
  String get seriesCandle {
    return Intl.message('Candles', name: 'seriesCandle', desc: '', args: []);
  }

  /// `Line`
  String get seriesLine {
    return Intl.message('Line', name: 'seriesLine', desc: '', args: []);
  }

  /// `Area`
  String get seriesArea {
    return Intl.message('Area', name: 'seriesArea', desc: '', args: []);
  }

  /// `{name} (Pro)`
  String seriesProSuffix(String name) {
    return Intl.message(
      '$name (Pro)',
      name: 'seriesProSuffix',
      desc: '',
      args: [name],
    );
  }

  /// `The series only decides how bars are drawn; Renko, line break and other transforms that change the data itself are in Pro's "Data transforms".`
  String get seriesHint {
    return Intl.message(
      'The series only decides how bars are drawn; Renko, line break and other transforms that change the data itself are in Pro\'s "Data transforms".',
      name: 'seriesHint',
      desc: '',
      args: [],
    );
  }

  /// `Save`
  String get commonSave {
    return Intl.message('Save', name: 'commonSave', desc: '', args: []);
  }

  /// `Price decimals`
  String get formatSampleDecimals {
    return Intl.message(
      'Price decimals',
      name: 'formatSampleDecimals',
      desc: '',
      args: [],
    );
  }

  /// `{count} decimals`
  String formatSampleDecimalsOption(int count) {
    return Intl.message(
      '$count decimals',
      name: 'formatSampleDecimalsOption',
      desc: '',
      args: [count],
    );
  }

  /// `Time zone utcOffset`
  String get formatSampleTimezone {
    return Intl.message(
      'Time zone utcOffset',
      name: 'formatSampleTimezone',
      desc: '',
      args: [],
    );
  }

  /// `Custom time format timeFormatter`
  String get formatSampleCustomTime {
    return Intl.message(
      'Custom time format timeFormatter',
      name: 'formatSampleCustomTime',
      desc: '',
      args: [],
    );
  }

  /// `Custom labels`
  String get formatSampleCustomLabels {
    return Intl.message(
      'Custom labels',
      name: 'formatSampleCustomLabels',
      desc: '',
      args: [],
    );
  }

  /// `When timeFormatter is set, it handles the time zone; tooltip and legend text follow labels.`
  String get formatSampleHint {
    return Intl.message(
      'When timeFormatter is set, it handles the time zone; tooltip and legend text follow labels.',
      name: 'formatSampleHint',
      desc: '',
      args: [],
    );
  }

  /// `Show grid showGrid`
  String get gridSampleShowGrid {
    return Intl.message(
      'Show grid showGrid',
      name: 'gridSampleShowGrid',
      desc: '',
      args: [],
    );
  }

  /// `Dashed grid gridLineDash`
  String get gridSampleDash {
    return Intl.message(
      'Dashed grid gridLineDash',
      name: 'gridSampleDash',
      desc: '',
      args: [],
    );
  }

  /// `Axis text size axisTextSize`
  String get gridSampleTextSize {
    return Intl.message(
      'Axis text size axisTextSize',
      name: 'gridSampleTextSize',
      desc: '',
      args: [],
    );
  }

  /// `Grid line width gridLineWidth`
  String get gridSampleLineWidth {
    return Intl.message(
      'Grid line width gridLineWidth',
      name: 'gridSampleLineWidth',
      desc: '',
      args: [],
    );
  }

  /// `Base`
  String get themeSampleBase {
    return Intl.message('Base', name: 'themeSampleBase', desc: '', args: []);
  }

  /// `Follow app brightness`
  String get themeSampleBaseFollow {
    return Intl.message(
      'Follow app brightness',
      name: 'themeSampleBaseFollow',
      desc: '',
      args: [],
    );
  }

  /// `Colors`
  String get themeSamplePalette {
    return Intl.message(
      'Colors',
      name: 'themeSamplePalette',
      desc: '',
      args: [],
    );
  }

  /// `Default`
  String get themeSamplePaletteDefault {
    return Intl.message(
      'Default',
      name: 'themeSamplePaletteDefault',
      desc: '',
      args: [],
    );
  }

  /// `Blue up, orange down`
  String get themeSamplePaletteOcean {
    return Intl.message(
      'Blue up, orange down',
      name: 'themeSamplePaletteOcean',
      desc: '',
      args: [],
    );
  }

  /// `Warm indicator lines`
  String get themeSamplePaletteWarm {
    return Intl.message(
      'Warm indicator lines',
      name: 'themeSamplePaletteWarm',
      desc: '',
      args: [],
    );
  }

  /// `KLineTheme supports toJson / fromJson; copyWith changes only the fields you need.`
  String get themeSampleHint {
    return Intl.message(
      'KLineTheme supports toJson / fromJson; copyWith changes only the fields you need.',
      name: 'themeSampleHint',
      desc: '',
      args: [],
    );
  }

  /// `{year}`
  String timeAxisSampleTickYear(int year) {
    return Intl.message(
      '$year',
      name: 'timeAxisSampleTickYear',
      desc: '',
      args: [year],
    );
  }

  /// `Jan,Feb,Mar,Apr,May,Jun,Jul,Aug,Sep,Oct,Nov,Dec`
  String get timeAxisSampleMonthNames {
    return Intl.message(
      'Jan,Feb,Mar,Apr,May,Jun,Jul,Aug,Sep,Oct,Nov,Dec',
      name: 'timeAxisSampleMonthNames',
      desc: 'Short month names, comma separated, January first',
      args: [],
    );
  }

  /// `{day}`
  String timeAxisSampleTickDay(int day) {
    return Intl.message(
      '$day',
      name: 'timeAxisSampleTickDay',
      desc: '',
      args: [day],
    );
  }

  /// `Tiered time axis tieredTimeAxis`
  String get timeAxisSampleTiered {
    return Intl.message(
      'Tiered time axis tieredTimeAxis',
      name: 'timeAxisSampleTiered',
      desc: '',
      args: [],
    );
  }

  /// `Custom tick text tickFormatter`
  String get timeAxisSampleCustomTick {
    return Intl.message(
      'Custom tick text tickFormatter',
      name: 'timeAxisSampleCustomTick',
      desc: '',
      args: [],
    );
  }

  /// `Time zone utcOffset`
  String get timeAxisSampleTimezone {
    return Intl.message(
      'Time zone utcOffset',
      name: 'timeAxisSampleTimezone',
      desc: '',
      args: [],
    );
  }

  /// `Ticks and vertical grid lines move with the chart; day and month ticks are bold. Zooming picks an interval that does not crowd. Recommended for unevenly spaced data such as renko.`
  String get timeAxisSampleHint {
    return Intl.message(
      'Ticks and vertical grid lines move with the chart; day and month ticks are bold. Zooming picks an interval that does not crowd. Recommended for unevenly spaced data such as renko.',
      name: 'timeAxisSampleHint',
      desc: '',
      args: [],
    );
  }

  /// `Show watermark`
  String get watermarkSampleShow {
    return Intl.message(
      'Show watermark',
      name: 'watermarkSampleShow',
      desc: '',
      args: [],
    );
  }

  /// `Font size`
  String get watermarkSampleSize {
    return Intl.message(
      'Font size',
      name: 'watermarkSampleSize',
      desc: '',
      args: [],
    );
  }

  /// `underlayBuilder receives the RenderContext and can position by the main panel rect; it sits below the candles and does not block gestures.`
  String get watermarkSampleHint {
    return Intl.message(
      'underlayBuilder receives the RenderContext and can position by the main panel rect; it sits below the candles and does not block gestures.',
      name: 'watermarkSampleHint',
      desc: '',
      args: [],
    );
  }

  /// `Close price dots`
  String get customSeriesSampleDots {
    return Intl.message(
      'Close price dots',
      name: 'customSeriesSampleDots',
      desc: '',
      args: [],
    );
  }

  /// `Dot radius`
  String get customSeriesSampleRadius {
    return Intl.message(
      'Dot radius',
      name: 'customSeriesSampleRadius',
      desc: '',
      args: [],
    );
  }

  /// `Implement MainSeries.paint: ctx provides coordinate conversion and the visible range, no library changes needed.`
  String get customSeriesSampleHint {
    return Intl.message(
      'Implement MainSeries.paint: ctx provides coordinate conversion and the visible range, no library changes needed.',
      name: 'customSeriesSampleHint',
      desc: '',
      args: [],
    );
  }

  /// `Show candles above`
  String get depthSampleWithKline {
    return Intl.message(
      'Show candles above',
      name: 'depthSampleWithKline',
      desc: '',
      args: [],
    );
  }

  /// `Levels`
  String get depthSampleLevels {
    return Intl.message(
      'Levels',
      name: 'depthSampleLevels',
      desc: '',
      args: [],
    );
  }

  /// `Bid depth multiplier`
  String get depthSampleBidSkew {
    return Intl.message(
      'Bid depth multiplier',
      name: 'depthSampleBidSkew',
      desc: '',
      args: [],
    );
  }

  /// `Visible {start} - {end}`
  String overlaySampleVisibleRange(int start, int end) {
    return Intl.message(
      'Visible $start - $end',
      name: 'overlaySampleVisibleRange',
      desc: '',
      args: [start, end],
    );
  }

  /// `Latest`
  String get overlaySampleLatest {
    return Intl.message(
      'Latest',
      name: 'overlaySampleLatest',
      desc: '',
      args: [],
    );
  }

  /// `Visible range badge`
  String get overlaySampleRangeBadge {
    return Intl.message(
      'Visible range badge',
      name: 'overlaySampleRangeBadge',
      desc: '',
      args: [],
    );
  }

  /// `Label above the latest candle`
  String get overlaySampleLastBadge {
    return Intl.message(
      'Label above the latest candle',
      name: 'overlaySampleLastBadge',
      desc: '',
      args: [],
    );
  }

  /// `overlayBuilder gets the RenderContext (coordinate conversion, visible area) every frame and returns any widget, which follows panning and zooming.`
  String get overlaySampleHint {
    return Intl.message(
      'overlayBuilder gets the RenderContext (coordinate conversion, visible area) every frame and returns any widget, which follows panning and zooming.',
      name: 'overlaySampleHint',
      desc: '',
      args: [],
    );
  }

  /// `Computing in background…`
  String get computeSampleBusy {
    return Intl.message(
      'Computing in background…',
      name: 'computeSampleBusy',
      desc: '',
      args: [],
    );
  }

  /// `Background isolate asyncCompute`
  String get computeSampleAsync {
    return Intl.message(
      'Background isolate asyncCompute',
      name: 'computeSampleAsync',
      desc: '',
      args: [],
    );
  }

  /// `This page has 10,000 bars; a full computation goes to the background only from 2,000 bars, and on Web it depends on platform support.`
  String get computeSampleHint {
    return Intl.message(
      'This page has 10,000 bars; a full computation goes to the background only from 2,000 bars, and on Web it depends on platform support.',
      name: 'computeSampleHint',
      desc: '',
      args: [],
    );
  }

  /// `Demo indicator error callback`
  String get computeSampleTriggerError {
    return Intl.message(
      'Demo indicator error callback',
      name: 'computeSampleTriggerError',
      desc: '',
      args: [],
    );
  }

  /// `Period`
  String get indicatorParamSamplePeriod {
    return Intl.message(
      'Period',
      name: 'indicatorParamSamplePeriod',
      desc: '',
      args: [],
    );
  }

  /// `Std dev multiplier`
  String get indicatorParamSampleStdDev {
    return Intl.message(
      'Std dev multiplier',
      name: 'indicatorParamSampleStdDev',
      desc: '',
      args: [],
    );
  }

  /// `Short period`
  String get indicatorParamSampleShortPeriod {
    return Intl.message(
      'Short period',
      name: 'indicatorParamSampleShortPeriod',
      desc: '',
      args: [],
    );
  }

  /// `Long period`
  String get indicatorParamSampleLongPeriod {
    return Intl.message(
      'Long period',
      name: 'indicatorParamSampleLongPeriod',
      desc: '',
      args: [],
    );
  }

  /// `Signal period`
  String get indicatorParamSampleSignalPeriod {
    return Intl.message(
      'Signal period',
      name: 'indicatorParamSampleSignalPeriod',
      desc: '',
      args: [],
    );
  }

  /// `K smoothing`
  String get indicatorParamSampleKSmooth {
    return Intl.message(
      'K smoothing',
      name: 'indicatorParamSampleKSmooth',
      desc: '',
      args: [],
    );
  }

  /// `D smoothing`
  String get indicatorParamSampleDSmooth {
    return Intl.message(
      'D smoothing',
      name: 'indicatorParamSampleDSmooth',
      desc: '',
      args: [],
    );
  }

  /// `Changing a parameter changes the indicator id and recomputes it fully; invalid combinations are not applied and the reason is shown.`
  String get indicatorParamSampleHint {
    return Intl.message(
      'Changing a parameter changes the indicator id and recomputes it fully; invalid combinations are not applied and the reason is shown.',
      name: 'indicatorParamSampleHint',
      desc: '',
      args: [],
    );
  }

  /// `Main overlays`
  String get indicatorSwitchSampleMain {
    return Intl.message(
      'Main overlays',
      name: 'indicatorSwitchSampleMain',
      desc: '',
      args: [],
    );
  }

  /// `Sub panels / volume`
  String get indicatorSwitchSampleSub {
    return Intl.message(
      'Sub panels / volume',
      name: 'indicatorSwitchSampleSub',
      desc: '',
      args: [],
    );
  }

  /// `Each indicator's parameters are on its own "Parameters" page; Pro adds 40 advanced indicators.`
  String get indicatorSwitchSampleHint {
    return Intl.message(
      'Each indicator\'s parameters are on its own "Parameters" page; Pro adds 40 advanced indicators.',
      name: 'indicatorSwitchSampleHint',
      desc: '',
      args: [],
    );
  }

  /// `Main panel weight mainFlex`
  String get panelsSampleMainFlex {
    return Intl.message(
      'Main panel weight mainFlex',
      name: 'panelsSampleMainFlex',
      desc: '',
      args: [],
    );
  }

  /// `Weight per sub panel subFlex`
  String get panelsSampleSubFlex {
    return Intl.message(
      'Weight per sub panel subFlex',
      name: 'panelsSampleSubFlex',
      desc: '',
      args: [],
    );
  }

  /// `Drag dividers to resize panelResizable`
  String get panelsSampleResizable {
    return Intl.message(
      'Drag dividers to resize panelResizable',
      name: 'panelsSampleResizable',
      desc: '',
      args: [],
    );
  }

  /// `Dragged heights are kept in ChartConfig.panelWeights and saved / restored with saveState.`
  String get panelsSampleHint {
    return Intl.message(
      'Dragged heights are kept in ChartConfig.panelWeights and saved / restored with saveState.',
      name: 'panelsSampleHint',
      desc: '',
      args: [],
    );
  }

  /// `Bar {index} · close {close}`
  String crosshairSampleCustomTooltip(int index, String close) {
    return Intl.message(
      'Bar $index · close $close',
      name: 'crosshairSampleCustomTooltip',
      desc: '',
      args: [index, close],
    );
  }

  /// `Snap crosshairSnap`
  String get crosshairSampleSnap {
    return Intl.message(
      'Snap crosshairSnap',
      name: 'crosshairSampleSnap',
      desc: '',
      args: [],
    );
  }

  /// `Follow finger`
  String get crosshairSampleSnapFree {
    return Intl.message(
      'Follow finger',
      name: 'crosshairSampleSnapFree',
      desc: '',
      args: [],
    );
  }

  /// `Close price`
  String get crosshairSampleSnapClose {
    return Intl.message(
      'Close price',
      name: 'crosshairSampleSnapClose',
      desc: '',
      args: [],
    );
  }

  /// `Nearest of OHLC`
  String get crosshairSampleSnapOhlc {
    return Intl.message(
      'Nearest of OHLC',
      name: 'crosshairSampleSnapOhlc',
      desc: '',
      args: [],
    );
  }

  /// `Show tooltip`
  String get crosshairSampleShowTooltip {
    return Intl.message(
      'Show tooltip',
      name: 'crosshairSampleShowTooltip',
      desc: '',
      args: [],
    );
  }

  /// `Tooltip style tooltipStyle`
  String get crosshairSampleTooltipStyle {
    return Intl.message(
      'Tooltip style tooltipStyle',
      name: 'crosshairSampleTooltipStyle',
      desc: '',
      args: [],
    );
  }

  /// `One line above the legend`
  String get crosshairSampleStyleInline {
    return Intl.message(
      'One line above the legend',
      name: 'crosshairSampleStyleInline',
      desc: '',
      args: [],
    );
  }

  /// `Floating card`
  String get crosshairSampleStyleCard {
    return Intl.message(
      'Floating card',
      name: 'crosshairSampleStyleCard',
      desc: '',
      args: [],
    );
  }

  /// `Custom tooltip tooltipBuilder`
  String get crosshairSampleCustomBuilder {
    return Intl.message(
      'Custom tooltip tooltipBuilder',
      name: 'crosshairSampleCustomBuilder',
      desc: '',
      args: [],
    );
  }

  /// `On mobile, long-press the chart; on desktop, hover over it.`
  String get crosshairSampleHint {
    return Intl.message(
      'On mobile, long-press the chart; on desktop, hover over it.',
      name: 'crosshairSampleHint',
      desc: '',
      args: [],
    );
  }

  /// `Order price {price} ({time})`
  String gestureSampleOrderPrice(String price, String time) {
    return Intl.message(
      'Order price $price ($time)',
      name: 'gestureSampleOrderPrice',
      desc: '',
      args: [price, time],
    );
  }

  /// `Vertical pan yPan`
  String get gestureSampleYPan {
    return Intl.message(
      'Vertical pan yPan',
      name: 'gestureSampleYPan',
      desc: '',
      args: [],
    );
  }

  /// `No pan, leave it to outer scrolling`
  String get gestureSampleYPanNone {
    return Intl.message(
      'No pan, leave it to outer scrolling',
      name: 'gestureSampleYPanNone',
      desc: '',
      args: [],
    );
  }

  /// `Only on the price axis`
  String get gestureSampleYPanAxis {
    return Intl.message(
      'Only on the price axis',
      name: 'gestureSampleYPanAxis',
      desc: '',
      args: [],
    );
  }

  /// `Whole main panel`
  String get gestureSampleYPanChart {
    return Intl.message(
      'Whole main panel',
      name: 'gestureSampleYPanChart',
      desc: '',
      args: [],
    );
  }

  /// `Drag axis to zoom axisDragScale`
  String get gestureSampleAxisDrag {
    return Intl.message(
      'Drag axis to zoom axisDragScale',
      name: 'gestureSampleAxisDrag',
      desc: '',
      args: [],
    );
  }

  /// `When on, drag the price axis to zoom prices and the time axis to zoom time; double-tap to reset.`
  String get gestureSampleAxisDragHint {
    return Intl.message(
      'When on, drag the price axis to zoom prices and the time axis to zoom time; double-tap to reset.',
      name: 'gestureSampleAxisDragHint',
      desc: '',
      args: [],
    );
  }

  /// `Tap candle for price onBarTap`
  String get gestureSampleBarTap {
    return Intl.message(
      'Tap candle for price onBarTap',
      name: 'gestureSampleBarTap',
      desc: '',
      args: [],
    );
  }

  /// `Tap a candle to get its Bar; trading pages often use it to fill the close price into the order form. With onBarTap set, double-tap no longer resets the y axis.`
  String get gestureSampleBarTapHint {
    return Intl.message(
      'Tap a candle to get its Bar; trading pages often use it to fill the close price into the order form. With onBarTap set, double-tap no longer resets the y axis.',
      name: 'gestureSampleBarTapHint',
      desc: '',
      args: [],
    );
  }

  /// `Tapped: O {open}  H {high}  L {low}  C {close}`
  String gestureSampleTapped(
    String open,
    String high,
    String low,
    String close,
  ) {
    return Intl.message(
      'Tapped: O $open  H $high  L $low  C $close',
      name: 'gestureSampleTapped',
      desc: '',
      args: [open, high, low, close],
    );
  }

  /// `Enable keyboard`
  String get keyboardSampleEnable {
    return Intl.message(
      'Enable keyboard',
      name: 'keyboardSampleEnable',
      desc: '',
      args: [],
    );
  }

  /// `Tap the chart first to focus it. The chart ignores keys while a text field has focus.`
  String get keyboardSampleFocusHint {
    return Intl.message(
      'Tap the chart first to focus it. The chart ignores keys while a text field has focus.',
      name: 'keyboardSampleFocusHint',
      desc: '',
      args: [],
    );
  }

  /// `Left / Right: pan\nUp / Down or + / -: zoom\nHome / End: earliest / latest\nEsc: clear crosshair`
  String get keyboardSampleShortcuts {
    return Intl.message(
      'Left / Right: pan\nUp / Down or + / -: zoom\nHome / End: earliest / latest\nEsc: clear crosshair',
      name: 'keyboardSampleShortcuts',
      desc: '',
      args: [],
    );
  }

  /// `Saved: zoom, indicators, locked coordinates, panel heights and theme.`
  String get storageSampleSaved {
    return Intl.message(
      'Saved: zoom, indicators, locked coordinates, panel heights and theme.',
      name: 'storageSampleSaved',
      desc: '',
      args: [],
    );
  }

  /// `Must contain chart and theme objects`
  String get storageSampleNeedChartTheme {
    return Intl.message(
      'Must contain chart and theme objects',
      name: 'storageSampleNeedChartTheme',
      desc: '',
      args: [],
    );
  }

  /// `chart.indicators must be a list`
  String get storageSampleIndicatorsNotList {
    return Intl.message(
      'chart.indicators must be a list',
      name: 'storageSampleIndicatorsNotList',
      desc: '',
      args: [],
    );
  }

  /// `Restored.`
  String get storageSampleRestored {
    return Intl.message(
      'Restored.',
      name: 'storageSampleRestored',
      desc: '',
      args: [],
    );
  }

  /// `Restore failed: {error}`
  String storageSampleRestoreFailed(String error) {
    return Intl.message(
      'Restore failed: $error',
      name: 'storageSampleRestoreFailed',
      desc: '',
      args: [error],
    );
  }

  /// `Save first, then zoom, drag dividers, change indicators or theme, and finally restore from the text. Market data is not saved.`
  String get storageSampleHint {
    return Intl.message(
      'Save first, then zoom, drag dividers, change indicators or theme, and finally restore from the text. Market data is not saved.',
      name: 'storageSampleHint',
      desc: '',
      args: [],
    );
  }

  /// `Restore from text`
  String get storageSampleRestore {
    return Intl.message(
      'Restore from text',
      name: 'storageSampleRestore',
      desc: '',
      args: [],
    );
  }

  /// `Swap indicators`
  String get storageSampleSwapIndicators {
    return Intl.message(
      'Swap indicators',
      name: 'storageSampleSwapIndicators',
      desc: '',
      args: [],
    );
  }

  /// `Switch theme`
  String get storageSampleSwitchTheme {
    return Intl.message(
      'Switch theme',
      name: 'storageSampleSwitchTheme',
      desc: '',
      args: [],
    );
  }

  /// `Saved JSON`
  String get storageSampleJsonHint {
    return Intl.message(
      'Saved JSON',
      name: 'storageSampleJsonHint',
      desc: '',
      args: [],
    );
  }

  /// `Reset`
  String get commonReset {
    return Intl.message('Reset', name: 'commonReset', desc: '', args: []);
  }

  /// `Connecting…`
  String get liveConnecting {
    return Intl.message(
      'Connecting…',
      name: 'liveConnecting',
      desc: '',
      args: [],
    );
  }

  /// `Log segment`
  String get liveLogSegment {
    return Intl.message(
      'Log segment',
      name: 'liveLogSegment',
      desc: '',
      args: [],
    );
  }

  /// `Switch market`
  String get liveSwitchMarket {
    return Intl.message(
      'Switch market',
      name: 'liveSwitchMarket',
      desc: '',
      args: [],
    );
  }

  /// `Chart Settings`
  String get liveChartSettings {
    return Intl.message(
      'Chart Settings',
      name: 'liveChartSettings',
      desc: '',
      args: [],
    );
  }

  /// `Tap to retry`
  String get liveTapToRetry {
    return Intl.message(
      'Tap to retry',
      name: 'liveTapToRetry',
      desc: '',
      args: [],
    );
  }

  /// `Indicator parameters`
  String get liveIndicatorParams {
    return Intl.message(
      'Indicator parameters',
      name: 'liveIndicatorParams',
      desc: '',
      args: [],
    );
  }

  /// `Configure`
  String get liveGoToSettings {
    return Intl.message(
      'Configure',
      name: 'liveGoToSettings',
      desc: '',
      args: [],
    );
  }

  /// `Display`
  String get liveSectionDisplay {
    return Intl.message(
      'Display',
      name: 'liveSectionDisplay',
      desc: '',
      args: [],
    );
  }

  /// `Last price`
  String get liveLastPrice {
    return Intl.message(
      'Last price',
      name: 'liveLastPrice',
      desc: '',
      args: [],
    );
  }

  /// `Countdown`
  String get liveCountdown {
    return Intl.message('Countdown', name: 'liveCountdown', desc: '', args: []);
  }

  /// `Bid/ask`
  String get liveBookPrice {
    return Intl.message('Bid/ask', name: 'liveBookPrice', desc: '', args: []);
  }

  /// `Y-axis outside`
  String get liveYAxisOutside {
    return Intl.message(
      'Y-axis outside',
      name: 'liveYAxisOutside',
      desc: '',
      args: [],
    );
  }

  /// `Follow latest`
  String get liveAutoFollow {
    return Intl.message(
      'Follow latest',
      name: 'liveAutoFollow',
      desc: '',
      args: [],
    );
  }

  /// `Chart`
  String get liveSectionChart {
    return Intl.message('Chart', name: 'liveSectionChart', desc: '', args: []);
  }

  /// `Chart type`
  String get liveChartType {
    return Intl.message(
      'Chart type',
      name: 'liveChartType',
      desc: '',
      args: [],
    );
  }

  /// `Candlestick`
  String get liveSeriesCandle {
    return Intl.message(
      'Candlestick',
      name: 'liveSeriesCandle',
      desc: '',
      args: [],
    );
  }

  /// `Line`
  String get liveSeriesLine {
    return Intl.message('Line', name: 'liveSeriesLine', desc: '', args: []);
  }

  /// `Area`
  String get liveSeriesArea {
    return Intl.message('Area', name: 'liveSeriesArea', desc: '', args: []);
  }

  /// `Heikin-Ashi`
  String get liveHeikinAshi {
    return Intl.message(
      'Heikin-Ashi',
      name: 'liveHeikinAshi',
      desc: '',
      args: [],
    );
  }

  /// `Log scale`
  String get liveLogScale {
    return Intl.message('Log scale', name: 'liveLogScale', desc: '', args: []);
  }

  /// `Percent scale`
  String get livePercentScale {
    return Intl.message(
      'Percent scale',
      name: 'livePercentScale',
      desc: '',
      args: [],
    );
  }

  /// `Time zone`
  String get liveTimeZone {
    return Intl.message('Time zone', name: 'liveTimeZone', desc: '', args: []);
  }

  /// `Device`
  String get liveTimeZoneDevice {
    return Intl.message(
      'Device',
      name: 'liveTimeZoneDevice',
      desc: '',
      args: [],
    );
  }

  /// `UTC+8 Shanghai`
  String get liveTimeZoneShanghai {
    return Intl.message(
      'UTC+8 Shanghai',
      name: 'liveTimeZoneShanghai',
      desc: '',
      args: [],
    );
  }

  /// `UTC-5 New York (winter)`
  String get liveTimeZoneNewYork {
    return Intl.message(
      'UTC-5 New York (winter)',
      name: 'liveTimeZoneNewYork',
      desc: '',
      args: [],
    );
  }

  /// `Chart height`
  String get liveSectionChartHeight {
    return Intl.message(
      'Chart height',
      name: 'liveSectionChartHeight',
      desc: '',
      args: [],
    );
  }

  /// `More`
  String get liveIntervalMore {
    return Intl.message('More', name: 'liveIntervalMore', desc: '', args: []);
  }

  /// `1m`
  String get liveInterval1m {
    return Intl.message('1m', name: 'liveInterval1m', desc: '', args: []);
  }

  /// `3m`
  String get liveInterval3m {
    return Intl.message('3m', name: 'liveInterval3m', desc: '', args: []);
  }

  /// `5m`
  String get liveInterval5m {
    return Intl.message('5m', name: 'liveInterval5m', desc: '', args: []);
  }

  /// `15m`
  String get liveInterval15m {
    return Intl.message('15m', name: 'liveInterval15m', desc: '', args: []);
  }

  /// `30m`
  String get liveInterval30m {
    return Intl.message('30m', name: 'liveInterval30m', desc: '', args: []);
  }

  /// `1h`
  String get liveInterval1h {
    return Intl.message('1h', name: 'liveInterval1h', desc: '', args: []);
  }

  /// `2h`
  String get liveInterval2h {
    return Intl.message('2h', name: 'liveInterval2h', desc: '', args: []);
  }

  /// `4h`
  String get liveInterval4h {
    return Intl.message('4h', name: 'liveInterval4h', desc: '', args: []);
  }

  /// `6h`
  String get liveInterval6h {
    return Intl.message('6h', name: 'liveInterval6h', desc: '', args: []);
  }

  /// `8h`
  String get liveInterval8h {
    return Intl.message('8h', name: 'liveInterval8h', desc: '', args: []);
  }

  /// `12h`
  String get liveInterval12h {
    return Intl.message('12h', name: 'liveInterval12h', desc: '', args: []);
  }

  /// `1D`
  String get liveInterval1d {
    return Intl.message('1D', name: 'liveInterval1d', desc: '', args: []);
  }

  /// `3D`
  String get liveInterval3d {
    return Intl.message('3D', name: 'liveInterval3d', desc: '', args: []);
  }

  /// `1W`
  String get liveInterval1w {
    return Intl.message('1W', name: 'liveInterval1w', desc: '', args: []);
  }

  /// `1M`
  String get liveInterval1M {
    return Intl.message('1M', name: 'liveInterval1M', desc: '', args: []);
  }

  /// `Failed to load market data: {reason}`
  String liveLoadFailed(String reason) {
    return Intl.message(
      'Failed to load market data: $reason',
      name: 'liveLoadFailed',
      desc: '',
      args: [reason],
    );
  }

  /// `please retry`
  String get livePleaseRetry {
    return Intl.message(
      'please retry',
      name: 'livePleaseRetry',
      desc: '',
      args: [],
    );
  }

  /// `No data returned`
  String get liveNoData {
    return Intl.message(
      'No data returned',
      name: 'liveNoData',
      desc: '',
      args: [],
    );
  }

  /// `Data transforms`
  String get proSampleTransforms {
    return Intl.message(
      'Data transforms',
      name: 'proSampleTransforms',
      desc: '',
      args: [],
    );
  }

  /// `Advanced indicators`
  String get proSampleIndicators {
    return Intl.message(
      'Advanced indicators',
      name: 'proSampleIndicators',
      desc: '',
      args: [],
    );
  }

  /// `Drawing tools`
  String get proSampleDrawing {
    return Intl.message(
      'Drawing tools',
      name: 'proSampleDrawing',
      desc: '',
      args: [],
    );
  }

  /// `Order lines`
  String get proSampleOrders {
    return Intl.message(
      'Order lines',
      name: 'proSampleOrders',
      desc: '',
      args: [],
    );
  }

  /// `Price alerts`
  String get proSampleAlerts {
    return Intl.message(
      'Price alerts',
      name: 'proSampleAlerts',
      desc: '',
      args: [],
    );
  }

  /// `Fill markers`
  String get proSampleFills {
    return Intl.message(
      'Fill markers',
      name: 'proSampleFills',
      desc: '',
      args: [],
    );
  }

  /// `Position and measure`
  String get proSamplePosition {
    return Intl.message(
      'Position and measure',
      name: 'proSamplePosition',
      desc: '',
      args: [],
    );
  }

  /// `Replay`
  String get proSampleReplay {
    return Intl.message('Replay', name: 'proSampleReplay', desc: '', args: []);
  }

  /// `Linked charts`
  String get proSampleSync {
    return Intl.message(
      'Linked charts',
      name: 'proSampleSync',
      desc: '',
      args: [],
    );
  }

  /// `Compare overlay`
  String get proSampleCompare {
    return Intl.message(
      'Compare overlay',
      name: 'proSampleCompare',
      desc: '',
      args: [],
    );
  }

  /// `OHLC bars`
  String get proSeriesOhlc {
    return Intl.message('OHLC bars', name: 'proSeriesOhlc', desc: '', args: []);
  }

  /// `Volume candles`
  String get proSeriesVolCandle {
    return Intl.message(
      'Volume candles',
      name: 'proSeriesVolCandle',
      desc: '',
      args: [],
    );
  }

  /// `Line with markers`
  String get proSeriesMarkers {
    return Intl.message(
      'Line with markers',
      name: 'proSeriesMarkers',
      desc: '',
      args: [],
    );
  }

  /// `Step line`
  String get proSeriesStep {
    return Intl.message('Step line', name: 'proSeriesStep', desc: '', args: []);
  }

  /// `HLC area`
  String get proSeriesHlcArea {
    return Intl.message(
      'HLC area',
      name: 'proSeriesHlcArea',
      desc: '',
      args: [],
    );
  }

  /// `Baseline`
  String get proSeriesBaseline {
    return Intl.message(
      'Baseline',
      name: 'proSeriesBaseline',
      desc: '',
      args: [],
    );
  }

  /// `Columns`
  String get proSeriesColumn {
    return Intl.message('Columns', name: 'proSeriesColumn', desc: '', args: []);
  }

  /// `High-low`
  String get proSeriesHiLo {
    return Intl.message('High-low', name: 'proSeriesHiLo', desc: '', args: []);
  }

  /// `Main chart (Pro)`
  String get proGroupMain {
    return Intl.message(
      'Main chart (Pro)',
      name: 'proGroupMain',
      desc: '',
      args: [],
    );
  }

  /// `Sub chart (Pro)`
  String get proGroupSub {
    return Intl.message(
      'Sub chart (Pro)',
      name: 'proGroupSub',
      desc: '',
      args: [],
    );
  }

  /// `Weighted moving average`
  String get proIndicatorWma {
    return Intl.message(
      'Weighted moving average',
      name: 'proIndicatorWma',
      desc: '',
      args: [],
    );
  }

  /// `Parabolic SAR`
  String get proIndicatorSar {
    return Intl.message(
      'Parabolic SAR',
      name: 'proIndicatorSar',
      desc: '',
      args: [],
    );
  }

  /// `Supertrend`
  String get proIndicatorSt {
    return Intl.message(
      'Supertrend',
      name: 'proIndicatorSt',
      desc: '',
      args: [],
    );
  }

  /// `Keltner channel`
  String get proIndicatorKc {
    return Intl.message(
      'Keltner channel',
      name: 'proIndicatorKc',
      desc: '',
      args: [],
    );
  }

  /// `Donchian channel`
  String get proIndicatorDc {
    return Intl.message(
      'Donchian channel',
      name: 'proIndicatorDc',
      desc: '',
      args: [],
    );
  }

  /// `Ichimoku cloud`
  String get proIndicatorIchi {
    return Intl.message(
      'Ichimoku cloud',
      name: 'proIndicatorIchi',
      desc: '',
      args: [],
    );
  }

  /// `Double EMA`
  String get proIndicatorDema {
    return Intl.message(
      'Double EMA',
      name: 'proIndicatorDema',
      desc: '',
      args: [],
    );
  }

  /// `Triple EMA`
  String get proIndicatorTema {
    return Intl.message(
      'Triple EMA',
      name: 'proIndicatorTema',
      desc: '',
      args: [],
    );
  }

  /// `Hull moving average`
  String get proIndicatorHma {
    return Intl.message(
      'Hull moving average',
      name: 'proIndicatorHma',
      desc: '',
      args: [],
    );
  }

  /// `Volume-weighted MA`
  String get proIndicatorVwma {
    return Intl.message(
      'Volume-weighted MA',
      name: 'proIndicatorVwma',
      desc: '',
      args: [],
    );
  }

  /// `Kaufman adaptive MA`
  String get proIndicatorKama {
    return Intl.message(
      'Kaufman adaptive MA',
      name: 'proIndicatorKama',
      desc: '',
      args: [],
    );
  }

  /// `Arnaud Legoux MA`
  String get proIndicatorAlma {
    return Intl.message(
      'Arnaud Legoux MA',
      name: 'proIndicatorAlma',
      desc: '',
      args: [],
    );
  }

  /// `Least squares MA`
  String get proIndicatorLsma {
    return Intl.message(
      'Least squares MA',
      name: 'proIndicatorLsma',
      desc: '',
      args: [],
    );
  }

  /// `Pivot points`
  String get proIndicatorPivot {
    return Intl.message(
      'Pivot points',
      name: 'proIndicatorPivot',
      desc: '',
      args: [],
    );
  }

  /// `ZigZag`
  String get proIndicatorZigzag {
    return Intl.message(
      'ZigZag',
      name: 'proIndicatorZigzag',
      desc: '',
      args: [],
    );
  }

  /// `Commodity channel index`
  String get proIndicatorCci {
    return Intl.message(
      'Commodity channel index',
      name: 'proIndicatorCci',
      desc: '',
      args: [],
    );
  }

  /// `On-balance volume`
  String get proIndicatorObv {
    return Intl.message(
      'On-balance volume',
      name: 'proIndicatorObv',
      desc: '',
      args: [],
    );
  }

  /// `Stochastic RSI`
  String get proIndicatorStochRsi {
    return Intl.message(
      'Stochastic RSI',
      name: 'proIndicatorStochRsi',
      desc: '',
      args: [],
    );
  }

  /// `Average true range`
  String get proIndicatorAtr {
    return Intl.message(
      'Average true range',
      name: 'proIndicatorAtr',
      desc: '',
      args: [],
    );
  }

  /// `Directional movement index`
  String get proIndicatorDmi {
    return Intl.message(
      'Directional movement index',
      name: 'proIndicatorDmi',
      desc: '',
      args: [],
    );
  }

  /// `Money flow index`
  String get proIndicatorMfi {
    return Intl.message(
      'Money flow index',
      name: 'proIndicatorMfi',
      desc: '',
      args: [],
    );
  }

  /// `Chaikin money flow`
  String get proIndicatorCmf {
    return Intl.message(
      'Chaikin money flow',
      name: 'proIndicatorCmf',
      desc: '',
      args: [],
    );
  }

  /// `Rate of change`
  String get proIndicatorRoc {
    return Intl.message(
      'Rate of change',
      name: 'proIndicatorRoc',
      desc: '',
      args: [],
    );
  }

  /// `Momentum`
  String get proIndicatorMtm {
    return Intl.message(
      'Momentum',
      name: 'proIndicatorMtm',
      desc: '',
      args: [],
    );
  }

  /// `Triple exponential average`
  String get proIndicatorTrix {
    return Intl.message(
      'Triple exponential average',
      name: 'proIndicatorTrix',
      desc: '',
      args: [],
    );
  }

  /// `Stochastic oscillator`
  String get proIndicatorStoch {
    return Intl.message(
      'Stochastic oscillator',
      name: 'proIndicatorStoch',
      desc: '',
      args: [],
    );
  }

  /// `Aroon`
  String get proIndicatorAroon {
    return Intl.message('Aroon', name: 'proIndicatorAroon', desc: '', args: []);
  }

  /// `Standard deviation`
  String get proIndicatorStd {
    return Intl.message(
      'Standard deviation',
      name: 'proIndicatorStd',
      desc: '',
      args: [],
    );
  }

  /// `Historical volatility`
  String get proIndicatorHv {
    return Intl.message(
      'Historical volatility',
      name: 'proIndicatorHv',
      desc: '',
      args: [],
    );
  }

  /// `Accumulation/distribution`
  String get proIndicatorAd {
    return Intl.message(
      'Accumulation/distribution',
      name: 'proIndicatorAd',
      desc: '',
      args: [],
    );
  }

  /// `Chaikin oscillator`
  String get proIndicatorCho {
    return Intl.message(
      'Chaikin oscillator',
      name: 'proIndicatorCho',
      desc: '',
      args: [],
    );
  }

  /// `Bollinger %B`
  String get proIndicatorPercentB {
    return Intl.message(
      'Bollinger %B',
      name: 'proIndicatorPercentB',
      desc: '',
      args: [],
    );
  }

  /// `Bollinger bandwidth`
  String get proIndicatorBbw {
    return Intl.message(
      'Bollinger bandwidth',
      name: 'proIndicatorBbw',
      desc: '',
      args: [],
    );
  }

  /// `Vortex indicator`
  String get proIndicatorVortex {
    return Intl.message(
      'Vortex indicator',
      name: 'proIndicatorVortex',
      desc: '',
      args: [],
    );
  }

  /// `Choppiness index`
  String get proIndicatorChop {
    return Intl.message(
      'Choppiness index',
      name: 'proIndicatorChop',
      desc: '',
      args: [],
    );
  }

  /// `Awesome oscillator`
  String get proIndicatorAo {
    return Intl.message(
      'Awesome oscillator',
      name: 'proIndicatorAo',
      desc: '',
      args: [],
    );
  }

  /// `Percentage price oscillator`
  String get proIndicatorPpo {
    return Intl.message(
      'Percentage price oscillator',
      name: 'proIndicatorPpo',
      desc: '',
      args: [],
    );
  }

  /// `Fisher transform`
  String get proIndicatorFisher {
    return Intl.message(
      'Fisher transform',
      name: 'proIndicatorFisher',
      desc: '',
      args: [],
    );
  }

  /// `Request cancelled`
  String get netRequestCancelled {
    return Intl.message(
      'Request cancelled',
      name: 'netRequestCancelled',
      desc: '',
      args: [],
    );
  }

  /// `Server error`
  String get netServerError {
    return Intl.message(
      'Server error',
      name: 'netServerError',
      desc: '',
      args: [],
    );
  }

  /// `Connection timed out`
  String get netConnectTimeout {
    return Intl.message(
      'Connection timed out',
      name: 'netConnectTimeout',
      desc: '',
      args: [],
    );
  }

  /// `Send timed out`
  String get netSendTimeout {
    return Intl.message(
      'Send timed out',
      name: 'netSendTimeout',
      desc: '',
      args: [],
    );
  }

  /// `Receive timed out`
  String get netReceiveTimeout {
    return Intl.message(
      'Receive timed out',
      name: 'netReceiveTimeout',
      desc: '',
      args: [],
    );
  }

  /// `Network connection failed`
  String get netConnectionFailed {
    return Intl.message(
      'Network connection failed',
      name: 'netConnectionFailed',
      desc: '',
      args: [],
    );
  }

  /// `S`
  String get axisTagAsk {
    return Intl.message('S', name: 'axisTagAsk', desc: '', args: []);
  }

  /// `B`
  String get axisTagBid {
    return Intl.message('B', name: 'axisTagBid', desc: '', args: []);
  }

  /// `{name} params not applied: {reason}`
  String indicatorParamsNotApplied(String name, String reason) {
    return Intl.message(
      '$name params not applied: $reason',
      name: 'indicatorParamsNotApplied',
      desc: '',
      args: [name, reason],
    );
  }

  /// `Line`
  String get indicatorLine {
    return Intl.message('Line', name: 'indicatorLine', desc: '', args: []);
  }

  /// `Value`
  String get indicatorReferenceValue {
    return Intl.message(
      'Value',
      name: 'indicatorReferenceValue',
      desc: '',
      args: [],
    );
  }

  /// `Color`
  String get indicatorColor {
    return Intl.message('Color', name: 'indicatorColor', desc: '', args: []);
  }

  /// `Period`
  String get indicatorPeriod {
    return Intl.message('Period', name: 'indicatorPeriod', desc: '', args: []);
  }

  /// `Std dev multiplier`
  String get indicatorStdDevMultiplier {
    return Intl.message(
      'Std dev multiplier',
      name: 'indicatorStdDevMultiplier',
      desc: '',
      args: [],
    );
  }

  /// `Short period`
  String get indicatorShortPeriod {
    return Intl.message(
      'Short period',
      name: 'indicatorShortPeriod',
      desc: '',
      args: [],
    );
  }

  /// `Long period`
  String get indicatorLongPeriod {
    return Intl.message(
      'Long period',
      name: 'indicatorLongPeriod',
      desc: '',
      args: [],
    );
  }

  /// `Signal period`
  String get indicatorSignalPeriod {
    return Intl.message(
      'Signal period',
      name: 'indicatorSignalPeriod',
      desc: '',
      args: [],
    );
  }

  /// `Period N`
  String get indicatorPeriodN {
    return Intl.message(
      'Period N',
      name: 'indicatorPeriodN',
      desc: '',
      args: [],
    );
  }

  /// `Indicator Settings`
  String get indicatorSettingsTitle {
    return Intl.message(
      'Indicator Settings',
      name: 'indicatorSettingsTitle',
      desc: '',
      args: [],
    );
  }

  /// `Main chart`
  String get indicatorGroupMain {
    return Intl.message(
      'Main chart',
      name: 'indicatorGroupMain',
      desc: '',
      args: [],
    );
  }

  /// `Sub chart`
  String get indicatorGroupSub {
    return Intl.message(
      'Sub chart',
      name: 'indicatorGroupSub',
      desc: '',
      args: [],
    );
  }

  /// `Moving average`
  String get indicatorMaDesc {
    return Intl.message(
      'Moving average',
      name: 'indicatorMaDesc',
      desc: '',
      args: [],
    );
  }

  /// `Exponential moving average`
  String get indicatorEmaDesc {
    return Intl.message(
      'Exponential moving average',
      name: 'indicatorEmaDesc',
      desc: '',
      args: [],
    );
  }

  /// `Bollinger bands`
  String get indicatorBollDesc {
    return Intl.message(
      'Bollinger bands',
      name: 'indicatorBollDesc',
      desc: '',
      args: [],
    );
  }

  /// `Moving average convergence divergence`
  String get indicatorMacdDesc {
    return Intl.message(
      'Moving average convergence divergence',
      name: 'indicatorMacdDesc',
      desc: '',
      args: [],
    );
  }

  /// `Stochastic oscillator`
  String get indicatorKdjDesc {
    return Intl.message(
      'Stochastic oscillator',
      name: 'indicatorKdjDesc',
      desc: '',
      args: [],
    );
  }

  /// `Relative strength index`
  String get indicatorRsiDesc {
    return Intl.message(
      'Relative strength index',
      name: 'indicatorRsiDesc',
      desc: '',
      args: [],
    );
  }

  /// `Williams %R`
  String get indicatorWrDesc {
    return Intl.message(
      'Williams %R',
      name: 'indicatorWrDesc',
      desc: '',
      args: [],
    );
  }

  /// `Pro feature`
  String get proLockFeature {
    return Intl.message(
      'Pro feature',
      name: 'proLockFeature',
      desc: '',
      args: [],
    );
  }

  /// `Switch to light theme`
  String get themeSwitchToLight {
    return Intl.message(
      'Switch to light theme',
      name: 'themeSwitchToLight',
      desc: '',
      args: [],
    );
  }

  /// `Switch to dark theme`
  String get themeSwitchToDark {
    return Intl.message(
      'Switch to dark theme',
      name: 'themeSwitchToDark',
      desc: '',
      args: [],
    );
  }

  /// `Stock market`
  String get homeStocks {
    return Intl.message('Stock market', name: 'homeStocks', desc: '', args: []);
  }

  /// `Stocks`
  String get stockTitle {
    return Intl.message('Stocks', name: 'stockTitle', desc: '', args: []);
  }

  /// `A-share`
  String get stockMarketA {
    return Intl.message('A-share', name: 'stockMarketA', desc: '', args: []);
  }

  /// `HK`
  String get stockMarketHk {
    return Intl.message('HK', name: 'stockMarketHk', desc: '', args: []);
  }

  /// `US`
  String get stockMarketUs {
    return Intl.message('US', name: 'stockMarketUs', desc: '', args: []);
  }

  /// `Intraday`
  String get stockPeriodIntraday {
    return Intl.message(
      'Intraday',
      name: 'stockPeriodIntraday',
      desc: '',
      args: [],
    );
  }

  /// `5 days`
  String get stockPeriodFiveDay {
    return Intl.message(
      '5 days',
      name: 'stockPeriodFiveDay',
      desc: '',
      args: [],
    );
  }

  /// `Daily`
  String get stockPeriodDay {
    return Intl.message('Daily', name: 'stockPeriodDay', desc: '', args: []);
  }

  /// `Weekly`
  String get stockPeriodWeek {
    return Intl.message('Weekly', name: 'stockPeriodWeek', desc: '', args: []);
  }

  /// `Monthly`
  String get stockPeriodMonth {
    return Intl.message(
      'Monthly',
      name: 'stockPeriodMonth',
      desc: '',
      args: [],
    );
  }

  /// `Unadjusted`
  String get stockAdjustNone {
    return Intl.message(
      'Unadjusted',
      name: 'stockAdjustNone',
      desc: '',
      args: [],
    );
  }

  /// `Forward adj.`
  String get stockAdjustForward {
    return Intl.message(
      'Forward adj.',
      name: 'stockAdjustForward',
      desc: '',
      args: [],
    );
  }

  /// `Backward adj.`
  String get stockAdjustBackward {
    return Intl.message(
      'Backward adj.',
      name: 'stockAdjustBackward',
      desc: '',
      args: [],
    );
  }

  /// `Avg`
  String get stockAverage {
    return Intl.message('Avg', name: 'stockAverage', desc: '', args: []);
  }

  /// `Prev close`
  String get stockPrevClose {
    return Intl.message(
      'Prev close',
      name: 'stockPrevClose',
      desc: '',
      args: [],
    );
  }

  /// `Limit up`
  String get stockLimitUp {
    return Intl.message('Limit up', name: 'stockLimitUp', desc: '', args: []);
  }

  /// `Limit down`
  String get stockLimitDown {
    return Intl.message(
      'Limit down',
      name: 'stockLimitDown',
      desc: '',
      args: [],
    );
  }

  /// `LU`
  String get stockLimitUpShort {
    return Intl.message('LU', name: 'stockLimitUpShort', desc: '', args: []);
  }

  /// `LD`
  String get stockLimitDownShort {
    return Intl.message('LD', name: 'stockLimitDownShort', desc: '', args: []);
  }

  /// `Trading`
  String get stockTrading {
    return Intl.message('Trading', name: 'stockTrading', desc: '', args: []);
  }

  /// `Closed`
  String get stockClosed {
    return Intl.message('Closed', name: 'stockClosed', desc: '', args: []);
  }

  /// `Red up, green down`
  String get stockRedUp {
    return Intl.message(
      'Red up, green down',
      name: 'stockRedUp',
      desc: '',
      args: [],
    );
  }

  /// `Data: Eastmoney, delayed quotes, for demo only`
  String get stockDataSource {
    return Intl.message(
      'Data: Eastmoney, delayed quotes, for demo only',
      name: 'stockDataSource',
      desc: '',
      args: [],
    );
  }

  /// `Stocks`
  String get sampleCategoryStocks {
    return Intl.message(
      'Stocks',
      name: 'sampleCategoryStocks',
      desc: '',
      args: [],
    );
  }

  /// `Intraday chart`
  String get sampleIntradayTitle {
    return Intl.message(
      'Intraday chart',
      name: 'sampleIntradayTitle',
      desc: '',
      args: [],
    );
  }

  /// `One trading day in fixed minute slots: lunch break without gaps, average price line, previous-close baseline with percent on the right, limit lines.`
  String get sampleIntradayDesc {
    return Intl.message(
      'One trading day in fixed minute slots: lunch break without gaps, average price line, previous-close baseline with percent on the right, limit lines.',
      name: 'sampleIntradayDesc',
      desc: '',
      args: [],
    );
  }

  /// `Market`
  String get intradayMarket {
    return Intl.message('Market', name: 'intradayMarket', desc: '', args: []);
  }

  /// `Average price line`
  String get intradayAverage {
    return Intl.message(
      'Average price line',
      name: 'intradayAverage',
      desc: '',
      args: [],
    );
  }

  /// `Percent on the right axis`
  String get intradayPercent {
    return Intl.message(
      'Percent on the right axis',
      name: 'intradayPercent',
      desc: '',
      args: [],
    );
  }

  /// `Limit up / down lines`
  String get intradayLimits {
    return Intl.message(
      'Limit up / down lines',
      name: 'intradayLimits',
      desc: '',
      args: [],
    );
  }

  /// `Simulate live minutes`
  String get intradayLive {
    return Intl.message(
      'Simulate live minutes',
      name: 'intradayLive',
      desc: '',
      args: [],
    );
  }

  /// `slotAxis fixes the x axis to the session's minutes, so the chart does not scroll or zoom; slots after the latest minute stay empty.`
  String get intradayHint {
    return Intl.message(
      'slotAxis fixes the x axis to the session\'s minutes, so the chart does not scroll or zoom; slots after the latest minute stay empty.',
      name: 'intradayHint',
      desc: '',
      args: [],
    );
  }

  /// `mainRange keeps the range symmetric around the previous close and stretches it to include the limit prices.`
  String get intradayRangeHint {
    return Intl.message(
      'mainRange keeps the range symmetric around the previous close and stretches it to include the limit prices.',
      name: 'intradayRangeHint',
      desc: '',
      args: [],
    );
  }

  /// `Daily bars and limits`
  String get sampleStockDailyTitle {
    return Intl.message(
      'Daily bars and limits',
      name: 'sampleStockDailyTitle',
      desc: '',
      args: [],
    );
  }

  /// `Daily bars over trading days only (weekends take no space), limit up / down marks and the red-up color convention.`
  String get sampleStockDailyDesc {
    return Intl.message(
      'Daily bars over trading days only (weekends take no space), limit up / down marks and the red-up color convention.',
      name: 'sampleStockDailyDesc',
      desc: '',
      args: [],
    );
  }

  /// `Limit ratio`
  String get stockLimitBoard {
    return Intl.message(
      'Limit ratio',
      name: 'stockLimitBoard',
      desc: '',
      args: [],
    );
  }

  /// `Main board ±10%`
  String get stockBoardMain {
    return Intl.message(
      'Main board ±10%',
      name: 'stockBoardMain',
      desc: '',
      args: [],
    );
  }

  /// `ChiNext / STAR ±20%`
  String get stockBoardGrowth {
    return Intl.message(
      'ChiNext / STAR ±20%',
      name: 'stockBoardGrowth',
      desc: '',
      args: [],
    );
  }

  /// `ST ±5%`
  String get stockBoardSt {
    return Intl.message('ST ±5%', name: 'stockBoardSt', desc: '', args: []);
  }

  /// `Limit marks`
  String get stockLimitMarks {
    return Intl.message(
      'Limit marks',
      name: 'stockLimitMarks',
      desc: '',
      args: [],
    );
  }

  /// `LimitMarksOverlay compares each close with the previous close; PriceLimit rounds half up to the cent like the exchange.`
  String get stockDailyHint {
    return Intl.message(
      'LimitMarksOverlay compares each close with the previous close; PriceLimit rounds half up to the cent like the exchange.',
      name: 'stockDailyHint',
      desc: '',
      args: [],
    );
  }

  /// `Five-day intraday`
  String get proSampleFiveDay {
    return Intl.message(
      'Five-day intraday',
      name: 'proSampleFiveDay',
      desc: '',
      args: [],
    );
  }

  /// `Price adjustment`
  String get proSampleAdjust {
    return Intl.message(
      'Price adjustment',
      name: 'proSampleAdjust',
      desc: '',
      args: [],
    );
  }

  /// `Fit limits in range`
  String get intradayLimitsInRange {
    return Intl.message(
      'Fit limits in range',
      name: 'intradayLimitsInRange',
      desc: '',
      args: [],
    );
  }
}

class AppLocalizationDelegate extends LocalizationsDelegate<S> {
  const AppLocalizationDelegate();

  List<Locale> get supportedLocales {
    return const <Locale>[
      Locale.fromSubtags(languageCode: 'en'),
      Locale.fromSubtags(languageCode: 'zh'),
    ];
  }

  @override
  bool isSupported(Locale locale) => _isSupported(locale);
  @override
  Future<S> load(Locale locale) => S.load(locale);
  @override
  bool shouldReload(AppLocalizationDelegate old) => false;

  bool _isSupported(Locale locale) {
    for (var supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == locale.languageCode) {
        return true;
      }
    }
    return false;
  }
}
