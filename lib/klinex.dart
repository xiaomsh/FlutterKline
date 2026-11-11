/// klinex: a lightweight, fast, plugin-based K-line chart with zero third-party dependencies.
/// Entry points are [ChartController] (data source) + [KChart] (widget); extend with [Indicator],
/// [OverlayPlugin], and [MainSeries].
library;

import 'klinex.dart';

export 'src/controller.dart' show ChartController;
export 'src/debug.dart' show KlinexDebug;
export 'src/indicator/builtin/boll.dart';
export 'src/indicator/builtin/ema.dart';
export 'src/indicator/builtin/kdj.dart';
export 'src/indicator/builtin/ma.dart';
export 'src/indicator/builtin/macd.dart';
export 'src/indicator/builtin/rsi.dart';
export 'src/indicator/builtin/vol.dart';
export 'src/indicator/builtin/wr.dart';
export 'src/indicator/indicator.dart'
    show
        Indicator,
        LineIndicator,
        IndicatorStore,
        LegendItem,
        legendOfKeys,
        paintSeriesLines,
        seriesColor,
        seriesRange;
export 'src/indicator/indicator_registry.dart';
export 'src/indicator/indicator_set.dart';
export 'src/indicator/secondary_axis.dart';
export 'src/interaction/gesture_binding.dart';
export 'src/interaction/interaction_mode.dart';
export 'src/interaction/level_drag.dart';
export 'src/model/bar.dart';
export 'src/model/bar_aggregator.dart';
export 'src/model/crosshair_state.dart';
export 'src/model/data_source.dart' show DataChange, DataSource;
export 'src/model/min_max.dart';
export 'src/model/time_map.dart';
export 'src/model/viewport.dart';
export 'src/overlay/builtin/crosshair.dart';
export 'src/overlay/builtin/legend.dart';
export 'src/overlay/builtin/price_line.dart';
export 'src/overlay/overlay_plugin.dart';
export 'src/panel/panel.dart';
export 'src/render/context.dart'
    show
        CandleFillMode,
        ChartConfig,
        CrosshairSnap,
        MainSeriesStyle,
        MainSeriesStyleScale,
        PanelLayout,
        YPanMode,
        RenderContext,
        YAxisPosition,
        defaultCompactFormat;
export 'src/render/main_series.dart';
export 'src/render/paint_pool.dart';
export 'src/render/series/area_series.dart';
export 'src/render/series/candle_series.dart';
export 'src/render/series/line_series.dart';
export 'src/render/series_paint_kit.dart';
export 'src/render/time_ticks.dart' show TimeTier, defaultTickLabel, pickTimeTicks;
export 'src/theme/theme.dart';
export 'src/widget/depth_chart.dart';
export 'src/widget/kchart.dart';
