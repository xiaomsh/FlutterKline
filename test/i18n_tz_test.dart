import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klinex/klinex.dart';

// 1700000000000 ms = 2023-11-14 22:13:20 UTC，a fixed reference so the
// expected label strings below are deterministic regardless of host tz.
const t0 = 1700000000000;

List<Bar> genBars(int n) {
  final rnd = math.Random(1);
  final bars = <Bar>[];
  var close = 100.0;
  for (var i = 0; i < n; i++) {
    final open = close;
    close = (open + (rnd.nextDouble() - 0.5) * 4).clamp(1.0, double.infinity);
    bars.add(
      Bar(
        time: t0 + i * 60000,
        open: open,
        high: math.max(open, close) + 1,
        low: math.min(open, close) - 1,
        close: close,
        vol: 100,
      ),
    );
  }
  return bars;
}

Widget host(
  ChartController c, {
  Duration? utcOffset,
  KChartLabels labels = const KChartLabels(),
  KChartTooltipStyle style = KChartTooltipStyle.card,
}) => MaterialApp(
  home: Scaffold(
    body: SizedBox(
      width: 400,
      height: 400,
      child: KChart(
        controller: c,
        theme: KLineTheme.light(),
        utcOffset: utcOffset,
        labels: labels,
        tooltipStyle: style,
      ),
    ),
  ),
);

void main() {
  testWidgets('utcOffset shifts every rendered time; switching repaints', (tester) async {
    final controller = ChartController()..setBars(genBars(50));
    await tester.pumpWidget(host(controller, utcOffset: Duration.zero));
    // select bar 0 (known timestamp), tooltip shows its time
    controller.crosshair.value = CrosshairState(
      time: controller.bars[0].time,
      position: const Offset(100, 100),
    );
    await tester.pump();
    expect(find.text('11-14 22:13'), findsWidgets); // UTC

    // switch tz on the fly，same widget tree, labels must change
    await tester.pumpWidget(host(controller, utcOffset: const Duration(hours: 8)));
    await tester.pump();
    expect(find.text('11-15 06:13'), findsWidgets); // UTC+8 crosses midnight
    expect(find.text('11-14 22:13'), findsNothing);

    await tester.pumpWidget(host(controller, utcOffset: const Duration(hours: -5)));
    await tester.pump();
    expect(find.text('11-14 17:13'), findsWidgets); // UTC-5
    controller.dispose();
  });

  testWidgets('tooltip labels default to English and the host can replace them', (tester) async {
    final controller = ChartController()..setBars(genBars(50));
    await tester.pumpWidget(host(controller, utcOffset: Duration.zero));
    controller.crosshair.value = CrosshairState(
      time: controller.bars[0].time,
      position: const Offset(100, 100),
    );
    await tester.pump();
    expect(find.text('Time'), findsOneWidget);
    expect(find.text('Vol'), findsOneWidget);

    const zh = KChartLabels(time: '时间', volume: '量');
    await tester.pumpWidget(host(controller, utcOffset: Duration.zero, labels: zh));
    await tester.pump();
    expect(find.text('时间'), findsOneWidget);
    expect(find.text('量'), findsOneWidget);
    expect(find.text('Time'), findsNothing);
    controller.dispose();
  });

  testWidgets('custom timeFormatter wins over utcOffset', (tester) async {
    final controller = ChartController()..setBars(genBars(50));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            height: 400,
            child: KChart(
              controller: controller,
              theme: KLineTheme.light(),
              utcOffset: const Duration(hours: 8), // must be ignored
              timeFormatter: (ms) => 'T${(ms - t0) ~/ 60000}',
              tooltipStyle: KChartTooltipStyle.card,
            ),
          ),
        ),
      ),
    );
    controller.crosshair.value = CrosshairState(
      time: controller.bars[3].time,
      position: const Offset(100, 100),
    );
    await tester.pump();
    expect(find.text('T3'), findsWidgets);
    controller.dispose();
  });

  testWidgets('default inline tooltip sits top-left and pushes the main legend down', (
    tester,
  ) async {
    final controller = ChartController(indicators: [Ma()])
      ..asyncCompute = false
      ..setBars(genBars(50));
    await tester.pumpWidget(host(controller, style: KChartTooltipStyle.inline));
    controller.crosshair.value = CrosshairState(
      time: controller.bars[10].time,
      position: const Offset(300, 100),
    );
    await tester.pump();
    await tester.pump();
    final row = find.byWidgetPredicate(
      (w) => w is RichText && w.text.toPlainText().startsWith('O '),
    );
    expect(row, findsOneWidget);
    expect(controller.tooltipInset.value, greaterThan(10));
    final pos = tester.getTopLeft(row);
    expect(pos.dx, lessThan(20));
    controller.crosshair.value = CrosshairState(
      time: controller.bars[40].time,
      position: const Offset(50, 100),
    );
    await tester.pump();
    expect(tester.getTopLeft(row), pos);
    controller.dispose();
  });
}
