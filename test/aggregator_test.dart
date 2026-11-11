import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:klinex/klinex.dart';

class Every extends BarAggregator {
  const Every(this.ms);
  final int ms;
  @override
  int bucketOf(int time) => time - time % ms;
}

const minute = 60000;
const t0 = 1700000000000 - 1700000000000 % (60 * minute);

Bar mk(int i, double c, {double vol = 1}) =>
    Bar(time: t0 + i * minute, open: c - 0.5, high: c + 1, low: c - 1, close: c, vol: vol);

List<Bar> series(int from, int to, {int seed = 1}) {
  final rnd = math.Random(seed);
  return [for (var i = from; i < to; i++) mk(i, 100 + rnd.nextDouble() * 10)];
}

List<Indicator> inds() => [
  Ma(periods: [5, 10]),
  Ema(periods: [12]),
  Macd(),
  Rsi(),
];

/// Output equals aggregating the whole source; indicators equal a full compute on the result
/// ([indicators] false compares bars only)
void expectConsistent(ChartController c, {bool indicators = true}) {
  final agg = c.aggregator!;
  final want = agg.aggregate(c.sourceBars);
  expect(c.bars.length, want.length);
  for (var i = 0; i < want.length; i++) {
    final a = c.bars[i], b = want[i];
    expect(
      [a.time, a.open, a.high, a.low, a.close, a.vol],
      [b.time, b.open, b.high, b.low, b.close, b.vol],
      reason: 'bar $i',
    );
  }
  if (!indicators) return;
  final ref = ChartController(indicators: inds())
    ..asyncCompute = false
    ..setBars(want);
  for (var k = 0; k < c.indicators.list.length; k++) {
    final s1 = c.storeOf(c.indicators.list[k]), s2 = ref.storeOf(ref.indicators.list[k]);
    for (var i = 0; i < want.length; i++) {
      final v1 = s1.valuesAt(i), v2 = s2.valuesAt(i);
      for (final key in v2.keys) {
        final x = v1[key], y = v2[key]!;
        if (y.isNaN) {
          expect(x == null || x.isNaN, isTrue, reason: '$key@$i');
        } else {
          expect(x, closeTo(y, 1e-9), reason: '$key@$i');
        }
      }
    }
  }
  ref.dispose();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('aggregate merges OHLCV per bucket', () {
    final out = const Every(5 * minute).aggregate([
      mk(0, 10, vol: 1),
      mk(1, 12, vol: 2),
      mk(4, 9, vol: 3),
      mk(5, 11, vol: 4),
    ]);
    expect(out.length, 2);
    expect(out[0].time, t0);
    expect(out[0].open, 9.5);
    expect(out[0].high, 13);
    expect(out[0].low, 8);
    expect(out[0].close, 9);
    expect(out[0].vol, 6);
    expect(out[1].time, t0 + 5 * minute);
  });

  test('setBars / aggregator setter switch between source and aggregated', () {
    final c = ChartController(indicators: inds())
      ..asyncCompute = false
      ..setBars(series(0, 120));
    expect(c.bars.length, 120);
    c.aggregator = const Every(15 * minute);
    expect(c.bars.length, 8);
    expect(c.sourceBars.length, 120);
    expectConsistent(c);
    c.aggregator = null;
    expect(c.bars.length, 120);
    expect(identical(c.sourceBars, c.bars), isTrue);
    c.dispose();
  });

  test('live ticks only touch the last bucket and stay consistent', () {
    final c = ChartController(indicators: inds())
      ..asyncCompute = false
      ..aggregator = const Every(5 * minute)
      ..setBars(series(0, 63));
    final rnd = math.Random(7);
    var i = 63;
    for (var step = 0; step < 200; step++) {
      if (rnd.nextInt(4) == 0) {
        c.applyTick(mk(i++, 100 + rnd.nextDouble() * 10));
      } else {
        c.applyTick(mk(i - 1, 100 + rnd.nextDouble() * 10, vol: rnd.nextDouble()));
      }
      if (step % 25 == 0) expectConsistent(c);
    }
    expectConsistent(c);
    // appendBar / updateLast also take source data; wrong times are dropped
    final n = c.sourceBars.length;
    c.appendBar(mk(i - 5, 1));
    c.updateLast(mk(i - 5, 1));
    expect(c.sourceBars.length, n);
    c.appendBar(mk(i, 105));
    c.updateLast(mk(i, 106));
    expect(c.sourceBars.last.close, 106);
    expectConsistent(c);
    c.dispose();
  });

  test('historical correction rewrites only its bucket', () {
    final c = ChartController(indicators: inds())
      ..asyncCompute = false
      ..aggregator = const Every(5 * minute)
      ..setBars(series(0, 60));
    c.applyTick(mk(12, 500));
    expect(c.bars[2].high, 501);
    expectConsistent(c);
    // replaceAt index is a source-data index
    c.replaceAt(30, mk(30, 1));
    expect(c.bars[6].low, 0);
    expectConsistent(c);
    // unknown time ignored
    c.applyTick(Bar(time: t0 + 30 * minute + 1, open: 1, high: 1, low: 1, close: 1));
    expectConsistent(c);
    c.dispose();
  });

  test('prependHistory merges the boundary bucket and shifts the viewport', () {
    // source starts at minute 7, so the first 5-minute bucket has only 3 bars
    final all = series(0, 80);
    final c = ChartController(indicators: inds())
      ..asyncCompute = false
      ..aggregator = const Every(5 * minute)
      ..setBars(all.sublist(37));
    final firstBefore = c.bars.first;
    expect(firstBefore.time, t0 + 35 * minute);
    final right = c.viewport.rightIndex;
    final n0 = c.bars.length;
    c.prependHistory(all.sublist(20, 39)); // overlaps existing data by two bars, which get trimmed
    expect(c.sourceBars.length, 60);
    expect(c.bars.first.time, t0 + 20 * minute);
    expect(c.bars.length, n0 + 3);
    expect(c.viewport.rightIndex, right + 3);
    expectConsistent(c);
    // only fills inside the boundary bucket: no new bucket inserted, only the first bar fixed
    final c2 = ChartController(indicators: inds())
      ..asyncCompute = false
      ..aggregator = const Every(5 * minute)
      ..setBars(all.sublist(37));
    c2.prependHistory(all.sublist(35, 37));
    expect(c2.bars.length, n0);
    expect(c2.bars.first.open, all[35].open);
    expectConsistent(c2);
    c.dispose();
    c2.dispose();
  });

  test('maxBars trims source buckets along with output', () {
    final c = ChartController(indicators: inds())
      ..asyncCompute = false
      ..aggregator = const Every(5 * minute)
      ..maxBars = 10
      ..setBars(series(0, 100));
    expect(c.bars.length, 10);
    expect(c.sourceBars.first.time, c.bars.first.time);
    for (var i = 100; i < 120; i++) {
      c.applyTick(mk(i, 100));
    }
    expect(c.bars.length, 10);
    expect(c.sourceBars.length, 50);
    expect(c.sourceBars.first.time, c.bars.first.time);
    // after trimming, recursive indicators start differently from a full recompute (existing
    // maxBars behavior), so compare bars only
    expectConsistent(c, indicators: false);
    c.dispose();
  });

  test('applyTick on empty aggregated chart bootstraps', () {
    final c = ChartController(indicators: inds())
      ..asyncCompute = false
      ..aggregator = const Every(5 * minute);
    c.applyTick(mk(0, 10));
    c.applyTick(mk(1, 11));
    expect(c.bars.length, 1);
    expect(c.sourceBars.length, 2);
    expectConsistent(c);
    c.dispose();
  });

  test('incremental last-bucket merge matches full aggregation under random ticks', () {
    final rnd = math.Random(7);
    final c = ChartController(indicators: inds())
      ..asyncCompute = false
      ..aggregator = const Every(15 * minute)
      ..setBars(series(100, 130));
    var next = 130;
    for (var step = 0; step < 400; step++) {
      final r = rnd.nextInt(10);
      final price = 100 + rnd.nextDouble() * 10;
      if (r < 3) {
        c.applyTick(mk(next++, price, vol: rnd.nextDouble()));
      } else if (r < 9) {
        c.applyTick(mk(next - 1, price, vol: rnd.nextDouble()));
      } else {
        // edit history (may land in the last bucket)
        c.applyTick(mk(next - 1 - rnd.nextInt(20), price));
      }
      if (step == 200) c.prependHistory(series(80, 100, seed: 3));
      expectConsistent(c, indicators: false);
    }
    expectConsistent(c);
    c.dispose();
  });

  test('a malformed live tick folds the same as a full rebuild', () {
    final c = ChartController()
      ..asyncCompute = false
      ..aggregator = const Every(5 * minute)
      ..setBars(series(0, 62));
    final last = c.sourceBars.last;
    c.applyTick(Bar(time: last.time, open: 120, high: 90, low: 95, close: 100, vol: -5));
    expectConsistent(c, indicators: false);
    c.applyTick(Bar(time: last.time + minute, open: 130, high: 80, low: 85, close: 100, vol: -1));
    expectConsistent(c, indicators: false);
    c.dispose();
  });
}
