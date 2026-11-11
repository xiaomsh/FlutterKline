import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

import 'debug.dart';
import 'indicator/compute_worker.dart';
import 'indicator/indicator.dart';
import 'indicator/indicator_registry.dart';
import 'indicator/indicator_set.dart';
import 'model/bar.dart';
import 'model/bar_aggregator.dart';
import 'model/crosshair_state.dart';
import 'model/data_source.dart';
import 'model/min_max.dart';
import 'model/time_map.dart';
import 'model/viewport.dart';
import 'overlay/builtin/crosshair.dart';
import 'overlay/builtin/legend.dart';
import 'overlay/builtin/price_line.dart';
import 'overlay/overlay_plugin.dart';
import 'render/context.dart';
import 'render/layout_resolver.dart';
import 'render/paint_pool.dart';

/// The chart's single source of truth: data, viewport, crosshair, and indicator set, each its own
/// [Listenable].
/// Painters subscribe only to what they need, so data changes do not rebuild the widget tree.
class ChartController {
  ChartController({
    List<Indicator> indicators = const [],
    List<OverlayPlugin> overlays = const [],
    bool defaultOverlays = true,
  }) : overlays = List.unmodifiable([
         // Skip the default if the host passed a plugin of the same type, or it would draw twice
         if (defaultOverlays) ...[
           if (!overlays.any((o) => o is CrosshairOverlay)) CrosshairOverlay(),
           if (!overlays.any((o) => o is PriceLineOverlay)) PriceLineOverlay(),
           if (!overlays.any((o) => o is IndicatorLegendOverlay)) IndicatorLegendOverlay(),
         ],
         ...overlays,
       ]) {
    this.indicators.setAll(indicators);
    this.indicators.addListener(_syncStores);
    _layout = LayoutResolver(this);
    _syncStores();
  }

  final DataSource data = DataSource();

  /// Incremented on any data change (coalesced per frame).
  final ValueNotifier<int> dataRevision = ValueNotifier(0);

  /// The range tween advanced a frame. Display only: no bar changed, the y mapping is just sliding
  /// toward its target.
  final ValueNotifier<int> rangeRevision = ValueNotifier(0);

  /// Pan, zoom, auto range. Y-mapping changes go only through this, [dataRevision], and
  /// [rangeRevision].
  final ChartViewport viewport = ChartViewport();

  final ValueNotifier<CrosshairState?> crosshair = ValueNotifier(null);

  /// Height of the main panel's top tooltip row while the crosshair is shown (measured and written
  /// by the built-in one-line tooltip); the main legend moves down by it. 0 when there is no
  /// tooltip row.
  final ValueNotifier<double> tooltipInset = ValueNotifier(0);

  /// Display value of the last-price animation: when non-null, the series and last-price line use
  /// it instead of the last bar's close; data and indicators are unaffected.
  final ValueNotifier<double?> animatedLastClose = ValueNotifier(null);

  final IndicatorSet indicators = IndicatorSet();

  /// Overlay plugins, fixed at construction (overlay repaint listeners are wired from here).
  final List<OverlayPlugin> overlays;

  /// Paint / TextPainter / Float32List shared by all painters.
  final PaintPool pool = PaintPool();

  late final LayoutResolver _layout;
  final Map<String, IndicatorStore> _stores = {};
  bool _disposed = false;
  bool _notifyScheduled = false;

  // ---- Background isolate indicator computing ----

  /// Whether full recomputes on large data (symbol switch, indicator change) run in a background
  /// isolate; set false to force sync (unit tests, hosts that read indicator values right after
  /// setBars).
  bool asyncCompute = true;

  /// Background computing in progress; hosts can show "computing" based on it.
  final ValueNotifier<bool> computing = ValueNotifier(false);

  /// Minimum bar count to go to the background; small data is snappier synchronously.
  static const int _asyncBarThreshold = 2000;

  IndicatorComputeWorker? _worker;

  /// Permanently falls back to sync after the first spawn / compute failure.
  bool _workerBroken = false;
  int _computeSeq = 0;
  int _inFlight = 0;

  /// Latest job number dispatched to the background per indicator id.
  final Map<String, int> _storeJob = {};

  /// Count of in-place edits or prepend shifts of existing data. If it changes during computing,
  /// the background result is stale in the middle, so it is dropped and recomputed synchronously.
  int _structuralRev = 0;

  List<Bar> get bars => data.bars;

  IndicatorStore storeOf(Indicator indicator) =>
      _stores.putIfAbsent(indicator.id, IndicatorStore.new);

  /// Values of all indicators at bar [index]: `{indicator id: {series key: value}}`.
  Map<String, Map<String, double>> indicatorValuesAt(int index) => {
    for (final ind in indicators.list) ind.id: storeOf(ind).valuesAt(index),
  };

  /// Current index of the crosshair-selected bar, or -1 if none. If the timestamp falls between two
  /// bars (period changed), the nearest is used.
  int crosshairIndex() {
    final ch = crosshair.value;
    if (ch == null || data.isEmpty) return -1;
    final i = data.indexOfTime(ch.time);
    if (i >= 0) return i;
    return timeToIndex(bars, ch.time).round().clamp(0, data.length - 1);
  }

  // ---- Data ----

  /// Incremented on every [setBars] (symbol or period switch); display animations use it to avoid
  /// interpolating across data sets.
  int _dataEpoch = 0;

  int get dataEpoch => _dataEpoch;

  /// When true, KChart does not trigger onLoadMore (during replay: prepending would desync from the
  /// replay snapshot).
  bool loadMorePaused = false;

  // ---- Period aggregation ----

  BarAggregator? _agg;
  DataSource? _src;

  /// Period aggregation: once set, [setBars] / [applyTick] / [appendBar] / [updateLast] /
  /// [replaceAt] /
  /// [prependHistory] all take source-period bars; the controller aggregates before storing. Pushes
  /// only recompute the bucket of the last bar,
  /// and loading older data fixes the boundary bucket. [bars] is aggregated; source data is in
  /// [sourceBars].
  /// Setting or clearing rebuilds once from existing source data (like [setBars], viewport jumps to
  /// latest); does nothing if equal (`==`) to the current one.
  /// Custom aggregation rules that should compare by parameters should implement `==`.
  BarAggregator? get aggregator => _agg;

  set aggregator(BarAggregator? value) {
    if (_disposed) return;
    if (value == _agg) return;
    final raw = List<Bar>.of(sourceBars);
    _agg = value;
    _src = value == null ? null : DataSource();
    setBars(raw);
  }

  /// Source-period data; same as [bars] when no [aggregator] is set. Read-only.
  List<Bar> get sourceBars => _src?.bars ?? data.bars;

  /// Index of the first source bar whose bucket time is >= [bucket] (> [bucket] when [upper]).
  int _srcBound(int bucket, {bool upper = false}) {
    final b = _src!.bars;
    var lo = 0, hi = b.length;
    while (lo < hi) {
      final mid = (lo + hi) >> 1;
      final t = _agg!.bucketOf(b[mid].time);
      if (upper ? t <= bucket : t < bucket) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }
    return lo;
  }

  Bar? _bucketBar(int bucket) {
    final from = _srcBound(bucket), to = _srcBound(bucket, upper: true);
    return from < to ? BarAggregator.merge(_src!.bars, from, to, bucket) : null;
  }

  /// After output is trimmed, also drops source buckets that fall before the oldest output.
  void _trimSource() {
    final src = _src;
    if (src == null) return;
    if (data.isEmpty) {
      src.trimFront(src.length);
      return;
    }
    final k = _srcBound(data.bars.first.time);
    if (k > 0) src.trimFront(k);
  }

  /// Aggregate of the last bucket excluding its last source bar (null if it has only one), plus
  /// that last source bar's time. Pushes updating the last bar continue from it instead of
  /// re-aggregating the whole bucket each time (1-minute into monthly is 40k+ bars per bucket).
  Bar? _tailHead;
  int? _tailHeadKey;

  static Bar _fold(Bar? head, Bar b, int time) => head == null
      ? b.copyWith(time: time)
      : Bar(
          time: time,
          open: head.open,
          high: math.max(head.high, b.high),
          low: math.min(head.low, b.low),
          close: b.close,
          vol: head.vol + b.vol,
          amount: addAmount(head.amount, b.amount),
        );

  /// One source bar arrives: update source data, then write the affected bucket back to the output.
  void _sourceTick(Bar bar) {
    final src = _src!;
    if (src.isEmpty || data.isEmpty) {
      setBars([...src.bars, bar]);
      return;
    }
    final last = src.bars.last.time;
    final agg = _agg!;
    Bar? merged;
    if (bar.time > last) {
      final outLast = data.bars.last;
      if (!src.append(bar)) return;
      // Append: continue the last bucket if it falls in it; a new bucket contains only this bar
      final t = agg.bucketOf(bar.time);
      _tailHead = t == outLast.time ? outLast : null;
      _tailHeadKey = bar.time;
      // Use the corrected source bar (high/low, negative volume) so it matches a full rebuild
      merged = _fold(_tailHead, src.bars.last, t);
    } else if (bar.time == last) {
      if (!src.updateLast(bar)) return;
      final t = agg.bucketOf(bar.time);
      if (_tailHeadKey != bar.time) {
        final from = _srcBound(t), end = src.length - 1;
        _tailHead = from < end ? BarAggregator.merge(src.bars, from, end, t) : null;
        _tailHeadKey = bar.time;
      }
      merged = _fold(_tailHead, src.bars.last, t);
    } else {
      final i = src.indexOfTime(bar.time);
      if (i < 0 || !src.replaceAt(i, bar)) return;
      _tailHeadKey = null;
      final t = agg.bucketOf(bar.time);
      final o = data.indexOfTime(t);
      if (o < 0) return;
      if (o < data.length - 1) {
        _replaceOut(o, _bucketBar(t)!);
        return;
      }
    }
    final t = agg.bucketOf(src.bars.last.time);
    merged ??= _bucketBar(t)!;
    final outLast = data.bars.last.time;
    if (t > outLast) {
      _appendOut(merged);
    } else if (t == outLast) {
      _updateLastOut(merged);
    }
  }

  void _sourcePrepend(List<Bar> older) {
    final src = _src!;
    _tailHeadKey = null;
    if (src.prepend(older) == 0) return;
    final firstT = data.bars.first.time;
    final outs = _agg!.aggregate(src.bars.sublist(0, _srcBound(firstT, upper: true)));
    var replaced = false;
    if (outs.isNotEmpty && outs.last.time == firstT) {
      final head = outs.removeLast();
      final cur = data.bars.first;
      if (head.open != cur.open ||
          head.high != cur.high ||
          head.low != cur.low ||
          head.close != cur.close ||
          head.vol != cur.vol ||
          head.amount != cur.amount) {
        replaced = data.replaceAt(0, head);
      }
    }
    final inserted = outs.isEmpty ? 0 : _prependOut(outs);
    if (replaced && inserted == 0) {
      _structuralRev++;
      _recomputeList(indicators.list);
      _bump('prependHistory boundary bucket');
    }
    _trimSource();
  }

  /// Initial load / period switch: full recompute, viewport jumps to latest. Pass source-period
  /// data when [aggregator] is set.
  void setBars(List<Bar> bars) {
    if (_disposed) return;
    if (KlinexDebug.logData) KlinexDebug.data('setBars', '${bars.length} bars');
    _dataEpoch++;
    // The old data set's crosshair timestamp is meaningless for new data
    crosshair.value = null;
    final src = _src;
    _tailHeadKey = null;
    if (src != null) {
      src.setAll(bars);
      data.setAll(_agg!.aggregate(src.bars));
    } else {
      data.setAll(bars);
    }
    final max = _maxBars;
    if (max != null && data.length > max) data.trimFront(data.length - max);
    _trimSource();
    // New data set, so the locked price range is meaningless
    viewport.unlockYRange();
    viewport.setBarCount(data.length, jumpToLatest: true);
    // Cold start often calls restoreState before setBars: the saved vertical state is applied here
    if (_pendingY case final y?) {
      _pendingY = null;
      _applyY(y);
    }
    _computeStores(indicators.list);
    _bump('setBars');
  }

  /// Realtime data entry, dispatched by timestamp: newer than the last bar appends, equal updates
  /// the last bar, matching a historical bar replaces it with a full recompute, older unknown
  /// timestamps are ignored.
  void applyTick(Bar bar) {
    if (_disposed) return;
    if (KlinexDebug.logData) {
      KlinexDebug.data(
        'applyTick',
        't=${bar.time} close=${bar.close} current last=${data.isEmpty ? '-' : bars.last.time}',
      );
    }
    if (_src != null) {
      _sourceTick(bar);
      return;
    }
    if (data.isEmpty) {
      setBars([bar]);
      return;
    }
    final lastTime = bars.last.time;
    if (bar.time > lastTime) {
      appendBar(bar);
    } else if (bar.time == lastTime) {
      updateLast(bar);
    } else {
      final i = data.indexOfTime(bar.time);
      if (i >= 0) replaceAt(i, bar);
    }
  }

  /// A new bar: indicators only compute the last bar incrementally. DataSource drops bad data whose
  /// time does not increase.
  void appendBar(Bar bar) {
    if (_disposed) return;
    if (KlinexDebug.logData) KlinexDebug.data('appendBar', 't=${bar.time}');
    final src = _src;
    if (src != null) {
      if (src.isEmpty || bar.time > src.bars.last.time) _sourceTick(bar);
      return;
    }
    _appendOut(bar);
  }

  void _appendOut(Bar bar) {
    if (!data.append(bar)) return;
    viewport.setBarCount(data.length);
    // Cold start with restoreState then appendBar one by one: apply vertical state when the first
    // bar lands, not deferred to the next data set
    if (data.length == 1 && _pendingY != null) {
      final y = _pendingY!;
      _pendingY = null;
      _applyY(y);
    }
    _computeLastAll();
    _trimOverflow();
    _bump('appendBar');
  }

  /// Tick within the last bar: indicators only compute the last bar incrementally.
  void updateLast(Bar bar) {
    if (_disposed) return;
    if (KlinexDebug.logData) {
      KlinexDebug.data('updateLast', 't=${bar.time} close=${bar.close}');
    }
    final src = _src;
    if (src != null) {
      if (!src.isEmpty && bar.time == src.bars.last.time) _sourceTick(bar);
      return;
    }
    _updateLastOut(bar);
  }

  void _updateLastOut(Bar bar) {
    if (!data.updateLast(bar)) return;
    _computeLastAll();
    _bump('updateLast');
  }

  /// Out-of-order fix: recurrence state downstream of [index] is stale, so recompute fully.
  /// When [aggregator] is set, [index] is a source data index and its bucket is updated.
  void replaceAt(int index, Bar bar) {
    if (_disposed) return;
    if (KlinexDebug.logData) KlinexDebug.data('replaceAt', 'i=$index t=${bar.time}');
    final src = _src;
    if (src != null) {
      if (index >= 0 && index < src.length && src.bars[index].time == bar.time) _sourceTick(bar);
      return;
    }
    _replaceOut(index, bar);
  }

  void _replaceOut(int index, Bar bar) {
    if (!data.replaceAt(index, bar)) return;
    _structuralRev++;
    _recomputeList(indicators.list);
    _bump('replaceAt');
  }

  /// Loads older history. The viewport shifts by the same number of bars in the same frame, so the
  /// view does not jump.
  void prependHistory(List<Bar> older) {
    if (_disposed) return;
    if (KlinexDebug.logData) {
      KlinexDebug.data(
        'prependHistory',
        '${older.length} bars oldest=${older.isEmpty ? '-' : older.first.time}',
      );
    }
    if (older.isEmpty) return;
    if (data.isEmpty) {
      setBars(older);
      return;
    }
    if (_src != null) {
      _sourcePrepend(older);
      return;
    }
    _prependOut(older);
  }

  /// Returns the number of bars actually inserted.
  int _prependOut(List<Bar> older) {
    // Tail overlapping existing data is trimmed and the viewport shifts by the bars actually
    // inserted; the crosshair is anchored on time, so it stays put
    final max = _maxBars;
    final inserted = data.prepend(older, limit: max == null ? null : max - data.length);
    if (inserted == 0) return 0;
    _structuralRev++;
    viewport.shiftBy(inserted);
    _recomputeAfterPrepend(inserted);
    _bump('prependHistory');
    return inserted;
  }

  /// Max bars to keep; null for unlimited. Appends beyond it trim from the oldest end; at the
  /// limit, loading older data inserts nothing. A full recompute after trimming re-warms recursive
  /// indicators at the front, so they differ slightly from before trimming.
  int? get maxBars => _maxBars;
  int? _maxBars;

  set maxBars(int? value) {
    if (_disposed) return;
    if (value != null && value <= 0) {
      throw ArgumentError.value(value, 'maxBars', 'must be positive');
    }
    _maxBars = value;
    if (_trimOverflow()) _bump('maxBars');
  }

  /// Trims the oldest bars beyond [maxBars] and returns whether it trimmed. Appends only happen on
  /// new bars, so copying the array each time is negligible.
  bool _trimOverflow() {
    final max = _maxBars;
    if (max == null) return false;
    final over = data.length - max;
    if (over <= 0) return false;
    data.trimFront(over);
    // Clear the crosshair if its bar was trimmed, or it would clamp to the oldest bar and the
    // tooltip would show a different bar
    final ch = crosshair.value;
    if (ch != null && !data.isEmpty && ch.time < data.bars.first.time) crosshair.value = null;
    for (final store in _stores.values) {
      store.dropFront(over);
    }
    // Indices shift left: invalidate in-flight background results
    _structuralRev++;
    viewport.shiftBy(-over);
    _trimSource();
    return true;
  }

  /// Saves the whole state: indicators (registered only), bar width and y scale, maxBars, and
  /// plugins that declare a stateKey (e.g. drawings). Theme and KChart parameters belong to the
  /// host; the theme can be saved separately with `KLineTheme.toJson`.
  Map<String, dynamic> saveState() {
    final overlayStates = <String, dynamic>{};
    for (final o in overlays) {
      final key = o.stateKey;
      if (key == null) continue;
      final state = o.saveState();
      if (state != null) overlayStates[key] = state;
    }
    return {
      'version': 1,
      'indicators': [
        for (final ind in indicators.list)
          if (IndicatorRegistry.canSerialize(ind)) ?_toJsonOrNull(ind),
      ],
      'barWidth': viewport.barWidth,
      'yScale': viewport.yScale,
      'yOffset': viewport.yOffset,
      if (_maxBars != null) 'maxBars': _maxBars,
      if (viewport.lockedYRange case final r?) 'lockedY': [r.min, r.max],
      if (overlayStates.isNotEmpty) 'overlays': overlayStates,
    };
  }

  /// When a custom indicator kind collides with a built-in one (same id prefix), toJson throws;
  /// skip that one rather than failing the whole saveState.
  Map<String, dynamic>? _toJsonOrNull(Indicator ind) {
    try {
      return IndicatorRegistry.toJson(ind);
    } catch (_) {
      return null;
    }
  }

  /// Restores state saved by [saveState]; missing fields stay as is, unregistered indicator kinds
  /// are skipped. When called before data exists (restore state, then fetch data), the locked range
  /// and vertical zoom take effect after the next [setBars].
  void restoreState(Map<String, dynamic> state) {
    if (_disposed) return;
    final inds = state['indicators'];
    if (inds is List) indicators.setAll(IndicatorRegistry.fromJsonList(inds));
    final max = state['maxBars'];
    if (max is int && max > 0) maxBars = max;
    viewport.restoreScales(barWidth: _num(state['barWidth']));
    // Without data, setBars would unlock and clear vertical zoom, so stash it for the next setBars
    if (data.isEmpty) {
      _pendingY = state;
    } else {
      _pendingY = null;
      _applyY(state);
    }
    final overlayStates = state['overlays'];
    if (overlayStates is Map) {
      for (final o in overlays) {
        final s = overlayStates[o.stateKey];
        if (s is! Map) continue;
        // One plugin's corrupt state does not affect other plugins
        try {
          o.restoreState(s.cast<String, dynamic>());
        } catch (e) {
          debugPrint('klinex plugin ${o.stateKey} failed to restore state: $e');
        }
      }
    }
  }

  /// Treats a saved field of the wrong type (hand-edited, version mismatch) as absent; does not
  /// throw.
  static double? _num(Object? v) => v is num ? v.toDouble() : null;

  /// Vertical state stashed by [restoreState] when data was empty, applied after the next
  /// [setBars].
  Map<String, dynamic>? _pendingY;

  void _applyY(Map<String, dynamic> state) {
    final scale = _num(state['yScale']);
    final offset = _num(state['yOffset']);
    final locked = state['lockedY'];
    if (locked is List && locked.length == 2 && locked.every((v) => v is num)) {
      viewport.lockYRange(MinMax((locked[0] as num).toDouble(), (locked[1] as num).toDouble()));
    } else if (state.containsKey('version')) {
      viewport.unlockYRange();
    }
    viewport.restoreScales(yScale: scale, yOffset: offset);
  }

  /// Frees rebuildable caches (range block caches); KChart calls it automatically on system memory
  /// pressure. Data and indicator values are unaffected.
  void releaseCaches() {
    data.releaseCaches();
    for (final store in _stores.values) {
      store.releaseCaches();
    }
  }

  @visibleForTesting
  IndicatorComputeWorker? get debugWorker => _worker;

  /// Whether already [dispose]d; plugins shared by multiple controllers use it to tell if anyone
  /// still uses them.
  bool get isDisposed => _disposed;

  /// Disposed by the host; the widget does not own the controller. Writes after dispose (late
  /// pushes, etc.) are ignored; repeated dispose is harmless.
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    indicators.removeListener(_syncStores);
    for (final overlay in overlays) {
      overlay.dispose();
    }
    _worker?.dispose();
    _layout.dispose();
    dataRevision.dispose();
    rangeRevision.dispose();
    crosshair.dispose();
    tooltipInset.dispose();
    animatedLastClose.dispose();
    computing.dispose();
    viewport.dispose();
    indicators.dispose();
    pool.clear();
  }

  // ---- Layout ----

  /// Whether data-driven range changes (new extremes in/out, last bar moves) are tweened;
  /// changes from horizontal gestures are always tweened.
  bool animateRange = false;

  /// Locks the main range to the currently displayed range: panning and new data no longer
  /// autoscale y; manual zoom / pan still apply on top. Returns false if no frame has been painted
  /// yet.
  bool lockYRange() {
    if (_disposed) return false;
    final r = _layout.lastMainRange;
    if (r == null || r.isEmpty) return false;
    viewport.lockYRange(r);
    return true;
  }

  /// Drops the layout cache and repaints a frame: call when a plugin's contribution to the
  /// secondary value axis range ([OverlayPlugin.secondaryRange]) changes.
  void relayout() {
    if (_disposed) return;
    _layout.invalidate();
    _bump('relayout');
  }

  /// Unlocks the main range and returns to auto.
  void unlockYRange() {
    if (_disposed) return;
    viewport.unlockYRange();
  }

  /// This frame's layout (visible range, panel rects, value ranges), shared by all painters,
  /// cached.
  RenderContext resolveLayout(Size size, ChartConfig config) => _layout.resolve(size, config);

  // ---- Indicator computing ----

  /// The prefix recompute must match old values for this many consecutive bars before the rest is
  /// reused.
  static const int _prependVerifyOverlap = 64;

  /// After a prepend, only recomputes the affected prefix ([Indicator.prependSettleBars]) and
  /// reuses the rest shifted right; falls back to full on mismatch or when the indicator declares
  /// no range.
  void _recomputeAfterPrepend(int inserted) {
    final n = data.length;
    // Collect full recomputes into the unified entry: large data goes to the background, so paging
    // back through history does not block the main thread
    final full = <Indicator>[];
    for (final ind in indicators.list) {
      final store = storeOf(ind);
      try {
        final settle = ind.prependSettleBars;
        final prefix = settle == null ? n : inserted + settle + _prependVerifyOverlap;
        if (settle != null && prefix < n && store.length == n - inserted) {
          store.shiftRight(inserted);
          final tmp = IndicatorStore()..resize(prefix);
          ind.computeAll(bars.sublist(0, prefix), tmp);
          final from = math.max(inserted, prefix - _prependVerifyOverlap);
          if (from < prefix && store.matchesRange(tmp, from, prefix)) {
            store.copyPrefixFrom(tmp, prefix);
            continue;
          }
        }
        full.add(ind);
      } catch (e, s) {
        _reportIndicatorError(ind, e, s);
        full.add(ind);
      }
    }
    if (full.isNotEmpty) _computeStores(full);
  }

  /// Fully recomputes [inds] on the main isolate.
  void _recomputeList(List<Indicator> inds) {
    final n = data.length;
    for (final ind in inds) {
      final store = storeOf(ind)
        ..clear()
        ..resize(n);
      try {
        ind.computeAll(bars, store);
      } catch (e, s) {
        _reportIndicatorError(ind, e, s);
      }
    }
  }

  void _recomputeOne(Indicator ind) {
    final store = storeOf(ind)
      ..clear()
      ..resize(data.length);
    try {
      ind.computeAll(bars, store);
    } catch (e, s) {
      _reportIndicatorError(ind, e, s);
    }
  }

  /// Unified entry for full computing: background above the threshold, otherwise sync.
  void _computeStores(List<Indicator> inds) {
    if (_shouldOffload(inds)) {
      final specs = _specsFor(inds);
      if (specs != null) {
        _offload(List<Indicator>.of(inds), specs);
        return;
      }
    }
    _recomputeList(inds);
  }

  /// Serializes into a cross-isolate spec; if any fails, the whole batch goes sync. Must happen
  /// before touching the store / [computing], otherwise when a custom indicator collides with a
  /// built-in kind, the exception lands in an unawaited branch, leaving the indicator blank forever
  /// and "computing" stuck on.
  List<Map<String, dynamic>>? _specsFor(List<Indicator> inds) {
    try {
      return [for (final ind in inds) IndicatorRegistry.toJson(ind)];
    } catch (_) {
      return null;
    }
  }

  bool _shouldOffload(List<Indicator> inds) {
    if (!asyncCompute || kIsWeb || _workerBroken || _disposed) return false;
    if (inds.isEmpty || data.length < _asyncBarThreshold) return false;
    return inds.every(IndicatorRegistry.canSerialize);
  }

  /// Background full compute: stores are cleared during computing (drawn as gaps), results are
  /// claimed by [_storeJob];
  /// invalidated on data set change or mid-range edits; on failure recomputes synchronously and
  /// falls back permanently.
  Future<void> _offload(List<Indicator> inds, List<Map<String, dynamic>> specs) async {
    final n = data.length;
    final jobId = ++_computeSeq;
    for (final ind in inds) {
      _storeJob[ind.id] = jobId;
      storeOf(ind)
        ..clear()
        ..resize(n);
    }
    final epoch = _dataEpoch;
    final struct0 = _structuralRev;
    final l0 = n;
    _inFlight++;
    computing.value = true;

    Map<String, Map<String, Float64List>>? result;
    var failed = false;
    try {
      result = await (_worker ??= IndicatorComputeWorker()).compute(bars, specs);
    } catch (_) {
      failed = true;
      _workerBroken = true;
    }
    _inFlight--;
    // After dispose the notifiers are released, so computing must not be written
    if (_disposed) return;

    // No surprise on landing may leave computing stuck at true; always clean up in finally
    try {
      if (epoch != _dataEpoch) return;
      final stale = failed || _structuralRev != struct0;
      for (final ind in inds) {
        if (_storeJob[ind.id] != jobId) continue;
        if (!indicators.list.any((e) => e.id == ind.id)) continue;
        final series = stale ? null : result![ind.id];
        if (series == null) {
          _recomputeOne(ind);
          continue;
        }
        final store = storeOf(ind)..adoptSeries(l0, series);
        // Catch up from l0-1, covering last-bar updates and appends during computing; the
        // recurrence state at l0-1 comes from the snapshot just taken over
        final now = data.length;
        final from = l0 > 0 ? l0 - 1 : 0;
        if (now > from) {
          store.resize(now);
          for (var i = from; i < now; i++) {
            try {
              ind.computeLast(bars, i, store);
            } catch (e, s) {
              _reportIndicatorError(ind, e, s);
            }
          }
          store.invalidateFrom(from);
        }
      }
      // The layout cache key does not include store contents, so ranges computed from empty stores
      // during computing would linger
      _layout.invalidate();
      _bump('asyncCompute landed');
    } finally {
      if (_inFlight == 0 && !_disposed) computing.value = false;
    }
  }

  /// Incrementally computes the last bar with three fallbacks: full compute during warm-up, full on
  /// incremental error, and if that fails too the indicator stays empty this frame without
  /// affecting others.
  void _computeLastAll() {
    final n = data.length;
    final i = n - 1;
    for (final ind in indicators.list) {
      final store = storeOf(ind)..resize(n);
      if (n <= ind.warmupBars) {
        try {
          ind.computeAll(bars, store);
        } catch (e, s) {
          _reportIndicatorError(ind, e, s);
        }
        store.invalidateFrom(0);
        continue;
      }
      try {
        ind.computeLast(bars, i, store);
        store.invalidateFrom(i);
      } catch (e, s) {
        _reportIndicatorError(ind, e, s);
        try {
          store
            ..clear()
            ..resize(n);
          ind.computeAll(bars, store);
        } catch (e, s) {
          _reportIndicatorError(ind, e, s);
        }
      }
    }
  }

  /// Called when indicator computation throws: the chart continues, and the failing indicator falls
  /// back to full or stays empty this frame. If unset, errors are only printed in debug.
  void Function(Indicator indicator, Object error, StackTrace stack)? onIndicatorError;

  void _reportIndicatorError(Indicator ind, Object error, StackTrace stack) {
    final handler = onIndicatorError;
    if (handler != null) {
      // The host's report callback throwing (commonly "rethrow to the crash reporter") must not
      // interrupt computing and repainting of later indicators
      try {
        handler(ind, error, stack);
        return;
      } catch (e) {
        debugPrint('klinex onIndicatorError callback threw: $e');
      }
    }
    if (kDebugMode) debugPrint('klinex indicator ${ind.id} compute error: $error\n$stack');
  }

  /// Indicator set changed: delete stores of removed ones; compute new ones fully (large data in
  /// the background).
  void _syncStores() {
    final ids = {for (final ind in indicators.list) ind.id};
    _stores.removeWhere((id, _) => !ids.contains(id));
    _storeJob.removeWhere((id, _) => !ids.contains(id));
    final n = data.length;
    final pending = [
      for (final ind in indicators.list)
        if (storeOf(ind).length != n) ind,
    ];
    if (pending.isNotEmpty) _computeStores(pending);
    _bump('_syncStores');
  }

  /// Data merges immediately; only repaint notifications coalesce per frame: any number of ticks in
  /// a frame repaint once, and the last one always lands.
  void _bump([String from = '?']) {
    if (KlinexDebug.logData) {
      KlinexDebug.data('_bump', 'source=$from ${_notifyScheduled ? '(queued, merged)' : ''}');
    }
    if (_disposed || _notifyScheduled) return;
    _notifyScheduled = true;
    final scheduler = SchedulerBinding.instance;
    scheduler.scheduleFrameCallback((_) {
      _notifyScheduled = false;
      if (!_disposed) dataRevision.value++;
    });
    scheduler.scheduleFrame();
  }
}
