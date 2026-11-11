import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klinex/klinex.dart';
import 'package:klinex/src/render/grid_painter.dart';

/// Sub-pane height is kept after changing params; price axis on the left or both sides.

List<Bar> walk(int n, {int seed = 5}) {
  final rnd = math.Random(seed);
  var close = 100.0;
  return [
    for (var i = 0; i < n; i++)
      () {
        final open = close;
        close = math.max(1.0, close + (rnd.nextDouble() - 0.5) * 4);
        return Bar(
          time: 1700000000000 + i * 60000,
          open: open,
          high: math.max(open, close) + 1,
          low: math.max(0.5, math.min(open, close) - 1),
          close: close,
          vol: 100,
        );
      }(),
  ];
}

ChartConfig cfg({YAxisPosition axis = YAxisPosition.inside}) => ChartConfig(
  theme: KLineTheme.light(),
  priceFormatter: (v) => v.toStringAsFixed(2),
  timeFormatter: (ms) => '$ms',
  yAxisPosition: axis,
  yAxisWidth: 50,
);

const size = Size(400, 400);

class _TextProbe implements Canvas {
  final List<Offset> paragraphs = [];

  @override
  void drawParagraph(ui.Paragraph paragraph, Offset offset) => paragraphs.add(offset);

  @override
  void drawRawPoints(ui.PointMode mode, Float32List points, Paint paint) {}

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

double heightOf(RenderContext ctx, String id) =>
    ctx.panels.firstWhere((p) => p.id == id).rect.height;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('own-panel weight survives a parameter change', () {
    test('weight follows the replacement of the same kind', () {
      final c = ChartController(indicators: [Macd(), Rsi()])..setBars(walk(200));
      final config = cfg();
      config.panelWeights['own:rsi(14)'] = 2.5;
      final before = heightOf(c.resolveLayout(size, config), 'own:rsi(14)');

      c.indicators.setAll([Macd(), Rsi(period: 6)]);
      final ctx = c.resolveLayout(size, config);
      expect(config.panelWeights.containsKey('own:rsi(14)'), isFalse);
      expect(config.panelWeights['own:rsi(6)'], 2.5);
      expect(heightOf(ctx, 'own:rsi(6)'), closeTo(before, 1e-9));
      c.dispose();
    });

    test('two instances of a kind keep their own weights', () {
      final c = ChartController(indicators: [Rsi(period: 6), Rsi(period: 24)])..setBars(walk(200));
      final config = cfg();
      config.panelWeights
        ..['own:rsi(6)'] = 2
        ..['own:rsi(24)'] = 0.5;
      c.resolveLayout(size, config);

      c.indicators.setAll([Rsi(period: 6), Rsi(period: 30)]);
      c.resolveLayout(size, config);
      expect(config.panelWeights['own:rsi(6)'], 2, reason: 'untouched panel keeps its weight');
      expect(config.panelWeights['own:rsi(30)'], 0.5);
      c.dispose();
    });

    test('a different kind does not inherit the weight', () {
      final c = ChartController(indicators: [Rsi()])..setBars(walk(200));
      final config = cfg();
      config.panelWeights['own:rsi(14)'] = 3;
      c.resolveLayout(size, config);
      c.indicators.setAll([Macd()]);
      c.resolveLayout(size, config);
      expect(config.panelWeights.containsKey(Macd().target.keyFor(Macd())), isFalse);
      c.dispose();
    });
  });

  group('y axis on the left / both sides', () {
    test('plot area and axis strips', () {
      final c = ChartController()..setBars(walk(200));
      for (final (axis, left, right) in [
        (YAxisPosition.inside, 0.0, 0.0),
        (YAxisPosition.outside, 0.0, 50.0),
        (YAxisPosition.left, 50.0, 0.0),
        (YAxisPosition.both, 50.0, 50.0),
      ]) {
        final ctx = c.resolveLayout(size, cfg(axis: axis));
        expect(ctx.chartRect.left, left, reason: '$axis');
        expect(ctx.chartRect.right, size.width - right, reason: '$axis');
        expect(ctx.leftAxisRect.width, left, reason: '$axis');
        expect(ctx.yAxisRect.width, right, reason: '$axis');
        expect(ctx.timeAxisRect.left, left, reason: '$axis');
        for (final p in ctx.panels) {
          expect(p.rect.left, left, reason: '$axis ${p.id}');
          expect(p.rect.right, ctx.chartRect.right, reason: '$axis ${p.id}');
        }
        // The rightmost bar lands inside the plot area
        final xLast = ctx.xOf(c.bars.length - 1);
        expect(xLast, inInclusiveRange(ctx.chartRect.left, ctx.chartRect.right), reason: '$axis');
      }
      c.dispose();
    });

    test('value labels land in each axis strip', () {
      final c = ChartController()..setBars(walk(200));
      List<Offset> labels(YAxisPosition axis) {
        final probe = _TextProbe();
        final config = cfg(axis: axis);
        GridPainter(c, config).paint(probe, size);
        final ctx = c.resolveLayout(size, config);
        // Keep only scale labels: time labels live in the time axis
        return probe.paragraphs.where((o) => o.dy < ctx.timeAxisRect.top).toList();
      }

      final right = labels(YAxisPosition.outside);
      final left = labels(YAxisPosition.left);
      final both = labels(YAxisPosition.both);
      expect(right.every((o) => o.dx >= size.width - 50), isTrue);
      expect(left.every((o) => o.dx < 50), isTrue);
      expect(both.length, right.length + left.length);
      c.dispose();
    });

    testWidgets('KChart lays out with the axis on the left and on both sides', (tester) async {
      for (final axis in [YAxisPosition.left, YAxisPosition.both]) {
        final c = ChartController()..setBars(walk(200));
        await tester.pumpWidget(
          MaterialApp(
            home: Center(
              child: SizedBox(
                width: 400,
                height: 300,
                child: KChart(controller: c, theme: KLineTheme.dark(), yAxisPosition: axis),
              ),
            ),
          ),
        );
        final total = axis == YAxisPosition.both ? 112.0 : 56.0;
        expect(c.viewport.width, closeTo(400 - total, 1e-9), reason: '$axis');
        await tester.pumpWidget(const SizedBox());
        c.dispose();
      }
    });
  });
}
