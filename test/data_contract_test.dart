import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klinex/klinex.dart';

/// Edges of the data update contract: bad input must be dropped rather than break the ordering
/// invariant (ordering is the shared precondition of binary search / time mapping / block cache;
/// there are no asserts in release).

Bar bar(int t, double c) => Bar(time: t, open: c, high: c + 1, low: c - 1, close: c, vol: 1);

List<Bar> series(int n, {int t0 = 1700000000000, int step = 60000}) => [
  for (var i = 0; i < n; i++) bar(t0 + i * step, 100.0 + i),
];

bool isSorted(List<Bar> bars) {
  for (var i = 1; i < bars.length; i++) {
    if (bars[i].time <= bars[i - 1].time) return false;
  }
  return true;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('prependHistory trims the overlap (inclusive page-boundary bars are the norm)', () {
    final all = series(100);
    final c = ChartController()..setBars(all.sublist(50));
    // the previous page brought back 3 overlapping boundary bars
    c.prependHistory(all.sublist(20, 53));
    expect(isSorted(c.bars), isTrue, reason: 'overlap must be trimmed, ordering must not break');
    expect(c.bars.length, 80, reason: '30 bars actually inserted');
    expect(c.bars.first.time, all[20].time);

    // fully overlapping: dropped entirely, no state changes
    final len = c.bars.length;
    final right = c.viewport.rightIndex;
    c.prependHistory(all.sublist(30, 40));
    expect(c.bars.length, len);
    expect(c.viewport.rightIndex, right, reason: 'no insert means no viewport shift');
    c.dispose();
  });

  test('prependHistory shifts the viewport and relocates the crosshair by timestamp', () {
    final all = series(200);
    final c = ChartController()..setBars(all.sublist(100));
    c.viewport.attach(400);
    // select current bar 10 (= all[110]); its timestamp is stored
    c.crosshair.value = CrosshairState(time: c.bars[10].time, position: const Offset(50, 50));
    // 10 of the 40 bars overlap, 30 actually inserted
    c.prependHistory(all.sublist(70, 110));
    expect(c.bars.length, 130);
    expect(c.crosshairIndex(), 40, reason: 'crosshair relocates by timestamp automatically');
    expect(c.bars[c.crosshairIndex()].time, all[110].time, reason: 'still the original bar');
    c.dispose();
  });

  test('appendBar/updateLast/replaceAt reject bad input (ordering holds in release too)', () {
    final c = ChartController()..setBars(series(10));
    final n = c.bars.length;
    final lastTime = c.bars.last.time;

    // append with backward/duplicate time is dropped
    c.appendBar(bar(lastTime - 60000, 999));
    c.appendBar(bar(lastTime, 999));
    expect(c.bars.length, n);
    expect(isSorted(c.bars), isTrue);

    // updateLast with mismatched time is dropped
    c.updateLast(bar(lastTime - 60000, 999));
    expect(c.bars.last.close, isNot(999));

    // out-of-range / time-mismatched replaceAt is dropped
    c.replaceAt(999, bar(lastTime, 1));
    c.replaceAt(0, bar(lastTime, 1));
    expect(c.bars.length, n);
    expect(isSorted(c.bars), isTrue);

    // valid paths work as usual
    c.appendBar(bar(lastTime + 60000, 500));
    expect(c.bars.length, n + 1);
    c.updateLast(bar(lastTime + 60000, 501));
    expect(c.bars.last.close, 501);
    c.replaceAt(0, bar(c.bars.first.time, 42));
    expect(c.bars.first.close, 42);
    c.dispose();
  });

  test('applyTick three-way dispatch and unknown old timestamps', () {
    final c = ChartController()..setBars(series(10));
    final n = c.bars.length;
    final t = c.bars.last.time;

    c.applyTick(bar(t + 60000, 1)); // append
    expect(c.bars.length, n + 1);
    c.applyTick(bar(t + 60000, 2)); // updateLast
    expect(c.bars.length, n + 1);
    expect(c.bars.last.close, 2);
    c.applyTick(bar(c.bars[3].time, 3)); // replaceAt
    expect(c.bars[3].close, 3);
    c.applyTick(bar(t - 999999, 4)); // unknown old timestamp: silently dropped
    expect(c.bars.length, n + 1);
    expect(isSorted(c.bars), isTrue);
    c.dispose();
  });

  test('empty data / single bar / empty prepend do not crash', () {
    final c = ChartController(indicators: [Ma(), Vol()])..setBars([]);
    const size = Size(400, 300);
    final config = ChartConfig(
      theme: KLineTheme.light(),
      priceFormatter: (v) => v.toStringAsFixed(2),
      timeFormatter: (ms) => '$ms',
    );
    expect(c.resolveLayout(size, config).isEmpty, isTrue);
    c.prependHistory([]);
    expect(c.bars, isEmpty);

    // a tick on empty data follows setBars semantics
    c.applyTick(bar(1700000000000, 100));
    expect(c.bars.length, 1);
    expect(c.resolveLayout(size, config).isEmpty, isFalse);

    // a prepend on empty data is equivalent to setBars
    final c2 = ChartController()..setBars([]);
    c2.prependHistory(series(5));
    expect(c2.bars.length, 5);
    c.dispose();
    c2.dispose();
  });

  test('NaN/Inf bars are dropped (in release too, otherwise min/max is permanently polluted)', () {
    final c = ChartController()..setBars(series(10));
    final n = c.bars.length;
    final t = c.bars.last.time;

    // single-bar paths: all three entry points filter
    c.appendBar(Bar(time: t + 60000, open: 1, high: double.nan, low: 1, close: 1, vol: 1));
    c.appendBar(Bar(time: t + 60000, open: 1, high: 1, low: 1, close: double.infinity, vol: 1));
    expect(c.bars.length, n);
    c.updateLast(Bar(time: t, open: 1, high: 1, low: 1, close: 1, vol: double.nan));
    expect(c.bars.last.vol.isFinite, isTrue);
    c.replaceAt(
      0,
      Bar(time: c.bars.first.time, open: double.nan, high: 1, low: 1, close: 1, vol: 1),
    );
    expect(c.bars.first.open.isFinite, isTrue);

    // value range not polluted
    final mm = c.data.rangeOf(0, c.bars.length - 1);
    expect(mm.min.isFinite && mm.max.isFinite, isTrue);
    c.dispose();
  });

  test('batch paths filter NaN: a gap beats a blank screen', () {
    final good = series(10);
    final dirty = [
      ...good.sublist(0, 3),
      Bar(time: good[3].time, open: 1, high: double.nan, low: 1, close: 1, vol: 1),
      ...good.sublist(4),
    ];
    final c = ChartController()..setBars(dirty);
    expect(c.bars.length, 9, reason: 'bad bars removed, the rest kept');
    expect(c.bars.every((b) => b.high.isFinite), isTrue);
    final mm = c.data.rangeOf(0, c.bars.length - 1);
    expect(mm.max.isFinite, isTrue);

    // prepend filters too, and clean data shows no behavior difference from the extra copy path
    final older = [
      Bar(
        time: good[0].time - 120000,
        open: 1,
        high: 1,
        low: double.negativeInfinity,
        close: 1,
        vol: 1,
      ),
      Bar(time: good[0].time - 60000, open: 50, high: 51, low: 49, close: 50, vol: 1),
    ];
    c.prependHistory(older);
    expect(c.bars.length, 10);
    expect(c.bars.first.low, 49, reason: 'only the clean bar was inserted');
    c.dispose();
  });

  test('unordered/duplicate-timestamp batch input is cleaned to strictly increasing', () {
    final s = series(6);
    // unordered + one duplicate
    final c = ChartController()..setBars([s[3], s[1], s[5], s[1], s[0], s[2], s[4]]);
    expect(isSorted(c.bars), isTrue, reason: 'binary search / time mapping require ordering');
    expect(c.bars.length, 6, reason: 'duplicate timestamps merged into one bar');
    // binary search must still be accurate after reordering
    for (final b in s) {
      expect(c.bars[c.data.indexOfTime(b.time)].time, b.time);
    }
    c.dispose();
  });

  test('block cache matches brute-force scan after data changes (contiguous window cache)', () {
    final c = ChartController()..setBars(series(500));
    MinMax brute(int s, int e) {
      var lo = double.infinity, hi = double.negativeInfinity;
      for (var i = s; i <= e; i++) {
        if (c.bars[i].low < lo) lo = c.bars[i].low;
        if (c.bars[i].high > hi) hi = c.bars[i].high;
      }
      return MinMax(lo, hi);
    }

    // jump between windows (relocation path of the contiguous window cache)
    for (final (s, e) in [(400, 460), (10, 90), (200, 300), (0, 499), (450, 470)]) {
      final got = c.data.rangeOf(s, e);
      final want = brute(s, e);
      expect(got.min, want.min, reason: 'min[$s,$e]');
      expect(got.max, want.max, reason: 'max[$s,$e]');
    }
    // still consistent after changes
    c.updateLast(bar(c.bars.last.time, 1e4));
    expect(c.data.rangeOf(450, 499).max, brute(450, 499).max);
    c.prependHistory([for (var i = 20; i > 0; i--) bar(1700000000000 - i * 60000, 50)]);
    expect(c.data.rangeOf(0, 40).min, brute(0, 40).min);
    c.dispose();
  });
}
