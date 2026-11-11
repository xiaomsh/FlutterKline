import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:klinex/klinex.dart';

/// Regression net for the block min/max caches (data + indicator stores) and
/// the opt-in autoFollow: cached range answers must equal a brute-force scan
/// through every mutation path that shifts, rewrites or extends the data.

List<Bar> randomWalk(int n, {int seed = 7, int t0 = 1700000000000}) {
  final rnd = math.Random(seed);
  final bars = <Bar>[];
  var close = 100.0;
  for (var i = 0; i < n; i++) {
    final open = close;
    close = (open + (rnd.nextDouble() - 0.5) * 4).clamp(1.0, double.infinity);
    final high = math.max(open, close) + rnd.nextDouble() * 2;
    final low = math.max(math.min(open, close) - rnd.nextDouble() * 2, 0.5);
    bars.add(
      Bar(
        time: t0 + i * 60000,
        open: open,
        high: high,
        low: low,
        close: close,
        vol: 10 + rnd.nextDouble() * 1000,
      ),
    );
  }
  return bars;
}

MinMax bruteRange(List<Bar> bars, int start, int end, {bool closeOnly = false}) {
  var lo = double.infinity, hi = double.negativeInfinity;
  for (var i = start; i <= end; i++) {
    final b = bars[i];
    final bh = closeOnly ? b.close : b.high;
    final bl = closeOnly ? b.close : b.low;
    if (bh > hi) hi = bh;
    if (bl < lo) lo = bl;
  }
  return lo > hi ? MinMax.empty : MinMax(lo, hi);
}

void expectSameRange(MinMax a, MinMax b, String label) {
  expect(a.isEmpty, b.isEmpty, reason: label);
  if (a.isEmpty) return;
  expect(a.min, closeTo(b.min, 1e-9), reason: label);
  expect(a.max, closeTo(b.max, 1e-9), reason: label);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('DataSource.rangeOf matches brute force across random ranges', () {
    final data = DataSource()..setAll(randomWalk(500));
    final rnd = math.Random(1);
    for (var k = 0; k < 200; k++) {
      final a = rnd.nextInt(500), b = rnd.nextInt(500);
      final start = math.min(a, b), end = math.max(a, b);
      for (final closeOnly in [false, true]) {
        expectSameRange(
          data.rangeOf(start, end, closeOnly: closeOnly),
          bruteRange(data.bars, start, end, closeOnly: closeOnly),
          'range [$start,$end] closeOnly=$closeOnly',
        );
      }
    }
  });

  test('DataSource.rangeOf stays correct through every mutation path', () {
    final data = DataSource()..setAll(randomWalk(300));
    void check(String label) {
      final n = data.length;
      // Full range + a mid window + the cached-block-heavy tail.
      for (final (s, e) in [(0, n - 1), (n ~/ 4, 3 * n ~/ 4), (n - 70, n - 1)]) {
        expectSameRange(
          data.rangeOf(s, e),
          bruteRange(data.bars, s, e),
          '$label [$s,$e]',
        );
        // Warm the cache, then re-query (hits the built blocks).
        expectSameRange(
          data.rangeOf(s, e),
          bruteRange(data.bars, s, e),
          '$label cached [$s,$e]',
        );
      }
    }

    check('initial');

    // updateLast with a new extreme (the classic stale-cache trap).
    final last = data.bars.last;
    data.updateLast(
      Bar(
        time: last.time,
        open: last.open,
        high: last.high + 500,
        low: 0.1,
        close: last.close,
        vol: last.vol,
      ),
    );
    check('updateLast extreme');

    // Mid replace with a new global max, inside an already-built block.
    final mid = data.bars[137];
    data.replaceAt(
      137,
      Bar(
        time: mid.time,
        open: mid.open,
        high: 9999,
        low: mid.low,
        close: mid.close,
        vol: mid.vol,
      ),
    );
    check('replaceAt extreme');

    // Append past the built blocks.
    final t = data.bars.last.time;
    for (var i = 1; i <= 80; i++) {
      final b = randomWalk(1, seed: i, t0: t + i * 60000).first;
      data.append(b);
    }
    check('append');

    // Prepend shifts every index，caches must drop wholesale.
    final first = data.bars.first.time;
    data.prepend(randomWalk(150, seed: 99, t0: first - 150 * 60000));
    check('prepend');
  });

  test('indicator seriesRange matches brute force through live ticks', () {
    final controller = ChartController(
      indicators: [
        Ma(periods: [5, 20]),
        Macd(),
        Rsi(),
      ],
    );
    controller.setBars(randomWalk(400));

    // Live ticks: intra-bar updates and appends, warming caches in between.
    final rnd = math.Random(3);
    for (var k = 0; k < 60; k++) {
      final last = controller.bars.last;
      if (k % 3 == 0) {
        controller.applyTick(
          Bar(
            time: last.time + 60000,
            open: last.close,
            high: last.close + rnd.nextDouble() * 3,
            low: math.max(last.close - rnd.nextDouble() * 3, 0.5),
            close: last.close + (rnd.nextDouble() - 0.5) * 2,
            vol: 50,
          ),
        );
      } else {
        controller.applyTick(
          Bar(
            time: last.time,
            open: last.open,
            high: last.high + rnd.nextDouble() * 2,
            low: last.low,
            close: last.close + (rnd.nextDouble() - 0.5) * 2,
            vol: last.vol + 1,
          ),
        );
      }
      final n = controller.bars.length;
      for (final ind in controller.indicators.list) {
        final store = controller.storeOf(ind);
        final cached = ind.range(store, n - 100, n - 1);
        // Brute force over the same store values (per-series scan).
        var brute = MinMax.empty;
        for (final key in store.valuesAt(n - 1).keys) {
          brute = brute.union(seriesMinMax(store.series(key), n - 100, n - 1));
        }
        // range() may include a baseline (e.g. MACD's 0) or use a key subset;
        // instead compare the choke point both paths share: rangeOf vs scan.
        for (final key in store.valuesAt(n - 1).keys) {
          expectSameRange(
            store.rangeOf(key, n - 100, n - 1),
            seriesMinMax(store.series(key), n - 100, n - 1),
            'tick $k ${ind.id} $key',
          );
        }
        expect(cached.isEmpty, false, reason: 'tick $k ${ind.id}');
        expect(brute.isEmpty, false);
      }
    }
    controller.dispose();
  });

  test('IndicatorStore survives shrink-then-grow without stale values', () {
    final store = IndicatorStore()..resize(200);
    final s = store.series('x');
    for (var i = 0; i < 200; i++) {
      s[i] = i.toDouble();
    }
    expectSameRange(store.rangeOf('x', 0, 199), const MinMax(0, 199), 'full');
    store.resize(50); // shrink: [50,200) gone
    store.resize(120); // regrow: tail must be NaN, not stale
    final v = store.series('x');
    expect(v[49], 49.0);
    expect(v[50].isNaN, true);
    expect(v[119].isNaN, true);
    expectSameRange(store.rangeOf('x', 0, 119), const MinMax(0, 49), 'regrown');
  });

  test('autoFollow keeps the newest bar on screen; off by default', () {
    final vp = ChartViewport()..attach(800);
    vp.setBarCount(300, jumpToLatest: true);
    final before = vp.rightIndex;

    // Default: an append never moves the x axis.
    vp.setBarCount(301);
    expect(vp.rightIndex, before);

    // autoFollow + pinned: the viewport advances with the append.
    vp.autoFollow = true;
    vp.setBarCount(303);
    expect(vp.rightIndex, before + 2);

    // Scrolled away from the newest bar: follow disengages.
    vp.scroll(500); // finger right = show older data
    final parked = vp.rightIndex;
    vp.setBarCount(310);
    expect(vp.rightIndex, parked);

    // Scrolling back to the newest bar re-engages the pin.
    vp.scroll(-1e9);
    final atRight = vp.rightIndex;
    vp.setBarCount(315);
    expect(vp.rightIndex, atRight + 5);
  });
}
