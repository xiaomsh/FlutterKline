import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klinex/klinex.dart';

/// Edge-case and robustness regressions: each covers a path that once could break silently.

const t0 = 1700000000000;

List<Bar> genBars(int n, {int stepMs = 60000, int seed = 7}) {
  final rnd = math.Random(seed);
  final bars = <Bar>[];
  var close = 100.0;
  for (var i = 0; i < n; i++) {
    final open = close;
    close = (open + (rnd.nextDouble() - 0.5) * 4).clamp(1.0, double.infinity);
    bars.add(
      Bar(
        time: t0 + i * stepMs,
        open: open,
        high: math.max(open, close) + 1,
        low: math.min(open, close) - 1,
        close: close,
        vol: 1000 + rnd.nextDouble() * 5000,
      ),
    );
  }
  return bars;
}

ChartConfig makeConfig() => ChartConfig(
  theme: KLineTheme.light(),
  priceFormatter: (v) => v.toStringAsFixed(2),
  timeFormatter: (ms) => '$ms',
);

/// Fake canvas that only cares "where text is drawn": all other draw calls are swallowed.
class _TextProbe implements Canvas {
  final List<Offset> textAt = [];

  @override
  void drawParagraph(ui.Paragraph paragraph, Offset offset) => textAt.add(offset);

  @override
  void noSuchMethod(Invocation invocation) {}
}

/// Custom indicator whose id is deliberately the built-in `rsi(14)`, so kind parses as 'rsi' and
/// hits the built-in registry's serializer, while the instance is not an Rsi at all.
class _FakeRsi extends LineIndicator {
  @override
  String get id => 'rsi(14)';

  @override
  PanelRef get target => const PanelRef.own();

  @override
  List<String> get seriesKeys => const ['rsi14'];

  @override
  List<String> get seriesLabels => const ['FAKE'];

  @override
  void computeAt(List<Bar> bars, int i, IndicatorStore store) {
    store.series('rsi14')[i] = bars[i].close;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('custom indicator with colliding kind falls back to sync, does not stall computing', () {
    // 2000 bars exceed the background threshold; asyncCompute must stay on to reach that path
    final c = ChartController(indicators: [_FakeRsi()]);
    c.setBars(genBars(2500));

    expect(
      c.computing.value,
      isFalse,
      reason: 'catch serialize failure before store writes, go all sync, else "computing" sticks',
    );
    final store = c.storeOf(c.indicators.list.single);
    expect(store.length, 2500);
    expect(store.value('rsi14', 2499), c.bars.last.close, reason: 'indicator must be computed');
    c.dispose();
  });

  test('duplicate indicator ids are merged, no twin instances sharing a store', () {
    final c = ChartController(
      indicators: [
        Ma(periods: [7]),
        Ma(periods: [7]),
      ],
    );
    expect(c.indicators.list.length, 1);

    c.indicators.add(Ma(periods: [7]));
    expect(c.indicators.list.length, 1, reason: 'same-id add replaces in place, no coexistence');

    c.indicators.setAll([Macd(), Macd(), Kdj()]);
    expect(c.indicators.list.map((e) => e.id).toList(), ['macd(12,26,9)', 'kdj(9,3,3)']);
    c.dispose();
  });

  test('default overlay is not added when the host provides one of the same kind', () {
    final mine = IndicatorLegendOverlay(hideOnCrosshair: true);
    final c = ChartController(overlays: [mine]);
    expect(c.overlays.whereType<IndicatorLegendOverlay>().length, 1);
    expect(identical(c.overlays.whereType<IndicatorLegendOverlay>().single, mine), isTrue);
    // the two default plugins not taken over by the host remain
    expect(c.overlays.whereType<CrosshairOverlay>().length, 1);
    expect(c.overlays.whereType<PriceLineOverlay>().length, 1);
    c.dispose();
  });

  test('snap: odd physical line widths snap to half pixels, even to whole pixels', () {
    final config = makeConfig()..devicePixelRatio = 2;
    // 1 logical px @dpr2 = 2 physical px (even), aligned to whole-pixel boundaries
    expect(config.snap(10.3, strokeWidth: 1), closeTo(10.0, 1e-9));
    // 0.5 logical px @dpr2 = 1 physical px (odd), lands on pixel centers
    expect(config.snap(10.3, strokeWidth: 0.5), closeTo(10.25, 1e-9));
    config.devicePixelRatio = 1;
    expect(config.snap(10.3, strokeWidth: 1), closeTo(10.5, 1e-9));
    expect(config.snap(10.3, strokeWidth: 2), closeTo(10.0, 1e-9));
  });

  test('dashed line drawing does not overrun on float boundaries (safe for any length)', () {
    final pool = PaintPool();
    final paint = Paint();
    final rec = ui.PictureRecorder();
    final canvas = Canvas(rec);
    for (var len = 0.0; len < 60; len += 0.13) {
      pool.drawDashedHLine(canvas, 5, 0, len, paint);
      pool.drawDashedVLine(canvas, 5, 0, len, paint);
    }
    rec.endRecording().dispose();
    pool.clear();
  });

  testWidgets('daily default time format has the year (MM-dd hides the year)', (tester) async {
    final c = ChartController()..setBars(genBars(60, stepMs: Duration.millisecondsPerDay));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            height: 400,
            child: KChart(
              tooltipStyle: KChartTooltipStyle.card,
              controller: c,
              theme: KLineTheme.light(),
              utcOffset: Duration.zero,
            ),
          ),
        ),
      ),
    );
    c.crosshair.value = CrosshairState(time: c.bars[0].time, position: const Offset(100, 100));
    await tester.pump();
    expect(find.text('2023-11-14'), findsWidgets);
    c.dispose();
  });

  testWidgets('linked mirror crosshair: vertical line only, no tooltip card', (tester) async {
    final c = ChartController()..setBars(genBars(60));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            height: 400,
            child: KChart(
              tooltipStyle: KChartTooltipStyle.card,
              controller: c,
              theme: KLineTheme.light(),
            ),
          ),
        ),
      ),
    );
    // this chart's own crosshair: card shown as usual
    c.crosshair.value = CrosshairState(time: c.bars[5].time, position: const Offset(120, 100));
    await tester.pump();
    expect(find.text('Time'), findsOneWidget);

    // mirrored from another chart: position is Offset.zero, the card would stick in the corner
    c.crosshair.value = CrosshairState(
      time: c.bars[5].time,
      position: Offset.zero,
      timeOnly: true,
    );
    await tester.pump();
    expect(find.text('Time'), findsNothing);
    c.dispose();
  });

  testWidgets('onLoadMore can retry after failing by scrolling away and back', (tester) async {
    final c = ChartController()..setBars(genBars(80));
    var calls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            height: 400,
            child: KChart(
              tooltipStyle: KChartTooltipStyle.card,
              controller: c,
              theme: KLineTheme.light(),
              // host request failed: no history fed, data length unchanged
              onLoadMore: () => calls++,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    Future<void> dragTo(double dx) async {
      for (var i = 0; i < 12; i++) {
        await tester.drag(find.byType(KChart), Offset(dx, 0), warnIfMissed: false);
        await tester.pumpAndSettle();
      }
    }

    await dragTo(200); // drag to the oldest edge
    expect(calls, 1);

    await dragTo(-200); // scroll back to latest
    await dragTo(200); // drag to the edge again
    expect(calls, 2, reason: 'must retry at the same data length, else one failure never loads');
    c.dispose();
  });

  testWidgets('at the oldest edge, live appends do not re-request a history page', (tester) async {
    final c = ChartController()..setBars(genBars(80));
    var calls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            height: 400,
            // host request in flight (not prepended yet); live bars keep arriving meanwhile
            child: KChart(
              tooltipStyle: KChartTooltipStyle.card,
              controller: c,
              theme: KLineTheme.light(),
              onLoadMore: () => calls++,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    for (var i = 0; i < 12; i++) {
      await tester.drag(find.byType(KChart), const Offset(200, 0), warnIfMissed: false);
      await tester.pumpAndSettle();
    }
    expect(calls, 1);

    // push 5 live bars: count changed but the oldest bar didn't, so no new request
    for (var i = 0; i < 5; i++) {
      final last = c.bars.last;
      c.appendBar(
        Bar(
          time: last.time + 60000,
          open: last.close,
          high: last.close + 1,
          low: last.close - 1,
          close: last.close,
          vol: 1000,
        ),
      );
      await tester.pump();
    }
    expect(calls, 1, reason: 'if append resets the dedupe latch, one page is fetched concurrently');
    c.dispose();
  });

  testWidgets('sync history from host does not recurse paging within one frame', (tester) async {
    // Zoomed out wider than the data (800 bars per screen > 60 bars): after every prepend lands
    // it is still at the oldest edge, exactly the chain-paging scenario.
    final c = ChartController()..setBars(genBars(60));
    c.viewport
      ..minBarWidth = 0.5
      ..maxBarWidth = 0.5
      ..clampBarWidthBounds();
    var calls = 0;
    var oldest = t0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            height: 400,
            child: KChart(
              tooltipStyle: KChartTooltipStyle.card,
              controller: c,
              theme: KLineTheme.light(),
              minBarWidth: 0.5,
              maxBarWidth: 0.5,
              // sync paging (local-cache host): feeds back at once, recursing into _maybeLoadMore
              onLoadMore: () {
                calls++;
                final older = [
                  for (var i = 50; i >= 1; i--)
                    Bar(
                      time: oldest - i * 60000,
                      open: 100,
                      high: 101,
                      low: 99,
                      close: 100,
                      vol: 1000,
                    ),
                ];
                oldest = older.first.time;
                c.prependHistory(older);
              },
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(calls, 0, reason: 'viewport not moved yet');

    c.viewport.scroll(1); // exactly one viewport change
    await tester.pump();
    // without a reentrancy guard: prepend, notify, prepend again, recursing until the screen fills
    expect(calls, 1, reason: 'one viewport change should load one page, got $calls');
    expect(c.bars.length, 110);
    c.dispose();
  });
}
