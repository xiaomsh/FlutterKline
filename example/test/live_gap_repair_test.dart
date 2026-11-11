import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:klinex/klinex.dart';

import 'package:klinex_example/api/binance_spot_api.dart';
import 'package:klinex_example/widget/binance_live_feed.dart';

/// 1m bars; time is the minute index * 60000.
List<Bar> bars(Iterable<int> minutes) => [
  for (final m in minutes) Bar(time: m * 60000, open: 1, high: 2, low: 0.5, close: 1.5, vol: 10),
];

List<int> minutesOf(List<Bar> list) => [for (final b in list) b.time ~/ 60000];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized(); // ChartController._bump needs a scheduler

  group('mergeLivePage: gap repair decision after the screen wakes up', () {
    test('contiguous tail -> null (incremental catch-up keeps the viewport)', () {
      final old = bars([1, 2, 3, 4, 5]);
      final page = bars([3, 4, 5, 6, 7]);
      expect(BinanceLiveFeed.mergeLivePage(old, page), isNull);
    });

    test('missing bars in the middle -> whole page merged, gap filled', () {
      // 6-9 were missed while the screen was off; after WS resumed, applyTick appended 10.
      final old = bars([1, 2, 3, 4, 5, 10]);
      final page = bars([4, 5, 6, 7, 8, 9, 10, 11]);
      final merged = BinanceLiveFeed.mergeLivePage(old, page);
      expect(merged, isNotNull);
      expect(minutesOf(merged!), [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]);
    });

    test('history before the page start is kept (repair does not drop loaded pages)', () {
      final old = bars([1, 2, 3, 20]);
      final page = bars([3, 4, 5]);
      final merged = BinanceLiveFeed.mergeLivePage(old, page);
      expect(minutesOf(merged!), [1, 2, 3, 4, 5]);
    });

    test('offline too long, one page cannot reach the old data -> drop it, jump to latest', () {
      final old = bars([1, 2, 3]);
      final page = bars([100, 101, 102]);
      final merged = BinanceLiveFeed.mergeLivePage(old, page);
      expect(minutesOf(merged!), [100, 101, 102]);
    });

    test('empty page -> null (a failed request must not touch the data)', () {
      expect(BinanceLiveFeed.mergeLivePage(bars([1, 2]), []), isNull);
    });

    test('only reads old, never mutates it in place', () {
      final old = bars([1, 2, 3, 10]);
      BinanceLiveFeed.mergeLivePage(old, bars([2, 3, 4, 5]));
      expect(minutesOf(old), [1, 2, 3, 10]);
    });
  });

  group('regression: applyTick cannot fill a hole in the middle', () {
    test('a gap created by append cannot be filled later with the missing bars', () {
      final c = ChartController();
      c.setBars(bars([1, 2, 3]));
      c.applyTick(bars([10]).first); // first push after the screen wakes up
      expect(minutesOf(c.bars), [1, 2, 3, 10]);
      // Feed the missed bars back: old-timestamp branch, indexOfTime finds no slot, dropped.
      for (final b in bars([4, 5, 6, 7, 8, 9])) {
        c.applyTick(b);
      }
      expect(minutesOf(c.bars), [
        1,
        2,
        3,
        10,
      ], reason: 'the hole remains, so the whole range must be replaced');
      c.dispose();
    });
  });

  test(
    'ticks held during loading: latest per bar, oldest dropped over capacity, drained in time order',
    () {
      final held = HeldTicks(capacity: 3);
      held.hold(120000, {'v': 'b1'});
      held.hold(60000, {'v': 'a'});
      held.hold(120000, {'v': 'b2'});
      held.hold(180000, {'v': 'c'});
      held.hold(240000, {'v': 'd'});
      expect(held.length, 3);
      expect([for (final d in held.drain()) d['v']], ['b2', 'c', 'd']);
      expect(held.length, 0);
    },
  );

  test('a repair requested while one is in flight runs again afterwards', () async {
    final pending = <Completer<List<Bar>?>>[];
    BinanceSpotApi.debugKline = (from, _) {
      if (from == 'feed._loadHistory') return Future.value(bars([1, 2, 3, 4, 5]));
      final c = Completer<List<Bar>?>();
      pending.add(c);
      return c.future;
    };
    final chart = ChartController();
    final feed = BinanceLiveFeed(chart);
    try {
      await feed.resync();
      expect(chart.bars.length, 5);
      final first = feed.debugRepairGap();
      await feed.debugRepairGap();
      expect(pending.length, 1);
      pending.first.complete(bars([3, 4, 5]));
      await Future<void>.delayed(Duration.zero);
      expect(pending.length, 2, reason: 'the second trigger must not be dropped');
      pending.last.complete(bars([4, 5, 6]));
      await first;
      expect(minutesOf(chart.bars), [1, 2, 3, 4, 5, 6]);
    } finally {
      BinanceSpotApi.debugKline = null;
      feed.dispose();
      chart.dispose();
    }
  });

  test('ticks held during a failed reload are not replayed onto a later repair', () async {
    final loads = <Completer<List<Bar>?>>[];
    BinanceSpotApi.debugKline = (from, _) {
      if (from == 'feed._loadHistory') {
        final c = Completer<List<Bar>?>();
        loads.add(c);
        return c.future;
      }
      return Future.value(bars([3, 4, 5]));
    };
    final chart = ChartController();
    final feed = BinanceLiveFeed(chart);
    try {
      final first = feed.resync();
      loads.last.complete(bars([1, 2, 3, 4, 5]));
      await first;
      final retry = feed.resync();
      feed.debugLiveData({
        's': BinanceSpotApi.toExchangeSymbol('btc_usdt'),
        'k': {
          't': 5 * 60000,
          'i': '1m',
          'o': '1',
          'h': '2',
          'l': '0.5',
          'c': '1.9',
          'v': '10',
          'q': '10',
        },
      });
      loads.last.complete(null);
      await retry;
      await feed.debugRepairGap();
      expect(chart.bars.last.close, 1.5);
    } finally {
      BinanceSpotApi.debugKline = null;
      feed.dispose();
      chart.dispose();
    }
  });
}
