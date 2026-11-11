import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/animation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klinex/klinex.dart';
import 'package:klinex/src/render/grid_painter.dart';

List<Bar> _bars(int n, {double base = 100, double step = 1}) => [
  for (var i = 0; i < n; i++)
    Bar(
      time: 1700000000000 + i * 60000,
      open: base + (i % 7) * step,
      high: base + (i % 7 + 3) * step,
      low: base + (i % 5) * step,
      close: base + (i % 9) * step,
      vol: 10,
    ),
];

ChartConfig _cfg({YAxisPosition axis = YAxisPosition.inside}) => ChartConfig(
  theme: KLineTheme.light(),
  priceFormatter: (v) => v.toStringAsFixed(2),
  timeFormatter: (ms) => '$ms',
  yAxisPosition: axis,
);

class _TextProbe implements Canvas {
  final List<Offset> paragraphs = [];

  @override
  void drawParagraph(ui.Paragraph paragraph, Offset offset) => paragraphs.add(offset);

  @override
  void drawRawPoints(ui.PointMode mode, Float32List points, Paint paint) {}

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeVsync implements TickerProvider {
  @override
  Ticker createTicker(TickerCallback onTick) => Ticker(onTick);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('inside value labels are painted by the plot-label layer, above the series', () {
    final c = ChartController()..setBars(_bars(200));
    const size = Size(400, 400);
    final config = _cfg();
    final ctx = c.resolveLayout(size, config);
    bool inAxis(Offset o) => o.dy < ctx.timeAxisRect.top && o.dx > ctx.chartRect.right - 60;

    final grid = _TextProbe();
    GridPainter(c, config).paint(grid, size);
    expect(grid.paragraphs.where(inAxis), isEmpty);

    final labels = _TextProbe();
    GridPainter(c, config, plotLabels: true).paint(labels, size);
    expect(labels.paragraphs.where(inAxis), isNotEmpty);
    expect(labels.paragraphs.where((o) => o.dy >= ctx.timeAxisRect.top), isEmpty);

    // outside axis has no labels inside the plot area
    final outside = _TextProbe();
    GridPainter(c, _cfg(axis: YAxisPosition.outside), plotLabels: true).paint(outside, size);
    expect(outside.paragraphs, isEmpty);
    c.dispose();
  });

  test('a sub panel shorter than a label paints no value labels into its neighbour', () {
    final c = ChartController(indicators: [Macd()])..setBars(_bars(200));
    const size = Size(400, 400);
    final config = _cfg(axis: YAxisPosition.outside);
    var ctx = c.resolveLayout(size, config);
    final sub = ctx.panels.last;
    config.panelWeights[sub.id] = 0.02;
    config.bumpLayout();
    ctx = c.resolveLayout(size, config);
    final rect = ctx.panels.last.rect;
    expect(rect.height, lessThan(12));
    final probe = _TextProbe();
    GridPainter(c, config).paint(probe, size);
    final above = ctx.panels[ctx.panels.length - 2].rect;
    final leaking = probe.paragraphs.where(
      (o) => o.dx >= ctx.yAxisRect.left && o.dy > above.bottom - 4 && o.dy < rect.bottom,
    );
    expect(leaking, isEmpty);
    c.dispose();
  });

  test('rightBlankRatio 0 keeps the whole newest bar inside the plot', () {
    final c = ChartController()..setBars(_bars(300));
    final vp = c.viewport
      ..rightBlankRatio = 0
      ..initialRightBlankRatio = 0
      ..attach(400);
    vp.scrollToLatest();
    expect(vp.indexToX(299) + vp.barWidth / 2, lessThanOrEqualTo(400 + 1e-9));
    c.dispose();
  });

  testWidgets('the default price format keeps significant digits below 1', (tester) async {
    final semantics = tester.ensureSemantics();
    final c = ChartController()..setBars(_bars(100, base: 0.00001234, step: 0.0000001));
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox(
            width: 400,
            height: 400,
            child: KChart(controller: c, theme: KLineTheme.light()),
          ),
        ),
      ),
    );
    await tester.pump();
    final close = c.bars.last.close;
    expect(close, lessThan(0.0001));
    expect(find.bySemanticsLabel(RegExp(close.toStringAsFixed(8))), findsOneWidget);
    semantics.dispose();
    c.dispose();
  });

  test('trackpad pinch signals zoom around the cursor', () {
    final c = ChartController()..setBars(_bars(300));
    const size = Size(400, 400);
    final config = _cfg(axis: YAxisPosition.left);
    c.resolveLayout(size, config);
    final g = GestureCoordinator(
      controller: c,
      resolve: () => c.resolveLayout(size, config),
      fling: AnimationController.unbounded(vsync: _FakeVsync()),
    );
    const p = Offset(200, 200);
    final bw = c.viewport.barWidth;
    final before = g.resolve().indexAt(p.dx);
    g.onPointerScale(p, 1.5);
    expect(c.viewport.barWidth, closeTo(bw * 1.5, 1e-9));
    expect(g.resolve().indexAt(p.dx), closeTo(before, 0.5));
    c.dispose();
  });
}
