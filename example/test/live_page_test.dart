import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:klinex_example/l10n/l10n.dart';
import 'package:klinex_example/page/live/live_controller.dart';
import 'package:klinex_example/page/live/live_page.dart';
import 'package:klinex_example/pro/live_pro.dart';
import 'package:klinex_example/socket/binance_public_ws.dart';
import 'package:klinex_example/widget/live_style.dart';

import 'support/fake_market.dart';

void main() {
  late FakeMarket market;

  setUp(() => market = FakeMarket()..install());
  tearDown(FakeMarket.uninstall);

  Future<LiveController> openPage(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(414, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final controller = Get.put(LiveController());
    addTearDown(() {
      Get.delete<LiveController>(force: true);
      isLiveDark.value = false;
    });
    await tester.pumpWidget(
      GetMaterialApp(
        builder: FlutterSmartDialog.init(),
        home: LivePage(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    return controller;
  }

  /// Drops toasts and the page, then lets pending timers and animations finish.
  Future<void> closePage(WidgetTester tester) async {
    // Not awaited: the dismiss future waits on a real-time animation the fake clock never runs.
    SmartDialog.dismiss(status: SmartStatus.allToast);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpWidget(const SizedBox());
    Get.delete<LiveController>(force: true);
    await tester.pump(const Duration(seconds: 3));
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    await tester.ensureVisible(find.text(text).last);
    await tester.tap(find.text(text).last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets('loads history, subscribes and applies kline / book pushes', (tester) async {
    final controller = await openPage(tester);
    expect(controller.hasBars.value, isTrue);
    expect(controller.chart.bars, hasLength(market.count));
    expect(BinancePublicWs.instance.connected.value, isTrue);
    final subscribed = market.socket.sent.expand((m) => m['params'] as List).toSet();
    expect(subscribed, containsAll(['btcusdt@kline_1m', 'btcusdt@bookTicker']));

    market.pushKline(time: market.lastTime, close: 120);
    market.pushKline(time: market.lastTime + FakeMarket.minute, close: 121);
    market.pushBook();
    // Ignored frames: server error, unknown event, other symbol, garbage.
    market.socket.incoming
      ..add(jsonEncode({'code': 2, 'msg': 'bad'}))
      ..add(jsonEncode({'e': 'trade', 's': 'BTCUSDT'}))
      ..add('not json');
    market.pushKline(symbol: 'ETHUSDT', time: market.lastTime);
    await tester.pump(const Duration(milliseconds: 100));
    expect(controller.chart.bars, hasLength(market.count + 1));
    expect(controller.chart.bars.last.close, 121);
    expect(controller.feed.book.value?.bid, 104);

    BinancePublicWs.instance.checkAlive();
    expect(market.socket.sent.last['method'], 'LIST_SUBSCRIPTIONS');
    await closePage(tester);
  });

  testWidgets('interval bar, More panel and symbol switch reload the series', (tester) async {
    final controller = await openPage(tester);

    await tapText(tester, intervalLabel('1h'));
    expect(controller.interval.value, '1h');

    await tapText(tester, S.current.liveIntervalMore);
    await tapText(tester, intervalLabel('5m'));
    expect(controller.interval.value, '5m');
    expect(find.text(S.current.liveIntervalMore), findsNothing);

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tapText(tester, symbolDisplayName('eth_usdt'));
    expect(controller.symbol.value, 'eth_usdt');
    expect(controller.hasBars.value, isTrue);
    expect(market.requests.where((r) => r == 'feed._loadHistory'), hasLength(4));
    await closePage(tester);
  });

  testWidgets('first-load failure shows retry, tapping it reloads', (tester) async {
    market.queued.add(null);
    final controller = await openPage(tester);
    expect(controller.hasError.value, isTrue);
    final retry = find.textContaining(S.current.liveTapToRetry);
    expect(retry, findsOneWidget);

    await tester.tap(retry);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(controller.hasError.value, isFalse);
    expect(controller.hasBars.value, isTrue);
    await closePage(tester);
  });

  testWidgets('reload failure of the same series only shows a notice', (tester) async {
    final controller = await openPage(tester);
    market.queued.add(null);
    await controller.feed.resync();
    await tester.pump();
    expect(controller.hasBars.value, isTrue);
    expect(controller.hasError.value, isFalse);
    market.queued.add(const []);
    await controller.feed.resync();
    await tester.pump();
    expect(controller.hasBars.value, isTrue);
    await closePage(tester);
  });

  testWidgets('reconnects after a drop and repairs the gap', (tester) async {
    final controller = await openPage(tester);
    final first = market.socket;
    await first.incoming.close();
    await tester.pump();
    expect(BinancePublicWs.instance.connected.value, isFalse);
    expect(find.text(S.current.liveConnecting), findsOneWidget);
    expect(controller.feed.book.value, isNull);

    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(milliseconds: 100));
    expect(market.channels, hasLength(2));
    expect(BinancePublicWs.instance.connected.value, isTrue);
    expect(market.requests, contains('feed._repairGap'));

    controller.feed.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await tester.pump(const Duration(milliseconds: 100));
    await closePage(tester);
  });

  testWidgets('loadMore pages history until the exchange runs out', (tester) async {
    final controller = await openPage(tester);
    await controller.feed.loadMore();
    expect(controller.chart.bars.length, greaterThan(market.count));
    market.queued.add(const []);
    await controller.feed.loadMore();
    await controller.feed.loadMore();
    expect(market.requests.where((r) => r == 'feed.loadMore'), hasLength(2));
    await closePage(tester);
  });

  testWidgets('indicator bar toggles indicators; pro ones only when unlocked', (tester) async {
    final controller = await openPage(tester);
    await tapText(tester, 'EMA');
    expect(controller.main, contains('EMA'));
    await tapText(tester, 'MACD');
    expect(controller.sub, contains('MACD'));
    await tapText(tester, 'MACD');
    expect(controller.sub, isNot(contains('MACD')));

    final proMain = LiveController.mainOptions.last;
    await tester.dragUntilVisible(
      find.text(proMain),
      find.byType(SingleChildScrollView).at(2),
      const Offset(-200, 0),
    );
    await tapText(tester, proMain);
    await tester.pump(const Duration(milliseconds: 100));
    // Locked in the free edition (toast), a normal toggle in the paid one.
    expect(controller.main.contains(proMain), LivePro.unlocked);
    expect(find.text(S.current.proLockFeature), LivePro.unlocked ? findsNothing : findsOneWidget);
    await closePage(tester);
  });

  testWidgets('settings sheet drives the chart toggles', (tester) async {
    final controller = await openPage(tester);
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await tapText(tester, S.current.liveAutoFollow);
    expect(controller.autoFollow.value, isFalse);
    await tapText(tester, S.current.liveYAxisOutside);
    expect(controller.yAxisOutside.value, isFalse);
    await tapText(tester, S.current.liveBookPrice);
    expect(controller.showBookPrice.value, isFalse);

    // Switch order in the sheet: Heikin-Ashi (pro), log scale, percent scale.
    for (var i = 0; i < 3; i++) {
      await tester.ensureVisible(find.byType(Switch).at(i));
      await tester.tap(find.byType(Switch).at(i));
      await tester.pump();
    }
    expect(controller.pro.heikinAshi.value, LivePro.unlocked);
    expect(controller.isLog.value, isTrue);
    expect(controller.percent.value, isTrue);

    await tapText(tester, S.current.liveSeriesCandle);
    await tapText(tester, S.current.liveSeriesLine);
    expect(controller.seriesKind.value, 'line');

    await tapText(tester, S.current.liveTimeZoneDevice);
    await tapText(tester, 'UTC');
    expect(controller.utcOffset.value, Duration.zero);

    await tester.drag(find.byType(Slider), const Offset(60, 0));
    await tester.pump();
    expect(controller.chartHeight.value, isNot(300));
    expect(tester.takeException(), isNull);
    await closePage(tester);
  });

  testWidgets('indicator settings list opens every free detail sheet', (tester) async {
    final controller = await openPage(tester);
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tapText(tester, S.current.liveGoToSettings);
    expect(find.text(S.current.indicatorSettingsTitle), findsOneWidget);

    for (final name in ['MA', 'EMA', 'BOLL', 'MACD', 'KDJ', 'RSI', 'WR']) {
      await tapText(tester, name);
      // Edit the first numeric field, then close the detail to return to the list.
      final fields = find.byType(TextFormField);
      if (fields.evaluate().isNotEmpty) {
        await tester.enterText(fields.first, '9');
        await tester.pump();
      }
      await tester.tap(find.byIcon(Icons.arrow_back_ios_new).last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text(S.current.indicatorSettingsTitle), findsOneWidget, reason: name);
    }
    expect(controller.indRev.value, greaterThan(0));
    await closePage(tester);
  });

  testWidgets('theme toggle flips the palette', (tester) async {
    await openPage(tester);
    await tester.tap(find.byTooltip(S.current.themeSwitchToDark));
    await tester.pump();
    expect(isLiveDark.value, isTrue);
    expect(find.byTooltip(S.current.themeSwitchToLight), findsOneWidget);
    await closePage(tester);
  });
}
