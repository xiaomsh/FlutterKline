import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:klinex/klinex.dart';

import '../../pro/live_pro.dart';
import '../../widget/binance_live_feed.dart';
import '../../widget/indicator_configs.dart';
import '../../widget/pro_lock.dart';
import '../feed_state_mixin.dart';

/// State and lifecycle of the live page. Page toggles are .obs; released in [onClose] when the
/// route is disposed
class LiveController extends GetxController with FeedStateMixin {
  LiveController({this.symbol0 = 'btc_usdt'});

  final String symbol0;

  // ---- Owned objects (created in onInit, released in onClose) ----
  late final ChartController chart;
  late final BinanceLiveFeed feed;
  late final PriceLineOverlay priceLine;
  late final LivePro pro;

  VoidCallback? _unbindNotice;
  final IndicatorConfigs indicatorCfg = IndicatorConfigs();

  // ---- Indicator selection (plain Sets; changes are broadcast via indRev) ----
  final Set<String> main = {'MA'};
  final Set<String> sub = {'VOL'};
  final indRev = 0.obs; // Indicator set/param change tick: rebuilds selectors and chart height

  static const mainOptions = ['MA', 'EMA', 'BOLL', ...LivePro.mainOptions];

  /// Selector order = sub panel order from top to bottom: free ones first, paid ones after
  static const subOptions = ['VOL', 'MACD', 'KDJ', 'RSI', 'WR', ...LivePro.subOptions];

  static const symbols = [
    'btc_usdt', 'eth_usdt', 'xrp_usdt', 'sol_usdt', 'doge_usdt', //
  ];

  // ---- Reactive page state ----
  final yAxisOutside = true.obs;
  final autoFollow = true.obs;
  final percent = false.obs;
  final isLog = false.obs;
  final chartHeight = 300.0.obs;

  /// Main series style: candle / line / area, or one of [LivePro.seriesNames]
  final seriesKind = 'candle'.obs;
  final utcOffset = Rxn<Duration>();
  // Last price: priceLine.showPrice controls the dashed line; mirrored here as .obs for Obx,
  // and the same value goes to AxisPriceTags for the price tag text.
  final showPrice = true.obs;
  // The countdown only exists in the widget layer (AxisPriceTags); the library has no switch.
  final showCountdown = true.obs;

  /// Best bid / ask price tags on the y axis
  final showBookPrice = true.obs;

  // ---- Feed bridge (loading/hasError/hasBars come from FeedStateMixin) ----
  final symbol = ''.obs;
  final interval = ''.obs;

  @override
  void onInit() {
    super.onInit();
    pro = LivePro(this);
    // Price tags/countdown are drawn by the widget layer (AxisPriceTags); the overlay only
    // draws the dashed line
    priceLine = PriceLineOverlay();
    chart = ChartController(
      indicators: buildIndicators(),
      defaultOverlays: false,
      overlays: [CrosshairOverlay(), priceLine, IndicatorLegendOverlay()],
    );
    feed = BinanceLiveFeed(chart, symbol: symbol0)..addListener(_onFeed);
    _unbindNotice = bindFeedNotice(feed);
    symbol.value = feed.symbol;
    interval.value = feed.interval;
    showPrice.value = priceLine.showPrice;
    feed.start();
  }

  void setShowPrice(bool v) {
    priceLine.showPrice = v;
    showPrice.value = v;
  }

  void _onFeed() {
    syncFeedState(feed, chart);
    symbol.value = feed.symbol;
    interval.value = feed.interval;
    pro.heikinAshi.value = feed.heikinAshi;
  }

  @override
  void onClose() {
    _unbindNotice?.call();
    feed
      ..removeListener(_onFeed)
      ..dispose();
    chart.dispose();
    super.onClose();
  }

  // ---- Indicators / series ----

  List<Indicator> buildIndicators() {
    return [...indicatorCfg.build(main, sub), ...pro.buildIndicators(main, sub)];
  }

  MainSeries get series {
    final proSeries = LivePro.seriesOf(seriesKind.value);
    if (proSeries != null) return proSeries;
    return MainSeries.fromStyle(MainSeriesStyle.values.byName(seriesKind.value));
  }

  /// Sub panel count = distinct non-main panels declared by the actual indicators.
  int get subPanelCount => {
    for (final ind in chart.indicators.list)
      if (!ind.target.isMain) ind.target.keyFor(ind),
  }.length;

  void toggleIndicator(Set<String> set, String key) {
    final isPro = LivePro.mainOptions.contains(key) || LivePro.subOptions.contains(key);
    if (isPro && !LivePro.unlocked) {
      showProLock();
      return;
    }
    set.contains(key) ? set.remove(key) : set.add(key);
    chart.indicators.setAll(buildIndicators());
    indRev.value++;
  }

  void applyIndicatorSettings() {
    chart.indicators.setAll(buildIndicators());
    indRev.value++;
  }

  // ---- Interval / symbol ----

  void setInterval(String iv) => feed.setInterval(iv);

  void setSymbol(String s) => feed.setSymbol(s);
}
