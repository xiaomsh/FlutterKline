import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klinex/klinex.dart';

import 'package:klinex_example/widget/back_to_latest_button.dart';

Bar _bar(int i) =>
    Bar(time: 1700000000000 + i * 60000, open: 100, high: 104, low: 98, close: 101, vol: 10);

void main() {
  testWidgets('after sliding back, new bars are followed again', (tester) async {
    final c = ChartController()..setBars([for (var i = 0; i < 300; i++) _bar(i)]);
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox(
            width: 400,
            height: 400,
            child: Stack(
              children: [
                KChart(
                  controller: c,
                  theme: KLineTheme.light(),
                  animateRange: false,
                  autoFollow: true,
                ),
                BackToLatestButton(controller: c),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    c.viewport.scroll(600);
    await tester.pumpAndSettle();
    expect(c.viewport.atLatest, isFalse);

    await tester.tap(find.byIcon(Icons.chevron_right));
    await tester.pumpAndSettle();
    expect(c.viewport.atLatest, isTrue);

    final r0 = c.viewport.rightIndex;
    c.appendBar(_bar(300));
    await tester.pumpAndSettle();
    expect(c.viewport.rightIndex, closeTo(r0 + 1, 1e-6));
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });

  testWidgets('tapping it mid-fling still lands on the newest bar and follows', (tester) async {
    final c = ChartController()..setBars([for (var i = 0; i < 300; i++) _bar(i)]);
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox(
            width: 400,
            height: 400,
            child: Stack(
              children: [
                KChart(controller: c, theme: KLineTheme.light(), autoFollow: true),
                BackToLatestButton(controller: c),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.fling(find.byType(KChart), const Offset(300, 0), 1500);
    await tester.pump(const Duration(milliseconds: 100));
    expect(c.viewport.atLatest, isFalse);

    await tester.tap(find.byIcon(Icons.chevron_right));
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(c.viewport.atLatest, isTrue);

    final r0 = c.viewport.rightIndex;
    c.appendBar(_bar(300));
    await tester.pump(const Duration(milliseconds: 500));
    expect(c.viewport.rightIndex, closeTo(r0 + 1, 1e-6));
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });
}
