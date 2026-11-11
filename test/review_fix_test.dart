import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klinex/klinex.dart';
import 'package:klinex/src/widget/price_animator.dart';

/// Issues found in the 2026-11 code review, one regression test each

const t0 = 1700000000000;

Bar bar(int i, {double close = 100, double vol = 10}) => Bar(
  time: t0 + i * 60000,
  open: 100,
  high: close > 100 ? close + 1 : 101,
  low: close < 100 ? close - 1 : 99,
  close: close,
  vol: vol,
);

List<Bar> bars(int n) => [for (var i = 0; i < n; i++) bar(i)];

class _Broken extends Indicator {
  @override
  String get id => 'broken';

  @override
  PanelRef get target => PanelRef.main;

  @override
  void computeAll(List<Bar> bars, IndicatorStore store) => throw StateError('boom');

  @override
  void computeLast(List<Bar> bars, int index, IndicatorStore store) => throw StateError('boom');

  @override
  void paint(Canvas canvas, RenderContext ctx, IndicatorStore store) {}

  @override
  MinMax range(IndicatorStore store, int start, int end) => MinMax.empty;

  @override
  void legendInto(List<LegendItem> out, RenderContext ctx, IndicatorStore store, int index) {}
}

class _ViewProbe extends _Broken {
  double? seenRight;

  @override
  String get id => 'probe';

  @override
  void computeAll(List<Bar> bars, IndicatorStore store) {}

  @override
  void computeLast(List<Bar> bars, int index, IndicatorStore store) {}

  @override
  MinMax rangeInView(IndicatorStore store, int start, int end, double rightIndex) {
    seenRight = rightIndex;
    return MinMax.empty;
  }
}

class _RecordMode extends InteractionMode {
  int ends = 0;

  @override
  void onDragEnd(RenderContext ctx) => ends++;
}

List<Bar> walkBars(int n, {int from = 0}) => [
  for (var i = from; i < from + n; i++)
    Bar(
      time: t0 + i * 60000,
      open: 100 + (i % 17),
      high: 105 + (i % 17),
      low: 95 + (i % 13),
      close: 100 + (i % 11),
      vol: 10.0 + i % 7,
    ),
];

void main() {
  testWidgets('tooltip updates when the newest bar changes under a still mouse', (tester) async {
    final c = ChartController()..setBars(bars(50));
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 400,
          height: 300,
          child: KChart(
            tooltipStyle: KChartTooltipStyle.card,
            controller: c,
            theme: KLineTheme.light(),
          ),
        ),
      ),
    );
    c.crosshair.value = CrosshairState(time: t0 + 49 * 60000, position: const Offset(300, 100));
    await tester.pump();
    expect(find.text('100.00'), findsWidgets);

    c.updateLast(bar(49, close: 123.45));
    await tester.pump();
    expect(find.text('123.45'), findsOneWidget);
    c.dispose();
  });

  test('crosshair plugin repaints with data', () {
    final c = ChartController();
    expect(CrosshairOverlay().repaintOn(c), contains(c.dataRevision));
    c.dispose();
  });

  testWidgets('changing panelWeights at runtime takes effect', (tester) async {
    final c = ChartController(indicators: [Vol()])..setBars(bars(50));
    var mainHeight = 0.0, volHeight = 0.0;
    Widget chart(Map<String, double> weights) => MaterialApp(
      home: SizedBox(
        width: 400,
        height: 300,
        child: KChart(
          tooltipStyle: KChartTooltipStyle.card,
          controller: c,
          theme: KLineTheme.light(),
          panelWeights: weights,
          overlayBuilder: (context, ctx) {
            mainHeight = ctx.mainPanel.rect.height;
            volHeight = ctx.panels.last.rect.height;
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    await tester.pumpWidget(chart(const {'main': 1, 'vol': 1}));
    await tester.pump();
    expect(mainHeight / volHeight, closeTo(1, 0.01));

    await tester.pumpWidget(chart(const {'main': 3, 'vol': 1}));
    await tester.pump();
    expect(mainHeight / volHeight, closeTo(3, 0.01));
    c.dispose();
  });

  testWidgets('last-price animation off then on: no slide from the old price', (tester) async {
    final c = ChartController()..setBars(bars(10));
    var enabled = true;
    final anim = PriceAnimator(const TestVSync(), c, enabled: () => enabled)..attach(c);

    enabled = false;
    c.updateLast(bar(9, close: 200));
    anim.onData();

    enabled = true;
    c.updateLast(bar(9, close: 201));
    anim.onData();
    await tester.pump(const Duration(milliseconds: 50));
    expect(c.animatedLastClose.value, inInclusiveRange(200, 201));
    anim.dispose();
    c.dispose();
  });

  test('negative volume clamped to 0, price still stored', () {
    final c = ChartController()..setBars(bars(3));
    c.appendBar(bar(3, close: 101, vol: -5));
    expect(c.bars.length, 4);
    expect(c.bars.last.vol, 0);
    expect(c.bars.last.close, 101);
    c.dispose();
  });

  test('unsorted input keeps the last bar seen for a duplicate timestamp', () {
    final input = <Bar>[
      for (var i = 40; i >= 0; i--) bar(i),
      for (var i = 0; i <= 40; i++) bar(i, close: 150),
    ];
    final c = ChartController()..setBars(input);
    expect(c.bars.length, 41);
    expect(c.bars.every((b) => b.close == 150), isTrue);
    c.dispose();
  });

  test('empty period list throws at construction', () {
    expect(() => Ma(periods: const []), throwsArgumentError);
    expect(() => Ema(periods: const []), throwsArgumentError);
  });

  test('zoom does not throw when bar width min/max are inverted', () {
    final vp = ChartViewport()
      ..minBarWidth = 10
      ..maxBarWidth = 5
      ..setBarCount(100, jumpToLatest: true)
      ..attach(400);
    expect(() => vp.zoomAt(200, 1.5), returnsNormally);
    expect(vp.barWidth, 10);
    vp.dispose();
  });

  test('indicator errors go to onIndicatorError', () {
    final errors = <String>[];
    final c = ChartController(indicators: [_Broken()])
      ..asyncCompute = false
      ..onIndicatorError = (ind, e, s) => errors.add(ind.id);
    c.setBars(bars(20));
    c.appendBar(bar(20));
    expect(errors, isNotEmpty);
    expect(errors.toSet(), {'broken'});
    c.dispose();
  });

  test('layout calls rangeInView with the screen right edge', () {
    final probe = _ViewProbe();
    final c = ChartController(indicators: [probe])..setBars(bars(50));
    c.resolveLayout(
      const Size(400, 300),
      ChartConfig(
        theme: KLineTheme.light(),
        priceFormatter: (v) => '$v',
        timeFormatter: (ms) => '$ms',
      ),
    );
    expect(probe.seenRight, c.viewport.rightIndex);
    expect(probe.seenRight, greaterThan(49));
    c.dispose();
  });

  testWidgets('resetting maxBarWidth to null restores the default cap', (tester) async {
    final c = ChartController()..setBars(bars(50));
    Widget chart(double? max) => MaterialApp(
      home: KChart(
        tooltipStyle: KChartTooltipStyle.card,
        controller: c,
        theme: KLineTheme.light(),
        maxBarWidth: max,
      ),
    );
    await tester.pumpWidget(chart(20));
    expect(c.viewport.maxBarWidth, 20);
    await tester.pumpWidget(chart(null));
    expect(c.viewport.maxBarWidth, ChartViewport.defaultMaxBarWidth);
    c.dispose();
  });

  testWidgets('grid still paints when the panel is shorter than axis labels', (tester) async {
    final c = ChartController(indicators: [Macd()])..setBars(bars(50));
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox(
            width: 400,
            height: 40,
            child: KChart(
              tooltipStyle: KChartTooltipStyle.card,
              controller: c,
              theme: KLineTheme.light(),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    c.dispose();
  });

  testWidgets('layout recomputes on a screen with a different pixel ratio', (tester) async {
    final c = ChartController()..setBars(bars(50));
    RenderContext? last;
    Widget chart(double dpr) => MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(devicePixelRatio: dpr, size: const Size(400, 300)),
        child: KChart(
          tooltipStyle: KChartTooltipStyle.card,
          controller: c,
          theme: KLineTheme.light(),
          overlayBuilder: (context, ctx) {
            last = ctx;
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    await tester.pumpWidget(chart(1));
    await tester.pump();
    final first = last;
    await tester.pumpWidget(chart(3));
    await tester.pump();
    expect(identical(last, first), isFalse);
    expect(last!.config.devicePixelRatio, 3);
    c.dispose();
  });

  test('paints normally with unreasonable theme dash params', () {
    final pool = PaintPool();
    final canvas = Canvas(PictureRecorder());
    final paint = Paint();
    for (final (dash, gap) in [(0.001, 0.0), (4.0, -5.0), (double.nan, 4.0), (-1.0, 4.0)]) {
      expect(
        () => pool.drawDashedHLine(canvas, 10, 0, 1000, paint, dash: dash, gap: gap),
        returnsNormally,
      );
      expect(
        () => pool.drawDashedVLine(canvas, 10, 0, 1000, paint, dash: dash, gap: gap),
        returnsNormally,
      );
    }
    pool.clear();
  });

  test('prepend runs full-recompute indicators in background, matching sync results', () async {
    final all = walkBars(6000);
    final bg = ChartController(indicators: [Vol(), Ma()])..setBars(all.sublist(3000));
    for (var i = 0; i < 400 && bg.computing.value; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    bg.prependHistory(all.sublist(0, 3000));
    expect(bg.computing.value, isTrue, reason: 'Vol: no prefix range, full recompute, bg if large');
    for (var i = 0; i < 400 && bg.computing.value; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    expect(bg.computing.value, isFalse);
    final ref = ChartController(indicators: [Vol(), Ma()])
      ..asyncCompute = false
      ..setBars(all);
    for (final ind in ref.indicators.list) {
      for (final i in [0, 2999, 3000, 5999]) {
        final a = bg.storeOf(ind).valuesAt(i), b = ref.storeOf(ind).valuesAt(i);
        for (final k in b.keys) {
          final x = a[k]!, y = b[k]!;
          expect(
            x.isNaN ? 'nan' : x,
            y.isNaN ? 'nan' : closeTo(y, 1e-9),
            reason: '${ind.id}.$k @ $i',
          );
        }
      }
    }
    bg.dispose();
    ref.dispose();
  });

  testWidgets('interaction mode also gets the end when the system cancels a drag', (tester) async {
    final c = ChartController()..setBars(bars(50));
    final mode = _RecordMode();
    final fling = AnimationController.unbounded(vsync: const TestVSync());
    final config = ChartConfig(
      theme: KLineTheme.light(),
      priceFormatter: (v) => '$v',
      timeFormatter: (ms) => '$ms',
    );
    final g = GestureCoordinator(
      controller: c,
      resolve: () => c.resolveLayout(const Size(400, 300), config),
      fling: fling,
      mode: mode,
    );
    g.onModePanStart(DragStartDetails(localPosition: const Offset(100, 100)));
    g.onModePanCancel();
    expect(mode.ends, 1);
    g.dispose();
    fling.dispose();
    c.dispose();
  });

  test('current yScale is clamped in when the y-scale minimum is raised', () {
    final vp = ChartViewport()..zoomY(0.25);
    expect(vp.yScale, 0.25);
    vp.minYScale = 0.5;
    expect(vp.yScale, 0.5);
    vp.dispose();
  });

  test('setRightIndex rejects NaN; inverted y-scale min/max does not throw', () {
    final vp = ChartViewport()
      ..setBarCount(100, jumpToLatest: true)
      ..attach(400);
    final before = vp.rightIndex;
    vp.setRightIndex(double.nan);
    expect(vp.rightIndex, before);
    vp
      ..minYScale = 3
      ..maxYScale = 2;
    expect(() => vp.zoomY(2), returnsNormally);
    vp.dispose();
  });

  testWidgets('bar width clamped in when default min grows with pixel ratio', (tester) async {
    final c = ChartController()..setBars(bars(5000));
    Widget chart(double dpr) => MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(devicePixelRatio: dpr, size: const Size(400, 300)),
        child: KChart(
          tooltipStyle: KChartTooltipStyle.card,
          controller: c,
          theme: KLineTheme.light(),
        ),
      ),
    );
    await tester.pumpWidget(chart(4));
    c.viewport.zoomAt(200, 0.001);
    expect(c.viewport.barWidth, closeTo(0.25 / 4, 1e-9));
    await tester.pumpWidget(chart(1));
    await tester.pump();
    expect(c.viewport.barWidth, closeTo(0.25, 1e-9));
    c.dispose();
  });
}
