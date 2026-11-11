import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klinex/klinex.dart';

/// Rendering goldens: full-image comparison of a few fixed scenes to guard against paint
/// regressions. Data is synthesized from sine waves, no randomness; text uses flutter_test's
/// built-in test font, so results are consistent across machines.
/// After changing painting, update the baselines:
/// `flutter test --update-goldens test/golden_test.dart`

List<Bar> synth(int n) => [
  for (var i = 0; i < n; i++)
    () {
      final base = 100 + 20 * math.sin(i / 17) + 6 * math.sin(i / 3.3);
      final open = base + 2 * math.sin(i * 1.7);
      final close = base + 2 * math.cos(i * 1.3);
      return Bar(
        time: 1700000000000 + i * 60000,
        open: open,
        high: math.max(open, close) + 1 + (i % 5) * 0.4,
        low: math.min(open, close) - 1 - (i % 3) * 0.5,
        close: close,
        vol: 200 + 150 * (1 + math.sin(i / 5)),
      );
    }(),
];

const _key = ValueKey('chart');

Future<void> pumpChart(
  WidgetTester tester,
  ChartController c, {
  KLineTheme? theme,
  bool logScale = false,
  MainSeriesStyle style = MainSeriesStyle.candle,
  CandleFillMode fill = CandleFillMode.solid,
  YAxisPosition axis = YAxisPosition.outside,
  bool showHighLow = false,
  double? barWidth,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Center(
        child: RepaintBoundary(
          key: _key,
          child: SizedBox(
            width: 480,
            height: 320,
            child: KChart(
              controller: c,
              theme: theme ?? KLineTheme.light(),
              logScale: logScale,
              seriesStyle: style,
              candleFill: fill,
              yAxisPosition: axis,
              showHighLow: showHighLow,
              minBarWidth: barWidth,
              maxBarWidth: barWidth,
              utcOffset: Duration.zero,
            ),
          ),
        ),
      ),
    ),
  );
  // The widget only sets the bounds and doesn't clamp the current bar width; clamp it to get the
  // desired value
  c.viewport.clampBarWidthBounds();
  await tester.pump();
}

void main() {
  testWidgets('candles + MA + MACD', (tester) async {
    final c =
        ChartController(
            indicators: [
              Ma(periods: const [7, 25]),
              Macd(),
            ],
          )
          ..asyncCompute = false
          ..setBars(synth(160));
    await pumpChart(tester, c, barWidth: 6);
    await expectLater(find.byKey(_key), matchesGoldenFile('goldens/candle_ma_macd.png'));
    c.dispose();
  });

  testWidgets('log scale line series, dark theme', (tester) async {
    final c = ChartController(indicators: [Boll()])
      ..asyncCompute = false
      ..setBars(synth(160));
    await pumpChart(
      tester,
      c,
      theme: KLineTheme.dark(),
      logScale: true,
      style: MainSeriesStyle.line,
      barWidth: 5,
    );
    await expectLater(find.byKey(_key), matchesGoldenFile('goldens/log_line_dark.png'));
    c.dispose();
  });

  testWidgets('dense zoom-out aggregates candles', (tester) async {
    final c = ChartController(indicators: [Vol()])
      ..asyncCompute = false
      ..setBars(synth(4000));
    await pumpChart(tester, c, barWidth: 0.1);
    await expectLater(find.byKey(_key), matchesGoldenFile('goldens/dense_aggregate.png'));
    c.dispose();
  });

  testWidgets('axes on both sides, hollow candles, high/low marks, styled wicks', (tester) async {
    final c = ChartController(indicators: [Rsi()])
      ..asyncCompute = false
      ..setBars(synth(120));
    await pumpChart(
      tester,
      c,
      theme: KLineTheme.light().copyWith(
        upWick: const Color(0xFF555555),
        downWick: const Color(0xFF555555),
        downBorder: const Color(0xFF000000),
        showGrid: false,
      ),
      fill: CandleFillMode.hollowUp,
      axis: YAxisPosition.both,
      showHighLow: true,
      barWidth: 8,
    );
    await expectLater(find.byKey(_key), matchesGoldenFile('goldens/both_axes_styled.png'));
    c.dispose();
  });
}
