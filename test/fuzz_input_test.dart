import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klinex/klinex.dart';

/// Edge-input fuzz: unsorted, duplicate timestamps, NaN / Inf, inverted high/low, negative
/// volume, empty data, single bar,
/// randomly interleaving setBars / applyTick / prependHistory / appendBar / updateLast.
/// Asserts only two things: no throw; stored data always meets the input contract.
/// Fixed seed, so failures reproduce.

const t0 = 1700000000000;
const step = 60000;

double _price(math.Random r) {
  final roll = r.nextInt(40);
  if (roll == 0) return double.nan;
  if (roll == 1) return double.infinity;
  if (roll == 2) return double.negativeInfinity;
  return 50 + r.nextDouble() * 100;
}

Bar _bar(math.Random r, int index) {
  final open = _price(r), close = _price(r);
  // high/low sometimes deliberately inverted, sometimes not covering open/close
  final high = r.nextInt(10) == 0
      ? math.min(open, close) - 5
      : math.max(open, close) + r.nextDouble();
  final low = r.nextInt(10) == 0
      ? math.max(open, close) + 5
      : math.min(open, close) - r.nextDouble();
  final vol = r.nextInt(15) == 0 ? -r.nextDouble() * 10 : r.nextDouble() * 1000;
  return Bar(time: t0 + index * step, open: open, high: high, low: low, close: close, vol: vol);
}

/// Bars with timestamps around [from, from + n): sometimes shuffled, sometimes duplicated
List<Bar> _batch(math.Random r, int from, int n) {
  final out = [for (var i = 0; i < n; i++) _bar(r, from + i)];
  if (out.length > 1 && r.nextBool()) out.shuffle(r);
  if (out.isNotEmpty && r.nextInt(3) == 0) out.add(out[r.nextInt(out.length)]);
  return out;
}

void _expectContract(ChartController c, String where) {
  final bars = c.bars;
  for (var i = 0; i < bars.length; i++) {
    final b = bars[i];
    final at = '$where @ $i';
    expect(
      b.open.isFinite && b.high.isFinite && b.low.isFinite && b.close.isFinite,
      isTrue,
      reason: '$at: non-finite price',
    );
    expect(b.vol.isFinite && b.vol >= 0, isTrue, reason: '$at: bad volume ${b.vol}');
    expect(b.high >= math.max(b.open, b.close), isTrue, reason: '$at: high below body');
    expect(b.low <= math.min(b.open, b.close), isTrue, reason: '$at: low above body');
    if (i > 0) expect(b.time > bars[i - 1].time, isTrue, reason: '$at: time not increasing');
  }
}

List<Indicator> _indicators() => [
  Ma(periods: const [5, 20]),
  Ema(periods: const [12]),
  Boll(),
  Macd(),
  Kdj(),
  Rsi(),
  Wr(),
  Vol(),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // Sanitizing logs in debug; hundreds of such lines in fuzz are pointless
  final print = debugPrint;
  setUp(() => debugPrint = (String? message, {int? wrapWidth}) {});
  tearDown(() => debugPrint = print);

  for (final seed in [1, 2, 3, 4, 5, 6, 7, 8]) {
    test('random mutation sequence keeps the input contract (seed $seed)', () {
      final r = math.Random(seed);
      final c = ChartController(indicators: _indicators())..asyncCompute = false;
      final config = ChartConfig(
        theme: KLineTheme.light(),
        priceFormatter: (v) => v.toStringAsFixed(2),
        timeFormatter: (ms) => '$ms',
      );
      var head = 1000; // next prepend goes back from here
      var tail = 1000; // index of the next new bar
      var populated = 0;

      for (var round = 0; round < 120; round++) {
        final op = r.nextInt(8);
        final String where;
        switch (op) {
          case 0:
            final n = [0, 1, 2, 50, 300][r.nextInt(5)];
            head = tail = 1000;
            c.setBars(_batch(r, tail, n));
            tail += n;
            where = 'setBars($n)';
          case 1 || 2:
            // a new bar, update the last one, or backfill an earlier one
            final kind = r.nextInt(3);
            final index = kind == 0 ? tail++ : (kind == 1 ? tail - 1 : tail - 1 - r.nextInt(5));
            c.applyTick(_bar(r, index));
            where = 'applyTick($index)';
          case 3:
            final n = 1 + r.nextInt(40);
            head -= n;
            // occasionally overlaps existing data
            final overlap = r.nextInt(4) == 0 ? 3 : 0;
            c.prependHistory(_batch(r, head, n + overlap));
            where = 'prependHistory($n)';
          case 4:
            c.appendBar(_bar(r, r.nextInt(5) == 0 ? tail - 2 : tail++));
            where = 'appendBar';
          case 5:
            if (c.bars.isEmpty) continue;
            c.updateLast(_bar(r, tail - 1));
            where = 'updateLast';
          case 6:
            c.maxBars = r.nextBool() ? null : 50 + r.nextInt(200);
            where = 'maxBars=${c.maxBars}';
          default:
            c.setBars(const []);
            head = tail = 1000;
            where = 'setBars(empty)';
        }
        _expectContract(c, 'seed $seed round $round $where');
        // layout and indicator lookups must also run
        final ctx = c.resolveLayout(const Size(400, 300), config);
        if (!ctx.isEmpty) c.indicatorValuesAt(ctx.end);
        if (c.bars.length > 20) populated++;
      }
      expect(populated, greaterThan(30), reason: 'fuzz must spend time on real data');
      c.dispose();
    });
  }
}
