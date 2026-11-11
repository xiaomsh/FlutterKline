import '../../l10n/l10n.dart';
import '../../pro/live_pro.dart';
import 'sample/sample_entry.dart';
import 'samples/appearance/format_sample.dart';
import 'samples/appearance/grid_sample.dart';
import 'samples/appearance/theme_sample.dart';
import 'samples/appearance/time_axis_sample.dart';
import 'samples/appearance/watermark_sample.dart';
import 'samples/coordinates/axis_position_sample.dart';
import 'samples/coordinates/lock_range_sample.dart';
import 'samples/coordinates/scale_mode_sample.dart';
import 'samples/coordinates/secondary_axis_sample.dart';
import 'samples/data/data_limit_sample.dart';
import 'samples/data/history_sample.dart';
import 'samples/data/realtime_sample.dart';
import 'samples/extensions/custom_series_sample.dart';
import 'samples/extensions/depth_sample.dart';
import 'samples/extensions/overlay_sample.dart';
import 'samples/indicators/compute_sample.dart';
import 'samples/indicators/indicator_param_sample.dart';
import 'samples/indicators/indicator_switch_sample.dart';
import 'samples/indicators/panels_sample.dart';
import 'samples/interaction/crosshair_sample.dart';
import 'samples/interaction/gesture_sample.dart';
import 'samples/interaction/keyboard_sample.dart';
import 'samples/main/candle_style_sample.dart';
import 'samples/main/price_line_sample.dart';
import 'samples/main/series_sample.dart';
import 'samples/storage/storage_sample.dart';

/// All catalog entries: free samples + full-version samples (locked placeholders in the free
/// version), ordered by category.
List<SampleEntry> allSamples() {
  final all = [...coreSamples(), ...LivePro.settingSamples()];
  return [
    for (final category in SampleCategory.values) ...all.where((e) => e.category == category),
  ];
}

List<SampleEntry> coreSamples() => [
  SampleEntry(
    id: 'data-limit',
    category: SampleCategory.data,
    title: () => S.current.sampleDataLimitTitle,
    description: () => S.current.sampleDataLimitDesc,
    keywords: const ['setBars', 'maxBars'],
    builder: () => const DataLimitSample(),
  ),
  SampleEntry(
    id: 'realtime',
    category: SampleCategory.data,
    title: () => S.current.sampleRealtimeTitle,
    description: () => S.current.sampleRealtimeDesc,
    keywords: const ['applyTick', 'autoFollow'],
    builder: () => const RealtimeSample(),
  ),
  SampleEntry(
    id: 'history',
    category: SampleCategory.data,
    title: () => S.current.sampleHistoryTitle,
    description: () => S.current.sampleHistoryDesc,
    keywords: const ['onLoadMore', 'prependHistory'],
    builder: () => const HistorySample(),
  ),
  SampleEntry(
    id: 'series',
    category: SampleCategory.main,
    title: () => S.current.sampleSeriesTitle,
    description: () => S.current.sampleSeriesDesc,
    keywords: const ['seriesStyle', 'MainSeries'],
    builder: () => const SeriesSample(),
  ),
  SampleEntry(
    id: 'candle',
    category: SampleCategory.main,
    title: () => S.current.sampleCandleTitle,
    description: () => S.current.sampleCandleDesc,
    keywords: const ['CandleFillMode', 'upWick', 'upBorder'],
    builder: () => const CandleStyleSample(),
  ),
  SampleEntry(
    id: 'price',
    category: SampleCategory.main,
    title: () => S.current.samplePriceTitle,
    description: () => S.current.samplePriceDesc,
    keywords: const ['PriceLineOverlay', 'AxisPriceTags', 'animatePrice', 'showHighLow'],
    searchTerms: () => S.current.samplePriceSearchTerms,
    builder: () => const PriceLineSample(),
  ),
  SampleEntry(
    id: 'scale',
    category: SampleCategory.coordinates,
    title: () => S.current.sampleScaleTitle,
    description: () => S.current.sampleScaleDesc,
    keywords: const ['logScale', 'percentScale', 'invertScale'],
    builder: () => const ScaleModeSample(),
  ),
  SampleEntry(
    id: 'lock-range',
    category: SampleCategory.coordinates,
    title: () => S.current.sampleLockRangeTitle,
    description: () => S.current.sampleLockRangeDesc,
    keywords: const ['lockYRange', 'unlockYRange'],
    builder: () => const LockRangeSample(),
  ),
  SampleEntry(
    id: 'secondary-axis',
    category: SampleCategory.coordinates,
    title: () => S.current.sampleSecondaryAxisTitle,
    description: () => S.current.sampleSecondaryAxisDesc,
    keywords: const ['SecondaryAxis', 'secondaryFormatter'],
    builder: () => const SecondaryAxisSample(),
  ),
  SampleEntry(
    id: 'axis-position',
    category: SampleCategory.coordinates,
    title: () => S.current.sampleAxisPositionTitle,
    description: () => S.current.sampleAxisPositionDesc,
    keywords: const ['yAxisPosition', 'yAxisWidth'],
    builder: () => const AxisPositionSample(),
  ),
  SampleEntry(
    id: 'indicators',
    category: SampleCategory.indicators,
    title: () => S.current.sampleIndicatorsTitle,
    description: () => S.current.sampleIndicatorsDesc,
    keywords: const ['controller.indicators.setAll'],
    builder: () => const IndicatorSwitchSample(),
  ),
  for (final name in IndicatorParamSample.names)
    SampleEntry(
      id: 'indicator-${name.toLowerCase()}',
      category: SampleCategory.indicators,
      title: () => S.current.sampleIndicatorParamTitle(name),
      description: () => S.current.sampleIndicatorParamDesc,
      keywords: [name],
      builder: () => IndicatorParamSample(name),
    ),
  SampleEntry(
    id: 'panels',
    category: SampleCategory.indicators,
    title: () => S.current.samplePanelsTitle,
    description: () => S.current.samplePanelsDesc,
    keywords: const ['mainFlex', 'subFlex', 'panelResizable'],
    builder: () => const PanelsSample(),
  ),
  SampleEntry(
    id: 'compute',
    category: SampleCategory.indicators,
    title: () => S.current.sampleComputeTitle,
    description: () => S.current.sampleComputeDesc,
    keywords: const ['asyncCompute', 'onIndicatorError'],
    builder: () => const ComputeSample(),
  ),
  SampleEntry(
    id: 'crosshair',
    category: SampleCategory.interaction,
    title: () => S.current.sampleCrosshairTitle,
    description: () => S.current.sampleCrosshairDesc,
    keywords: const ['CrosshairSnap', 'tooltipBuilder'],
    builder: () => const CrosshairSample(),
  ),
  SampleEntry(
    id: 'gestures',
    category: SampleCategory.interaction,
    title: () => S.current.sampleGesturesTitle,
    description: () => S.current.sampleGesturesDesc,
    keywords: const ['yPan', 'axisDragScale', 'onBarTap'],
    builder: () => const GestureSample(),
  ),
  SampleEntry(
    id: 'keyboard',
    category: SampleCategory.interaction,
    title: () => S.current.sampleKeyboardTitle,
    description: () => S.current.sampleKeyboardDesc,
    keywords: const ['keyboard'],
    builder: () => const KeyboardSample(),
  ),
  SampleEntry(
    id: 'theme',
    category: SampleCategory.appearance,
    title: () => S.current.sampleThemeTitle,
    description: () => S.current.sampleThemeDesc,
    keywords: const ['KLineTheme'],
    builder: () => const ThemeSample(),
  ),
  SampleEntry(
    id: 'grid',
    category: SampleCategory.appearance,
    title: () => S.current.sampleGridTitle,
    description: () => S.current.sampleGridDesc,
    keywords: const ['showGrid', 'gridLineDash', 'axisTextSize'],
    builder: () => const GridSample(),
  ),
  SampleEntry(
    id: 'format',
    category: SampleCategory.appearance,
    title: () => S.current.sampleFormatTitle,
    description: () => S.current.sampleFormatDesc,
    keywords: const ['priceFormatter', 'timeFormatter', 'utcOffset', 'KChartLabels'],
    builder: () => const FormatSample(),
  ),
  SampleEntry(
    id: 'time-axis',
    category: SampleCategory.appearance,
    title: () => S.current.sampleTimeAxisTitle,
    description: () => S.current.sampleTimeAxisDesc,
    keywords: const ['tieredTimeAxis', 'tickFormatter', 'TimeTier'],
    builder: () => const TimeAxisSample(),
  ),
  SampleEntry(
    id: 'watermark',
    category: SampleCategory.appearance,
    title: () => S.current.sampleWatermarkTitle,
    description: () => S.current.sampleWatermarkDesc,
    keywords: const ['underlayBuilder'],
    builder: () => const WatermarkSample(),
  ),
  SampleEntry(
    id: 'overlay',
    category: SampleCategory.extensions,
    title: () => S.current.sampleOverlayTitle,
    description: () => S.current.sampleOverlayDesc,
    keywords: const ['overlayBuilder', 'RenderContext'],
    builder: () => const OverlaySample(),
  ),
  SampleEntry(
    id: 'custom-series',
    category: SampleCategory.extensions,
    title: () => S.current.sampleCustomSeriesTitle,
    description: () => S.current.sampleCustomSeriesDesc,
    keywords: const ['MainSeries.paint', 'SeriesPaintKit'],
    builder: () => const CustomSeriesSample(),
  ),
  SampleEntry(
    id: 'depth',
    category: SampleCategory.extensions,
    title: () => S.current.sampleDepthTitle,
    description: () => S.current.sampleDepthDesc,
    keywords: const ['DepthChart', 'DepthLevel'],
    builder: () => const DepthSample(),
  ),
  SampleEntry(
    id: 'storage',
    category: SampleCategory.storage,
    title: () => S.current.sampleStorageTitle,
    description: () => S.current.sampleStorageDesc,
    keywords: const ['saveState', 'restoreState', 'toJson'],
    builder: () => const StorageSample(),
  ),
];
