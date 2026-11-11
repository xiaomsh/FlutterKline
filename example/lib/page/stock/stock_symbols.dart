import 'package:klinex/klinex.dart';

import '../../l10n/l10n.dart';

enum StockMarket {
  a,
  hk,
  us;

  String get label => switch (this) {
    a => S.current.stockMarketA,
    hk => S.current.stockMarketHk,
    us => S.current.stockMarketUs,
  };

  TradingSession get session => switch (this) {
    a => TradingSession.cnA,
    hk => TradingSession.hk,
    us => TradingSession.us,
  };

  /// Eastmoney reports A-share volume in lots of 100 shares.
  double get volumeUnit => this == a ? 100 : 1;

  /// Mainland China and Hong Kong color rises red; the US colors them green.
  bool get redUp => this != us;

  List<StockSymbol> get symbols => stockSymbols.where((s) => s.market == this).toList();
}

class StockSymbol {
  const StockSymbol(this.secid, this.code, this.market, {this.limit});

  /// Eastmoney id: `<market>.<code>`.
  final String secid;
  final String code;
  final StockMarket market;

  /// Daily price limit; null for markets without one.
  final PriceLimit? limit;
}

const stockSymbols = [
  StockSymbol('1.600519', '600519', StockMarket.a, limit: PriceLimit.mainBoard),
  StockSymbol('0.300750', '300750', StockMarket.a, limit: PriceLimit.growth),
  StockSymbol('1.688981', '688981', StockMarket.a, limit: PriceLimit.growth),
  StockSymbol('116.00700', '00700', StockMarket.hk),
  StockSymbol('116.09988', '09988', StockMarket.hk),
  StockSymbol('105.AAPL', 'AAPL', StockMarket.us),
  StockSymbol('105.NVDA', 'NVDA', StockMarket.us),
  StockSymbol('105.TSLA', 'TSLA', StockMarket.us),
];

enum StockPeriod {
  intraday,
  fiveDay,
  day,
  week,
  month;

  String get label => switch (this) {
    intraday => S.current.stockPeriodIntraday,
    fiveDay => S.current.stockPeriodFiveDay,
    day => S.current.stockPeriodDay,
    week => S.current.stockPeriodWeek,
    month => S.current.stockPeriodMonth,
  };

  bool get isIntraday => this == intraday || this == fiveDay;

  /// Eastmoney kline type.
  int get klt => switch (this) {
    week => 102,
    month => 103,
    _ => 101,
  };
}

enum StockAdjust {
  none,
  forward,
  backward;

  String get label => switch (this) {
    none => S.current.stockAdjustNone,
    forward => S.current.stockAdjustForward,
    backward => S.current.stockAdjustBackward,
  };

  /// Eastmoney fqt.
  int get fqt => index;
}
