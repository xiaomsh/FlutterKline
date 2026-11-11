import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klinex/klinex.dart';

List<Bar> _bars(int n) => [
  for (var i = 0; i < n; i++)
    Bar(
      time: 1700000000000 + i * 60000,
      open: 100.0 + i,
      high: 102.0 + i,
      low: 99.0 + i,
      close: 101.0 + i,
      vol: 10,
    ),
];

Widget _host(ChartController controller, {ValueChanged<Bar>? onBarTap}) => MaterialApp(
  home: Scaffold(
    body: Center(
      child: SizedBox(
        width: 400,
        height: 600,
        child: KChart(controller: controller, theme: KLineTheme.dark(), onBarTap: onBarTap),
      ),
    ),
  ),
);

void main() {
  testWidgets('tap on the chart reports the tapped bar', (tester) async {
    final controller = ChartController(indicators: [Vol()])..setBars(_bars(200));
    final tapped = <Bar>[];
    await tester.pumpWidget(_host(controller, onBarTap: tapped.add));
    await tester.pump();

    final rect = tester.getRect(find.byType(KChart));
    await tester.tapAt(rect.topLeft + const Offset(100, 100));
    await tester.pump();
    expect(tapped.length, 1);

    // tapping further right hits a later bar
    await tester.tapAt(rect.topLeft + const Offset(200, 100));
    await tester.pump();
    expect(tapped.length, 2);
    expect(tapped[1].time, greaterThan(tapped[0].time));

    // blank space right of the newest bar does not count as a bar hit
    final vp = controller.viewport;
    final lastX = vp.width - (vp.rightIndex - (vp.barCount - 1)) * vp.barWidth;
    await tester.tapAt(rect.topLeft + Offset(lastX + vp.barWidth * 3, 100));
    await tester.pump();
    expect(tapped.length, 2);
  });

  testWidgets('tap fires immediately, without waiting for the double-tap timeout', (tester) async {
    final controller = ChartController(indicators: [Vol()])..setBars(_bars(200));
    var count = 0;
    await tester.pumpWidget(_host(controller, onBarTap: (_) => count++));
    await tester.pump();

    final rect = tester.getRect(find.byType(KChart));
    await tester.tapAt(rect.topLeft + const Offset(100, 100));
    // pump one frame only, not the 300ms double-tap window
    await tester.pump(const Duration(milliseconds: 16));
    expect(count, 1);

    // two quick taps are two single taps, not swallowed as a double tap
    await tester.tapAt(rect.topLeft + const Offset(100, 100));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tapAt(rect.topLeft + const Offset(100, 100));
    await tester.pump(const Duration(milliseconds: 16));
    expect(count, 3);
  });

  testWidgets('tap without onBarTap does not throw', (tester) async {
    final controller = ChartController(indicators: [Vol()])..setBars(_bars(200));
    await tester.pumpWidget(_host(controller));
    await tester.pump();
    final rect = tester.getRect(find.byType(KChart));
    await tester.tapAt(rect.topLeft + const Offset(100, 100));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
