// App smoke test: renders a KChart with data (the demo's core dependency) through the real
// layout and three-layer paint pipeline. Does not pump MyApp, which would start WS/network.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klinex/klinex.dart';

void main() {
  testWidgets('KChart renders bars and survives a pan', (tester) async {
    final controller = ChartController(indicators: [Ma(), Vol()]);
    controller.setBars([
      for (var i = 0; i < 120; i++)
        Bar(
          time: 1700000000000 + i * 60000,
          open: 100.0 + i % 7,
          high: 103.0 + i % 7,
          low: 98.0 + i % 5,
          close: 101.0 + (i * 3) % 6,
          vol: 500.0 + i,
        ),
    ]);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            height: 400,
            child: KChart(controller: controller, theme: KLineTheme.light()),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(KChart), findsOneWidget);

    // A pan does not crash and actually moves the viewport.
    final before = controller.viewport.rightIndex;
    await tester.drag(find.byType(KChart), const Offset(80, 0));
    await tester.pumpAndSettle();
    expect(controller.viewport.rightIndex, lessThan(before));

    controller.dispose();
  });
}
