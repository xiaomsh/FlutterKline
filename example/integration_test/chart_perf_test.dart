// On-device frame time benchmark: 10k bars + full indicator set, sampled over pan, zoom and
// tick-push scenes. Run via tool/perf.sh; test_driver/perf_driver.dart archives results to
// benchmark/results/.
import 'dart:io' show Platform;
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:klinex/klinex.dart';

const barCount = 10000;

List<Bar> genBars(int n, {int seed = 21}) {
  final rnd = math.Random(seed);
  final bars = <Bar>[];
  var close = 100.0;
  for (var i = 0; i < n; i++) {
    final open = close;
    close = (open + (rnd.nextDouble() - 0.5) * 4).clamp(1.0, double.infinity);
    bars.add(
      Bar(
        time: 1600000000000 + i * 60000,
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

List<Indicator> fullSet() => [
  Ma(periods: [7, 25, 99]),
  Ema(periods: [12, 26]),
  Boll(),
  Vol(),
  MaVol(),
  Macd(),
  Kdj(),
  Rsi(),
];

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  late ChartController controller;

  Future<void> host(WidgetTester tester) async {
    controller = ChartController(indicators: fullSet())..setBars(genBars(barCount));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: KChart(controller: controller, theme: KLineTheme.dark(), showHighLow: true),
        ),
      ),
    );
    await tester.pumpAndSettle();
    binding.reportData ??= {};
    binding.reportData!['meta'] = {
      'os': Platform.operatingSystem,
      'osVersion': Platform.operatingSystemVersion,
      'bars': barCount,
      'indicators': controller.indicators.list.map((i) => i.id).toList(),
      'size': tester.view.physicalSize.toString(),
      'dpr': tester.view.devicePixelRatio,
    };
  }

  testWidgets('pan', (tester) async {
    await host(tester);
    final chart = find.byType(KChart);
    await binding.watchPerformance(() async {
      for (var i = 0; i < 6; i++) {
        await tester.timedDrag(chart, const Offset(400, 0), const Duration(milliseconds: 600));
        await tester.timedDrag(chart, const Offset(-400, 0), const Duration(milliseconds: 600));
      }
      await tester.fling(chart, const Offset(600, 0), 3000);
      await tester.pumpAndSettle();
    }, reportKey: 'pan');
    controller.dispose();
  });

  testWidgets('zoom', (tester) async {
    await host(tester);
    final cx = tester.getCenter(find.byType(KChart)).dx;
    await binding.watchPerformance(() async {
      for (var round = 0; round < 3; round++) {
        for (var i = 0; i < 40; i++) {
          controller.viewport.zoomAt(cx, 0.94);
          await tester.pump(const Duration(milliseconds: 16));
        }
        for (var i = 0; i < 40; i++) {
          controller.viewport.zoomAt(cx, 1 / 0.94);
          await tester.pump(const Duration(milliseconds: 16));
        }
      }
    }, reportKey: 'zoom');
    controller.dispose();
  });

  testWidgets('ticks', (tester) async {
    await host(tester);
    final rnd = math.Random(5);
    await binding.watchPerformance(() async {
      // Push at 60Hz for 5 seconds, closing a new bar every second.
      for (var i = 0; i < 300; i++) {
        final last = controller.bars.last;
        if (i % 60 == 59) {
          controller.appendBar(
            Bar(
              time: last.time + 60000,
              open: last.close,
              high: last.close,
              low: last.close,
              close: last.close,
              vol: 0,
            ),
          );
        } else {
          final p = last.close + (rnd.nextDouble() - 0.5);
          controller.applyTick(
            last.copyWith(
              close: p,
              high: math.max(last.high, p),
              low: math.min(last.low, p),
              vol: last.vol + 1,
            ),
          );
        }
        await tester.pump(const Duration(milliseconds: 16));
      }
    }, reportKey: 'ticks');
    controller.dispose();
  });
}
