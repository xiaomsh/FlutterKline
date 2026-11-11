import 'package:klinex_example/api/binance_spot_api.dart';
import 'package:klinex_example/model/data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Binance Spot data mapping', () {
    test('normalizes display symbols to Binance symbols', () {
      expect(BinanceSpotApi.toExchangeSymbol('btc_usdt'), 'BTCUSDT');
      expect(BinanceSpotApi.toExchangeSymbol('BTC/USDT'), 'BTCUSDT');
    });

    test('parses and sorts REST klines by open time', () {
      final bars = BinanceSpotApi.parseKlines([
        [2000, '2', '3', '1', '2.5', '20', 2999, '50'],
        [1000, '1', '2', '0.5', '1.5', '10', 1999, '15'],
      ]);

      expect(bars.map((bar) => bar.time), [1000, 2000]);
      expect(bars.first.open, 1);
      expect(bars.first.vol, 10);
    });

    test('rejects malformed REST rows instead of silently dropping them', () {
      expect(
        () => BinanceSpotApi.parseKlines([
          [1000, '1', '2'],
        ]),
        throwsFormatException,
      );
    });

    test('maps websocket kline open time and both Binance volumes', () {
      final ticker = LiveData.fromBinanceKlineJson({
        's': 'BTCUSDT',
        'k': {
          't': 1700000000000,
          'o': '10',
          'h': '12',
          'l': '9',
          'c': '11',
          'v': '4',
          'q': '44',
        },
      });

      expect(ticker.time, 1700000000000);
      expect(ticker.qty, 4);
      expect(ticker.vol, 44);
      expect(ticker.toBar().time, ticker.time);
      expect(ticker.toBar().vol, 4);
    });
  });
}
