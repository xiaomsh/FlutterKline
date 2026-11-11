import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/animation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klinex/klinex.dart';
import 'package:klinex/src/render/indicator_painter.dart';
import 'package:klinex/src/render/series_painter.dart';

Bar _bar(int i, double c) =>
    Bar(time: i * 60000, open: c, high: c * 1.01, low: c * 0.99, close: c, vol: 10 + i % 7);

class _FakeVsync implements TickerProvider {
  @override
  Ticker createTicker(TickerCallback onTick) => Ticker(onTick);
}

ChartConfig _config({bool log = false}) => ChartConfig(
  theme: KLineTheme.light(),
  priceFormatter: (v) => v.toStringAsFixed(2),
  timeFormatter: (ms) => '$ms',
  logScale: log,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('log scale survives a wide range with the volume overlay reserve', () {
    final c = ChartController(indicators: [VolOverlay()])
      ..asyncCompute = false
      ..setBars([for (var i = 0; i < 100; i++) _bar(i, math.pow(1.1, i).toDouble())]);
    final ctx = c.resolveLayout(const Size(400, 400), _config(log: true));
    expect(ctx.mainPanel.logScale, isTrue);
    expect(ctx.mainPanel.range.min, greaterThan(0));
    final visibleLow = [
      for (var i = ctx.start; i <= ctx.end; i++) c.bars[i].low,
    ].reduce((a, b) => a < b ? a : b);
    expect(ctx.mainPanel.yOf(visibleLow), lessThan(ctx.mainPanel.rect.bottom));
    c.dispose();
  });

  test('volume overlay paints without throwing in a panel under 1px tall', () {
    final c = ChartController(indicators: [VolOverlay()])
      ..asyncCompute = false
      ..setBars([for (var i = 0; i < 50; i++) _bar(i, 100.0 + i)]);
    final config = _config();
    final size = Size(400, config.timeAxisHeight + 0.5);
    final rec = PictureRecorder();
    final canvas = Canvas(rec);
    SeriesPainter(c, config).paint(canvas, size);
    IndicatorPainter(c, config).paint(canvas, size);
    rec.endRecording().dispose();
    c.dispose();
  });

  test('snapped crosshair stays inside the main panel after a manual y zoom', () {
    final c = ChartController(indicators: [Vol()])
      ..asyncCompute = false
      ..setBars([for (var i = 0; i < 50; i++) _bar(i, 100.0 + i)]);
    const size = Size(400, 400);
    final config = _config()..crosshairSnap = CrosshairSnap.close;
    var ctx = c.resolveLayout(size, config);
    c.viewport.zoomY(8);
    ctx = c.resolveLayout(size, config);
    final main = ctx.mainPanel.rect;
    expect(ctx.mainPanel.yOf(c.bars.last.close), lessThan(main.top));
    final g = GestureCoordinator(
      controller: c,
      resolve: () => c.resolveLayout(size, config),
      fling: AnimationController.unbounded(vsync: _FakeVsync()),
    );
    g.setCrosshair(Offset(ctx.xOf(c.bars.length - 1), main.center.dy));
    final y = c.crosshair.value!.position.dy;
    expect(y, inInclusiveRange(main.top, main.bottom));
    c.dispose();
  });

  test('an empty palette falls back to the series line colour', () {
    final t = KLineTheme.light().copyWith(palette: const []);
    expect(t.lineColor(3), t.seriesLine);
  });
}
