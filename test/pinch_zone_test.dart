import 'dart:math' as math;

import 'package:flutter/gestures.dart';
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

/// Two-finger pinch through the real GestureDetector pipeline. Fingers start diagonal
/// so both horizontal and vertical initial spans are nonzero (axis scale needs them).
Future<void> pinch(
  WidgetTester tester, {
  required Offset center,
  required Offset spread, // movement vector of each finger (opposite directions)
}) async {
  const half = Offset(14, 20);
  final g1 = await tester.createGesture();
  final g2 = await tester.createGesture();
  await g1.down(center - half);
  await g2.down(center + half);
  await tester.pump(const Duration(milliseconds: 50));
  for (var i = 1; i <= 5; i++) {
    await g1.moveBy(-spread / 5);
    await g2.moveBy(spread / 5);
    await tester.pump(const Duration(milliseconds: 16));
  }
  await g1.up();
  await g2.up();
  await tester.pump();
}

void main() {
  testWidgets('pinch splits axes; axis drag no longer zooms; wheel keeps zones', (tester) async {
    final controller = ChartController()..setBars(genBars(300));
    await tester.pumpWidget(
      MaterialApp(
        home: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 400,
            height: 400,
            child: KChart(
              controller: controller,
              theme: KLineTheme.light(),
              yAxisPosition: YAxisPosition.outside,
              yAxisWidth: 56,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    // plot area 0..344, axis strip 344..400

    // single-finger drag on the axis strip: no longer zooms (passes through to outer when nested)
    final bw0 = controller.viewport.barWidth;
    final y00 = controller.viewport.yScale;
    final drag = await tester.createGesture();
    await drag.down(const Offset(372, 260));
    await tester.pump(const Duration(milliseconds: 50));
    for (var i = 0; i < 5; i++) {
      await drag.moveBy(const Offset(0, -24));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await drag.up();
    await tester.pump();
    expect(controller.viewport.yScale, y00, reason: 'single-finger axis drag removed');
    expect(controller.viewport.barWidth, bw0);

    // pinch in plot area (vertical spread too): only x zooms, y unchanged
    await pinch(tester, center: const Offset(180, 200), spread: const Offset(0, 120));
    expect(
      controller.viewport.barWidth,
      greaterThan(bw0),
      reason: 'plot pinch zooms x regardless of direction',
    );
    expect(controller.viewport.yScale, y00);

    // pinch in axis area: only y zooms, x no longer changes
    final bw1 = controller.viewport.barWidth;
    await pinch(tester, center: const Offset(372, 200), spread: const Offset(0, 100));
    expect(controller.viewport.yScale, greaterThan(1.0), reason: 'axis-strip pinch zooms y');
    expect(controller.viewport.barWidth, bw1);

    // wheel zones unchanged: wheel on the axis strip zooms y
    controller.viewport.resetYScale();
    final tp = TestPointer(99, PointerDeviceKind.mouse);
    tp.hover(const Offset(372, 200));
    await tester.sendEventToBinding(tp.scroll(const Offset(0, -120)));
    await tester.pump();
    expect(controller.viewport.yScale, greaterThan(1.0));

    controller.dispose();
  });

  testWidgets('inside a scroll view: vertical drags scroll the page, horizontal pans the chart', (
    tester,
  ) async {
    final controller = ChartController()..setBars(genBars(300));
    final scroll = ScrollController();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            controller: scroll,
            child: Column(
              children: [
                const SizedBox(height: 100),
                SizedBox(
                  width: 400,
                  height: 400,
                  child: KChart(
                    controller: controller,
                    theme: KLineTheme.light(),
                  ),
                ),
                const SizedBox(height: 1200),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    // vertical drag on chart: outer page scrolls, chart stays
    final right0 = controller.viewport.rightIndex;
    final yScale0 = controller.viewport.yScale;
    await tester.drag(find.byType(KChart), const Offset(0, -150));
    await tester.pumpAndSettle();
    expect(
      scroll.offset,
      greaterThan(0),
      reason: 'vertical drag on the chart must scroll the outer page',
    );
    expect(controller.viewport.yScale, yScale0);
    expect(controller.viewport.rightIndex, right0);

    // horizontal drag on chart: chart pans, page does not scroll
    final scroll0 = scroll.offset;
    await tester.drag(find.byType(KChart), const Offset(-80, 0));
    await tester.pumpAndSettle();
    expect(controller.viewport.rightIndex, isNot(right0), reason: 'horizontal drag pans the chart');
    expect(scroll.offset, scroll0);

    // two-finger pinch (EagerScale second finger claims): chart zooms, page does not scroll
    final bw1 = controller.viewport.barWidth;
    final scroll1 = scroll.offset;
    await pinch(
      tester,
      center: tester.getCenter(find.byType(KChart)),
      spread: const Offset(120, 0),
    );
    expect(
      controller.viewport.barWidth,
      greaterThan(bw1),
      reason: 'pinch inside a scroll view zooms the chart',
    );
    expect(scroll.offset, scroll1, reason: 'page must not scroll');

    controller.dispose();
    scroll.dispose();
  });
}
