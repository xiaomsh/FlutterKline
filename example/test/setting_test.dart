import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:klinex/klinex.dart';

import 'package:klinex_example/l10n/l10n.dart';
import 'package:klinex_example/page/setting/sample/sample_data.dart';
import 'package:klinex_example/page/setting/sample/sample_entry.dart';
import 'package:klinex_example/page/setting/sample/sample_feed.dart';
import 'package:klinex_example/page/setting/sample_list.dart';
import 'package:klinex_example/page/setting/setting_menu.dart';
import 'package:klinex_example/page/setting/setting_page.dart';
import 'package:klinex_example/pro/live_pro.dart';
import 'package:klinex_example/route.dart';

Future<void> _open(WidgetTester tester, String id, {Size size = const Size(1280, 800)}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      builder: FlutterSmartDialog.init(),
      home: SettingPage(entryId: id),
    ),
  );
  await tester.pumpAndSettle();
}

/// Placeholder value marking where a localized message's arguments start.
const _hole = '\u0000';

/// The fixed text of a localized message up to its first argument filled with [_hole].
String _prefix(String message) => message.substring(0, message.indexOf(_hole));

KChart _chart(WidgetTester tester) => tester.widget<KChart>(find.byType(KChart).first);

Future<void> _tapToggle(WidgetTester tester, String label) async {
  final tile = find.widgetWithText(SwitchListTile, label);
  await tester.ensureVisible(tile);
  await tester.tap(tile);
  await tester.pumpAndSettle();
}

Future<void> _menu(WidgetTester tester, String id) async {
  final item = find.byKey(ValueKey('menu-$id'));
  await tester.ensureVisible(item);
  await tester.pumpAndSettle();
  await tester.tap(item);
  await tester.pumpAndSettle();
}

void main() {
  setUp(resetSettingMenuMemory);

  for (final size in [const Size(1280, 800), const Size(900, 800), const Size(375, 812)]) {
    testWidgets('responsive layout at $size', (tester) async {
      await _open(tester, 'crosshair', size: size);
      expect(
        find.text(S.current.settingPageTitle),
        size.width >= 700 ? findsOneWidget : findsNothing,
      );
      expect(find.byType(KChart), findsOneWidget);
      final panel = tester.getRect(find.byKey(const ValueKey('sample-panel')));
      final chart = tester.getRect(find.byType(KChart));
      if (size.width >= 700) {
        expect(find.byKey(const ValueKey('setting-menu')), findsOneWidget);
      } else {
        expect(find.byKey(const ValueKey('setting-menu')), findsNothing);
      }
      if (size.width - (size.width >= 700 ? 233 : 0) >= 860) {
        expect(panel.width, 340);
        expect(panel.left, greaterThanOrEqualTo(chart.right));
      } else {
        expect(panel.top, greaterThanOrEqualTo(chart.bottom));
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets('defaults to the light theme and toggles dark', (tester) async {
    settingDark.value = false;
    await _open(tester, 'scale');
    expect(Theme.of(tester.element(find.byType(KChart))).brightness, Brightness.light);
    expect(_chart(tester).theme.background, KLineTheme.light().background);
    await tester.tap(find.byTooltip(S.current.settingDarkMode));
    await tester.pumpAndSettle();
    expect(_chart(tester).theme.background, KLineTheme.dark().background);
    settingDark.value = false;
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('every unlocked sample builds standalone, ids are unique', (tester) async {
    final entries = allSamples();
    expect(entries.map((e) => e.id).toSet().length, entries.length);
    for (final entry in entries.where((e) => !e.locked)) {
      await _open(tester, entry.id);
      expect(find.byKey(const ValueKey('sample-panel')), findsOneWidget, reason: entry.id);
      expect(tester.takeException(), isNull, reason: entry.id);
      await tester.pumpWidget(const SizedBox.shrink());
      // A sample's own timers (pushes) are disposed with the sample.
      await tester.pump(const Duration(seconds: 2));
      expect(tester.takeException(), isNull, reason: '${entry.id} dispose');
    }
    if (!LivePro.unlocked) {
      expect(LivePro.settingSamples().every((e) => e.locked && e.builder == null), isTrue);
    }
  });

  testWidgets('samples are independent and reset rebuilds only the current one', (tester) async {
    await _open(tester, 'scale');
    await _tapToggle(tester, S.current.scaleModeLog);
    expect(_chart(tester).logScale, isTrue);
    final first = _chart(tester).controller;
    await _menu(tester, 'axis-position');
    expect(_chart(tester).logScale, isFalse);
    expect(_chart(tester).controller, isNot(same(first)));
    await _menu(tester, 'scale');
    expect(
      _chart(tester).logScale,
      isFalse,
      reason: 'returning creates a fresh sample without the previous settings',
    );
    await _tapToggle(tester, S.current.scaleModeInvert);
    expect(_chart(tester).invertScale, isTrue);
    final before = _chart(tester).controller;
    await tester.tap(find.byTooltip(S.current.sampleResetPage));
    await tester.pumpAndSettle();
    expect(_chart(tester).invertScale, isFalse);
    expect(_chart(tester).controller, isNot(same(before)));
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('equivalent code follows the current settings', (tester) async {
    await _open(tester, 'format');
    await tester.tap(find.text(S.current.controlsEquivalentCode));
    await tester.pumpAndSettle();
    expect(find.textContaining('timeFormatter: null'), findsOneWidget);
    await _tapToggle(tester, S.current.formatSampleCustomTime);
    expect(find.textContaining('String formatTime(int millis)'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('parameter typing updates immediately without losing focus', (tester) async {
    await _open(tester, 'indicator-boll');
    final field = find.byType(TextFormField).first;
    await tester.enterText(field, '32');
    await tester.pump();
    expect(_chart(tester).controller.indicators.list.whereType<Boll>().single.period, 32);
    expect(tester.testTextInput.isVisible, isTrue);
    await tester.enterText(find.byType(TextFormField).first, '0');
    await tester.pump();
    expect(_chart(tester).controller.indicators.list.whereType<Boll>().single.period, 32);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('MA with every line off removes the indicator and the code says so', (
    tester,
  ) async {
    await _open(tester, 'indicator-ma');
    for (var i = 0; i < 3; i++) {
      final box = find.byType(CheckboxListTile).at(i);
      await tester.ensureVisible(box);
      await tester.tap(box);
      await tester.pumpAndSettle();
    }
    expect(_chart(tester).controller.indicators.list.whereType<Ma>(), isEmpty);
    await tester.ensureVisible(find.text(S.current.controlsEquivalentCode));
    await tester.tap(find.text(S.current.controlsEquivalentCode));
    await tester.pumpAndSettle();
    expect(find.textContaining('MA is not added'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('menu search filters categories and titles', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SettingMenu(entries: allSamples(), selected: null, onSelect: (_) {}),
        ),
      ),
    );
    await tester.enterText(find.byType(TextField).first, 'crosshairsnap');
    await tester.pumpAndSettle();
    expect(find.text(S.current.sampleCrosshairTitle), findsOneWidget);
    expect(find.text(S.current.sampleDataLimitTitle), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('direct routes and menu navigation', (tester) async {
    Get.testMode = true;
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      GetMaterialApp(
        initialRoute: '/setting/crosshair',
        getPages: pages,
        builder: FlutterSmartDialog.init(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(S.current.crosshairSampleSnap), findsOneWidget);
    final controller = _chart(tester).controller;
    await _menu(tester, 'scale');
    expect(Get.currentRoute, '/setting/scale');
    expect(
      controller.indicators.hasListeners,
      isFalse,
      reason: 'the sample left behind is disposed',
    );
    if (!LivePro.unlocked) {
      await tester.enterText(find.byType(TextField).first, 'drawing');
      await tester.pumpAndSettle();
      await tester.tap(find.text(S.current.proSampleDrawing));
      await tester.pump();
      expect(Get.currentRoute, '/setting/scale');
      expect(find.text(S.current.proLockFeature), findsOneWidget);
      await tester.pumpAndSettle(const Duration(seconds: 3));
    }
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    Get.reset();
  });

  testWidgets('price line sample shows the price tag, countdown and book tags', (tester) async {
    await _open(tester, 'price');
    expect(find.text(S.current.axisTagAsk), findsOneWidget);
    expect(find.text(S.current.axisTagBid), findsOneWidget);
    expect(find.textContaining(RegExp(r'^00:0\d$')), findsOneWidget);
    await _tapToggle(tester, S.current.priceLineCountdown);
    expect(find.textContaining(RegExp(r'^00:0\d$')), findsNothing);
    await _tapToggle(tester, S.current.priceLineBook);
    expect(find.text(S.current.axisTagBid), findsNothing);
    expect(find.text(S.current.priceLineTipMark), findsNothing);
    await tester.ensureVisible(find.text(S.current.priceLineTypeLast));
    await tester.tap(find.text(S.current.priceLineTypeLast));
    await tester.pumpAndSettle();
    await tester.tap(find.text(S.current.priceLineTypeMark).last);
    await tester.pumpAndSettle();
    expect(find.text(S.current.priceLineTipMark), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('tapping a bar picks its close price', (tester) async {
    await _open(tester, 'gestures');
    final chart = tester.getRect(find.byType(KChart).first);
    await tester.tapAt(chart.center);
    await tester.pumpAndSettle();
    expect(
      find.textContaining(_prefix(S.current.gestureSampleOrderPrice(_hole, ''))),
      findsOneWidget,
    );
    expect(
      find.textContaining(_prefix(S.current.gestureSampleTapped(_hole, '', '', ''))),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('menu keeps its scroll position across sample routes', (tester) async {
    Get.testMode = true;
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      GetMaterialApp(
        initialRoute: '/setting/crosshair',
        getPages: pages,
        builder: FlutterSmartDialog.init(),
      ),
    );
    await tester.pumpAndSettle();
    final last = allSamples().lastWhere((e) => !e.locked);
    final menuScroll = find.descendant(
      of: find.descendant(of: find.byType(SettingMenu), matching: find.byType(ListView)),
      matching: find.byType(Scrollable),
    );
    await tester.scrollUntilVisible(
      find.byKey(ValueKey('menu-${last.id}')),
      200,
      scrollable: menuScroll.first,
    );
    await _menu(tester, last.id);
    expect(Get.currentRoute, '/setting/${last.id}');
    expect(tester.state<ScrollableState>(menuScroll.first).position.pixels, greaterThan(0));
    final item = tester.getRect(find.byKey(ValueKey('menu-${last.id}')));
    expect(item.bottom, lessThanOrEqualTo(800), reason: 'the selected item stays on screen');
    await tester.pumpWidget(const SizedBox.shrink());
    Get.reset();
  });

  if (!LivePro.unlocked)
    testWidgets('locked series does not change the selector', (tester) async {
      await _open(tester, 'series');
      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text(S.current.seriesProSuffix(S.current.proSeriesOhlc)).last);
      await tester.pumpAndSettle(const Duration(seconds: 3));
      expect(
        tester.widget<DropdownButton<String>>(find.byType(DropdownButton<String>)).value,
        'candle',
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });

  testWidgets('storage restores indicators and zoom, rejects bad input atomically', (
    tester,
  ) async {
    await _open(tester, 'storage');
    final c = _chart(tester).controller;
    c.viewport.zoomAt(200, 1.7);
    final width = c.viewport.barWidth;
    await tester.tap(find.text(S.current.commonSave));
    await tester.pumpAndSettle();
    await tester.tap(find.text(S.current.storageSampleSwapIndicators));
    await tester.pumpAndSettle();
    c.viewport.zoomAt(200, 0.5);
    expect(c.indicators.list.whereType<Ma>(), isEmpty);
    await tester.tap(find.text(S.current.storageSampleRestore));
    await tester.pumpAndSettle();
    expect(c.indicators.list.whereType<Ma>(), isNotEmpty);
    expect(c.viewport.barWidth, closeTo(width, 1e-9));
    await tester.enterText(find.byType(TextField).last, '[]');
    await tester.tap(find.text(S.current.storageSampleRestore));
    await tester.pumpAndSettle();
    expect(
      find.textContaining(_prefix(S.current.storageSampleRestoreFailed(_hole))),
      findsOneWidget,
    );
    expect(c.indicators.list.whereType<Ma>(), isNotEmpty);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  group('SampleFeed', () {
    test('manual last-bar update never appends', () {
      final c = ChartController();
      final feed = SampleFeed(c);
      final length = c.bars.length;
      final time = c.bars.last.time;
      for (var i = 0; i < 10; i++) {
        feed.push();
      }
      expect(c.bars.length, length);
      expect(c.bars.last.time, time);
      feed.push(append: true);
      expect(c.bars.length, length + 1);
      feed.dispose();
      c.dispose();
    });

    test('source respects the cap and prepend preserves the viewport', () {
      final c = ChartController();
      final feed = SampleFeed(c, initial: 10000)..setMaxBars(1000);
      expect(c.bars.length, 1000);
      expect(feed.source.length, 1000);
      feed.push(append: true);
      expect(c.bars.length, 1000);
      expect(feed.source.length, 1000);
      feed.setMaxBars(null);
      c.viewport.attach(500);
      c.viewport.setRightIndex(800);
      final before = c.viewport.rightIndex;
      final time = c.bars[before.floor()].time;
      feed.loadHistory();
      expect(c.viewport.rightIndex, before + 200);
      expect(c.bars[c.viewport.rightIndex.floor()].time, time);
      feed.dispose();
      c.dispose();
    });

    test('a transformed push keeps the crosshair the user is holding', () {
      final c = ChartController();
      final feed = SampleFeed(c, initial: 200, transform: (src) => List.of(src));
      final time = c.bars[150].time;
      c.crosshair.value = CrosshairState(time: time, position: const Offset(100, 100));
      feed
        ..push()
        ..push(append: true);
      expect(c.crosshair.value?.time, time);
      feed.dispose();
      c.dispose();
    });

    test('blocked feed ignores every data operation', () {
      final c = ChartController();
      final feed = SampleFeed(c, initial: 100)..blocked = () => true;
      feed
        ..push(append: true)
        ..loadHistory()
        ..reset(500);
      expect(c.bars.length, 100);
      feed.dispose();
      c.dispose();
    });

    test('generated data is deterministic across prepend', () {
      expect(SampleData.generate(-5, 10).map((b) => b.close), [
        for (var i = -5; i < 5; i++) SampleData.barAt(i).close,
      ]);
      expect(SampleData.indexOf(SampleData.barAt(-7)), -7);
    });
  });

  test('every entry is searchable by its id', () {
    for (final SampleEntry e in allSamples()) {
      expect(e.matches(e.id), isTrue);
    }
  });

  testWidgets('the sample back-to-latest button restores following after looking at history', (
    tester,
  ) async {
    await _open(tester, 'realtime');
    await _tapToggle(tester, S.current.realtimeAutoPush);
    final c = _chart(tester).controller;
    final g = await tester.startGesture(tester.getCenter(find.byType(KChart).first));
    for (var i = 0; i < 10; i++) {
      await g.moveBy(const Offset(30, 0));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await tester.pump(const Duration(milliseconds: 200));
    await g.up();
    await tester.pumpAndSettle();
    expect(c.viewport.atLatest, isFalse);

    await tester.tap(find.widgetWithText(TextButton, S.current.sampleBackToLatest));
    await tester.pumpAndSettle();
    final r0 = c.viewport.rightIndex;
    final add = find.widgetWithText(FilledButton, S.current.realtimeAppend);
    await tester.ensureVisible(add);
    await tester.tap(add);
    await tester.pumpAndSettle();
    expect(c.viewport.rightIndex, closeTo(r0 + 1, 1e-6));
  });
}
