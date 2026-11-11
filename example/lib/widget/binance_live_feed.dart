import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:klinex/klinex.dart';

import '../api/binance_spot_api.dart';
import '../l10n/l10n.dart';
import '../model/data.dart';
import '../model/error.dart';
import '../pro/live_pro.dart';
import '../socket/binance_public_ws.dart';
import 'axis_price_tags.dart';

/// Binds Binance spot market data (REST history + WS live) to a klinex [ChartController],
/// and tracks the best bid / ask
class BinanceLiveFeed extends ChangeNotifier with WidgetsBindingObserver {
  final ChartController controller;

  String _symbol = 'btc_usdt';
  String _interval = '1m';

  BinanceLiveFeed(this.controller, {String symbol = 'btc_usdt', String interval = '1m'}) {
    _symbol = symbol;
    _interval = interval;
  }

  String get symbol => _symbol;

  String get interval => _interval;

  /// Best bid / ask (bookTicker stream)
  final ValueNotifier<BookPrice?> book = ValueNotifier(null);

  /// One-shot user notice for recoverable issues that leave the chart intact. [error] is the
  /// first-load failure that covers the chart and drives retry.
  /// Hosts call [clearNotice] after consuming it, or it shows again on rebuild
  final ValueNotifier<String?> notice = ValueNotifier(null);

  void clearNotice() => notice.value = null;

  bool loading = false;
  String? error;
  bool _noMoreHistory = false;

  /// Series currently paging back: an old series' paging must not block the new series' paging
  String? _loadingMoreKey;
  bool _started = false;

  /// Generation of full loads: +1 per load; only the latest may clear [loading], write data and
  /// report errors. Otherwise an older request returning first would open the gate early and
  /// ticks of the new symbol would land on the old symbol's data
  int _loadGen = 0;

  bool _disposed = false;

  /// Which symbol / interval / Heikin-Ashi the chart data belongs to. After a switch it differs
  /// from [_seriesKey] until new data lands; ticks, gap repairs and paging must not write to the
  /// chart meanwhile, or the new symbol's prices would be appended to the old series
  String? _barsKey;

  String get _seriesKey => '$_symbol/$_interval/$_heikinAshi';

  // All REST requests share one cancel token, cancelled once on dispose
  final CancelToken _cancel = CancelToken();

  String get _liveTopic =>
      '${BinanceSpotApi.toExchangeSymbol(_symbol).toLowerCase()}@kline_$_interval';

  String get _bookTopic => '${BinanceSpotApi.toExchangeSymbol(_symbol).toLowerCase()}@bookTicker';

  Future<void> start() async {
    if (_started) return;
    _started = true;
    // Repair gaps after reconnects (subscribe triggers the first connect while _sawDisconnect
    // is still false, so the first connect does not trigger a repair)
    BinancePublicWs.instance.connected.addListener(_onConnectionChanged);
    // While the screen is off / app is in background the socket is often half-open and WS may
    // not report a disconnect, so on resume the lifecycle path must always reconcile once,
    // not just the reconnect callback.
    WidgetsBinding.instance.addObserver(this);
    BinancePublicWs.instance.subscribe(_liveTopic, _onLiveData, from: 'feed.live');
    BinancePublicWs.instance.subscribe(_bookTopic, _onBookData, from: 'feed.book');
    await _loadHistory();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !_started || _disposed) return;
    // First ask WS to self-check (half-open connections are detected and reconnected here),
    // then reconcile ourselves. Independent: even a live connection may have missed ticks to
    // throttling while the screen was off.
    BinancePublicWs.instance.checkAlive();
    _repairGap();
  }

  bool _sawDisconnect = false;

  void _onConnectionChanged() {
    if (!BinancePublicWs.instance.connected.value) {
      _sawDisconnect = true;
      // The book stops updating after a disconnect; stale bid/ask on the axis would look live
      book.value = null;
      return;
    }
    if (!_sawDisconnect || !_started) return;
    _sawDisconnect = false;
    _repairGap();
  }

  /// Series being gap-repaired; ticks are held meanwhile (see [_heldTicks]).
  /// Appending directly would put ticks at the end first, and the page that arrives later would
  /// be filtered down to the last bar by time, sealing the gap.
  /// Tracked per series: an old series' repair must not block the new series' ticks
  String? _repairingKey;

  /// Another trigger during a repair (reconnect again, resume): the in-flight page may predate
  /// the latest disconnect, so reconcile once more afterwards
  bool _repairAgain = false;
  bool get _repairing => _repairingKey != null && _repairingKey == _seriesKey;

  /// Ticks held during load / repair, keeping only the latest per bar open time, replayed after
  /// data lands. Without replay the unfinished bar in the snapshot never gets corrected (the next
  /// tick is already a new bar)
  final _heldTicks = HeldTicks();

  void _holdTick(Map<String, dynamic> data) {
    final kline = data['k'];
    if (kline is! Map || kline['i'] != _interval) return;
    if (data['s'] != BinanceSpotApi.toExchangeSymbol(_symbol)) return;
    final t = kline['t'];
    if (t is! int) return;
    _heldTicks.hold(t, data);
  }

  void _replayHeldTicks() {
    for (final data in _heldTicks.drain()) {
      _onLiveData(data);
    }
  }

  /// Fetches the latest page as the source of truth and reconciles it with existing data
  /// (on WS reconnect and app resume). Appending at the tail is not enough: missing bars in the
  /// middle cannot be inserted later, so compare timestamps bar by bar and splice only on a gap
  Future<void> _repairGap() async {
    if (loading) return;
    if (_repairingKey != null) {
      _repairAgain = true;
      return;
    }
    if (controller.bars.isEmpty || _heikinAshi || _barsKey != _seriesKey) return _loadHistory();
    final symbol = _symbol, interval = _interval;
    _repairingKey = _seriesKey;
    _repairAgain = false;
    // Ticks are held during the repair, so don't wait out the global 60 s timeout on weak networks
    final page = await BinanceSpotApi.kline(
      from: 'feed._repairGap',
      symbol: symbol,
      interval: interval,
      cancelToken: _cancel,
    ).timeout(const Duration(seconds: 10), onTimeout: () => null);
    _repairingKey = null; // Fully synchronous below; no tick can interleave
    if (_disposed) return;
    // A full reload started during the repair (switched away and back): the reload wins.
    // Touching _loadGen here would drop the reload result as stale and loading would never clear
    if (loading) return;
    try {
      _applyRepair(symbol, interval, page);
    } finally {
      _replayHeldTicks();
    }
    if (_repairAgain) {
      _repairAgain = false;
      await _repairGap();
    }
  }

  void _applyRepair(String symbol, String interval, List<Bar>? page) {
    if (symbol != _symbol || interval != _interval || _barsKey != _seriesKey) return;
    if (page == null || page.isEmpty || controller.bars.isEmpty) return;
    final clean = sanitizeSpikes(page);
    final lastTime = controller.bars.last.time;
    final merged = mergeLivePage(controller.bars, clean);

    if (merged == null) {
      // Tail is continuous, no gap: append incrementally to keep the user's scroll position
      for (final b in clean) {
        if (b.time >= lastTime) controller.applyTick(b);
      }
      return;
    }

    // Gap: the series must be rebuilt. setBars moves the viewport back to latest; the incremental
    // path cannot fill a hole in the middle, and showing the latest after resume is expected.
    // Whole series replaced: in-flight paging used the old series' endTime and would leave a gap
    _loadGen++;
    controller.setBars(merged);
    debugPrint('[live] gap repaired: ${controller.bars.length} bars, last ${clean.last.time}');
  }

  /// Reconciles the latest page with the existing series. Returns null when the tail is
  /// continuous (caller appends incrementally); a list when there is a gap (replace the series)
  @visibleForTesting
  static List<Bar>? mergeLivePage(List<Bar> old, List<Bar> page) {
    if (page.isEmpty) return null;
    if (old.isEmpty) return List<Bar>.of(page);
    // Offline too long: one page cannot reconnect to the old segment (the middle bars are not in
    // it), so drop the old segment and land on the latest; loadMore refetches dropped history.
    if (page.first.time > old.last.time) return List<Bar>.of(page);

    final from = page.first.time;
    var i = 0;
    for (final b in old) {
      if (b.time < from) continue; // Keep old history before the page start as-is
      if (i >= page.length || page[i].time != b.time) {
        return [...old.where((e) => e.time < from), ...page];
      }
      i++;
    }
    return null;
  }

  Future<void> setInterval(String interval) async {
    if (interval == _interval) return;
    final oldLive = _liveTopic;
    _interval = interval;
    _noMoreHistory = false;
    // Subscribe new before unsubscribing old (see setSymbol)
    BinancePublicWs.instance.subscribe(_liveTopic, _onLiveData, from: 'feed.live');
    BinancePublicWs.instance.unsubscribe(oldLive, _onLiveData);
    await _loadHistory();
  }

  Future<void> setSymbol(String symbol) async {
    if (symbol == _symbol) return;
    final oldLive = _liveTopic, oldBook = _bookTopic;
    _symbol = symbol;
    _noMoreHistory = false;
    book.value = null;

    // Subscribe new, then unsubscribe old: the reverse would briefly empty the subscription list,
    // closing the connection and forcing a new handshake.
    // Old-channel ticks during the overlap are filtered out by the symbol check
    BinancePublicWs.instance.subscribe(_liveTopic, _onLiveData, from: 'feed.live');
    BinancePublicWs.instance.subscribe(_bookTopic, _onBookData, from: 'feed.book');
    BinancePublicWs.instance.unsubscribe(oldLive, _onLiveData);
    BinancePublicWs.instance.unsubscribe(oldBook, _onBookData);
    await _loadHistory();
  }

  @visibleForTesting
  Future<void> debugRepairGap() => _repairGap();

  @visibleForTesting
  void debugLiveData(Map<String, dynamic> data) => _onLiveData(data);

  /// Reloads the latest data (retry after a first-load failure)
  Future<void> resync() => _loadHistory();

  // ---- Heikin-Ashi ----

  bool _heikinAshi = false;

  bool get heikinAshi => _heikinAshi;

  /// Whether the chart shows the selected symbol / interval (false after a switch until new data
  /// lands)
  bool get showsCurrentSeries => _barsKey == _seriesKey;

  /// Toggles Heikin-Ashi: reloads everything and converts it as a whole (HA recursion depends on
  /// the previous HA bar, so it must start from the beginning); live ticks are incremental.
  set heikinAshi(bool v) {
    if (v == _heikinAshi) return;
    _heikinAshi = v;
    _loadHistory();
  }

  /// History paging when scrolled to the oldest edge (wired to KChart.onLoadMore).
  Future<void> loadMore() async {
    if (_loadingMoreKey == _seriesKey || _noMoreHistory || loading) return;
    final bars = controller.bars;
    if (bars.isEmpty || _barsKey != _seriesKey) return;
    final symbol = _symbol, interval = _interval, gen = _loadGen;
    final key = _loadingMoreKey = _seriesKey;
    // endTime includes the boundary bar; filtered out by time below
    final older = await BinanceSpotApi.kline(
      from: 'feed.loadMore',
      symbol: symbol,
      interval: interval,
      endTime: bars.first.time,
      cancelToken: _cancel,
    );
    if (_disposed) return;
    if (_loadingMoreKey == key) _loadingMoreKey = null;

    // Symbol/interval switched while paging: this page belongs to the old series, and prepending
    // it would join data of two different intervals.
    if (symbol != _symbol || interval != _interval) return;
    // A full reload happened while paging (Heikin-Ashi toggle): endTime is from the old series and
    // would leave a gap
    if (gen != _loadGen || loading || _barsKey != _seriesKey) return;

    // null = request/parse failure (retry on next scroll); [] means truly no more history.
    // Relies on live()'s parse returning null for malformed responses; see safeCall's contract.
    if (older == null) return;
    if (older.isEmpty) {
      _noMoreHistory = true;
      return;
    }

    final firstTime = controller.bars.isEmpty ? double.maxFinite : controller.bars.first.time;
    final distinct = older.where((b) => b.time < firstTime).toList();
    if (distinct.isEmpty) {
      _noMoreHistory = true;
    } else {
      final clean = sanitizeSpikes(distinct);
      // HA recursion should start from the very beginning; prepended pages self-seed instead, and
      // the seam error halves every bar, becoming invisible within a few bars.
      controller.prependHistory(_heikinAshi ? LivePro.toHeikinAshi(clean) : clean);
    }
  }

  Future<void> _loadHistory() async {
    final gen = ++_loadGen;
    _heldTicks.clear();
    loading = true;
    error = null;
    notifyListeners();
    final symbol = _symbol, interval = _interval;
    // onError is only used to show the reason; success is still judged by a null return value
    ApiError? failure;
    final bars = await BinanceSpotApi.kline(
      from: 'feed._loadHistory',
      symbol: symbol,
      interval: interval,
      cancelToken: _cancel,
      onError: (e) => failure = e,
    );
    if (_disposed) return; // Page closed/disposed mid-request: don't touch controller or notifiers

    // A newer load started meanwhile, or we switched away: the result and loading state belong
    // to the latest load, so don't even touch loading here (see _loadGen).
    if (gen != _loadGen || symbol != _symbol || interval != _interval) return;
    // loading must clear first: it gates _onLiveData, and if any return path below skipped it,
    // live ticks would be blocked forever (the chart would stop updating).
    loading = false;
    // Load failed, so held ticks have no snapshot to attach to; keeping them would replay them onto
    // corrected data at the next repair
    if (bars == null || bars.isEmpty) _heldTicks.clear();
    // Deliberate cancellation (leaving page/switching symbol) is not a failure; don't set error
    if (failure?.cancelled ?? false) {
      notifyListeners();
      return;
    }

    if (bars == null || bars.isEmpty) {
      // A network/parse failure is not the same as "really no data"; don't report both as no data
      final message = bars == null
          ? S.current.liveLoadFailed(failure?.message ?? S.current.livePleaseRetry)
          : S.current.liveNoData;
      if (_barsKey == _seriesKey) {
        // Reload of the same series failed: the chart data is still valid, just notify
        notice.value = message;
      } else {
        // Switched symbol / interval but got no new data: the old series must not stay under the
        // new title, so clear it and let the error view take over
        controller.setBars(const []);
        _barsKey = null;
        error = message;
      }
    } else {
      final clean = sanitizeSpikes(bars);
      controller.setBars(_heikinAshi ? LivePro.toHeikinAshi(clean) : clean);
      _barsKey = _seriesKey;
      debugPrint('[live] $symbol/$interval loaded ${bars.length} bars, last=${bars.last.close}');
      _replayHeldTicks();
    }
    notifyListeners();
  }

  int _tickCount = 0;

  void _onLiveData(Map<String, dynamic> data) {
    if (loading || _repairing) return _holdTick(data);
    if (_barsKey != _seriesKey) return;
    if (data['s'] != BinanceSpotApi.toExchangeSymbol(_symbol)) return;
    final kline = data['k'];
    if (kline is! Map || kline['i'] != _interval) return;
    if (controller.bars.isEmpty) return;
    var bar = LiveData.fromBinanceKlineJson(data).toBar();
    if (!hasPrices(bar)) return;
    // Drop out-of-order ticks older than the oldest history (applyTick has no slot for them)
    if (bar.time < controller.bars.first.time) return;
    // Previous bar: the second to last when updating the last bar, the last when appending;
    // spike filtering and HA recursion use the same bar.
    final bars = controller.bars;
    final isNewBar = bar.time > bars.last.time;
    // Late update of the previous bar: find its predecessor by time, not the second to last
    // (which would be itself)
    final at = isNewBar ? bars.length : controller.data.indexOfTime(bar.time);
    final prev = at > 0 ? bars[at - 1] : null;
    bar = sanitizeTick(bar, prev);
    // In HA mode the controller stores HA bars, so prev is already an HA value
    if (_heikinAshi) bar = LivePro.nextHeikinAshi(bar, prev);
    controller.applyTick(bar);
    _tickCount++;
    // One line per interval (every minute for 1m): answers "is the market still moving" without
    // enabling tick logs
    if (isNewBar) {
      debugPrint('[live] new bar $_interval  open=${bar.open}  from tick #$_tickCount');
    }
  }

  void _onBookData(Map<String, dynamic> data) {
    if (data['s'] != BinanceSpotApi.toExchangeSymbol(_symbol)) return;
    final bid = double.tryParse('${data['b']}'), ask = double.tryParse('${data['a']}');
    if (bid == book.value?.bid && ask == book.value?.ask) return;
    book.value = (bid: bid, ask: ask);
  }

  @override
  void dispose() {
    _disposed = true;
    // Abort in-flight REST requests (page left mid-open): cancel instead of waiting for them
    if (!_cancel.isCancelled) _cancel.cancel('BinanceLiveFeed disposed');
    if (_started) {
      BinancePublicWs.instance.connected.removeListener(_onConnectionChanged);
      WidgetsBinding.instance.removeObserver(this);
    }
    BinancePublicWs.instance.unsubscribe(_liveTopic, _onLiveData);
    BinancePublicWs.instance.unsubscribe(_bookTopic, _onBookData);
    book.dispose();
    notice.dispose();
    super.dispose();
  }
}

/// Holds blocked ticks: only the latest per bar, at most [capacity] bars, drained in open-time
/// order
class HeldTicks {
  HeldTicks({this.capacity = 8});

  final int capacity;
  final Map<int, Map<String, dynamic>> _byTime = {};

  int get length => _byTime.length;

  void hold(int openTime, Map<String, dynamic> data) {
    _byTime
      ..remove(openTime)
      ..[openTime] = data;
    if (_byTime.length > capacity) _byTime.remove(_byTime.keys.first);
  }

  List<Map<String, dynamic>> drain() {
    final keys = _byTime.keys.toList()..sort();
    final out = [for (final k in keys) _byTime[k]!];
    _byTime.clear();
    return out;
  }

  void clear() => _byTime.clear();
}
