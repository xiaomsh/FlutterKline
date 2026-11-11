// Dragging a level line changes its price: a press on the line owns the whole gesture (chart
// does not pan); callback only if the price changed on release; dragging out of the main
// panel or an unchanged price cancels; yields while drawing is exclusive

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klinex/klinex.dart';

List<Bar> genBars(int n) {
  final rnd = math.Random(5);
  var c = 100.0;
  return [
    for (var i = 0; i < n; i++)
      Bar(
        time: 1700000000000 + i * 60000,
        open: c,
        high: (c = c + (rnd.nextDouble() - 0.5) * 2) + 1,
        low: c - 1,
        close: c,
        vol: 100,
      ),
  ];
}

final config = ChartConfig(
  theme: KLineTheme.light(),
  priceFormatter: (v) => v.toStringAsFixed(2),
  timeFormatter: (ms) => '$ms',
);

void main() {
  late ChartController controller;
  late LevelDragController drag;
  final drops = <(String, double)>[];

  Widget host({InteractionMode? mode}) => MaterialApp(
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: 400,
          height: 400,
          child: KChart(
            controller: controller,
            theme: KLineTheme.light(),
            levelDrag: drag,
            mode: mode,
            animateRange: false,
          ),
        ),
      ),
    ),
  );

  RenderContext ctx() => controller.resolveLayout(const Size(400, 400), config);

  /// Price at the middle of the main panel; hang a line there
  double midPrice() {
    final p = ctx().mainPanel;
    return p.valueOf(p.rect.center.dy);
  }

  Offset chartPoint(WidgetTester tester, double price) {
    final origin = tester.getTopLeft(find.byType(KChart));
    return origin + Offset(200, ctx().mainPanel.yOf(price));
  }

  setUp(() {
    controller = ChartController(indicators: [Ma()])..setBars(genBars(200));
    drops.clear();
    drag = LevelDragController(
      snap: (p) => (p * 100).roundToDouble() / 100,
      onDrop: (l, p) => drops.add((l.id, p)),
    );
  });

  testWidgets('press on line, drag up: new price reported, chart does not pan', (tester) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();
    final price = midPrice();
    drag.levels = [DraggableLevel(id: 'o1', price: price)];
    final right = controller.viewport.rightIndex;
    final start = chartPoint(tester, price);
    final g = await tester.startGesture(start);
    await g.moveBy(const Offset(-30, -40));
    await tester.pump();
    expect(drag.draggingId, 'o1');
    expect(drag.previewPrice, greaterThan(price));
    await g.up();
    await tester.pump();
    expect(drops.single.$1, 'o1');
    expect(drops.single.$2, greaterThan(price));
    // price already rounded
    expect(drops.single.$2 * 100, closeTo((drops.single.$2 * 100).roundToDouble(), 1e-6));
    expect(controller.viewport.rightIndex, right);
    expect(drag.isDragging, isFalse);
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('press elsewhere: chart pans as usual, level line untouched', (tester) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();
    final price = midPrice();
    drag.levels = [DraggableLevel(id: 'o1', price: price)];
    final right = controller.viewport.rightIndex;
    final away = chartPoint(tester, price) + const Offset(0, 60);
    await tester.dragFrom(away, const Offset(120, 0));
    await tester.pumpAndSettle();
    expect(drops, isEmpty);
    expect(controller.viewport.rightIndex, lessThan(right));
  });

  testWidgets('drag back to the original price or just tap: no callback', (tester) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();
    final price = (midPrice() * 100).roundToDouble() / 100;
    drag.levels = [DraggableLevel(id: 'o1', price: price)];
    final start = chartPoint(tester, price);
    final g = await tester.startGesture(start);
    await g.moveBy(const Offset(0, -40));
    await g.moveBy(const Offset(0, 40));
    await g.up();
    await tester.tapAt(start);
    await tester.pump();
    expect(drops, isEmpty);
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('drag out of main panel: line returns to its price, release cancels', (tester) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();
    final price = midPrice();
    drag.levels = [DraggableLevel(id: 'o1', price: price)];
    final g = await tester.startGesture(chartPoint(tester, price));
    await g.moveBy(const Offset(0, -400));
    await tester.pump();
    expect(drag.previewPrice, price);
    await g.up();
    await tester.pump();
    expect(drops, isEmpty);
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('the dragged line gets removed: this drag is void', (tester) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();
    final price = midPrice();
    drag.levels = [DraggableLevel(id: 'o1', price: price)];
    final g = await tester.startGesture(chartPoint(tester, price));
    await g.moveBy(const Offset(0, -40));
    drag.levels = const [];
    expect(drag.isDragging, isFalse);
    await g.up();
    await tester.pump();
    expect(drops, isEmpty);
    await tester.pump(const Duration(seconds: 1));
  });

  test('lines outside the scale cannot be hit; nearest wins when two are close', () {
    final c = ChartController(indicators: [Ma()])..setBars(genBars(200));
    c.viewport.attach(344);
    final rc = c.resolveLayout(const Size(400, 400), config);
    final p = rc.mainPanel;
    final mid = p.valueOf(p.rect.center.dy);
    final near = p.valueOf(p.rect.center.dy - 4);
    final d = LevelDragController()
      ..levels = [
        DraggableLevel(id: 'far', price: p.range.max + 100),
        DraggableLevel(id: 'a', price: mid),
        DraggableLevel(id: 'b', price: near),
      ];
    expect(d.hitTest(Offset(200, p.rect.center.dy - 3), rc)?.id, 'b');
    expect(d.hitTest(Offset(200, p.rect.center.dy + 1), rc)?.id, 'a');
    expect(d.hitTest(Offset(200, p.rect.top + 2), rc), isNull);
  });

  test('host button areas are not taken over', () {
    final c = ChartController(indicators: [Ma()])..setBars(genBars(200));
    c.viewport.attach(344);
    final rc = c.resolveLayout(const Size(400, 400), config);
    final p = rc.mainPanel;
    final mid = p.valueOf(p.rect.center.dy);
    final d = LevelDragController(passThrough: (pt, _) => pt.dx > 300)
      ..levels = [DraggableLevel(id: 'a', price: mid)];
    expect(d.hitTest(Offset(200, p.rect.center.dy), rc)?.id, 'a');
    expect(d.hitTest(Offset(320, p.rect.center.dy), rc), isNull);
  });

  testWidgets('drag a new line from a host button; release reports its id', (tester) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();
    final price = midPrice();
    final y = ctx().mainPanel.yOf(price);
    drag
      ..levels = [DraggableLevel(id: 'o1', price: price)]
      ..pick = (p, _) => (p.dx - 100).abs() < 10 && (p.dy - y).abs() < 10
          ? DraggableLevel(id: 'o1:tp', price: price)
          : null;
    final origin = tester.getTopLeft(find.byType(KChart));
    final g = await tester.startGesture(origin + Offset(100, y));
    await g.moveBy(const Offset(0, -50));
    await tester.pump();
    expect(drag.draggingId, 'o1:tp');
    // The pulled-out line is not in levels; a host refreshing levels must not treat it as "removed"
    drag.levels = [DraggableLevel(id: 'o1', price: price)];
    expect(drag.isDragging, isTrue);
    await g.up();
    await tester.pump();
    expect(drops.single.$1, 'o1:tp');
    expect(drops.single.$2, greaterThan(price));
    await tester.pump(const Duration(seconds: 1));
  });
}
