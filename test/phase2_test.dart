import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klinex/klinex.dart';

List<Bar> genBars(int n, {int seed = 1, int t0 = 1700000000000}) {
  final rnd = math.Random(seed);
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
        vol: 100 + rnd.nextDouble() * 500,
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('time-based anchors stay put across prependHistory', () {
    final all = genBars(250, seed: 9);
    final c = ChartController()..setBars(all.sublist(50));
    final config = makeConfig();
    const size = Size(400, 400);

    final ctx1 = c.resolveLayout(size, config);
    final anchorTime = all[150].time;
    final x1 = ctx1.xOfTime(anchorTime);

    c.prependHistory(all.sublist(0, 50));
    final ctx2 = c.resolveLayout(size, config);
    expect(
      ctx2.xOfTime(anchorTime),
      closeTo(x1, 1e-6),
      reason: 'prepend anchoring + time anchors = drawings never shift',
    );
    c.dispose();
  });

  testWidgets('append never moves the x axis (except initial landing)', (tester) async {
    final controller = ChartController()..setBars(genBars(120));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            height: 400,
            // inside axis: plot area = full widget width, placement formula uses 400
            child: KChart(
              controller: controller,
              theme: KLineTheme.light(),
              yAxisPosition: YAxisPosition.inside,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    // default initial placement: newest bar at 2/3, not at the right edge
    final lastIndex = controller.bars.length - 1;
    expect(controller.viewport.indexToX(lastIndex), closeTo(400 * 2 / 3, 8));
    final rightBefore = controller.viewport.rightIndex;

    Bar next() {
      final last = controller.bars.last;
      return Bar(
        time: last.time + 60000,
        open: last.close,
        high: last.close + 1,
        low: last.close - 1,
        close: last.close,
        vol: 10,
      );
    }

    // blank on the right: new bars quietly fill it, viewport stays still
    controller.appendBar(next());
    await tester.pumpAndSettle();
    expect(controller.viewport.rightIndex, closeTo(rightBefore, 1e-6));

    // append after dragging to the right edge (blank used up): x-axis still unchanged,
    // new bars land off-screen for the user to scroll to
    final flushIndex = (controller.bars.length - 1).toDouble();
    controller.viewport.scroll((rightBefore - flushIndex) * controller.viewport.barWidth);
    expect(controller.viewport.rightIndex, closeTo(flushIndex, 1e-6));
    controller.appendBar(next());
    await tester.pumpAndSettle();
    expect(controller.viewport.rightIndex, closeTo(flushIndex, 1e-6));
    expect(controller.viewport.rightIndex, lessThan(controller.bars.length - 1));
    controller.dispose();
  });
}
