import 'dart:math' as math;
import 'dart:ui';

import '../controller.dart';
import '../indicator/indicator.dart';
import '../model/data_source.dart';
import '../model/min_max.dart';
import '../overlay/builtin/legend.dart';
import 'context.dart';
import 'range_animator.dart';

/// Indicators that land on the same panel.
class _PanelGroup {
  const _PanelGroup({required this.id, required this.isMain, required this.indicators});

  final String id;
  final bool isMain;
  final List<Indicator> indicators;
}

/// Computes a frame's layout: visible range, panel rects and value ranges, shared by all
/// painters. Reuses the previous frame's if size, viewport, data, indicators and theme are all
/// unchanged; also reuses it if data changed only outside the visible range.
class LayoutResolver {
  LayoutResolver(this.controller) {
    range = RangeAnimator(() => controller.rangeRevision.value++);
    for (final o in controller.overlays) {
      if (o is IndicatorLegendOverlay) {
        _legend = o;
        break;
      }
    }
  }

  final ChartController controller;
  late final RangeAnimator range;

  /// Legend plugin (if attached): the main panel's top padding grows with its row height per
  /// indicator.
  IndicatorLegendOverlay? _legend;

  int _groupsGen = -1;
  List<_PanelGroup> _groups = const [];
  List<String> _groupIds = const [];

  RenderContext? _ctx;
  double _ctxW = -1, _ctxH = -1;
  int _ctxVpGen = -1, _ctxMut = -1, _ctxIndGen = -1, _ctxLayoutRev = -1;
  int _ctxAnimGen = -1;
  Object? _ctxTheme;
  Object? _ctxConfig;

  int _seenUserGen = -1, _seenEpoch = -1;
  double _seenYScale = 1.0;
  double _seenYOffset = 0;

  void dispose() => range.disposed = true;

  /// Drops the cached layout so the next frame recomputes (used when plugin-contributed ranges
  /// change).
  void invalidate() => _ctx = null;

  /// The main panel's actual range in the last frame (including manual scaling and tweens);
  /// null if nothing has been drawn yet.
  MinMax? get lastMainRange {
    final ctx = _ctx;
    return ctx == null || ctx.panels.isEmpty ? null : ctx.mainPanel.range;
  }

  RenderContext resolve(Size size, ChartConfig config) {
    final viewport = controller.viewport;
    final data = controller.data;
    final indicators = controller.indicators;
    final theme = config.theme.value;
    // Outside axis strips are reserved on both sides; the plot area and the viewport's bar
    // mapping sit between them.
    final axisL = config.leftAxisWidth.clamp(0.0, size.width);
    final axisR = config.rightAxisWidth.clamp(0.0, size.width - axisL);
    final plotW = size.width - axisL - axisR;
    viewport.attach(plotW);

    final cached = _ctx;
    // Tween-eligible: since the last frame only data, horizontal gestures and tween frames
    // changed; changes to y scale, indicators, layout, theme, size or symbol jump directly.
    final animEligible =
        cached != null &&
        _ctxW == size.width &&
        _ctxH == size.height &&
        _seenYScale == viewport.yScale &&
        _seenYOffset == viewport.yOffset &&
        _ctxIndGen == indicators.generation &&
        _ctxLayoutRev == config.layoutRevision.value &&
        identical(_ctxConfig, config) &&
        identical(_ctxTheme, theme) &&
        _seenEpoch == controller.dataEpoch;
    // Range changes from horizontal gestures (pan, x zoom, linked mirroring) always tween,
    // regardless of animateRange.
    final xGesture = _seenUserGen != viewport.userGeneration;
    _seenUserGen = viewport.userGeneration;
    _seenYScale = viewport.yScale;
    _seenYOffset = viewport.yOffset;
    _seenEpoch = controller.dataEpoch;
    final sameStatic =
        cached != null &&
        _ctxW == size.width &&
        _ctxH == size.height &&
        _ctxVpGen == viewport.generation &&
        _ctxIndGen == indicators.generation &&
        _ctxLayoutRev == config.layoutRevision.value &&
        _ctxAnimGen == range.generation &&
        identical(_ctxConfig, config) &&
        identical(_ctxTheme, theme);
    if (sameStatic && _ctxMut == data.mutations) return cached;
    // Exactly one append / last-bar update outside the visible range: the range can't change.
    // Multiple changes coalesced into one frame, or a replace (all downstream recurrences
    // change), must recompute.
    if (sameStatic &&
        data.mutations == _ctxMut + 1 &&
        (data.lastChange == DataChange.append || data.lastChange == DataChange.updateLast) &&
        (data.lastChangeIndex > cached.end || data.lastChangeIndex < cached.start)) {
      _ctxMut = data.mutations;
      return cached;
    }

    final (start, end) = viewport.visibleRange();
    final chartH = (size.height - config.timeAxisHeight).clamp(0.0, double.infinity);
    final chartRect = Rect.fromLTWH(axisL, 0, plotW, chartH);
    final timeAxisRect = Rect.fromLTWH(axisL, chartH, plotW, config.timeAxisHeight);
    final yAxisRect = Rect.fromLTWH(axisL + plotW, 0, axisR, chartH);
    final leftAxisRect = Rect.fromLTWH(0, 0, axisL, chartH);

    final groups = _groupsForLayout(config);
    var totalFlex = 0.0;
    for (final group in groups) {
      totalFlex += config.weightFor(group.id, group.isMain);
    }
    range.prune(_groupIds);
    final smoothEnabled = controller.animateRange || xGesture || range.isActive;
    final panels = <PanelLayout>[];
    var top = 0.0;
    for (final group in groups) {
      final isMain = group.isMain;
      final h = chartH * config.weightFor(group.id, isMain) / totalFlex;
      final rect = Rect.fromLTWH(axisL, top, plotW, h);
      top += h;

      final locked = isMain ? viewport.lockedYRange : null;
      var mm = MinMax.empty;
      if (isMain && locked == null && end >= start) {
        mm = data.rangeOf(start, end, closeOnly: !config.series.usesHighLow);
        mm = _clampOutliers(mm, start, end, config);
      }
      var secondaryMm = MinMax.empty;
      for (final ind in group.indicators) {
        final r = ind.rangeInView(controller.storeOf(ind), start, end, viewport.rightIndex);
        if (isMain && ind.target.isSecondaryAxis) {
          secondaryMm = secondaryMm.union(r);
        } else if (locked == null) {
          mm = mm.union(r);
        }
      }
      if (isMain && end >= start) {
        for (final o in controller.overlays) {
          secondaryMm = secondaryMm.union(o.secondaryRange(controller, start, end));
        }
      }
      // Main panel pads in pixels (extremes keep a fixed distance from the border); sub-panels
      // pad proportionally.
      var padTop = config.mainPaddingTop;
      var padBottom = config.mainPaddingBottom;
      if (isMain) {
        // Main-panel overlay indicators (e.g. VolOverlay volume bars) declare a bottom reserve;
        // prices are pushed above it.
        var reserve = 0.0;
        var legendRows = 0;
        for (final ind in group.indicators) {
          final band = ind.mainBottomReserveFraction;
          reserve += band;
          // In-band indicators draw their legend at the top of their own band, not in a top row.
          if (band <= 0) legendRows++;
        }
        final legend = _legend;
        if (legend != null && legendRows > 1) {
          padTop = math.max(padTop, legend.inset.dy + legendRows * legend.rowHeight + 6);
        }
        if (reserve > 0) {
          padBottom = math.max(padBottom, h * reserve.clamp(0.0, 0.5));
        }
      }
      final inverted = isMain && config.invertScale;
      MinMax padMain(double top, double bottom) =>
          config.logScale ? mm.paddedPxLog(h, top, bottom) : mm.paddedPx(h, top, bottom);
      // When inverted, the screen top is the minimum: legend padding and the bottom reserve
      // swap to the other end of the range.
      var panelRange =
          locked ??
          (isMain
              ? (inverted ? padMain(padBottom, padTop) : padMain(padTop, padBottom))
              : (mm.min == 0 ? mm.padded(0.08, 0) : mm.padded(0.08)));
      // Sub-panel legends draw at the panel top; without padding, indicator lines overlap the
      // text.
      final adjust = config.mainRange;
      if (isMain && locked == null && adjust != null && end >= start) {
        panelRange = adjust.apply(panelRange);
      }
      final subLegend = isMain ? null : _legend;
      if (subLegend != null) {
        panelRange = panelRange.paddedPx(h, subLegend.subPanelReserve, 0);
      }
      if (isMain && locked == null && config.yFitValues != null) {
        viewport.minYScale = _minYScaleFor(panelRange, config.yFitValues!());
      }
      if (isMain && (viewport.yScale != 1.0 || viewport.yOffset != 0)) {
        panelRange = _applyManualY(panelRange, config.logScale);
      }
      panelRange = range.smooth(
        group.id,
        panelRange,
        enabled: smoothEnabled,
        eligible: animEligible,
        logSpace: isMain && config.logScale && panelRange.min > 0,
      );

      // Secondary value axis: auto-fit (ignores manual y scale/pan), but range changes tween
      // like the main axis.
      final secondaryRange = secondaryMm.isEmpty
          ? null
          : range.smooth(
              '${group.id}@axis2',
              inverted
                  ? secondaryMm.paddedPx(h, padBottom, padTop)
                  : secondaryMm.paddedPx(h, padTop, padBottom),
              enabled: smoothEnabled,
              eligible: animEligible,
              logSpace: false,
            );
      panels.add(
        PanelLayout(
          id: group.id,
          isMain: isMain,
          rect: rect,
          range: panelRange,
          indicators: group.indicators,
          logScale: isMain && config.logScale,
          inverted: inverted,
          secondary: secondaryRange == null
              ? null
              : PanelLayout(
                  id: '${group.id}@axis2',
                  isMain: true,
                  isSecondary: true,
                  rect: rect,
                  range: secondaryRange,
                  indicators: [
                    for (final ind in group.indicators)
                      if (ind.target.isSecondaryAxis) ind,
                  ],
                  inverted: inverted,
                ),
        ),
      );
    }

    final ctx = RenderContext(
      controller: controller,
      theme: theme,
      config: config,
      size: size,
      chartRect: chartRect,
      timeAxisRect: timeAxisRect,
      yAxisRect: yAxisRect,
      leftAxisRect: leftAxisRect,
      panels: panels,
      start: start,
      end: end,
      barWidth: viewport.barWidth,
      rightIndex: viewport.rightIndex,
    );

    _ctx = ctx;
    _ctxW = size.width;
    _ctxH = size.height;
    _ctxVpGen = viewport.generation;
    _ctxMut = data.mutations;
    _ctxIndGen = indicators.generation;
    _ctxLayoutRev = config.layoutRevision.value;
    _ctxAnimGen = range.generation;
    _ctxConfig = config;
    _ctxTheme = theme;
    return ctx;
  }

  List<_PanelGroup> _groupsForLayout(ChartConfig config) {
    final indicators = controller.indicators;
    if (_groupsGen == indicators.generation) return _groups;
    final previous = _groups;
    final order = <String>['main'];
    final grouped = <String, List<Indicator>>{'main': <Indicator>[]};
    for (final ind in indicators.list) {
      final key = ind.target.keyFor(ind);
      final bucket = grouped.putIfAbsent(key, () {
        order.add(key);
        return <Indicator>[];
      });
      bucket.add(ind);
    }
    _groups = List.unmodifiable([
      for (final key in order)
        _PanelGroup(id: key, isMain: key == 'main', indicators: grouped[key]!),
    ]);
    // The main panel's secondary value axis has its own tween state too.
    _groupIds = List.unmodifiable([...order, 'main@axis2']);
    _groupsGen = indicators.generation;
    _carryOverWeights(previous, _groups, config);
    return _groups;
  }

  /// Own sub-panel ids include indicator params, so changing params changes the id and would
  /// lose the dragged height. Removed and newly added own sub-panels are paired in order by
  /// indicator kind and the height weight carries over; two instances of the same kind pair
  /// separately and are never merged.
  static void _carryOverWeights(
    List<_PanelGroup> before,
    List<_PanelGroup> after,
    ChartConfig config,
  ) {
    if (before.isEmpty || config.panelWeights.isEmpty) return;
    final afterIds = {for (final g in after) g.id};
    final beforeIds = {for (final g in before) g.id};
    final orphans = <String, List<String>>{};
    for (final g in before) {
      if (!g.id.startsWith('own:') || afterIds.contains(g.id)) continue;
      if (!config.panelWeights.containsKey(g.id)) continue;
      orphans.putIfAbsent(g.indicators.first.kind, () => []).add(g.id);
    }
    if (orphans.isEmpty) return;
    for (final g in after) {
      if (!g.id.startsWith('own:') || beforeIds.contains(g.id)) continue;
      if (config.panelWeights.containsKey(g.id)) continue;
      final queue = orphans[g.indicators.first.kind];
      if (queue == null || queue.isEmpty) continue;
      config.panelWeights[g.id] = config.panelWeights.remove(queue.removeAt(0))!;
    }
  }

  /// Keeps spikes from flattening the chart: high/low may exceed the close range by at most
  /// span * ratio (floored at 0.5% of price to avoid false clamps in sideways markets). In real
  /// moves the closes follow, widening the range too, so there are no false clamps.
  MinMax _clampOutliers(MinMax mm, int start, int end, ChartConfig config) {
    final clamp = config.outlierClampRatio;
    if (clamp == null || !config.series.usesHighLow || mm.isEmpty) return mm;
    final closes = controller.data.rangeOf(start, end, closeOnly: true);
    if (closes.isEmpty) return mm;
    final allow = math.max(closes.span * clamp, closes.max.abs() * 0.005);
    final cap = closes.max + allow;
    final floor = closes.min - allow;
    if (mm.max <= cap && mm.min >= floor) return mm;
    return MinMax(math.max(mm.min, floor), math.min(mm.max, cap));
  }

  /// Manual y scaling zooms around the auto range's midpoint, then manual panning shifts by a
  /// fraction of the result; on a log axis both happen in log space.
  MinMax _applyManualY(MinMax r, bool logScale) {
    final viewport = controller.viewport;
    final zoom = 1 / viewport.yScale;
    if (logScale && r.min > 0) {
      final lmin = math.log(r.min), lmax = math.log(r.max);
      final h = (lmax - lmin) / 2 * zoom;
      final c = (lmin + lmax) / 2 + viewport.yOffset * h * 2;
      return MinMax(math.exp(c - h), math.exp(c + h));
    }
    final h = r.span / 2 * zoom;
    final c = (r.min + r.max) / 2 + viewport.yOffset * h * 2;
    return MinMax(c - h, c + h);
  }

  /// With yFitValues, how far the y axis may zoom out: 0.2 by default, relaxed to fit those
  /// prices (plus 10%), at least 0.01.
  double _minYScaleFor(MinMax auto, List<double> values) {
    const base = 0.2;
    if (values.isEmpty || auto.isEmpty || auto.span <= 0) return base;
    final c = (auto.min + auto.max) / 2, half = auto.span / 2;
    var need = 1.0;
    for (final v in values) {
      if (!v.isFinite) continue;
      need = math.max(need, (v - c).abs() / half * 1.1);
    }
    return math.min(base, math.max(0.01, 1 / need));
  }
}
