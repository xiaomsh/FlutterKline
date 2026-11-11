import 'dart:ui' show PictureRecorder;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klinex/klinex.dart';

import 'package:klinex/src/render/series_painter.dart';

/// The main series is an open extension point: an external [MainSeries] must get the same
/// capabilities as built-ins (decimation buckets, batched segments, last-price interpolation)
/// and can declare its own autoscale basis. Tested from a third-party author's view so later
/// changes do not narrow this contract.

List<Bar> bars(int n) => [
  for (var i = 0; i < n; i++)
    Bar(
      time: 1700000000000 + i * 60000,
      open: 100.0 + i,
      high: 120.0 + i, // wicks deliberately wide: used to tell the two autoscale bases apart
      low: 80.0 + i,
      close: 101.0 + i,
      vol: 100,
    ),
];

/// A realistic external series: draws only close-price dots, declares close-only.
class _DotSeries extends MainSeries {
  const _DotSeries();

  @override
  String get kind => 'dots';

  @override
  bool get usesHighLow => false;

  /// Records how many draw units each frame paints, to verify decimation kicks in.
  static int lastBuckets = 0;

  @override
  void paint(Canvas canvas, RenderContext ctx, SeriesPaintKit kit) {
    var n = 0;
    final seg = kit.batch(0);
    kit.forEachBucket(ctx, (x, o, h, l, c) {
      n++;
      final y = ctx.mainPanel.yOf(c);
      seg.add(x, y, x, y + 1);
    });
    lastBuckets = n;
    kit.drawSegments(canvas, seg, ctx.theme.seriesLine, 2);
  }
}

ChartConfig config({MainSeries? series, MainSeriesStyle? style}) => ChartConfig(
  theme: KLineTheme.dark(),
  priceFormatter: (v) => v.toStringAsFixed(2),
  timeFormatter: (ms) => '$ms',
  seriesStyle: style ?? MainSeriesStyle.candle,
  series: series,
);

void paintOnce(ChartController c, ChartConfig cfg, Size size) {
  final rec = PictureRecorder();
  SeriesPainter(c, cfg).paint(Canvas(rec), size);
  rec.endRecording().dispose();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const size = Size(400, 300);

  test('external series renders, and with usesHighLow=false the range follows close only', () {
    final c = ChartController()..setBars(bars(100));
    final custom = config(series: const _DotSeries());
    paintOnce(c, custom, size);
    expect(_DotSeries.lastBuckets, greaterThan(0));

    final closeRange = c.resolveLayout(size, custom).mainPanel.range;
    // wicks swing outside [80, 120+]; a close-only basis must not be stretched by them
    expect(closeRange.max, lessThan(220));

    final candleRange = c
        .resolveLayout(size, config(style: MainSeriesStyle.candle))
        .mainPanel
        .range;
    expect(candleRange.max, greaterThan(closeRange.max), reason: 'high/low wider than close-only');
    expect(candleRange.min, lessThan(closeRange.min));
    c.dispose();
  });

  test('external series shares decimation: far fewer buckets than bars when very dense', () {
    final c = ChartController()..setBars(bars(60000));
    final cfg = config(series: const _DotSeries());
    c.viewport
      ..minBarWidth = 0.02
      ..attach(size.width);
    while (c.viewport.barWidth > 0.5) {
      c.viewport.zoomAt(size.width / 2, 0.2); // zoom to subpixel density
    }
    paintOnce(c, cfg, size);
    final ctx = c.resolveLayout(size, cfg);
    expect(ctx.drawGroup, greaterThan(1), reason: 'subpixel density should trigger decimation');
    expect(
      _DotSeries.lastBuckets,
      lessThan(ctx.end - ctx.start + 1),
      reason: 'bucket count must be below visible bar count, or decimation did not apply',
    );
    c.dispose();
  });

  test('series instance takes precedence over seriesStyle enum', () {
    final cfg = config(series: const _DotSeries(), style: MainSeriesStyle.candle);
    expect(cfg.series.kind, 'dots');
    // the enum setter can still switch back to built-in
    cfg.seriesStyle = MainSeriesStyle.area;
    expect(cfg.series.kind, 'area');
    expect(cfg.series.usesHighLow, isFalse);
  });

  test('built-in enum matches instance basis (enum extension is just a facade)', () {
    for (final style in MainSeriesStyle.values) {
      expect(style.usesHighLow, MainSeries.fromStyle(style).usesHighLow, reason: 'style=$style');
      expect(MainSeries.fromStyle(style).kind, style.name);
    }
  });

  testWidgets('KChart(series:) renders end to end and hot-swaps series', (tester) async {
    final c = ChartController()..setBars(bars(120));
    Widget app(MainSeries? s) => Directionality(
      textDirection: TextDirection.ltr,
      child: SizedBox(
        width: 400,
        height: 300,
        child: KChart(controller: c, theme: KLineTheme.dark(), series: s),
      ),
    );

    await tester.pumpWidget(app(const _DotSeries()));
    expect(tester.takeException(), isNull);
    expect(_DotSeries.lastBuckets, greaterThan(0));

    // hot-swap back to built-in: didUpdateWidget must pass the config and recompute the range
    await tester.pumpWidget(app(null));
    await tester.pump();
    expect(tester.takeException(), isNull);
    c.dispose();
  });
}
