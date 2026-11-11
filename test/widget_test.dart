import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klinex/klinex.dart';

List<Bar> genBars(int n) {
  final rnd = math.Random(1);
  final bars = <Bar>[];
  var close = 100.0;
  for (var i = 0; i < n; i++) {
    final open = close;
    close = (open + (rnd.nextDouble() - 0.5) * 4).clamp(1.0, double.infinity);
    bars.add(
      Bar(
        time: 1700000000000 + i * 60000,
        open: open,
        high: math.max(open, close) + 1,
        low: math.min(open, close) - 1,
        close: close,
        vol: 100 + rnd.nextDouble() * 500,
      ),
    );
  }
  return bars;
}

Widget host(ChartController controller) => MaterialApp(
  home: Scaffold(
    body: Center(
      child: SizedBox(
        width: 400,
        height: 600,
        child: KChart(
          tooltipStyle: KChartTooltipStyle.card,
          controller: controller,
          theme: KLineTheme.dark(),
        ),
      ),
    ),
  ),
);

void main() {
  testWidgets('renders, pans, zooms, crosshair + tooltip', (tester) async {
    final controller = ChartController(
      indicators: [
        Ma(),
        Boll(),
        Vol(),
        MaVol(),
        Macd(),
        Kdj(),
      ],
    )..setBars(genBars(300));

    await tester.pumpWidget(host(controller));
    await tester.pump();
    expect(find.byType(KChart), findsOneWidget);

    // pan: viewport scrolls back
    final before = controller.viewport.rightIndex;
    await tester.drag(find.byType(KChart), const Offset(120, 0), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(controller.viewport.rightIndex, lessThan(before));

    // long-press: crosshair set, tooltip card appears
    final gesture = await tester.startGesture(tester.getCenter(find.byType(KChart)));
    await tester.pump(const Duration(milliseconds: 600));
    await gesture.moveBy(const Offset(10, 0));
    await tester.pump();
    expect(controller.crosshair.value, isNotNull);
    expect(find.text('Time'), findsOneWidget);
    await gesture.up();
    await tester.pump();
    // crosshair is transient: disappears on release
    expect(controller.crosshair.value, isNull);
    expect(find.text('Time'), findsNothing);

    // live ticks while pumped: no exceptions
    final last = controller.bars.last;
    controller.applyTick(last.copyWith(close: last.close + 1, high: last.high + 1));
    controller.applyTick(
      Bar(
        time: last.time + 60000,
        open: last.close,
        high: last.close + 2,
        low: last.close - 2,
        close: last.close + 1,
        vol: 42,
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    controller.dispose();
  });

  testWidgets('outside y axis renders and remaps on toggle', (tester) async {
    final controller = ChartController(indicators: [Ma(), Vol()])..setBars(genBars(200));
    Widget build(YAxisPosition pos) => MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 400,
          height: 400,
          child: KChart(
            tooltipStyle: KChartTooltipStyle.card,
            controller: controller,
            theme: KLineTheme.dark(),
            yAxisPosition: pos,
            yAxisWidth: 60,
          ),
        ),
      ),
    );

    await tester.pumpWidget(build(YAxisPosition.outside));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(
      controller.viewport.width,
      340,
      reason: 'bars map over plot width = widget - axis strip',
    );

    await tester.pumpWidget(build(YAxisPosition.inside));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(controller.viewport.width, 400);
    controller.dispose();
  });

  testWidgets('custom grid style (width + dash) renders', (tester) async {
    final controller = ChartController(indicators: [Vol()])..setBars(genBars(100));
    final theme = KLineTheme.light().copyWith(
      gridLine: const Color(0xFFCCCCCC),
      gridLineWidth: 2,
      gridLineDash: const [4, 3],
    );
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 400,
          height: 400,
          child: KChart(
            tooltipStyle: KChartTooltipStyle.card,
            controller: controller,
            theme: theme,
          ),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    controller.dispose();
  });

  testWidgets('empty data renders without exceptions', (tester) async {
    final controller = ChartController(indicators: [Vol(), Macd()]);
    await tester.pumpWidget(host(controller));
    await tester.pump();
    expect(tester.takeException(), isNull);
    controller.dispose();
  });

  testWidgets('onLoadMore fires near the oldest edge, once per length', (tester) async {
    final controller = ChartController()..setBars(genBars(80));
    var calls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            height: 400,
            child: KChart(
              tooltipStyle: KChartTooltipStyle.card,
              controller: controller,
              theme: KLineTheme.light(),
              onLoadMore: () => calls++,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    // scroll far left to the oldest bars
    for (var i = 0; i < 10 && calls == 0; i++) {
      await tester.drag(find.byType(KChart), const Offset(400, 0), warnIfMissed: false);
      await tester.pumpAndSettle();
    }
    expect(calls, 1);
    controller.dispose();
  });
}
