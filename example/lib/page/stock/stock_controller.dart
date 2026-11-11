import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:klinex/klinex.dart';

import '../../api/eastmoney_api.dart';
import '../../l10n/l10n.dart';
import '../../pro/stock_pro.dart';
import '../../widget/pro_lock.dart';
import 'stock_symbols.dart';

/// State of the stock page: selected market / symbol / period, the chart controller and polling
/// during trading hours (paused in the background, reloaded on resume). Released in [onClose]
/// with the route.
class StockController extends GetxController with WidgetsBindingObserver {
  StockController({StockSymbol? initial}) : symbol = (initial ?? stockSymbols.first).obs;

  /// Current time source; tests pin it inside or outside trading hours.
  @visibleForTesting
  static int Function() clock = () => DateTime.now().millisecondsSinceEpoch;

  @visibleForTesting
  static Duration pollEvery = const Duration(seconds: 5);

  static const _prevCloseColor = Color(0xFF9AA0B0);
  static const _red = Color(0xFFEF5350);
  static const _green = Color(0xFF26A69A);

  late final ChartController chart;
  final levels = PriceLevelsOverlay();
  final limitMarks = LimitMarksOverlay();

  final Rx<StockSymbol> symbol;
  final period = StockPeriod.intraday.obs;
  final adjust = StockAdjust.none.obs;
  final redUp = true.obs;
  final name = ''.obs;
  final preClose = RxnDouble();

  /// Percent base and center of the intraday chart: [preClose] for one day, the close before
  /// the first day for five days; null for daily / weekly / monthly bars.
  final chartBase = RxnDouble();
  final lastPrice = RxnDouble();
  final decimals = 2.obs;
  final loading = false.obs;
  final hasError = false.obs;

  /// Fixed-slot axis of the intraday chart; null for daily / weekly / monthly bars.
  final axis = Rxn<SlotAxis>();

  /// Main range of the intraday chart, symmetric around [chartBase]; null for daily / weekly /
  /// monthly bars.
  RangeAdjust? mainRange;

  Timer? _poll;
  CancelToken? _cancel;
  int _seq = 0;

  StockMarket get market => symbol.value.market;

  bool get trading => market.session.isTrading(clock());

  @override
  void onInit() {
    super.onInit();
    chart = ChartController(overlays: [levels, limitMarks]);
    redUp.value = market.redUp;
    load();
    _poll = Timer.periodic(pollEvery, (_) => _refresh());
    WidgetsBinding.instance.addObserver(this);
  }

  bool _background = false;
  bool _polling = false;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final background = state != AppLifecycleState.resumed;
    if (background == _background) return;
    _background = background;
    // Polls were skipped meanwhile and only run during trading hours: reload once
    if (!background) load();
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _poll?.cancel();
    _cancel?.cancel();
    // In-flight polls carry no cancel token; a new sequence drops their responses
    _seq++;
    chart.dispose();
    super.onClose();
  }

  void selectMarket(StockMarket m) {
    if (m == market) return;
    redUp.value = m.redUp;
    selectSymbol(m.symbols.first);
  }

  void selectSymbol(StockSymbol s) {
    if (s.secid == symbol.value.secid) return;
    symbol.value = s;
    load();
  }

  void selectPeriod(StockPeriod p) {
    if (p == period.value) return;
    if (p == StockPeriod.fiveDay && !StockPro.unlocked) {
      showProLock();
      return;
    }
    period.value = p;
    load();
  }

  void selectAdjust(StockAdjust a) {
    if (a == adjust.value) return;
    if (a != StockAdjust.none && !StockPro.unlocked) {
      showProLock();
      return;
    }
    adjust.value = a;
    if (!period.value.isIntraday) load();
  }

  Future<void> load() async {
    _cancel?.cancel();
    final token = _cancel = CancelToken();
    final seq = ++_seq;
    loading.value = true;
    hasError.value = false;
    final s = symbol.value;
    final p = period.value;
    var ok = false;
    if (p.isIntraday) {
      final data = await EastmoneyApi.trends(
        s.secid,
        from: 'stock.load',
        days: p == StockPeriod.fiveDay ? 5 : 1,
        cancelToken: token,
      );
      if (seq != _seq) return;
      if (data != null) ok = _applyIntraday(data, reset: true);
    } else {
      final ownQuote = _quoteFromBars;
      final results = await Future.wait([
        EastmoneyApi.kline(
          s.secid,
          from: 'stock.load',
          klt: p.klt,
          fqt: adjust.value.fqt,
          cancelToken: token,
        ),
        if (!ownQuote) _quote(s, token),
      ]);
      if (seq != _seq) return;
      final data = results.first;
      if (data != null) {
        ok = _applyKlines(data);
        _setQuote(ownQuote ? data : results.last);
      }
    }
    loading.value = false;
    hasError.value = !ok;
  }

  /// The quote shows the real last price and the change against yesterday's close: daily
  /// unadjusted bars carry both; other periods and adjusted bars need a separate daily request.
  bool get _quoteFromBars => period.value == StockPeriod.day && adjust.value == StockAdjust.none;

  Future<KlineData?> _quote(StockSymbol s, [CancelToken? token]) =>
      EastmoneyApi.kline(s.secid, from: 'stock.quote', klt: 101, limit: 2, cancelToken: token);

  void _setQuote(KlineData? q) {
    final bars = q?.bars ?? const <Bar>[];
    lastPrice.value = bars.isEmpty ? null : bars.last.close;
    preClose.value = bars.length > 1 ? bars[bars.length - 2].close : null;
  }

  /// Polls the latest minutes (intraday) or the latest bar (daily / weekly / monthly) while the
  /// market is open.
  Future<void> _refresh() async {
    if (_polling || _background || loading.value || hasError.value || !trading) return;
    _polling = true;
    try {
      await _pollOnce();
    } finally {
      _polling = false;
    }
  }

  Future<void> _pollOnce() async {
    final p = period.value;
    final seq = _seq;
    final s = symbol.value;
    if (p.isIntraday) {
      // Today only, also for five days: the earlier days don't change while trading
      final data = await EastmoneyApi.trends(s.secid, from: 'stock.poll');
      if (seq != _seq || data == null) return;
      if (p == StockPeriod.fiveDay) {
        _appendToday(data);
      } else {
        _applyIntraday(data, reset: false);
      }
    } else {
      final data = await EastmoneyApi.kline(
        s.secid,
        from: 'stock.poll',
        klt: p.klt,
        fqt: adjust.value.fqt,
        limit: 2,
      );
      if (seq != _seq || data == null || data.bars.isEmpty) return;
      if (!_applyLatest(data.bars)) {
        load();
        return;
      }
      if (_quoteFromBars) {
        _setQuote(data);
      } else {
        final q = await _quote(s);
        if (seq == _seq && q != null) _setQuote(q);
      }
    }
  }

  /// Updates the last bar, or closes it and appends a new day's bar. Weekly / monthly bars are
  /// dated by their latest trading day, so a changed date there needs a reload; returns false then.
  bool _applyLatest(List<Bar> latest) {
    final old = chart.bars;
    if (old.isEmpty) return false;
    final last = latest.last;
    if (last.time == old.last.time) {
      chart.applyTick(last);
      return true;
    }
    final n = latest.length;
    if (period.value != StockPeriod.day || n < 2 || latest[n - 2].time != old.last.time) {
      return false;
    }
    chart
      ..applyTick(latest[n - 2])
      ..applyTick(last);
    return true;
  }

  bool _applyIntraday(IntradayData data, {required bool reset}) {
    final session = market.session;
    final fiveDay = period.value == StockPeriod.fiveDay;
    final pc = data.preClose > 0 ? data.preClose : null;
    final base = fiveDay ? (data.firstPreClose > 0 ? data.firstPreClose : null) : pc;
    final bars = session.normalize(data.bars, preClose: base);
    if (bars.isEmpty) return false;
    name.value = data.name;
    decimals.value = data.decimals;
    lastPrice.value = bars.last.close;
    final old = chart.bars;
    final sameDays = old.isNotEmpty && old.first.time == bars.first.time;
    if (reset || !sameDays || bars.length < old.length) {
      preClose.value = pc;
      chartBase.value = base;
      final days = {for (final b in bars) session.dayOf(b.time)}.toList()..sort();
      axis.value = fiveDay ? StockPro.multiDayAxis(session, days) : IntradayAxis(session);
      _setIntradayLevels(base, limits: !fiveDay);
      limitMarks.limit = null;
      chart.indicators.setAll([
        AveragePrice(
          session: session,
          volumeUnit: market.volumeUnit,
          label: S.current.stockAverage,
        ),
        Vol(),
      ]);
      chart.setBars(bars);
      return true;
    }
    for (var i = old.length - 1; i < bars.length; i++) {
      chart.applyTick(bars[i]);
    }
    return true;
  }

  /// Applies today's minutes to the end of the five-day chart; a new day shifts the window, so it
  /// reloads all five days.
  void _appendToday(IntradayData data) {
    final session = market.session;
    final today = session.normalize(data.bars, preClose: data.preClose > 0 ? data.preClose : null);
    final old = chart.bars;
    if (today.isEmpty || old.isEmpty) return;
    final last = old.last.time;
    if (session.dayOf(last) != session.dayOf(today.first.time)) {
      load();
      return;
    }
    lastPrice.value = today.last.close;
    for (var i = session.slotOf(last) ?? today.length; i < today.length; i++) {
      chart.applyTick(today[i]);
    }
  }

  /// Limit lines only make sense for one day: each day's limits follow its own previous close.
  void _setIntradayLevels(double? pc, {required bool limits}) {
    final limit = limits ? symbol.value.limit : null;
    if (pc == null) {
      levels.levels = const [];
      mainRange = null;
      return;
    }
    final up = limit?.up(pc);
    final down = limit?.down(pc);
    levels.levels = [
      PriceLevel(pc, color: _prevCloseColor, label: S.current.stockPrevClose),
      if (up != null) PriceLevel(up, color: _red, label: S.current.stockLimitUp),
      if (down != null) PriceLevel(down, color: _green, label: S.current.stockLimitDown),
    ];
    mainRange = StockRange(symmetricAround: pc);
  }

  bool _applyKlines(KlineData data) {
    if (data.bars.isEmpty) return false;
    final bars = data.bars;
    name.value = data.name;
    decimals.value = market == StockMarket.a ? 2 : 3;
    chartBase.value = null;
    axis.value = null;
    mainRange = null;
    levels.levels = const [];
    limitMarks
      // Adjusted prices are rescaled and rounded, so they no longer hit the exchange's limit prices
      ..limit = _quoteFromBars ? symbol.value.limit : null
      ..upLabel = S.current.stockLimitUpShort
      ..downLabel = S.current.stockLimitDownShort;
    chart.indicators.setAll([
      Ma(periods: const [5, 10, 20]),
      Vol(),
      Macd(),
    ]);
    chart.setBars(bars);
    return true;
  }
}
