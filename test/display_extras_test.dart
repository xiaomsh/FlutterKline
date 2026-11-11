import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klinex/klinex.dart';
import 'package:klinex/src/model/block_min_max.dart';
import 'package:klinex/src/render/grid_painter.dart';
import 'package:klinex/src/render/series_painter.dart';

/// Display details and resource reclamation: second-level time format, Semantics, visible
/// high/low markers, grid toggle, wick and border colors, block cache shrink, memory-pressure
/// reclamation, unexpected worker exit.

// 2023-11-14 22:13:20 UTC
const t0 = 1700000000000;

List<Bar> walk(int n, {int stepMs = 60000, int seed = 3}) {
  final rnd = math.Random(seed);
  var close = 100.0;
  return [
    for (var i = 0; i < n; i++)
      () {
        final open = close;
        close = math.max(1.0, close + (rnd.nextDouble() - 0.5) * 4);
        return Bar(
          time: t0 + i * stepMs,
          open: open,
          high: math.max(open, close) + rnd.nextDouble(),
          low: math.max(0.5, math.min(open, close) - rnd.nextDouble()),
          close: close,
          vol: 100 + rnd.nextDouble() * 50,
        );
      }(),
  ];
}

/// Records colors at call time (Paint is reused and rewritten, so reading later is wrong) and
/// paragraph count
class _ColorProbe implements Canvas {
  final List<int> colors = [];
  int lines = 0;
  int paragraphs = 0;

  @override
  void drawRawPoints(ui.PointMode mode, Float32List points, Paint paint) =>
      colors.add(paint.color.toARGB32());

  @override
  void drawPath(Path path, Paint paint) => colors.add(paint.color.toARGB32());

  @override
  void drawLine(Offset p1, Offset p2, Paint paint) {
    lines++;
    colors.add(paint.color.toARGB32());
  }

  @override
  void drawParagraph(ui.Paragraph paragraph, Offset offset) => paragraphs++;

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

ChartConfig cfg(KLineTheme theme, {bool showHighLow = false}) => ChartConfig(
  theme: theme,
  priceFormatter: (v) => v.toStringAsFixed(2),
  timeFormatter: (ms) => '$ms',
  showHighLow: showHighLow,
);

ChartController wideBars() {
  final c = ChartController()..setBars(walk(40));
  c.viewport
    ..minBarWidth = 10
    ..maxBarWidth = 10
    ..attach(400)
    ..clampBarWidthBounds();
  return c;
}

const size = Size(400, 300);

Widget host(ChartController c, {Duration? utcOffset, KChartLabels labels = const KChartLabels()}) =>
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 400,
          height: 400,
          child: KChart(
            tooltipStyle: KChartTooltipStyle.card,
            controller: c,
            theme: KLineTheme.light(),
            utcOffset: utcOffset,
            labels: labels,
          ),
        ),
      ),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('sub-minute bars get seconds in the default time format', (tester) async {
    final c = ChartController()..setBars(walk(50, stepMs: 1000));
    await tester.pumpWidget(host(c, utcOffset: Duration.zero));
    c.crosshair.value = CrosshairState(time: c.bars[0].time, position: const Offset(100, 100));
    await tester.pump();
    expect(find.text('11-14 22:13:20'), findsWidgets);
    c.dispose();
  });

  testWidgets('minute bars keep the hour:minute format', (tester) async {
    final c = ChartController()..setBars(walk(50));
    await tester.pumpWidget(host(c, utcOffset: Duration.zero));
    c.crosshair.value = CrosshairState(time: c.bars[0].time, position: const Offset(100, 100));
    await tester.pump();
    expect(find.text('11-14 22:13'), findsWidgets);
    c.dispose();
  });

  testWidgets('chart exposes a semantics label with range and last price', (tester) async {
    final handle = tester.ensureSemantics();
    final c = ChartController()..setBars(walk(50));
    await tester.pumpWidget(host(c, utcOffset: Duration.zero));
    await tester.pump();
    final last = c.bars.last.close.toStringAsFixed(2);
    expect(
      find.bySemanticsLabel(RegExp('^Candlestick chart, .+ to .+, last price $last\$')),
      findsOneWidget,
    );

    // a new bar arrives and the description follows
    final b = c.bars.last;
    c.appendBar(b.copyWith(time: b.time + 60000, close: b.close + 3, high: b.close + 3));
    await tester.pump();
    final next = c.bars.last.close.toStringAsFixed(2);
    expect(find.bySemanticsLabel(RegExp('last price $next\$')), findsOneWidget);
    c.dispose();
    handle.dispose();
  });

  test('showHighLow labels the visible extremes, off by default', () {
    final c = wideBars();
    final off = _ColorProbe();
    SeriesPainter(c, cfg(KLineTheme.light())).paint(off, size);
    expect(off.paragraphs, 0);

    const mark = Color(0xFF123456);
    final on = _ColorProbe();
    SeriesPainter(
      c,
      cfg(KLineTheme.light().copyWith(highLowText: mark), showHighLow: true),
    ).paint(on, size);
    expect(on.paragraphs, 2, reason: 'one label for the high, one for the low');
    expect(on.colors.where((col) => col == mark.toARGB32()).length, 2, reason: 'two leader lines');
    c.dispose();
  });

  test('showGrid false drops grid lines but keeps the axis labels', () {
    final c = wideBars();
    final withGrid = _ColorProbe();
    GridPainter(c, cfg(KLineTheme.light())).paint(withGrid, size);
    final noGrid = _ColorProbe();
    GridPainter(c, cfg(KLineTheme.light().copyWith(showGrid: false))).paint(noGrid, size);
    final gridColor = KLineTheme.light().gridLine.toARGB32();
    expect(withGrid.colors.where((col) => col == gridColor), isNotEmpty);
    expect(noGrid.colors.where((col) => col == gridColor), isEmpty);
    expect(noGrid.paragraphs, withGrid.paragraphs);
    c.dispose();
  });

  test('wick and border colors override the body color', () {
    final c = wideBars();
    const upWick = Color(0xFF000001), downWick = Color(0xFF000002);
    const upBorder = Color(0xFF000003), downBorder = Color(0xFF000004);
    final theme = KLineTheme.light().copyWith(
      upWick: upWick,
      downWick: downWick,
      upBorder: upBorder,
      downBorder: downBorder,
    );
    final probe = _ColorProbe();
    SeriesPainter(c, cfg(theme)).paint(probe, size);
    expect(
      probe.colors,
      containsAll([
        for (final c in [upWick, downWick, upBorder, downBorder]) c.toARGB32(),
      ]),
    );

    final plain = _ColorProbe();
    SeriesPainter(c, cfg(KLineTheme.light())).paint(plain, size);
    expect(plain.colors.toSet(), {
      KLineTheme.light().up.toARGB32(),
      KLineTheme.light().down.toARGB32(),
    });
    c.dispose();
  });

  test('theme JSON round-trips the new fields', () {
    final t = KLineTheme.dark().copyWith(
      showGrid: false,
      upWick: const Color(0xFF010101),
      downBorder: const Color(0xFF020202),
      highLowText: const Color(0xFF030303),
    );
    final r = KLineTheme.fromJson(t.toJson());
    expect(r.showGrid, isFalse);
    expect(r.upWick, const Color(0xFF010101));
    expect(r.downWick, isNull);
    expect(r.downBorder, const Color(0xFF020202));
    expect(r.highLowText, const Color(0xFF030303));
    expect(KLineTheme.fromJson(KLineTheme.light().toJson()).showGrid, isTrue);
  });

  test('block cache frees a large buffer on invalidateAll, keeps a small one', () {
    double v(int i) => (i % 97).toDouble();
    final big = BlockMinMaxCache();
    const n = BlockMinMaxCache.blockSize * (BlockMinMaxCache.keepCapacity + 50);
    big.minMax(0, n - 1, n, v, v);
    expect(big.capacity, greaterThan(BlockMinMaxCache.keepCapacity));
    big.invalidateAll();
    expect(big.capacity, 0);
    expect(big.minMax(0, n - 1, n, v, v), (0.0, 96.0), reason: 'rebuilt on demand');

    final small = BlockMinMaxCache();
    small.minMax(0, 6399, 6400, v, v);
    final cap = small.capacity;
    small.invalidateAll();
    expect(small.capacity, cap);
  });

  test('releaseCaches leaves ranges and indicator values intact', () {
    final c =
        ChartController(
            indicators: [
              Ma(periods: const [7]),
            ],
          )
          ..asyncCompute = false
          ..setBars(walk(5000));
    (double, double) pair(MinMax m) => (m.min, m.max);
    final before = pair(c.data.rangeOf(100, 4900));
    final ma = c.storeOf(Ma(periods: const [7]));
    final maBefore = pair(ma.rangeOf('ma7', 100, 4900));
    c.releaseCaches();
    expect(pair(c.data.rangeOf(100, 4900)), before);
    expect(pair(ma.rangeOf('ma7', 100, 4900)), maBefore);
    c.dispose();
  });

  test('worker exit mid-compute falls back to sync and stays sync', () async {
    final bars = walk(3000);
    final ref = ChartController(indicators: [Macd()])
      ..asyncCompute = false
      ..setBars(bars);
    final bg = ChartController(indicators: [Macd()])..setBars(bars);
    expect(bg.computing.value, isTrue);
    bg.debugWorker!.debugSimulateExit();
    for (var i = 0; i < 100 && bg.computing.value; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    expect(bg.computing.value, isFalse, reason: 'computing must not stick');
    for (final i in [100, 1500, 2999]) {
      expect(
        bg.storeOf(Macd()).value('macd_dif', i),
        closeTo(ref.storeOf(Macd()).value('macd_dif', i), 1e-9),
      );
    }
    // fallback is permanent: the next data batch computes synchronously
    bg.setBars(walk(3000, seed: 9));
    expect(bg.computing.value, isFalse);
    expect(bg.storeOf(Macd()).value('macd_dif', 2999).isNaN, isFalse);
    ref.dispose();
    bg.dispose();
  });
}
