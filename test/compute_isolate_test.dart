import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klinex/klinex.dart';

/// #3 Background-isolate indicator computation: large setBars / indicator switches are offloaded
/// to the background, and results must match main-isolate sync computation for every series and
/// index; realtime bars appended during computation must be caught up incrementally after the
/// results land. When isolates are unavailable in tests it falls back to sync; this test checks
/// correctness on both paths (without telling them apart: only that results are right, nothing
/// hangs, and the [computing] lifecycle is correct).

List<Bar> randomWalk(int n, {int seed = 7}) {
  final rnd = math.Random(seed);
  var close = 100.0;
  return [
    for (var i = 0; i < n; i++)
      () {
        final open = close;
        close = math.max(1.0, close + (rnd.nextDouble() - 0.5) * 4);
        final hi = math.max(open, close) + rnd.nextDouble() * 2;
        final lo = math.min(open, close) - rnd.nextDouble() * 2;
        return Bar(
          time: 1700000000000 + i * 60000,
          open: open,
          high: hi,
          low: math.max(0.5, lo),
          close: close,
          vol: 500 + rnd.nextDouble() * 1000,
        );
      }(),
  ];
}

Future<void> settle(ChartController c) async {
  for (var i = 0; i < 400 && c.computing.value; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}

/// NaN==NaN counts as equal (NaN on both sides of the warm-up segment is a correct match).
void expectClose(double? a, double? b, {double eps = 1e-9, String? reason}) {
  if (a != null && b != null && (a.isNaN || b.isNaN)) {
    expect(a.isNaN, b.isNaN, reason: reason);
    return;
  }
  expect(a, closeTo(b!, eps), reason: reason);
}

List<Indicator> probes() => [
  Macd(),
  Ma(periods: const [7, 25, 99]),
  Boll(),
  Kdj(),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('large setBars offloads compute and matches the sync reference', () async {
    final bars = randomWalk(3000);

    final ref = ChartController(indicators: probes())
      ..asyncCompute = false
      ..setBars(bars);
    expect(ref.computing.value, isFalse, reason: 'sync path never flips computing');

    final bg = ChartController(indicators: probes())..setBars(bars);
    expect(bg.computing.value, isTrue, reason: 'offloaded → computing while in flight');
    // during compute the offloaded stores paint as gaps (NaN), not stale values
    expect(bg.storeOf(Macd()).value('macd_dif', 100).isNaN, isTrue);

    await settle(bg);
    expect(bg.computing.value, isFalse, reason: 'result landed');

    for (final probe in probes()) {
      for (final i in [50, 500, 1500, 2999]) {
        final a = bg.storeOf(probe).valuesAt(i);
        final s = ref.storeOf(probe).valuesAt(i);
        expect(a.keys.toSet(), s.keys.toSet(), reason: '${probe.id} keys @ $i');
        for (final k in s.keys) {
          expectClose(a[k], s[k], reason: '${probe.id}.$k @ $i');
        }
      }
    }
    ref.dispose();
    bg.dispose();
  });

  test('ticks appended during an in-flight offload are caught up on the tail', () async {
    final bars = randomWalk(3000);
    final bg = ChartController(
      indicators: [
        Macd(),
        Ma(periods: const [7, 25]),
      ],
    )..setBars(bars);
    expect(bg.computing.value, isTrue);

    // append a live bar while the background compute is still running
    final last = bg.bars.last;
    final appended = Bar(
      time: last.time + 60000,
      open: last.close,
      high: last.close + 1,
      low: last.close - 1,
      close: last.close + 0.5,
      vol: 100,
    );
    bg.appendBar(appended);
    expect(bg.bars.length, 3001);

    await settle(bg);
    expect(bg.computing.value, isFalse);

    final ref =
        ChartController(
            indicators: [
              Macd(),
              Ma(periods: const [7, 25]),
            ],
          )
          ..asyncCompute = false
          ..setBars([...bars, appended]);
    for (final probe in [
      Macd(),
      Ma(periods: const [7, 25]),
    ]) {
      final a = bg.storeOf(probe).valuesAt(3000);
      final s = ref.storeOf(probe).valuesAt(3000);
      for (final k in s.keys) {
        expectClose(a[k], s[k], eps: 1e-6, reason: '${probe.id}.$k on the caught-up tail');
      }
    }
    ref.dispose();
    bg.dispose();
  });

  test('updateLast during an in-flight offload is reflected after settle', () async {
    final bars = randomWalk(3000);
    final bg = ChartController(indicators: [Macd()])..setBars(bars);
    expect(bg.computing.value, isTrue);

    // change the last bar's close while the background compute is in flight
    final last = bg.bars.last;
    final changed = last.copyWith(close: last.close + 5, high: last.high + 5);
    bg.updateLast(changed);

    await settle(bg);

    final ref = ChartController(indicators: [Macd()])
      ..asyncCompute = false
      ..setBars([...bars.sublist(0, 2999), changed]);
    final a = bg.storeOf(Macd()).valuesAt(2999);
    final s = ref.storeOf(Macd()).valuesAt(2999);
    for (final k in s.keys) {
      expectClose(a[k], s[k], eps: 1e-6, reason: 'macd.$k after updateLast during offload');
    }
    bg.dispose();
    ref.dispose();
  });

  test('dispose during an in-flight offload neither throws nor touches notifiers', () async {
    final bg = ChartController(indicators: probes())..setBars(randomWalk(3000));
    expect(bg.computing.value, isTrue);
    // Worker dispose makes the pending completer error, and _offload resumes after dispose:
    // all notifiers are released by then and any write would assert; returning silently is right
    bg.dispose();
    await Future<void>.delayed(const Duration(milliseconds: 100));
  });

  test('below threshold stays synchronous', () {
    final bg = ChartController(indicators: probes())..setBars(randomWalk(500));
    // 500 < 2000, so sync, values ready immediately, computing never set
    expect(bg.computing.value, isFalse);
    expect(bg.storeOf(Ma(periods: const [7, 25, 99])).value('ma7', 499).isNaN, isFalse);
    bg.dispose();
  });

  test('layout cached while computing is dropped once async results land', () async {
    final bars = randomWalk(3000);
    final config = ChartConfig(
      theme: KLineTheme.dark(),
      priceFormatter: (v) => v.toStringAsFixed(2),
      timeFormatter: (ms) => '$ms',
    );
    const size = Size(600, 400);
    final c = ChartController(indicators: [Macd()])..setBars(bars);
    c.resolveLayout(size, config);
    await settle(c);
    final landed = c.resolveLayout(size, config).panels[1].range;
    final ref = ChartController(indicators: [Macd()])
      ..asyncCompute = false
      ..setBars(bars);
    final want = ref.resolveLayout(size, config).panels[1].range;
    expect(landed.min, closeTo(want.min, 1e-9));
    expect(landed.max, closeTo(want.max, 1e-9));
    c.dispose();
    ref.dispose();
    config.dispose();
  });

  test('SecondaryAxis no longer forces the whole list onto the main isolate', () async {
    final bars = randomWalk(3000);
    final c = ChartController(indicators: [Macd(), SecondaryAxis(Rsi())])..setBars(bars);
    final ref = ChartController(indicators: [Macd(), SecondaryAxis(Rsi())])
      ..asyncCompute = false
      ..setBars(bars);
    await settle(c);
    final ind = c.indicators.list.last;
    final a = c.storeOf(ind), b = ref.storeOf(ref.indicators.list.last);
    for (final i in [20, 1500, 2999]) {
      expectClose(a.series('rsi14')[i], b.series('rsi14')[i], reason: '$i');
    }
    c.dispose();
    ref.dispose();
  });
}
