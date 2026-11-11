import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klinex/klinex.dart';

import 'package:klinex_example/l10n/l10n.dart';
import 'package:klinex_example/page/live/live_controller.dart';
import 'package:klinex_example/page/live/live_sheets.dart';
import 'package:klinex_example/pro/live_pro.dart';

void main() {
  test('the live page lists all 40 pro indicators, locked in the free edition', () {
    final pro = [...LivePro.mainOptions, ...LivePro.subOptions];
    expect(pro.toSet(), hasLength(pro.length));
    expect(pro, hasLength(40));
  });

  testWidgets('settings sheet fits a phone and drives the page switches', (tester) async {
    await tester.binding.setSurfaceSize(const Size(375, 667));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    // Skip onInit: it connects to the exchange. The settings sheet only touches switches and pro.
    final controller = LiveController();
    controller
      ..pro = LivePro(controller)
      ..priceLine = PriceLineOverlay();
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => showLiveSettings(context, controller),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    for (final label in [
      S.current.liveChartSettings,
      S.current.liveIndicatorParams,
      S.current.liveLastPrice,
      S.current.liveCountdown,
      S.current.liveBookPrice,
      S.current.liveChartType,
      S.current.liveTimeZone,
      S.current.liveSectionChartHeight,
    ]) {
      await tester.ensureVisible(find.text(label));
      expect(find.text(label), findsOneWidget, reason: label);
    }
    expect(find.text(S.current.proSampleDrawing), findsNothing);
    expect(find.text(S.current.proSampleReplay), findsNothing);

    await tester.ensureVisible(find.text(S.current.liveCountdown));
    await tester.tap(find.text(S.current.liveCountdown));
    await tester.pump();
    expect(controller.showCountdown.value, isFalse);

    await tester.ensureVisible(find.text(S.current.liveLastPrice));
    await tester.tap(find.text(S.current.liveLastPrice));
    await tester.pump();
    expect(controller.showPrice.value, isFalse);
    expect(controller.priceLine.showPrice, isFalse);
    expect(tester.takeException(), isNull);
  });
}
