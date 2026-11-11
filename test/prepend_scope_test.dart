import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:klinex/klinex.dart';

/// `prependHistory` recomputes only the affected prefix (see [Indicator.prependSettleBars]),
/// shifting and reusing the other old values. The whole risk of this tradeoff is whether the
/// settle length is long enough: too short and old data keeps values inconsistent with a full
/// recompute, silently and invisibly on the chart, found only by cross-checking. So every
/// built-in indicator is cross-checked here per series and per index.

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

/// Monotonic uptrend: the worst shape for "ratchet/state machine" indicators,
/// never reverses, so old state carries through and the settle assumption breaks most easily.
List<Bar> monotone(int n) => [
  for (var i = 0; i < n; i++)
    Bar(
      time: 1700000000000 + i * 60000,
      open: 100.0 + i * 0.5,
      high: 100.8 + i * 0.5,
      low: 99.6 + i * 0.5,
      close: 100.5 + i * 0.5,
      vol: 1000,
    ),
];

List<Indicator> makeIndicators() => [
  Ma(),
  Ema(),
  Boll(),
  Macd(),
  Kdj(),
  Rsi(),
  Vol(),
  Wr(),
];

/// Cross-checks indicator output of two controllers per series and per index.
void expectSameIndicators(
  ChartController got,
  ChartController want,
  String scenario,
) {
  expect(got.bars.length, want.bars.length, reason: '$scenario: bar count');
  final a = got.indicators.list, b = want.indicators.list;
  for (var k = 0; k < a.length; k++) {
    final sa = got.storeOf(a[k]), sb = want.storeOf(b[k]);
    expect(sa.length, sb.length, reason: '$scenario: ${a[k].id} length');
    for (var i = 0; i < sa.length; i++) {
      final va = sa.valuesAt(i), vb = sb.valuesAt(i);
      for (final key in vb.keys) {
        final x = vb[key]!, y = va[key];
        if (y == null) continue;
        if (x.isNaN) {
          expect(y.isNaN, isTrue, reason: '$scenario: ${a[k].id}.$key[$i] should be NaN, got $y');
          continue;
        }
        expect(y.isNaN, isFalse, reason: '$scenario: ${a[k].id}.$key[$i] got NaN, expected $x');
        // relative tolerance: smoothing types "decay below precision" rather than match exactly
        final tol = math.max(1e-9, x.abs() * 1e-9);
        expect((y - x).abs() <= tol, isTrue, reason: '$scenario: ${a[k].id}.$key[$i] $x != $y');
      }
    }
  }
}

void runCase(String scenario, List<Bar> all, int keepTail) {
  final split = all.length - keepTail;

  final want = ChartController(indicators: makeIndicators())..setBars(all);

  final got = ChartController(indicators: makeIndicators())..setBars(all.sublist(split));
  got.prependHistory(all.sublist(0, split));

  expectSameIndicators(got, want, scenario);
  got.dispose();
  want.dispose();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('random market: scoped recompute == full recompute', () {
    runCase('randomWalk', randomWalk(4000), 2500);
  });

  test('monotonic trend (worst for ratchet/state machine): scoped recompute == full recompute', () {
    runCase('monotone', monotone(4000), 2500);
  });

  test('many small prepends (real paging through history)', () {
    final all = randomWalk(3000, seed: 21);
    final want = ChartController(indicators: makeIndicators())..setBars(all);
    final got = ChartController(indicators: makeIndicators())..setBars(all.sublist(2400));
    // 300 bars per page, 8 pages in a row
    for (var end = 2400; end > 0; end -= 300) {
      got.prependHistory(all.sublist(math.max(0, end - 300), end));
    }
    expectSameIndicators(got, want, 'paged');
    got.dispose();
    want.dispose();
  });

  test('falls back to full when the prepend covers all data, results still match', () {
    final all = randomWalk(600, seed: 3);
    runCase('bigPrepend', all, 60); // keep only a 60-bar tail, prefix far beyond settle length
  });

  test('safety valve: lying about settle length cannot cause wrong values (full fallback)', () {
    final all = randomWalk(1200, seed: 11);
    // cumulative never settles yet claims to settle in 8 bars; the cross-check must catch it
    // and fall back to full
    final liar = _Cumulative(settle: 8);
    expect(liar.prependSettleBars, 8);

    final want = ChartController(indicators: [_Cumulative()])..setBars(all);
    final got = ChartController(indicators: [liar])..setBars(all.sublist(900));
    got.prependHistory(all.sublist(0, 900));
    expectSameIndicators(got, want, 'liar');

    // really went full, not a lucky match: the first bar's cumulative value must include all
    // history
    final s = got.storeOf(liar);
    expect(
      s.value('sum', all.length - 1),
      closeTo(all.fold<double>(0, (a, b) => a + b.close), 1e-6),
    );
    got.dispose();
    want.dispose();
  });

  test('third-party indicators without prependSettleBars take full recompute', () {
    final all = randomWalk(800, seed: 5);
    final probe = _Cumulative();
    expect(probe.prependSettleBars, isNull, reason: 'must default to full to be safe');

    final want = ChartController(indicators: [_Cumulative()])..setBars(all);
    final got = ChartController(indicators: [probe])..setBars(all.sublist(500));
    got.prependHistory(all.sublist(0, 500));
    expectSameIndicators(got, want, 'thirdParty');
    got.dispose();
    want.dispose();
  });
}

/// Cumulative third-party indicator: each value sums all history, never settles; exactly the
/// kind that cannot declare prependSettleBars. Default full recompute keeps it correct.
class _Cumulative extends Indicator {
  /// Used by subclasses to lie about settle length, to verify the safety valve.
  final int? settle;

  _Cumulative({this.settle});

  @override
  int? get prependSettleBars => settle;

  @override
  String get id => 'cumsum';

  @override
  PanelRef get target => const PanelRef.own();

  @override
  void computeAll(List<Bar> bars, IndicatorStore store) {
    final s = store.series('sum');
    var acc = 0.0;
    for (var i = 0; i < bars.length; i++) {
      s[i] = acc += bars[i].close;
    }
  }

  @override
  void computeLast(List<Bar> bars, int index, IndicatorStore store) {
    final s = store.series('sum');
    s[index] = (index > 0 ? s[index - 1] : 0) + bars[index].close;
  }

  @override
  void paint(canvas, ctx, store) {}

  @override
  MinMax range(IndicatorStore store, int start, int end) =>
      seriesRange(store, const ['sum'], start, end);

  @override
  void legendInto(
    List<LegendItem> out,
    RenderContext ctx,
    IndicatorStore store,
    int index,
  ) {}
}
