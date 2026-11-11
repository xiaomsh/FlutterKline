import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klinex/klinex.dart';

List<Bar> _bars(int n) => [
  for (var i = 0; i < n; i++)
    Bar(
      time: 1700000000000 + i * 60000,
      open: 100.0 + (i % 7),
      high: 103.0 + (i % 7),
      low: 98.0 + (i % 7),
      close: 101.0 + (i % 7),
      vol: 10,
    ),
];

ChartConfig _config({YPanMode yPan = YPanMode.none, List<double> Function()? yFitValues}) =>
    ChartConfig(
      theme: KLineTheme.dark(),
      priceFormatter: (v) => v.toStringAsFixed(2),
      timeFormatter: (ms) => '$ms',
      yPan: yPan,
      yFitValues: yFitValues,
    );

const _size = Size(400, 600);

Widget _host(ChartController controller, YPanMode yPan) => MaterialApp(
  home: Scaffold(
    body: Center(
      child: SizedBox(
        width: 400,
        height: 600,
        child: KChart(controller: controller, theme: KLineTheme.dark(), yPan: yPan),
      ),
    ),
  ),
);

void main() {
  test('panY: dragging down shows higher prices, span unchanged, sub-panes unaffected', () {
    final c = ChartController(indicators: [Vol()])..setBars(_bars(200));
    final config = _config();
    final before = c.resolveLayout(_size, config);
    final main0 = before.mainPanel.range;
    final sub0 = before.panels[1].range;

    c.viewport.panY(before.mainPanel.rect.height / 4, before.mainPanel.rect.height);
    final after = c.resolveLayout(_size, config);
    final main1 = after.mainPanel.range;

    expect(main1.span, closeTo(main0.span, 1e-9));
    expect(main1.min - main0.min, closeTo(main0.span / 4, 1e-9), reason: 'drag h/4 = shift span/4');
    expect(after.panels[1].range.min, closeTo(sub0.min, 1e-9));
    expect(after.panels[1].range.max, closeTo(sub0.max, 1e-9));
    c.dispose();
  });

  test('panY: capped; double-tap reset and re-landing both clear it', () {
    final c = ChartController(indicators: [Vol()])..setBars(_bars(200));
    for (var i = 0; i < 100; i++) {
      c.viewport.panY(500, 300);
    }
    expect(c.viewport.yOffset, c.viewport.maxYOffset);
    for (var i = 0; i < 200; i++) {
      c.viewport.panY(-500, 300);
    }
    expect(c.viewport.yOffset, -c.viewport.maxYOffset);

    c.viewport.resetYScale();
    expect(c.viewport.yOffset, 0);

    c.viewport.panY(100, 300);
    c.viewport.zoomY(2);
    c.setBars(_bars(100));
    expect(c.viewport.yOffset, 0, reason: 'switching interval / trading pair is a re-landing');
    expect(c.viewport.yScale, 1.0);
    c.dispose();
  });

  test('panY combined with zoom: zoom then pan, pan amount uses the zoomed span', () {
    final c = ChartController(indicators: [Vol()])..setBars(_bars(200));
    final config = _config();
    c.viewport.zoomY(2);
    final zoomed = c.resolveLayout(_size, config).mainPanel.range;
    c.viewport.panY(100, 400);
    final panned = c.resolveLayout(_size, config).mainPanel.range;
    expect(panned.span, closeTo(zoomed.span, 1e-9));
    expect(panned.min - zoomed.min, closeTo(zoomed.span / 4, 1e-9));
    c.dispose();
  });

  test('yFitValues: zoom-out lower bound relaxes to just fit a distant order price', () {
    final c = ChartController(indicators: [Vol()])..setBars(_bars(200));
    // not given: lower bound is still 0.2
    c.resolveLayout(_size, _config());
    expect(c.viewport.minYScale, 0.2);

    final auto = c.resolveLayout(_size, _config()).mainPanel.range;
    final far = auto.max + auto.span * 20;
    final config = _config(yFitValues: () => [far]);
    c.resolveLayout(_size, config);
    expect(c.viewport.minYScale, lessThan(0.2));

    for (var i = 0; i < 60; i++) {
      c.viewport.zoomY(0.5);
      c.resolveLayout(_size, config);
    }
    final range = c.resolveLayout(_size, config).mainPanel.range;
    expect(range.max, greaterThanOrEqualTo(far), reason: 'fully zoomed out shows the order line');
    expect(range.max, lessThan(far + auto.span * 10), reason: 'but not unlimited zoom-out');
    c.dispose();
  });

  test('yFitValues: no relaxing when the price is already within the visible range', () {
    final c = ChartController(indicators: [Vol()])..setBars(_bars(200));
    final auto = c.resolveLayout(_size, _config()).mainPanel.range;
    c.resolveLayout(_size, _config(yFitValues: () => [(auto.min + auto.max) / 2]));
    expect(c.viewport.minYScale, 0.2);
    c.dispose();
  });

  testWidgets('gesture none: vertical drag never pans, chart area or axis strip', (tester) async {
    final c = ChartController(indicators: [Vol()])..setBars(_bars(200));
    await tester.pumpWidget(_host(c, YPanMode.none));
    await tester.pump();
    final rect = tester.getRect(find.byType(KChart));
    await tester.dragFrom(rect.topLeft + const Offset(150, 150), const Offset(0, 80));
    await tester.dragFrom(rect.topRight + const Offset(-10, 150), const Offset(0, 80));
    await tester.pumpAndSettle();
    expect(c.viewport.yOffset, 0);
  });

  testWidgets('gesture axis: only vertical drag on the axis strip pans', (tester) async {
    final c = ChartController(indicators: [Vol()])..setBars(_bars(200));
    await tester.pumpWidget(_host(c, YPanMode.axis));
    await tester.pump();
    final rect = tester.getRect(find.byType(KChart));

    await tester.dragFrom(rect.topLeft + const Offset(150, 150), const Offset(0, 80));
    await tester.pumpAndSettle();
    expect(c.viewport.yOffset, 0, reason: 'chart area yields to the outer scroll');

    await tester.dragFrom(rect.topRight + const Offset(-10, 150), const Offset(0, 80));
    await tester.pumpAndSettle();
    expect(c.viewport.yOffset, greaterThan(0));

    // double-tap reset
    await tester.tapAt(rect.topLeft + const Offset(150, 150));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tapAt(rect.topLeft + const Offset(150, 150));
    await tester.pumpAndSettle();
    expect(c.viewport.yOffset, 0);
  });

  testWidgets('gesture chart: vertical drag pans all of main pane, not sub-panes', (tester) async {
    final c = ChartController(indicators: [Vol()])..setBars(_bars(200));
    await tester.pumpWidget(_host(c, YPanMode.chart));
    await tester.pump();
    final rect = tester.getRect(find.byType(KChart));

    await tester.dragFrom(rect.topLeft + const Offset(150, 150), const Offset(0, -80));
    await tester.pumpAndSettle();
    expect(c.viewport.yOffset, lessThan(0), reason: 'dragging up shows lower prices');

    final before = c.viewport.yOffset;
    await tester.dragFrom(rect.bottomLeft + const Offset(150, -60), const Offset(0, -30));
    await tester.pumpAndSettle();
    expect(c.viewport.yOffset, before, reason: 'sub-pane area does not pan');
  });

  testWidgets('gesture chart: horizontal drag pans x as usual, y unchanged', (tester) async {
    final c = ChartController(indicators: [Vol()])..setBars(_bars(300));
    await tester.pumpWidget(_host(c, YPanMode.chart));
    await tester.pump();
    final rect = tester.getRect(find.byType(KChart));
    final right0 = c.viewport.rightIndex;
    await tester.dragFrom(rect.topLeft + const Offset(150, 150), const Offset(120, 0));
    await tester.pumpAndSettle();
    expect(c.viewport.rightIndex, lessThan(right0));
    expect(c.viewport.yOffset, 0);
  });
}
