import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../controller.dart';
import '../debug.dart';
import '../interaction/gesture_binding.dart';
import '../interaction/interaction_mode.dart';
import '../interaction/level_drag.dart';
import '../model/bar.dart';
import '../model/time_map.dart';
import '../model/viewport.dart';
import '../render/context.dart';
import '../render/grid_painter.dart';
import '../render/indicator_painter.dart';
import '../render/main_series.dart';
import '../render/overlay_painter.dart';
import '../render/range_adjust.dart';
import '../render/series_painter.dart';
import '../render/slot_axis.dart';
import '../render/time_ticks.dart';
import '../theme/theme.dart';
import 'chart_gestures.dart';
import 'chart_keys.dart';
import 'chart_layers.dart';
import 'crosshair_snapshot.dart';
import 'default_tooltip.dart';
import 'inline_tooltip.dart';
import 'kchart_config.dart';
import 'load_more_trigger.dart';
import 'price_animator.dart';

export 'crosshair_snapshot.dart';

String _defaultPriceFormat(double v) {
  final a = v.abs();
  if (a == 0 || !a.isFinite) return v.toStringAsFixed(2);
  // At least 2 decimals and 4 significant digits: low-priced coins like 0.0000123 don't all show
  // as 0.00,
  // and near 1 (stablecoins) both sides have matching digits (1.000 / 0.9999)
  final digits = (3 - (math.log(a) / math.ln10).floor()).clamp(2, 12);
  return v.toStringAsFixed(digits);
}

/// Default time format follows the data interval: daily and above show y-m-d (so month-day
/// isn't ambiguous across years of history), intraday shows m-d + h:m, seconds add seconds
String _defaultTimeFormat(int millis, Duration? utcOffset, List<Bar> bars) {
  final dt = utcOffset == null
      ? DateTime.fromMillisecondsSinceEpoch(millis)
      : DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true).add(utcOffset);
  String p2(int n) => n.toString().padLeft(2, '0');
  final period = avgPeriodMsOf(bars);
  if (period >= Duration.millisecondsPerDay) {
    return '${dt.year}-${p2(dt.month)}-${p2(dt.day)}';
  }
  final hm = '${p2(dt.month)}-${p2(dt.day)} ${p2(dt.hour)}:${p2(dt.minute)}';
  return period > 0 && period < Duration.millisecondsPerMinute ? '$hm:${p2(dt.second)}' : hm;
}

/// Candlestick chart widget: stacked canvas layers plus three optional widget layers:
/// [underlayBuilder], tooltip, [overlayBuilder].
/// [controller] is owned and disposed by the caller
class KChart extends StatefulWidget {
  const KChart({
    super.key,
    required this.controller,
    required this.theme,
    this.priceFormatter = _defaultPriceFormat,
    this.subValueFormatter,
    this.volumeFormatter,
    this.volumeAxisFormatter,
    this.secondaryFormatter,
    this.timeFormatter,
    this.utcOffset,
    this.labels = const KChartLabels(),
    this.tooltipBuilder,
    this.showTooltip = true,
    this.tooltipStyle = KChartTooltipStyle.inline,
    this.onLoadMore,
    this.mode,
    this.levelDrag,
    this.animatePrice = false,
    this.animateRange = false,
    this.mainFlex = 3,
    this.subFlex = 1,
    this.logScale = false,
    this.percentScale = false,
    this.percentBase,
    this.percentRightOnly = false,
    this.mainRange,
    this.slotAxis,
    this.outlierClampRatio,
    this.seriesStyle = MainSeriesStyle.candle,
    this.series,
    this.candleFill = CandleFillMode.solid,
    this.showHighLow = false,
    this.tieredTimeAxis = false,
    this.invertScale = false,
    this.tickFormatter,
    this.tickMinSpacing = 64,
    this.rightBlankRatio = 1.0,
    this.initialRightBlankRatio = 1 / 3,
    this.autoFollow = false,
    this.yAxisPosition = YAxisPosition.outside,
    this.yAxisWidth = 56,
    this.mainPaddingTop = 28,
    this.mainPaddingBottom = 10,
    this.panelResizable = false,
    this.yPan = YPanMode.none,
    this.yFitValues,
    this.crosshairSnap = CrosshairSnap.free,
    this.axisDragScale = false,
    this.keyboard = true,
    this.timeAxisHeight = 22,
    this.panelWeights,
    this.minBarWidth,
    this.maxBarWidth,
    this.underlayBuilder,
    this.overlayBuilder,
    this.onBarTap,
  }) : assert(yAxisWidth >= 0),
       assert(mainPaddingTop >= 0 && mainPaddingBottom >= 0),
       assert(rightBlankRatio >= 0 && rightBlankRatio <= 1),
       assert(
         minBarWidth == null || maxBarWidth == null || minBarWidth <= maxBarWidth,
         'minBarWidth must not exceed maxBarWidth',
       ),
       assert(
         initialRightBlankRatio >= 0 && initialRightBlankRatio <= rightBlankRatio,
         'initialRightBlankRatio must be within [0, rightBlankRatio]',
       );

  final ChartController controller;
  final KLineTheme theme;

  /// Price format. Defaults to at least 2 decimals and 4 significant digits (60000.00, 1.234,
  /// 0.00001234)
  final PriceFormatter priceFormatter;

  /// Sub-chart number format; null uses built-in K/M/B
  final PriceFormatter? subValueFormatter;

  /// Volume format (volume bars, tooltip); null uses built-in K/M/B
  final PriceFormatter? volumeFormatter;

  /// Volume ticks and crosshair label format; null uses built-in K/M/B
  final PriceFormatter? volumeAxisFormatter;

  /// Tick format for the main chart's second value axis (`SecondaryAxis` indicators, overlay
  /// plugins' `secondaryRange`); null uses [priceFormatter]
  final PriceFormatter? secondaryFormatter;

  /// Custom time format; when given, [utcOffset] is ignored. Pass a stable reference
  final TimeFormatter? timeFormatter;

  /// Time zone for the built-in time format: null follows the device; fixed offsets ignore DST
  /// (pass your own [timeFormatter] to handle it)
  final Duration? utcOffset;

  final KChartLabels labels;

  /// Custom tooltip; null uses the built-in OHLCV card
  final TooltipBuilder? tooltipBuilder;

  /// false hides the tooltip (crosshair labels remain)
  final bool showTooltip;

  /// Built-in tooltip style (when [tooltipBuilder] is not given): defaults to a fixed row at the
  /// main chart's top-left, above the indicator legend;
  /// [KChartTooltipStyle.card] is a floating card that switches sides with the crosshair
  final KChartTooltipStyle tooltipStyle;

  /// Called when scrolled to the oldest edge (once per data batch): after loading history, call
  /// [ChartController.prependHistory]
  final VoidCallback? onLoadMore;

  final InteractionMode? mode;

  /// Dragging a price line changes its price; the host draws the line in [overlayBuilder] from its
  /// state
  final LevelDragController? levelDrag;

  /// Last-price animation: on tick, the last bar's close and the last-price line slide to the new
  /// value over ~200ms, display only
  final bool animatePrice;

  /// 250ms tween for data-driven range changes; changes from horizontal panning and x zoom always
  /// tween, y zoom is always instant
  final bool animateRange;

  final double mainFlex;
  final double subFlex;

  /// Main chart log scale (falls back to linear when the visible range isn't all positive)
  final bool logScale;

  /// Percentage scale: main chart ticks and crosshair labels show change relative to the first
  /// visible close
  final bool percentScale;

  /// Fixed base for [percentScale] labels (e.g. a stock's previous close); null uses the first
  /// visible close
  final double? percentBase;

  /// With [percentScale] and a left tick strip ([YAxisPosition.both]): prices on the left,
  /// percent on the right
  final bool percentRightOnly;

  /// Adjusts the final main range (after padding), e.g. `StockRange`; see
  /// [ChartConfig.mainRange]. Relayouts only when it changes by `==`
  final RangeAdjust? mainRange;

  /// Fixed-slot time axis for intraday charts (e.g. `IntradayAxis`): the chart no longer scrolls
  /// or zooms and bar `i` sits in slot `i`. Relayouts only when it changes by `==`
  final SlotAxis? slotAxis;

  /// Spike clamping: high/low may exceed the visible close range by at most span * this factor
  /// (0.5~2 recommended); null disables
  final double? outlierClampRatio;

  /// Built-in main series style, overridden by [series]
  final MainSeriesStyle seriesStyle;

  /// Custom main series; when non-null takes precedence over [seriesStyle]
  final MainSeries? series;

  /// Max blank space draggable right of the latest bar (fraction of chart width): 1 drags it to
  /// the left edge, 0 keeps the latest bar flush right (at least half a bar)
  final double rightBlankRatio;

  /// Right blank fraction on first landing (load, interval switch); must not exceed
  /// [rightBlankRatio]
  final double initialRightBlankRatio;

  /// When true, stays on the latest bar and follows new bars; scrolling away stops following.
  /// Default false: appending doesn't move the x axis
  final bool autoFollow;

  /// Y-axis tick position: inside overlays the chart, outside reserves a [yAxisWidth] strip on the
  /// right, left on the left, both on both sides
  final YAxisPosition yAxisPosition;
  final double yAxisWidth;

  /// Top/bottom padding of the main chart range (px)
  final double mainPaddingTop;
  final double mainPaddingBottom;

  /// Whether dragging dividers between panels resizes them; off by default
  final bool panelResizable;

  /// Where single-finger vertical drags pan the main chart range; no panning by default (left to
  /// the outer page scroll)
  final YPanMode yPan;

  /// Price levels that must stay visible when manually shrinking the y axis (order lines,
  /// position lines)
  final List<double> Function()? yFitValues;

  /// Crosshair vertical snapping: follow finger, snap to close, or nearest OHLC
  final CrosshairSnap crosshairSnap;

  /// Vertical drag on the price scale zooms y, horizontal drag on the time axis zooms x
  final bool axisDragScale;

  /// Responds to keyboard after the chart is clicked with a mouse: left/right pan, up/down zoom,
  /// Home / End (End resumes following), Esc; only Esc during exclusive drawing
  final bool keyboard;

  final double timeAxisHeight;

  /// Panel height weights (panel id to weight); unlisted panels use mainFlex / subFlex
  final Map<String, double>? panelWeights;

  /// Bar width limits for x zoom (px); null uses library defaults (0.25 physical px ~ 48)
  final double? minBarWidth;
  final double? maxBarWidth;

  final CandleFillMode candleFill;

  /// Marks the visible high and low (close extremes for close-only styles), colored with
  /// [KLineTheme.highLowText]
  final bool showHighLow;

  /// Main chart inverted scale, see [ChartConfig.invertScale]
  final bool invertScale;

  /// Tiered time axis, see [ChartConfig.tieredTimeAxis]; time zone follows [utcOffset]
  final bool tieredTimeAxis;

  /// Tiered tick text; null uses [defaultTickLabel]; pass a stable reference. Receives the bar's
  /// raw UTC ms; do time zone conversion yourself
  final String Function(int millis, TimeTier tier)? tickFormatter;

  /// Minimum pixel gap between tiered ticks
  final double tickMinSpacing;

  /// Host widget layer above the canvas, using [RenderContext] for coordinates. Rebuilt when data,
  /// viewport, layout or theme change; keep it light
  final Widget Function(BuildContext context, RenderContext ctx)? overlayBuilder;

  /// Host widget layer between the grid and main chart, suited to gesture-free decorations like
  /// watermarks
  final Widget Function(BuildContext context, RenderContext ctx)? underlayBuilder;

  /// Tap on a bar (touch tap, left mouse click). When set, double-tap to reset the y axis is
  /// disabled
  final ValueChanged<Bar>? onBarTap;

  @override
  State<KChart> createState() => _KChartState();
}

class _KChartState extends State<KChart> with TickerProviderStateMixin, WidgetsBindingObserver {
  late ChartConfig _config;
  late AnimationController _fling;
  late PriceAnimator _price;
  late GestureCoordinator _gesture;
  late GridPainter _grid;
  late GridPainter _plotLabels;
  late SeriesPainter _series;
  late IndicatorPainter _indicators;
  late List<OverlayPainter> _overlayLayers;
  late List<OverlayPainter> _overlayTopLayers;
  var _loadMore = LoadMoreTrigger();
  final _focus = FocusNode(debugLabel: 'KChart');

  /// Rebuild tick for the overlayBuilder / underlayBuilder widget layers
  late Listenable _overlaySources;

  /// Tooltip follows crosshair and data: the selected bar changes live, so the card must update
  /// even when the mouse is still
  late Listenable _tooltipSources;

  /// Accessibility description follows the visible range and last price
  late Listenable _semanticsSources;
  final ValueNotifier<int> _overlayWidgetRev = ValueNotifier(0);
  bool _overlayBuildScheduled = false;
  RenderContext? _lastOverlayCtx;
  bool _overlayForceRebuild = true;
  double? _overlayAnimatedSnapshot;
  Size _lastSize = Size.zero;

  /// Diagnostics: attaches a log-only listener to each repaint channel (not attached when
  /// [KlinexDebug.logChannel] is off)
  final List<(Listenable, VoidCallback)> _channelTaps = [];

  ChartController get _controller => widget.controller;

  /// Width bars are laid out over: widget width minus outside tick strips on both sides
  double get _plotWidth {
    final axisW = _config.leftAxisWidth + _config.rightAxisWidth;
    return (_lastSize.width - axisW).clamp(0.0, _lastSize.width);
  }

  /// Uses the host's if given; the built-in one follows the current data interval, so bars are read
  /// at call time
  TimeFormatter get _effectiveTimeFormatter =>
      widget.timeFormatter ?? (ms) => _defaultTimeFormat(ms, widget.utcOffset, _controller.bars);

  @override
  void initState() {
    super.initState();
    _config = buildChartConfig(widget, _effectiveTimeFormatter);
    final weights = widget.panelWeights;
    if (weights != null) _config.panelWeights.addAll(weights);
    if (widget.minBarWidth != null) {
      _controller.viewport.minBarWidth = widget.minBarWidth!;
    }
    _controller.viewport.fixedSlots = widget.slotAxis?.slotCount;
    _fling = AnimationController.unbounded(vsync: this);
    _price = PriceAnimator(this, _controller, enabled: () => widget.animatePrice);
    _wire();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didHaveMemoryPressure() => _controller.releaseCaches();

  void _wire() {
    // On controller switch the new controller still has default limits; carry over host-given
    // limits
    _controller.viewport.maxBarWidth = widget.maxBarWidth ?? ChartViewport.defaultMaxBarWidth;
    // A new controller means different data; the previous one's "page already requested" must not
    // block the new one
    _loadMore = LoadMoreTrigger();
    _gesture = GestureCoordinator(
      controller: _controller,
      resolve: () => _controller.resolveLayout(_lastSize, _config),
      fling: _fling,
      // Read via widget: the coordinator is built once, so it must follow parent callback changes
      onBarTap: (bar) => widget.onBarTap?.call(bar),
      mode: widget.mode,
    )..levelDrag = widget.levelDrag;
    _grid = GridPainter(_controller, _config);
    _plotLabels = GridPainter(_controller, _config, plotLabels: true);
    _series = SeriesPainter(_controller, _config);
    _indicators = IndicatorPainter(_controller, _config);
    _overlayLayers = OverlayPainter.split(_controller, _config, onTop: false);
    _overlayTopLayers = OverlayPainter.split(_controller, _config, onTop: true);
    // Build only once: merging on every rebuild would subscribe repeatedly
    _overlaySources = Listenable.merge([
      _controller.dataRevision,
      _controller.rangeRevision,
      _controller.viewport,
      _controller.indicators,
      _config.theme,
      _config.layoutRevision,
      _controller.animatedLastClose,
    ]);
    _overlaySources.addListener(_onOverlaySourceChanged);
    _tooltipSources = Listenable.merge([_controller.crosshair, _controller.dataRevision]);
    _semanticsSources = Listenable.merge([_controller.dataRevision, _controller.viewport]);
    _tapChannels();
    _lastOverlayCtx = null;
    _overlayForceRebuild = true;
    _overlayAnimatedSnapshot = _controller.animatedLastClose.value;
    _controller.viewport.addListener(_maybeLoadMore);
    _controller.dataRevision.addListener(_price.onData);
    _price.attach(_controller);
  }

  void _unwire(ChartController controller) {
    _untapChannels();
    _overlaySources.removeListener(_onOverlaySourceChanged);
    controller.viewport.removeListener(_maybeLoadMore);
    controller.dataRevision.removeListener(_price.onData);
    _price.stop();
    _fling.stop();
    // Clear leftover interpolation and crosshair: the controller is still alive, and the next
    // attach shouldn't carry a crosshair from an unreleased press.
    // Deferred to post-frame: we're in dispose / didUpdateWidget with the tree locked, so a linked
    // chart or host listener can't rebuild now.
    // The host may have already disposed the controller; no writes after dispose
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (controller.isDisposed || (mounted && identical(controller, _controller))) return;
      controller.animatedLastClose.value = null;
      controller.crosshair.value = null;
      controller.tooltipInset.value = 0;
    });
    _gesture.dispose();
  }

  void _maybeLoadMore() => _loadMore.check(_controller, widget.onLoadMore);

  /// Overlay widgets rebuild coalesced per frame; skipped when layout is unchanged
  void _onOverlaySourceChanged() {
    final animNow = _controller.animatedLastClose.value;
    if (animNow != _overlayAnimatedSnapshot) {
      _overlayAnimatedSnapshot = animNow;
      _overlayForceRebuild = true;
    }
    if (_overlayBuildScheduled) return;
    _overlayBuildScheduled = true;
    final scheduler = SchedulerBinding.instance;
    scheduler.scheduleFrameCallback((_) {
      _overlayBuildScheduled = false;
      if (!mounted) return;
      final ctx = _controller.resolveLayout(_lastSize, _config);
      if (!_overlayForceRebuild && identical(ctx, _lastOverlayCtx)) {
        if (KlinexDebug.logData) KlinexDebug.data('overlayRev', 'layout unchanged → skip rebuild');
        return;
      }
      if (KlinexDebug.logData) {
        KlinexDebug.data(
          'overlayRev',
          'trigger overlayBuilder rebuild (force=$_overlayForceRebuild '
              'ctxChanged=${!identical(ctx, _lastOverlayCtx)})',
        );
      }
      _lastOverlayCtx = ctx;
      _overlayForceRebuild = false;
      _overlayWidgetRev.value++;
    });
    scheduler.scheduleFrame();
  }

  void _tapChannels() {
    if (!KlinexDebug.logChannel) return;
    void tap(String name, Listenable ch) {
      void listener() => KlinexDebug.channel(name);
      ch.addListener(listener);
      _channelTaps.add((ch, listener));
    }

    tap('dataRevision', _controller.dataRevision);
    tap('rangeRevision', _controller.rangeRevision);
    tap('viewport', _controller.viewport);
    tap('indicators', _controller.indicators);
    tap('crosshair', _controller.crosshair);
    tap('animatedLastClose', _controller.animatedLastClose);
    tap('theme', _config.theme);
    tap('layoutRevision', _config.layoutRevision);
    for (final o in _controller.overlays) {
      for (final ch in o.repaintOn(_controller)) {
        tap('${o.runtimeType}:${ch.runtimeType}', ch);
      }
    }
    KlinexDebug.channel(
      'layers',
      'L3=${_overlayLayers.map((l) => l.debugLayerName).join(' ')} '
          'top=${_overlayTopLayers.map((l) => l.debugLayerName).join(' ')}',
    );
  }

  void _untapChannels() {
    for (final (ch, listener) in _channelTaps) {
      ch.removeListener(listener);
    }
    _channelTaps.clear();
  }

  @override
  void didUpdateWidget(KChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    syncChartConfig(_config, widget, oldWidget, _effectiveTimeFormatter);
    _gesture.levelDrag = widget.levelDrag;

    if (widget.theme != oldWidget.theme) {
      _config.theme.value = widget.theme;
    }
    // The tooltip row is no longer drawn, so its measured height must not keep pushing the legend
    if (oldWidget.showTooltip && !widget.showTooltip) _setTooltipInset(0);
    // Right blank and bar width limits are clamped separately but merged into one notification, so
    // linked charts don't mirror the same update several times
    _controller.viewport.batch(() {
      final vp = _controller.viewport;
      if (widget.rightBlankRatio != oldWidget.rightBlankRatio) {
        vp.rightBlankRatio = widget.rightBlankRatio;
        // When the ratio shrinks, pull an out-of-range position back
        vp.setRightIndex(vp.rightIndex);
      }
      if (widget.minBarWidth != oldWidget.minBarWidth ||
          widget.maxBarWidth != oldWidget.maxBarWidth) {
        if (widget.minBarWidth != null) vp.minBarWidth = widget.minBarWidth!;
        // Resetting to null must restore the default limit, not keep the previous one
        vp.maxBarWidth = widget.maxBarWidth ?? ChartViewport.defaultMaxBarWidth;
        // New bounds don't apply automatically; the current bar width may already be out of range
        vp.clampBarWidthBounds();
      }
      // Affects only future landings; doesn't move the current position
      vp.initialRightBlankRatio = widget.initialRightBlankRatio;
      vp.fixedSlots = widget.slotAxis?.slotCount;
    });
    if (widget.controller != oldWidget.controller) {
      _unwire(oldWidget.controller);
      _wire();
      _controller.viewport.fixedSlots = widget.slotAxis?.slotCount;
      _controller.viewport.clampBarWidthBounds();
    } else if (widget.mode != oldWidget.mode) {
      _gesture.mode = widget.mode ?? BrowseMode();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _unwire(_controller);
    _fling.dispose();
    _focus.dispose();
    _price.dispose();
    _overlayWidgetRev.dispose();
    _config.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    // Moved to a screen with a different pixel ratio: pixel alignment and decimation need
    // recomputing, and the layout cache doesn't track this, so invalidate manually
    if (dpr != _config.devicePixelRatio) {
      _config.devicePixelRatio = dpr;
      _config.bumpLayout();
    }
    // By default allows zooming down to 1/4 physical pixel per bar (subpixels handled by paint-time
    // aggregation); host-given minBarWidth wins
    final vp = _controller.viewport;
    vp.minBarWidth = widget.minBarWidth ?? 0.25 / dpr;
    // A larger floor may leave the current bar width out of range; we're in build, so clamp after
    // this frame to avoid notifying listeners during build
    if (vp.barWidth < vp.minBarWidth) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // The controller may have been swapped and the old one disposed this frame; fetch again
        if (mounted && !_controller.isDisposed) _controller.viewport.clampBarWidthBounds();
      });
    }
    _controller.viewport
      ..rightBlankRatio = widget.rightBlankRatio
      ..initialRightBlankRatio = widget.initialRightBlankRatio
      ..autoFollow = widget.autoFollow;
    _controller.animateRange = widget.animateRange;

    if (KlinexDebug.logRebuild) KlinexDebug.rebuild('KChart.build');
    return LayoutBuilder(
      builder: (context, constraints) {
        _lastSize = constraints.biggest;
        if (KlinexDebug.logRebuild) {
          KlinexDebug.rebuild('LayoutBuilder', '${constraints.biggest}');
        }
        _controller.viewport.attach(_plotWidth);
        final chart = ChartGestures(
          // Switching controllers creates a new coordinator, so recognizers must be rebuilt too, or
          // their predicate closures still capture the old one
          key: ObjectKey(_gesture),
          gesture: _gesture,
          hasBarTap: () => widget.onBarTap != null,
          child: ChartLayers(
            grid: _grid,
            plotLabels: _plotLabels,
            series: _series,
            indicators: _indicators,
            overlayLayers: _overlayLayers,
            overlayTopLayers: _overlayTopLayers,
            overlayRev: _overlayWidgetRev,
            resolve: () => _controller.resolveLayout(_lastSize, _config),
            underlayBuilder: widget.underlayBuilder,
            overlayBuilder: widget.overlayBuilder,
            tooltip: widget.showTooltip
                ? ListenableBuilder(
                    listenable: _tooltipSources,
                    builder: (context, _) {
                      if (KlinexDebug.logRebuild) KlinexDebug.rebuild('tooltip');
                      return _buildTooltip(context);
                    },
                  )
                : null,
          ),
        );
        final described = ListenableBuilder(
          listenable: _semanticsSources,
          builder: (context, child) =>
              Semantics(container: true, label: _semanticsLabel(), child: child),
          child: chart,
        );
        if (!widget.keyboard) return described;
        // Grab focus only on mouse down: on touch, grabbing focus would dismiss keyboards of other
        // inputs
        return Focus(
          focusNode: _focus,
          onKeyEvent: (node, event) {
            final r = handleChartKey(event, _controller, exclusive: _gesture.mode.exclusive);
            // Inertia still running after a key jump would drag the position away again
            if (r == KeyEventResult.handled) _fling.stop();
            return r;
          },
          child: Listener(
            onPointerDown: (e) {
              if (e.kind == PointerDeviceKind.mouse) _focus.requestFocus();
            },
            child: described,
          ),
        );
      },
    );
  }

  /// "Candlestick chart, start to end, last price x"; reports only the chart name without data
  String _semanticsLabel() {
    final labels = widget.labels;
    final bars = _controller.bars;
    if (bars.isEmpty || _lastSize.isEmpty) return labels.chart;
    final ctx = _controller.resolveLayout(_lastSize, _config);
    final from = ctx.start.clamp(0, bars.length - 1);
    final to = ctx.end.clamp(0, bars.length - 1);
    final fmtTime = _config.timeFormatter;
    final sep = labels.separator;
    return '${labels.chart}$sep${fmtTime(bars[from].time)} ${labels.rangeTo} ${fmtTime(bars[to].time)}'
        '$sep${labels.latest} ${_config.priceFormatter(bars.last.close)}';
  }

  void _setTooltipInset(double h) {
    if (!mounted || _controller.isDisposed) return;
    if (_controller.tooltipInset.value != h) _controller.tooltipInset.value = h;
  }

  Widget _buildTooltip(BuildContext context) {
    final state = _controller.crosshair.value;
    final bars = _controller.bars;
    if (state == null || bars.isEmpty) return const SizedBox.shrink();
    // A synced crosshair only has a real time; a card would smear in the corner and jump with
    // someone else's finger
    if (state.timeOnly) {
      _setTooltipInset(0);
      return const SizedBox.shrink();
    }
    final index = _controller.crosshairIndex();
    if (index < 0) return const SizedBox.shrink();
    final snapshot = CrosshairSnapshot.lazy(
      index: index,
      bar: bars[index],
      position: state.position,
      indicatorValuesLoader: () => _controller.indicatorValuesAt(index),
    );
    if (widget.tooltipBuilder != null) {
      _setTooltipInset(0);
      return widget.tooltipBuilder!(context, snapshot);
    }
    if (widget.tooltipStyle == KChartTooltipStyle.inline) {
      return InlineTooltip(
        snapshot: snapshot,
        theme: _config.theme.value,
        priceFormatter: _config.priceFormatter,
        labels: widget.labels,
        left: _lastSize.isEmpty
            ? 0
            : _controller.resolveLayout(_lastSize, _config).mainPanel.rect.left,
        onHeight: _setTooltipInset,
      );
    }
    _setTooltipInset(0);
    return DefaultTooltip(
      snapshot: snapshot,
      theme: _config.theme.value,
      priceFormatter: _config.priceFormatter,
      timeFormatter: _config.timeFormatter,
      volumeFormatter: _config.volumeFormatter,
      labels: widget.labels,
      chartWidth: _plotWidth,
    );
  }
}

/// Built-in tooltip style
enum KChartTooltipStyle {
  /// Fixed row at the main chart's top-left, above the indicator legend (the legend shifts down
  /// while the crosshair shows); doesn't follow the finger
  inline,

  /// Floating card: hugs the left when the crosshair is in the right half, the right when in the
  /// left half
  card,
}
