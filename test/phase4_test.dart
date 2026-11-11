import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klinex/klinex.dart';

const t0 = 1700000000000;

List<Bar> genBars(int n, {int seed = 1, int periodMs = 60000}) {
  final rnd = math.Random(seed);
  final bars = <Bar>[];
  var close = 100.0;
  for (var i = 0; i < n; i++) {
    final open = close;
    close = (open + (rnd.nextDouble() - 0.5) * 4).clamp(1.0, double.infinity);
    bars.add(
      Bar(
        time: t0 + i * periodMs,
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

List<Bar> aggregate(List<Bar> bars, int k) {
  final out = <Bar>[];
  for (var i = 0; i < bars.length; i += k) {
    final j = math.min(i + k, bars.length);
    var high = bars[i].high, low = bars[i].low, vol = 0.0;
    for (var m = i; m < j; m++) {
      high = math.max(high, bars[m].high);
      low = math.min(low, bars[m].low);
      vol += bars[m].vol;
    }
    out.add(
      Bar(
        time: bars[i].time,
        open: bars[i].open,
        high: high,
        low: low,
        close: bars[j - 1].close,
        vol: vol,
      ),
    );
  }
  return out;
}

ChartConfig makeConfig({MainSeriesStyle style = MainSeriesStyle.candle}) => ChartConfig(
  theme: KLineTheme.light(),
  priceFormatter: (v) => v.toStringAsFixed(2),
  timeFormatter: (ms) => '$ms',
  seriesStyle: style,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('line/area autoscale on close only; candle includes wicks', () {
    final bars = genBars(100, seed: 4);
    // one bar with an extreme wick far above every close (placed inside the default view's
    // visible window; by default half a screen is left blank on the right, so the visible data
    // is about the last 25 bars)
    bars[90] = bars[90].copyWith(high: 500);
    final c = ChartController()..setBars(bars);

    final candle = c.resolveLayout(const Size(400, 300), makeConfig());
    expect(candle.mainPanel.range.max, greaterThanOrEqualTo(500));

    final line = c.resolveLayout(const Size(400, 300), makeConfig(style: MainSeriesStyle.line));
    expect(line.mainPanel.range.max, lessThan(500), reason: 'line chart must ignore the wick');
    c.dispose();
  });

  testWidgets('line & area styles render without exceptions', (tester) async {
    final controller = ChartController(indicators: [Ma(), Vol()])..setBars(genBars(200));
    for (final style in [MainSeriesStyle.line, MainSeriesStyle.area]) {
      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 400,
            height: 400,
            child: KChart(
              controller: controller,
              theme: KLineTheme.dark(),
              seriesStyle: style,
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    }
    controller.dispose();
  });
}
