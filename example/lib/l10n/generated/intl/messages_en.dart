// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a en locale. All the
// messages from the main program should be duplicated here with the same
// function name.

// Ignore issues from commonly used lints in this file.
// ignore_for_file:unnecessary_brace_in_string_interps, unnecessary_new
// ignore_for_file:prefer_single_quotes,comment_references, directives_ordering
// ignore_for_file:annotate_overrides,prefer_generic_function_type_aliases
// ignore_for_file:unused_import, file_names, avoid_escaping_inner_quotes
// ignore_for_file:unnecessary_string_interpolations, unnecessary_string_escapes

import 'package:intl/intl.dart';
import 'package:intl/message_lookup_by_library.dart';

final messages = new MessageLookup();

typedef String MessageIfAbsent(String messageStr, List<dynamic> args);

class MessageLookup extends MessageLookupByLibrary {
  String get localeName => 'en';

  static String m0(label, value) => "${label}: ${value}";

  static String m1(index, close) => "Bar ${index} · close ${close}";

  static String m2(count) =>
      "${count} bars now; synthetic data needs no network.";

  static String m3(count) => "${count} decimals";

  static String m4(price, time) => "Order price ${price} (${time})";

  static String m5(open, high, low, close) =>
      "Tapped: O ${open}  H ${high}  L ${low}  C ${close}";

  static String m6(count) => "Load ${count} older bars";

  static String m7(pages, count) =>
      "Loaded ${pages} pages, ${count} bars in total.";

  static String m8(index) => "Line ${index}";

  static String m9(index) => "Line ${index} color";

  static String m10(index) => "Period ${index}";

  static String m11(name, reason) => "${name} params not applied: ${reason}";

  static String m12(reason) => "Failed to load market data: ${reason}";

  static String m13(min, max) => "Locked at ${min} ~ ${max}";

  static String m14(start, end) => "Visible ${start} - ${end}";

  static String m15(ms) => "${ms} ms";

  static String m16(count) => "KLINEX · Offline synthetic data · ${count} bars";

  static String m17(name) => "${name} parameters";

  static String m18(name) => "${name} (Pro)";

  static String m19(error) => "Restore failed: ${error}";

  static String m20(day) => "${day}";

  static String m21(year) => "${year}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "axisPositionBoth": MessageLookupByLibrary.simpleMessage("Both sides"),
    "axisPositionHint": MessageLookupByLibrary.simpleMessage(
      "Inside mode takes no width and draws ticks over the candles; outside / left / both reserve an axis strip.",
    ),
    "axisPositionInside": MessageLookupByLibrary.simpleMessage("Right, inside"),
    "axisPositionLabel": MessageLookupByLibrary.simpleMessage(
      "Price axis position",
    ),
    "axisPositionLeft": MessageLookupByLibrary.simpleMessage("Left"),
    "axisPositionOutside": MessageLookupByLibrary.simpleMessage(
      "Right, outside",
    ),
    "axisPositionWidth": MessageLookupByLibrary.simpleMessage("Axis width"),
    "axisTagAsk": MessageLookupByLibrary.simpleMessage("S"),
    "axisTagBid": MessageLookupByLibrary.simpleMessage("B"),
    "candleBorder": MessageLookupByLibrary.simpleMessage("Candle border"),
    "candleFill": MessageLookupByLibrary.simpleMessage("Fill"),
    "candleFillHollowDown": MessageLookupByLibrary.simpleMessage("Hollow down"),
    "candleFillHollowUp": MessageLookupByLibrary.simpleMessage("Hollow up"),
    "candleFillSolid": MessageLookupByLibrary.simpleMessage("Solid"),
    "candleWickColor": MessageLookupByLibrary.simpleMessage(
      "Separate wick color (grey)",
    ),
    "chartChange": MessageLookupByLibrary.simpleMessage("Chg%"),
    "chartClose": MessageLookupByLibrary.simpleMessage("C"),
    "chartHigh": MessageLookupByLibrary.simpleMessage("H"),
    "chartLatest": MessageLookupByLibrary.simpleMessage("last price"),
    "chartLow": MessageLookupByLibrary.simpleMessage("L"),
    "chartName": MessageLookupByLibrary.simpleMessage("Candlestick chart"),
    "chartOpen": MessageLookupByLibrary.simpleMessage("O"),
    "chartRangeTo": MessageLookupByLibrary.simpleMessage("to"),
    "chartSeparator": MessageLookupByLibrary.simpleMessage(", "),
    "chartTime": MessageLookupByLibrary.simpleMessage("Time"),
    "chartVolume": MessageLookupByLibrary.simpleMessage("Vol"),
    "commonReset": MessageLookupByLibrary.simpleMessage("Reset"),
    "commonSave": MessageLookupByLibrary.simpleMessage("Save"),
    "computeSampleAsync": MessageLookupByLibrary.simpleMessage(
      "Background isolate asyncCompute",
    ),
    "computeSampleBusy": MessageLookupByLibrary.simpleMessage(
      "Computing in background…",
    ),
    "computeSampleHint": MessageLookupByLibrary.simpleMessage(
      "This page has 10,000 bars; a full computation goes to the background only from 2,000 bars, and on Web it depends on platform support.",
    ),
    "computeSampleTriggerError": MessageLookupByLibrary.simpleMessage(
      "Demo indicator error callback",
    ),
    "controlsCodeCopied": MessageLookupByLibrary.simpleMessage("Code copied"),
    "controlsCopyCode": MessageLookupByLibrary.simpleMessage("Copy code"),
    "controlsEquivalentCode": MessageLookupByLibrary.simpleMessage(
      "Equivalent code",
    ),
    "controlsSliderValue": m0,
    "crosshairSampleCustomBuilder": MessageLookupByLibrary.simpleMessage(
      "Custom tooltip tooltipBuilder",
    ),
    "crosshairSampleCustomTooltip": m1,
    "crosshairSampleHint": MessageLookupByLibrary.simpleMessage(
      "On mobile, long-press the chart; on desktop, hover over it.",
    ),
    "crosshairSampleShowTooltip": MessageLookupByLibrary.simpleMessage(
      "Show tooltip",
    ),
    "crosshairSampleSnap": MessageLookupByLibrary.simpleMessage(
      "Snap crosshairSnap",
    ),
    "crosshairSampleSnapClose": MessageLookupByLibrary.simpleMessage(
      "Close price",
    ),
    "crosshairSampleSnapFree": MessageLookupByLibrary.simpleMessage(
      "Follow finger",
    ),
    "crosshairSampleSnapOhlc": MessageLookupByLibrary.simpleMessage(
      "Nearest of OHLC",
    ),
    "crosshairSampleStyleCard": MessageLookupByLibrary.simpleMessage(
      "Floating card",
    ),
    "crosshairSampleStyleInline": MessageLookupByLibrary.simpleMessage(
      "One line above the legend",
    ),
    "crosshairSampleTooltipStyle": MessageLookupByLibrary.simpleMessage(
      "Tooltip style tooltipStyle",
    ),
    "customSeriesSampleDots": MessageLookupByLibrary.simpleMessage(
      "Close price dots",
    ),
    "customSeriesSampleHint": MessageLookupByLibrary.simpleMessage(
      "Implement MainSeries.paint: ctx provides coordinate conversion and the visible range, no library changes needed.",
    ),
    "customSeriesSampleRadius": MessageLookupByLibrary.simpleMessage(
      "Dot radius",
    ),
    "dataLimitCurrent": m2,
    "dataLimitInitial": MessageLookupByLibrary.simpleMessage("Initial bars"),
    "dataLimitMaxBars": MessageLookupByLibrary.simpleMessage(
      "History limit maxBars",
    ),
    "dataLimitRegenerate": MessageLookupByLibrary.simpleMessage("Regenerate"),
    "dataLimitUnlimited": MessageLookupByLibrary.simpleMessage("Unlimited"),
    "depthSampleBidSkew": MessageLookupByLibrary.simpleMessage(
      "Bid depth multiplier",
    ),
    "depthSampleLevels": MessageLookupByLibrary.simpleMessage("Levels"),
    "depthSampleWithKline": MessageLookupByLibrary.simpleMessage(
      "Show candles above",
    ),
    "formatSampleCustomLabels": MessageLookupByLibrary.simpleMessage(
      "Custom labels",
    ),
    "formatSampleCustomTime": MessageLookupByLibrary.simpleMessage(
      "Custom time format timeFormatter",
    ),
    "formatSampleDecimals": MessageLookupByLibrary.simpleMessage(
      "Price decimals",
    ),
    "formatSampleDecimalsOption": m3,
    "formatSampleHint": MessageLookupByLibrary.simpleMessage(
      "When timeFormatter is set, it handles the time zone; tooltip and legend text follow labels.",
    ),
    "formatSampleTimezone": MessageLookupByLibrary.simpleMessage(
      "Time zone utcOffset",
    ),
    "gestureSampleAxisDrag": MessageLookupByLibrary.simpleMessage(
      "Drag axis to zoom axisDragScale",
    ),
    "gestureSampleAxisDragHint": MessageLookupByLibrary.simpleMessage(
      "When on, drag the price axis to zoom prices and the time axis to zoom time; double-tap to reset.",
    ),
    "gestureSampleBarTap": MessageLookupByLibrary.simpleMessage(
      "Tap candle for price onBarTap",
    ),
    "gestureSampleBarTapHint": MessageLookupByLibrary.simpleMessage(
      "Tap a candle to get its Bar; trading pages often use it to fill the close price into the order form. With onBarTap set, double-tap no longer resets the y axis.",
    ),
    "gestureSampleOrderPrice": m4,
    "gestureSampleTapped": m5,
    "gestureSampleYPan": MessageLookupByLibrary.simpleMessage(
      "Vertical pan yPan",
    ),
    "gestureSampleYPanAxis": MessageLookupByLibrary.simpleMessage(
      "Only on the price axis",
    ),
    "gestureSampleYPanChart": MessageLookupByLibrary.simpleMessage(
      "Whole main panel",
    ),
    "gestureSampleYPanNone": MessageLookupByLibrary.simpleMessage(
      "No pan, leave it to outer scrolling",
    ),
    "gridSampleDash": MessageLookupByLibrary.simpleMessage(
      "Dashed grid gridLineDash",
    ),
    "gridSampleLineWidth": MessageLookupByLibrary.simpleMessage(
      "Grid line width gridLineWidth",
    ),
    "gridSampleShowGrid": MessageLookupByLibrary.simpleMessage(
      "Show grid showGrid",
    ),
    "gridSampleTextSize": MessageLookupByLibrary.simpleMessage(
      "Axis text size axisTextSize",
    ),
    "historyAutoLoad": MessageLookupByLibrary.simpleMessage(
      "Auto-load when scrolled to the left",
    ),
    "historyHint": MessageLookupByLibrary.simpleMessage(
      "Drag toward history before loading and watch that the viewport does not jump.",
    ),
    "historyLoadButton": m6,
    "historyStatus": m7,
    "homeLive": MessageLookupByLibrary.simpleMessage("Live market"),
    "homeSamples": MessageLookupByLibrary.simpleMessage("Samples"),
    "indicatorBollDesc": MessageLookupByLibrary.simpleMessage(
      "Bollinger bands",
    ),
    "indicatorColor": MessageLookupByLibrary.simpleMessage("Color"),
    "indicatorEmaDesc": MessageLookupByLibrary.simpleMessage(
      "Exponential moving average",
    ),
    "indicatorFieldsLine": m8,
    "indicatorFieldsLineColor": m9,
    "indicatorFieldsPeriod": m10,
    "indicatorGroupMain": MessageLookupByLibrary.simpleMessage("Main chart"),
    "indicatorGroupSub": MessageLookupByLibrary.simpleMessage("Sub chart"),
    "indicatorKdjDesc": MessageLookupByLibrary.simpleMessage(
      "Stochastic oscillator",
    ),
    "indicatorLine": MessageLookupByLibrary.simpleMessage("Line"),
    "indicatorLongPeriod": MessageLookupByLibrary.simpleMessage("Long period"),
    "indicatorMaDesc": MessageLookupByLibrary.simpleMessage("Moving average"),
    "indicatorMacdDesc": MessageLookupByLibrary.simpleMessage(
      "Moving average convergence divergence",
    ),
    "indicatorParamSampleDSmooth": MessageLookupByLibrary.simpleMessage(
      "D smoothing",
    ),
    "indicatorParamSampleHint": MessageLookupByLibrary.simpleMessage(
      "Changing a parameter changes the indicator id and recomputes it fully; invalid combinations are not applied and the reason is shown.",
    ),
    "indicatorParamSampleKSmooth": MessageLookupByLibrary.simpleMessage(
      "K smoothing",
    ),
    "indicatorParamSampleLongPeriod": MessageLookupByLibrary.simpleMessage(
      "Long period",
    ),
    "indicatorParamSamplePeriod": MessageLookupByLibrary.simpleMessage(
      "Period",
    ),
    "indicatorParamSampleShortPeriod": MessageLookupByLibrary.simpleMessage(
      "Short period",
    ),
    "indicatorParamSampleSignalPeriod": MessageLookupByLibrary.simpleMessage(
      "Signal period",
    ),
    "indicatorParamSampleStdDev": MessageLookupByLibrary.simpleMessage(
      "Std dev multiplier",
    ),
    "indicatorParamsNotApplied": m11,
    "indicatorPeriod": MessageLookupByLibrary.simpleMessage("Period"),
    "indicatorPeriodN": MessageLookupByLibrary.simpleMessage("Period N"),
    "indicatorReferenceValue": MessageLookupByLibrary.simpleMessage("Value"),
    "indicatorRsiDesc": MessageLookupByLibrary.simpleMessage(
      "Relative strength index",
    ),
    "indicatorSettingsTitle": MessageLookupByLibrary.simpleMessage(
      "Indicator Settings",
    ),
    "indicatorShortPeriod": MessageLookupByLibrary.simpleMessage(
      "Short period",
    ),
    "indicatorSignalPeriod": MessageLookupByLibrary.simpleMessage(
      "Signal period",
    ),
    "indicatorStdDevMultiplier": MessageLookupByLibrary.simpleMessage(
      "Std dev multiplier",
    ),
    "indicatorSwitchSampleHint": MessageLookupByLibrary.simpleMessage(
      "Each indicator\'s parameters are on its own \"Parameters\" page; Pro adds 40 advanced indicators.",
    ),
    "indicatorSwitchSampleMain": MessageLookupByLibrary.simpleMessage(
      "Main overlays",
    ),
    "indicatorSwitchSampleSub": MessageLookupByLibrary.simpleMessage(
      "Sub panels / volume",
    ),
    "indicatorWrDesc": MessageLookupByLibrary.simpleMessage("Williams %R"),
    "keyboardSampleEnable": MessageLookupByLibrary.simpleMessage(
      "Enable keyboard",
    ),
    "keyboardSampleFocusHint": MessageLookupByLibrary.simpleMessage(
      "Tap the chart first to focus it. The chart ignores keys while a text field has focus.",
    ),
    "keyboardSampleShortcuts": MessageLookupByLibrary.simpleMessage(
      "Left / Right: pan\nUp / Down or + / -: zoom\nHome / End: earliest / latest\nEsc: clear crosshair",
    ),
    "language": MessageLookupByLibrary.simpleMessage("中文"),
    "liveAutoFollow": MessageLookupByLibrary.simpleMessage("Follow latest"),
    "liveBookPrice": MessageLookupByLibrary.simpleMessage("Bid/ask"),
    "liveChartSettings": MessageLookupByLibrary.simpleMessage("Chart Settings"),
    "liveChartType": MessageLookupByLibrary.simpleMessage("Chart type"),
    "liveConnecting": MessageLookupByLibrary.simpleMessage("Connecting…"),
    "liveCountdown": MessageLookupByLibrary.simpleMessage("Countdown"),
    "liveGoToSettings": MessageLookupByLibrary.simpleMessage("Configure"),
    "liveHeikinAshi": MessageLookupByLibrary.simpleMessage("Heikin-Ashi"),
    "liveIndicatorParams": MessageLookupByLibrary.simpleMessage(
      "Indicator parameters",
    ),
    "liveInterval12h": MessageLookupByLibrary.simpleMessage("12h"),
    "liveInterval15m": MessageLookupByLibrary.simpleMessage("15m"),
    "liveInterval1M": MessageLookupByLibrary.simpleMessage("1M"),
    "liveInterval1d": MessageLookupByLibrary.simpleMessage("1D"),
    "liveInterval1h": MessageLookupByLibrary.simpleMessage("1h"),
    "liveInterval1m": MessageLookupByLibrary.simpleMessage("1m"),
    "liveInterval1w": MessageLookupByLibrary.simpleMessage("1W"),
    "liveInterval2h": MessageLookupByLibrary.simpleMessage("2h"),
    "liveInterval30m": MessageLookupByLibrary.simpleMessage("30m"),
    "liveInterval3d": MessageLookupByLibrary.simpleMessage("3D"),
    "liveInterval3m": MessageLookupByLibrary.simpleMessage("3m"),
    "liveInterval4h": MessageLookupByLibrary.simpleMessage("4h"),
    "liveInterval5m": MessageLookupByLibrary.simpleMessage("5m"),
    "liveInterval6h": MessageLookupByLibrary.simpleMessage("6h"),
    "liveInterval8h": MessageLookupByLibrary.simpleMessage("8h"),
    "liveIntervalMore": MessageLookupByLibrary.simpleMessage("More"),
    "liveLastPrice": MessageLookupByLibrary.simpleMessage("Last price"),
    "liveLoadFailed": m12,
    "liveLogScale": MessageLookupByLibrary.simpleMessage("Log scale"),
    "liveLogSegment": MessageLookupByLibrary.simpleMessage("Log segment"),
    "liveNoData": MessageLookupByLibrary.simpleMessage("No data returned"),
    "livePercentScale": MessageLookupByLibrary.simpleMessage("Percent scale"),
    "livePleaseRetry": MessageLookupByLibrary.simpleMessage("please retry"),
    "liveSectionChart": MessageLookupByLibrary.simpleMessage("Chart"),
    "liveSectionChartHeight": MessageLookupByLibrary.simpleMessage(
      "Chart height",
    ),
    "liveSectionDisplay": MessageLookupByLibrary.simpleMessage("Display"),
    "liveSeriesArea": MessageLookupByLibrary.simpleMessage("Area"),
    "liveSeriesCandle": MessageLookupByLibrary.simpleMessage("Candlestick"),
    "liveSeriesLine": MessageLookupByLibrary.simpleMessage("Line"),
    "liveSwitchMarket": MessageLookupByLibrary.simpleMessage("Switch market"),
    "liveTapToRetry": MessageLookupByLibrary.simpleMessage("Tap to retry"),
    "liveTimeZone": MessageLookupByLibrary.simpleMessage("Time zone"),
    "liveTimeZoneDevice": MessageLookupByLibrary.simpleMessage("Device"),
    "liveTimeZoneNewYork": MessageLookupByLibrary.simpleMessage(
      "UTC-5 New York (winter)",
    ),
    "liveTimeZoneShanghai": MessageLookupByLibrary.simpleMessage(
      "UTC+8 Shanghai",
    ),
    "liveYAxisOutside": MessageLookupByLibrary.simpleMessage("Y-axis outside"),
    "lockRangeHint": MessageLookupByLibrary.simpleMessage(
      "Once locked, panning and new data no longer rescale prices; dragging the price axis to scale / pan still applies on top of the locked range.",
    ),
    "lockRangeLock": MessageLookupByLibrary.simpleMessage(
      "Lock current price range",
    ),
    "lockRangeLockedAt": m13,
    "lockRangeStorageHint": MessageLookupByLibrary.simpleMessage(
      "Saved with saveState; setBars unlocks automatically.",
    ),
    "netConnectTimeout": MessageLookupByLibrary.simpleMessage(
      "Connection timed out",
    ),
    "netConnectionFailed": MessageLookupByLibrary.simpleMessage(
      "Network connection failed",
    ),
    "netReceiveTimeout": MessageLookupByLibrary.simpleMessage(
      "Receive timed out",
    ),
    "netRequestCancelled": MessageLookupByLibrary.simpleMessage(
      "Request cancelled",
    ),
    "netSendTimeout": MessageLookupByLibrary.simpleMessage("Send timed out"),
    "netServerError": MessageLookupByLibrary.simpleMessage("Server error"),
    "overlaySampleHint": MessageLookupByLibrary.simpleMessage(
      "overlayBuilder gets the RenderContext (coordinate conversion, visible area) every frame and returns any widget, which follows panning and zooming.",
    ),
    "overlaySampleLastBadge": MessageLookupByLibrary.simpleMessage(
      "Label above the latest candle",
    ),
    "overlaySampleLatest": MessageLookupByLibrary.simpleMessage("Latest"),
    "overlaySampleRangeBadge": MessageLookupByLibrary.simpleMessage(
      "Visible range badge",
    ),
    "overlaySampleVisibleRange": m14,
    "panelsSampleHint": MessageLookupByLibrary.simpleMessage(
      "Dragged heights are kept in ChartConfig.panelWeights and saved / restored with saveState.",
    ),
    "panelsSampleMainFlex": MessageLookupByLibrary.simpleMessage(
      "Main panel weight mainFlex",
    ),
    "panelsSampleResizable": MessageLookupByLibrary.simpleMessage(
      "Drag dividers to resize panelResizable",
    ),
    "panelsSampleSubFlex": MessageLookupByLibrary.simpleMessage(
      "Weight per sub panel subFlex",
    ),
    "paramInputIntError": MessageLookupByLibrary.simpleMessage(
      "Enter a finite positive integer, at most 100000",
    ),
    "paramInputNumberError": MessageLookupByLibrary.simpleMessage(
      "Enter a finite positive number, at most 100000",
    ),
    "priceLineAnimateHint": MessageLookupByLibrary.simpleMessage(
      "Price animation slides the last close and price line to the new value in about 200 ms; display only.",
    ),
    "priceLineAnimatePrice": MessageLookupByLibrary.simpleMessage(
      "Price animation animatePrice",
    ),
    "priceLineAnimateRange": MessageLookupByLibrary.simpleMessage(
      "Range animation animateRange",
    ),
    "priceLineBook": MessageLookupByLibrary.simpleMessage("Bid / ask"),
    "priceLineCountdown": MessageLookupByLibrary.simpleMessage("Countdown"),
    "priceLineDataHint": MessageLookupByLibrary.simpleMessage(
      "The synthetic data here makes one bar every 3 seconds, the countdown follows that pace, and the order book is simulated.",
    ),
    "priceLineHighLow": MessageLookupByLibrary.simpleMessage(
      "High / low labels showHighLow",
    ),
    "priceLineOverlayHint": MessageLookupByLibrary.simpleMessage(
      "The library\'s PriceLineOverlay only draws the dashed line.",
    ),
    "priceLinePriceType": MessageLookupByLibrary.simpleMessage(
      "Candle price type",
    ),
    "priceLinePriceTypeHint": MessageLookupByLibrary.simpleMessage(
      "Futures can draw candles by mark or index price; a hint then shows in the lower left so it is not confused with the last trade price (only the hint changes here, not the data).",
    ),
    "priceLineShowPrice": MessageLookupByLibrary.simpleMessage(
      "Last price line + tag",
    ),
    "priceLineStackHint": MessageLookupByLibrary.simpleMessage(
      "Crowded tags are ordered by price from high to low, ask → last → bid at equal prices; scrolling into history adds a reference tag.",
    ),
    "priceLineTagsHint": MessageLookupByLibrary.simpleMessage(
      "Price tags, close countdown and best bid / ask on the y axis are drawn by overlayBuilder (the demo\'s AxisPriceTags).",
    ),
    "priceLineTipIndex": MessageLookupByLibrary.simpleMessage(
      "Showing index price candles",
    ),
    "priceLineTipMark": MessageLookupByLibrary.simpleMessage(
      "Showing mark price candles",
    ),
    "priceLineTypeIndex": MessageLookupByLibrary.simpleMessage("Index price"),
    "priceLineTypeLast": MessageLookupByLibrary.simpleMessage("Last price"),
    "priceLineTypeMark": MessageLookupByLibrary.simpleMessage("Mark price"),
    "proGroupMain": MessageLookupByLibrary.simpleMessage("Main chart (Pro)"),
    "proGroupSub": MessageLookupByLibrary.simpleMessage("Sub chart (Pro)"),
    "proIndicatorAd": MessageLookupByLibrary.simpleMessage(
      "Accumulation/distribution",
    ),
    "proIndicatorAlma": MessageLookupByLibrary.simpleMessage(
      "Arnaud Legoux MA",
    ),
    "proIndicatorAo": MessageLookupByLibrary.simpleMessage(
      "Awesome oscillator",
    ),
    "proIndicatorAroon": MessageLookupByLibrary.simpleMessage("Aroon"),
    "proIndicatorAtr": MessageLookupByLibrary.simpleMessage(
      "Average true range",
    ),
    "proIndicatorBbw": MessageLookupByLibrary.simpleMessage(
      "Bollinger bandwidth",
    ),
    "proIndicatorCci": MessageLookupByLibrary.simpleMessage(
      "Commodity channel index",
    ),
    "proIndicatorCho": MessageLookupByLibrary.simpleMessage(
      "Chaikin oscillator",
    ),
    "proIndicatorChop": MessageLookupByLibrary.simpleMessage(
      "Choppiness index",
    ),
    "proIndicatorCmf": MessageLookupByLibrary.simpleMessage(
      "Chaikin money flow",
    ),
    "proIndicatorDc": MessageLookupByLibrary.simpleMessage("Donchian channel"),
    "proIndicatorDema": MessageLookupByLibrary.simpleMessage("Double EMA"),
    "proIndicatorDmi": MessageLookupByLibrary.simpleMessage(
      "Directional movement index",
    ),
    "proIndicatorFisher": MessageLookupByLibrary.simpleMessage(
      "Fisher transform",
    ),
    "proIndicatorHma": MessageLookupByLibrary.simpleMessage(
      "Hull moving average",
    ),
    "proIndicatorHv": MessageLookupByLibrary.simpleMessage(
      "Historical volatility",
    ),
    "proIndicatorIchi": MessageLookupByLibrary.simpleMessage("Ichimoku cloud"),
    "proIndicatorKama": MessageLookupByLibrary.simpleMessage(
      "Kaufman adaptive MA",
    ),
    "proIndicatorKc": MessageLookupByLibrary.simpleMessage("Keltner channel"),
    "proIndicatorLsma": MessageLookupByLibrary.simpleMessage(
      "Least squares MA",
    ),
    "proIndicatorMfi": MessageLookupByLibrary.simpleMessage("Money flow index"),
    "proIndicatorMtm": MessageLookupByLibrary.simpleMessage("Momentum"),
    "proIndicatorObv": MessageLookupByLibrary.simpleMessage(
      "On-balance volume",
    ),
    "proIndicatorPercentB": MessageLookupByLibrary.simpleMessage(
      "Bollinger %B",
    ),
    "proIndicatorPivot": MessageLookupByLibrary.simpleMessage("Pivot points"),
    "proIndicatorPpo": MessageLookupByLibrary.simpleMessage(
      "Percentage price oscillator",
    ),
    "proIndicatorRoc": MessageLookupByLibrary.simpleMessage("Rate of change"),
    "proIndicatorSar": MessageLookupByLibrary.simpleMessage("Parabolic SAR"),
    "proIndicatorSt": MessageLookupByLibrary.simpleMessage("Supertrend"),
    "proIndicatorStd": MessageLookupByLibrary.simpleMessage(
      "Standard deviation",
    ),
    "proIndicatorStoch": MessageLookupByLibrary.simpleMessage(
      "Stochastic oscillator",
    ),
    "proIndicatorStochRsi": MessageLookupByLibrary.simpleMessage(
      "Stochastic RSI",
    ),
    "proIndicatorTema": MessageLookupByLibrary.simpleMessage("Triple EMA"),
    "proIndicatorTrix": MessageLookupByLibrary.simpleMessage(
      "Triple exponential average",
    ),
    "proIndicatorVortex": MessageLookupByLibrary.simpleMessage(
      "Vortex indicator",
    ),
    "proIndicatorVwma": MessageLookupByLibrary.simpleMessage(
      "Volume-weighted MA",
    ),
    "proIndicatorWma": MessageLookupByLibrary.simpleMessage(
      "Weighted moving average",
    ),
    "proIndicatorZigzag": MessageLookupByLibrary.simpleMessage("ZigZag"),
    "proLockFeature": MessageLookupByLibrary.simpleMessage("Pro feature"),
    "proSampleAlerts": MessageLookupByLibrary.simpleMessage("Price alerts"),
    "proSampleCompare": MessageLookupByLibrary.simpleMessage("Compare overlay"),
    "proSampleDrawing": MessageLookupByLibrary.simpleMessage("Drawing tools"),
    "proSampleFills": MessageLookupByLibrary.simpleMessage("Fill markers"),
    "proSampleIndicators": MessageLookupByLibrary.simpleMessage(
      "Advanced indicators",
    ),
    "proSampleOrders": MessageLookupByLibrary.simpleMessage("Order lines"),
    "proSamplePosition": MessageLookupByLibrary.simpleMessage(
      "Position and measure",
    ),
    "proSampleReplay": MessageLookupByLibrary.simpleMessage("Replay"),
    "proSampleSync": MessageLookupByLibrary.simpleMessage("Linked charts"),
    "proSampleTransforms": MessageLookupByLibrary.simpleMessage(
      "Data transforms",
    ),
    "proSeriesBaseline": MessageLookupByLibrary.simpleMessage("Baseline"),
    "proSeriesColumn": MessageLookupByLibrary.simpleMessage("Columns"),
    "proSeriesHiLo": MessageLookupByLibrary.simpleMessage("High-low"),
    "proSeriesHlcArea": MessageLookupByLibrary.simpleMessage("HLC area"),
    "proSeriesMarkers": MessageLookupByLibrary.simpleMessage(
      "Line with markers",
    ),
    "proSeriesOhlc": MessageLookupByLibrary.simpleMessage("OHLC bars"),
    "proSeriesStep": MessageLookupByLibrary.simpleMessage("Step line"),
    "proSeriesVolCandle": MessageLookupByLibrary.simpleMessage(
      "Volume candles",
    ),
    "realtimeAppend": MessageLookupByLibrary.simpleMessage("Append a bar"),
    "realtimeAutoPush": MessageLookupByLibrary.simpleMessage(
      "Auto push (append a bar every 5 pushes)",
    ),
    "realtimeFollow": MessageLookupByLibrary.simpleMessage(
      "Follow latest autoFollow",
    ),
    "realtimeHint": MessageLookupByLibrary.simpleMessage(
      "With follow off, drag left a bit: pushes will not pull the viewport back to the latest.",
    ),
    "realtimeInterval": MessageLookupByLibrary.simpleMessage("Push interval"),
    "realtimeMillis": m15,
    "realtimeOneSecond": MessageLookupByLibrary.simpleMessage("1 s"),
    "realtimeUpdateLast": MessageLookupByLibrary.simpleMessage(
      "Update last price",
    ),
    "sampleAutoPush": MessageLookupByLibrary.simpleMessage("Auto push"),
    "sampleAxisPositionDesc": MessageLookupByLibrary.simpleMessage(
      "Right inside / outside, left, both sides, and axis width.",
    ),
    "sampleAxisPositionTitle": MessageLookupByLibrary.simpleMessage(
      "Price axis position",
    ),
    "sampleBackToLatest": MessageLookupByLibrary.simpleMessage(
      "Back to latest",
    ),
    "sampleCandleDesc": MessageLookupByLibrary.simpleMessage(
      "Solid / hollow, with separate wick and border colors.",
    ),
    "sampleCandleTitle": MessageLookupByLibrary.simpleMessage("Candle style"),
    "sampleCategoryAppearance": MessageLookupByLibrary.simpleMessage(
      "Appearance",
    ),
    "sampleCategoryCoordinates": MessageLookupByLibrary.simpleMessage(
      "Coordinates",
    ),
    "sampleCategoryData": MessageLookupByLibrary.simpleMessage("Data"),
    "sampleCategoryExtensions": MessageLookupByLibrary.simpleMessage(
      "Extensions",
    ),
    "sampleCategoryIndicators": MessageLookupByLibrary.simpleMessage(
      "Indicators",
    ),
    "sampleCategoryInteraction": MessageLookupByLibrary.simpleMessage(
      "Interaction",
    ),
    "sampleCategoryMain": MessageLookupByLibrary.simpleMessage("Main chart"),
    "sampleCategoryPro": MessageLookupByLibrary.simpleMessage("Pro"),
    "sampleCategoryStorage": MessageLookupByLibrary.simpleMessage("Storage"),
    "sampleComputeDesc": MessageLookupByLibrary.simpleMessage(
      "Large data is computed in a background isolate; indicator errors are reported via a callback without affecting other indicators.",
    ),
    "sampleComputeTitle": MessageLookupByLibrary.simpleMessage(
      "Compute and errors",
    ),
    "sampleCrosshairDesc": MessageLookupByLibrary.simpleMessage(
      "Snap mode, tooltip toggle and custom tooltip.",
    ),
    "sampleCrosshairTitle": MessageLookupByLibrary.simpleMessage("Crosshair"),
    "sampleCustomSeriesDesc": MessageLookupByLibrary.simpleMessage(
      "Implement MainSeries.paint without changing the library source.",
    ),
    "sampleCustomSeriesTitle": MessageLookupByLibrary.simpleMessage(
      "Custom main series",
    ),
    "sampleDataLimitDesc": MessageLookupByLibrary.simpleMessage(
      "Load the whole series with setBars; maxBars drops the oldest bars when exceeded.",
    ),
    "sampleDataLimitTitle": MessageLookupByLibrary.simpleMessage(
      "Data size and limit",
    ),
    "sampleDepthDesc": MessageLookupByLibrary.simpleMessage(
      "DepthChart has its own price axis and works alone or next to the candles.",
    ),
    "sampleDepthTitle": MessageLookupByLibrary.simpleMessage("Depth chart"),
    "sampleFormatDesc": MessageLookupByLibrary.simpleMessage(
      "Price decimals, time zone, custom time format, and chart label language.",
    ),
    "sampleFormatTitle": MessageLookupByLibrary.simpleMessage("Formatting"),
    "sampleFrameStatus": m16,
    "sampleGesturesDesc": MessageLookupByLibrary.simpleMessage(
      "Vertical pan area, axis drag to scale, and tap a bar to read its price.",
    ),
    "sampleGesturesTitle": MessageLookupByLibrary.simpleMessage("Gestures"),
    "sampleGridDesc": MessageLookupByLibrary.simpleMessage(
      "Grid visibility, dashes, line width, and axis font size.",
    ),
    "sampleGridTitle": MessageLookupByLibrary.simpleMessage("Grid and text"),
    "sampleHistoryDesc": MessageLookupByLibrary.simpleMessage(
      "Scrolling to the left triggers onLoadMore, prependHistory adds older data, and the viewport does not jump.",
    ),
    "sampleHistoryTitle": MessageLookupByLibrary.simpleMessage(
      "History pagination",
    ),
    "sampleIndicatorParamDesc": MessageLookupByLibrary.simpleMessage(
      "Change parameters and colors; the indicator recomputes immediately.",
    ),
    "sampleIndicatorParamTitle": m17,
    "sampleIndicatorsDesc": MessageLookupByLibrary.simpleMessage(
      "Combine the 8 built-in indicators.",
    ),
    "sampleIndicatorsTitle": MessageLookupByLibrary.simpleMessage(
      "Indicator switches",
    ),
    "sampleKeyboardDesc": MessageLookupByLibrary.simpleMessage(
      "Arrow keys pan and zoom; Home / End jump to either end.",
    ),
    "sampleKeyboardTitle": MessageLookupByLibrary.simpleMessage("Keyboard"),
    "sampleLockRangeDesc": MessageLookupByLibrary.simpleMessage(
      "Pin the main chart range to the current one; panning and pushes no longer rescale it.",
    ),
    "sampleLockRangeTitle": MessageLookupByLibrary.simpleMessage("Lock range"),
    "sampleLockedDescription": MessageLookupByLibrary.simpleMessage(
      "Pro feature",
    ),
    "sampleOverlayDesc": MessageLookupByLibrary.simpleMessage(
      "overlayBuilder paints plain widgets on the chart that follow panning and zooming.",
    ),
    "sampleOverlayTitle": MessageLookupByLibrary.simpleMessage(
      "Custom overlay",
    ),
    "samplePanelsDesc": MessageLookupByLibrary.simpleMessage(
      "Main / sub panel weights; drag the divider to resize.",
    ),
    "samplePanelsTitle": MessageLookupByLibrary.simpleMessage("Panel height"),
    "samplePriceDesc": MessageLookupByLibrary.simpleMessage(
      "Last price line and tag, close countdown, bid / ask, mark price hint, price animation, and visible high / low labels.",
    ),
    "samplePriceSearchTerms": MessageLookupByLibrary.simpleMessage(
      "countdown order book mark price",
    ),
    "samplePriceTitle": MessageLookupByLibrary.simpleMessage("Price line"),
    "sampleRealtimeDesc": MessageLookupByLibrary.simpleMessage(
      "applyTick updates the last bar on the same timestamp and appends on a new one; autoFollow sticks to the latest.",
    ),
    "sampleRealtimeTitle": MessageLookupByLibrary.simpleMessage(
      "Real-time push",
    ),
    "sampleResetPage": MessageLookupByLibrary.simpleMessage("Reset this page"),
    "sampleScaleDesc": MessageLookupByLibrary.simpleMessage(
      "The three scale modes can be combined.",
    ),
    "sampleScaleTitle": MessageLookupByLibrary.simpleMessage(
      "Log / percent / inverted",
    ),
    "sampleSecondaryAxisDesc": MessageLookupByLibrary.simpleMessage(
      "Overlay indicators of a different scale on the main chart with their own range.",
    ),
    "sampleSecondaryAxisTitle": MessageLookupByLibrary.simpleMessage(
      "Secondary axis",
    ),
    "sampleSeriesDesc": MessageLookupByLibrary.simpleMessage(
      "Three free seriesStyle values, plus MainSeries instances in Pro.",
    ),
    "sampleSeriesTitle": MessageLookupByLibrary.simpleMessage("Main series"),
    "sampleStorageDesc": MessageLookupByLibrary.simpleMessage(
      "saveState / restoreState and KLineTheme.toJson / fromJson.",
    ),
    "sampleStorageTitle": MessageLookupByLibrary.simpleMessage(
      "Save and restore",
    ),
    "sampleThemeDesc": MessageLookupByLibrary.simpleMessage(
      "Light / dark background, up / down colors, and indicator palette.",
    ),
    "sampleThemeTitle": MessageLookupByLibrary.simpleMessage("Theme"),
    "sampleTimeAxisDesc": MessageLookupByLibrary.simpleMessage(
      "Ticks land on year / month / day / hour boundaries.",
    ),
    "sampleTimeAxisTitle": MessageLookupByLibrary.simpleMessage(
      "Tiered time axis",
    ),
    "sampleWatermarkDesc": MessageLookupByLibrary.simpleMessage(
      "underlayBuilder paints below the candles.",
    ),
    "sampleWatermarkTitle": MessageLookupByLibrary.simpleMessage("Watermark"),
    "scaleModeHint": MessageLookupByLibrary.simpleMessage(
      "Log scale falls back to linear when the range is not positive; percent only changes tick labels (the leftmost visible close is 0%).",
    ),
    "scaleModeInvert": MessageLookupByLibrary.simpleMessage(
      "Inverted scale invertScale",
    ),
    "scaleModeInvertHint": MessageLookupByLibrary.simpleMessage(
      "Inversion only affects the main chart: small values on top, and dragging the price axis is reversed too.",
    ),
    "scaleModeLog": MessageLookupByLibrary.simpleMessage("Log scale logScale"),
    "scaleModePercent": MessageLookupByLibrary.simpleMessage(
      "Percent scale percentScale",
    ),
    "secondaryAxisBoth": MessageLookupByLibrary.simpleMessage(
      "Both sides (secondary axis uses the left strip)",
    ),
    "secondaryAxisHint": MessageLookupByLibrary.simpleMessage(
      "The secondary axis has its own range and does not squeeze prices; the crosshair shows both readings.",
    ),
    "secondaryAxisNone": MessageLookupByLibrary.simpleMessage("None"),
    "secondaryAxisOverlay": MessageLookupByLibrary.simpleMessage(
      "Overlay on secondary axis",
    ),
    "secondaryAxisPercent": MessageLookupByLibrary.simpleMessage(
      "Secondary axis in % format secondaryFormatter",
    ),
    "secondaryAxisRight": MessageLookupByLibrary.simpleMessage(
      "Right (secondary labels inside the left edge)",
    ),
    "seriesArea": MessageLookupByLibrary.simpleMessage("Area"),
    "seriesCandle": MessageLookupByLibrary.simpleMessage("Candles"),
    "seriesHint": MessageLookupByLibrary.simpleMessage(
      "The series only decides how bars are drawn; Renko, line break and other transforms that change the data itself are in Pro\'s \"Data transforms\".",
    ),
    "seriesLabel": MessageLookupByLibrary.simpleMessage("Main series"),
    "seriesLine": MessageLookupByLibrary.simpleMessage("Line"),
    "seriesProSuffix": m18,
    "settingDarkMode": MessageLookupByLibrary.simpleMessage("Dark"),
    "settingLightMode": MessageLookupByLibrary.simpleMessage("Light"),
    "settingMenuSearchHint": MessageLookupByLibrary.simpleMessage(
      "Search features or APIs",
    ),
    "settingPageTitle": MessageLookupByLibrary.simpleMessage("Klinex Samples"),
    "settingSampleNotFound": MessageLookupByLibrary.simpleMessage(
      "Sample not found. Choose one from the menu.",
    ),
    "storageSampleHint": MessageLookupByLibrary.simpleMessage(
      "Save first, then zoom, drag dividers, change indicators or theme, and finally restore from the text. Market data is not saved.",
    ),
    "storageSampleIndicatorsNotList": MessageLookupByLibrary.simpleMessage(
      "chart.indicators must be a list",
    ),
    "storageSampleJsonHint": MessageLookupByLibrary.simpleMessage("Saved JSON"),
    "storageSampleNeedChartTheme": MessageLookupByLibrary.simpleMessage(
      "Must contain chart and theme objects",
    ),
    "storageSampleRestore": MessageLookupByLibrary.simpleMessage(
      "Restore from text",
    ),
    "storageSampleRestoreFailed": m19,
    "storageSampleRestored": MessageLookupByLibrary.simpleMessage("Restored."),
    "storageSampleSaved": MessageLookupByLibrary.simpleMessage(
      "Saved: zoom, indicators, locked coordinates, panel heights and theme.",
    ),
    "storageSampleSwapIndicators": MessageLookupByLibrary.simpleMessage(
      "Swap indicators",
    ),
    "storageSampleSwitchTheme": MessageLookupByLibrary.simpleMessage(
      "Switch theme",
    ),
    "themeSampleBase": MessageLookupByLibrary.simpleMessage("Base"),
    "themeSampleBaseFollow": MessageLookupByLibrary.simpleMessage(
      "Follow app brightness",
    ),
    "themeSampleHint": MessageLookupByLibrary.simpleMessage(
      "KLineTheme supports toJson / fromJson; copyWith changes only the fields you need.",
    ),
    "themeSamplePalette": MessageLookupByLibrary.simpleMessage("Colors"),
    "themeSamplePaletteDefault": MessageLookupByLibrary.simpleMessage(
      "Default",
    ),
    "themeSamplePaletteOcean": MessageLookupByLibrary.simpleMessage(
      "Blue up, orange down",
    ),
    "themeSamplePaletteWarm": MessageLookupByLibrary.simpleMessage(
      "Warm indicator lines",
    ),
    "themeSwitchToDark": MessageLookupByLibrary.simpleMessage(
      "Switch to dark theme",
    ),
    "themeSwitchToLight": MessageLookupByLibrary.simpleMessage(
      "Switch to light theme",
    ),
    "timeAxisSampleCustomTick": MessageLookupByLibrary.simpleMessage(
      "Custom tick text tickFormatter",
    ),
    "timeAxisSampleHint": MessageLookupByLibrary.simpleMessage(
      "Ticks and vertical grid lines move with the chart; day and month ticks are bold. Zooming picks an interval that does not crowd. Recommended for unevenly spaced data such as renko.",
    ),
    "timeAxisSampleMonthNames": MessageLookupByLibrary.simpleMessage(
      "Jan,Feb,Mar,Apr,May,Jun,Jul,Aug,Sep,Oct,Nov,Dec",
    ),
    "timeAxisSampleTickDay": m20,
    "timeAxisSampleTickYear": m21,
    "timeAxisSampleTiered": MessageLookupByLibrary.simpleMessage(
      "Tiered time axis tieredTimeAxis",
    ),
    "timeAxisSampleTimezone": MessageLookupByLibrary.simpleMessage(
      "Time zone utcOffset",
    ),
    "watermarkSampleHint": MessageLookupByLibrary.simpleMessage(
      "underlayBuilder receives the RenderContext and can position by the main panel rect; it sits below the candles and does not block gestures.",
    ),
    "watermarkSampleShow": MessageLookupByLibrary.simpleMessage(
      "Show watermark",
    ),
    "watermarkSampleSize": MessageLookupByLibrary.simpleMessage("Font size"),
  };
}
