import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klinex/klinex.dart';
import 'package:klinex/src/widget/chart_keys.dart';

Bar _bar(int i, [double c = 100]) =>
    Bar(time: i * 60000, open: c, high: c + 1, low: c - 1, close: c, vol: 1);

List<Bar> _bars(int n, [int from = 0]) => [
  for (var i = from; i < from + n; i++) _bar(i, 100.0 + i % 9),
];

Widget _host(ChartController c, {double? maxBarWidth, bool showTooltip = true}) => MaterialApp(
  home: Center(
    child: SizedBox(
      width: 400,
      height: 300,
      child: KChart(
        controller: c,
        theme: KLineTheme.dark(),
        maxBarWidth: maxBarWidth,
        showTooltip: showTooltip,
      ),
    ),
  ),
);

class _FakeMa extends LineIndicator {
  _FakeMa({this.boom = false});
  final bool boom;

  @override
  String get id => 'ma(5)';

  @override
  PanelRef get target => PanelRef.main;

  @override
  List<String> get seriesKeys => const ['ma5'];

  @override
  List<String> get seriesLabels => const ['FAKE'];

  @override
  void computeAt(List<Bar> bars, int i, IndicatorStore store) {
    if (boom && i == bars.length - 1) throw StateError('boom');
    store.series('ma5')[i] = bars[i].close;
  }
}

void main() {
  testWidgets('a fling in flight does not drag a freshly loaded dataset away from latest', (
    tester,
  ) async {
    final c = ChartController()
      ..asyncCompute = false
      ..setBars(_bars(500));
    await tester.pumpWidget(_host(c));
    await tester.pump();
    await tester.fling(find.byType(KChart), const Offset(300, 0), 3000);
    await tester.pump(const Duration(milliseconds: 16));
    c.setBars(_bars(500, 10000));
    final landed = c.viewport.rightIndex;
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(const Duration(milliseconds: 300));
    expect(c.viewport.rightIndex, landed);
    expect(c.viewport.atLatest, isTrue);
    c.dispose();
  });

  test('End restores auto-follow, Home stops it', () {
    final c = ChartController()
      ..asyncCompute = false
      ..setBars(_bars(300));
    c.viewport
      ..autoFollow = true
      ..attach(400);
    c.viewport.scroll(2000);
    expect(c.viewport.atLatest, isFalse);
    handleChartKey(
      const KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.end,
        logicalKey: LogicalKeyboardKey.end,
        timeStamp: Duration.zero,
      ),
      c,
    );
    final r0 = c.viewport.rightIndex;
    c.appendBar(_bar(300));
    expect(c.viewport.rightIndex, r0 + 1, reason: 'following again after End');

    handleChartKey(
      const KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.home,
        logicalKey: LogicalKeyboardKey.home,
        timeStamp: Duration.zero,
      ),
      c,
    );
    final r1 = c.viewport.rightIndex;
    c.appendBar(_bar(301));
    expect(c.viewport.rightIndex, r1, reason: 'Home leaves the latest bar, so no follow');
    c.dispose();
  });

  test('writes after dispose are ignored and dispose is idempotent', () {
    final c = ChartController()
      ..asyncCompute = false
      ..setBars(_bars(50));
    c.dispose();
    c
      ..applyTick(_bar(50))
      ..appendBar(_bar(51))
      ..updateLast(_bar(51, 120))
      ..replaceAt(0, _bar(0, 90))
      ..prependHistory([_bar(-1)])
      ..setBars(_bars(10))
      ..maxBars = 20
      ..relayout();
    c.dispose();
  });

  testWidgets('swapping the controller carries maxBarWidth and drops the old crosshair', (
    tester,
  ) async {
    final a = ChartController()..setBars(_bars(100));
    final b = ChartController()..setBars(_bars(100));
    await tester.pumpWidget(_host(a, maxBarWidth: 20));
    await tester.pump();
    a.crosshair.value = CrosshairState(time: a.bars[50].time, position: const Offset(100, 100));
    await tester.pumpWidget(_host(b, maxBarWidth: 20));
    await tester.pump();
    expect(b.viewport.maxBarWidth, 20);
    expect(b.viewport.barWidth, lessThanOrEqualTo(20));
    expect(a.crosshair.value, isNull);
    await tester.pumpWidget(const SizedBox());
    a.dispose();
    b.dispose();
  });

  testWidgets('disposing the controller before the chart goes away does not throw', (
    tester,
  ) async {
    final c = ChartController()..setBars(_bars(100));
    await tester.pumpWidget(_host(c));
    await tester.pump();
    c.updateLast(_bar(99, 150));
    await tester.pump(const Duration(milliseconds: 50));
    c.dispose();
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.takeException(), isNull);
  });

  test('setAll keeps the last of duplicate ids, like add', () {
    final set = IndicatorSet()
      ..setAll([
        Ma(periods: const [5]),
        Ma(periods: const [5], lineWidth: 2),
      ]);
    expect(set.list, hasLength(1));
    expect((set.list.single as Ma).lineWidth, 2);
  });

  test('restoreState skips malformed entries instead of aborting half way', () {
    final c = ChartController()..asyncCompute = false;
    c.restoreState({
      'version': 1,
      'indicators': [
        {
          'kind': 'ma',
          'periods': [7.0],
        },
        {
          'kind': 'ma',
          'periods': [0],
        },
        null,
        {'kind': 1},
        {'kind': 'rsi'},
      ],
      'barWidth': '8',
      'yScale': 'x',
    });
    expect([for (final i in c.indicators.list) i.id], ['ma(7)', 'rsi(14)']);
    c.dispose();
  });

  test('saveState survives a custom indicator whose id looks built-in', () {
    final c = ChartController(indicators: [_FakeMa(), Rsi()])..asyncCompute = false;
    final state = c.saveState();
    expect([for (final i in state['indicators'] as List) (i as Map)['kind']], ['rsi']);
    c.dispose();
  });

  test('a rethrowing onIndicatorError does not stop the other indicators', () {
    final c = ChartController(indicators: [_FakeMa(boom: true), Rsi()])
      ..asyncCompute = false
      ..onIndicatorError = ((i, e, s) => throw e)
      ..setBars(_bars(40));
    c.appendBar(_bar(40, 120));
    final rsi = c.storeOf(c.indicators.list.last).series('rsi14');
    expect(rsi[40].isNaN, isFalse);
    c.dispose();
    expect(c.lockYRange(), isFalse);
    c.unlockYRange();
  });

  test('vertical state restored before data applies when bars arrive one by one', () {
    final c = ChartController()..asyncCompute = false;
    c.restoreState({
      'version': 1,
      'lockedY': [100, 200],
    });
    c.appendBar(_bar(0));
    expect(c.viewport.lockedYRange?.min, 100);
    c.setBars(_bars(10, 500));
    expect(c.viewport.lockedYRange, isNull);
    c.dispose();
  });
}
