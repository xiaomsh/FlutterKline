import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:klinex/klinex.dart';
import 'package:klinex_example/api/eastmoney_api.dart';
import 'package:klinex_example/l10n/l10n.dart';
import 'package:klinex_example/page/home/home_page.dart';
import 'package:klinex_example/page/setting/sample/stock_sample_data.dart';
import 'package:klinex_example/page/setting/setting_page.dart';
import 'package:klinex_example/page/stock/stock_controller.dart';
import 'package:klinex_example/page/stock/stock_page.dart';
import 'package:klinex_example/page/stock/stock_symbols.dart';
import 'package:klinex_example/pro/stock_pro.dart';
import 'package:klinex_example/route.dart';
import 'package:klinex_example/widget/live_style.dart';

/// Beijing wall-clock text of a UTC instant, as Eastmoney sends it.
String beijing(int ms, {bool date = false}) {
  final t = DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true).add(const Duration(hours: 8));
  String p2(int v) => v.toString().padLeft(2, '0');
  final d = '${t.year}-${p2(t.month)}-${p2(t.day)}';
  return date ? d : '$d ${p2(t.hour)}:${p2(t.minute)}';
}

/// Fake Eastmoney backend: minutes of one session day and daily rows, adjustable between polls.
class FakeEastmoney {
  int minutes = 120;
  int dayOffset = 0;
  double preClose = 10;
  bool fail = false;
  double lastDailyClose = 12;

  /// New daily rows after the last one (a new trading day), closing at [lastDailyClose].
  int appendDays = 0;

  /// Moves the last row's date forward, as a weekly / monthly bar does on each trading day.
  int shiftLastDays = 0;
  final calls = <String>[];

  StockMarket market = StockMarket.a;

  Future<dynamic> get(String path, Map<String, dynamic> params) async {
    calls.add(
      [path, params['secid'], params['klt'] ?? params['ndays'], ?params['lmt']].join(' '),
    );
    if (fail) throw const FormatException('offline');
    final secid = params['secid'] as String;
    market = stockSymbols.firstWhere((s) => s.secid == secid).market;
    if (path.startsWith('trends')) {
      final bars = StockSampleData.intraday(
        market.session,
        preClose: 10,
        minutes: minutes,
        dayOffset: dayOffset,
      );
      // String body exercises the JSON decode path
      return jsonEncode({
        'data': {
          'name': 'Name $secid',
          'decimal': 2,
          'preClose': preClose,
          'hisPrePrices': [
            {'date': 20261105, 'prePrice': 9.5},
          ],
          'trends': [
            for (final b in bars)
              '${beijing(b.time)},${b.open},${b.close},${b.high},${b.low},${b.vol},'
                  '${b.amount},${b.close}',
            '${beijing(market.session.timeOf(StockSampleData.day(market.session), 0) - 3600000)},'
                '0,10,10,10,1,10,10',
          ],
        },
      });
    }
    const day = 86400000;
    final rows = StockSampleData.daily(60);
    final last = rows.removeLast();
    rows.add(last.copyWith(time: last.time + shiftLastDays * day, close: lastDailyClose));
    for (var d = 1; d <= appendDays; d++) {
      rows.add(rows.last.copyWith(time: rows.last.time + day, close: lastDailyClose));
    }
    final limit = params['lmt'] as int;
    return {
      'data': {
        'name': 'Daily $secid',
        'klines': [
          for (final b in rows.skip(math.max(0, rows.length - limit)))
            '${beijing(b.time, date: true)},${b.open},${b.close},${b.high},${b.low},${b.vol},1',
        ],
      },
    };
  }
}

void main() {
  late FakeEastmoney fake;

  setUp(() {
    fake = FakeEastmoney();
    EastmoneyApi.debugGet = fake.get;
    // Tuesday 2026-11-10 10:30 Beijing: A-share and HK sessions are open
    StockController.clock = () => DateTime.utc(2026, 11, 10, 2, 30).millisecondsSinceEpoch;
    StockController.pollEvery = const Duration(seconds: 1);
  });

  tearDown(() {
    EastmoneyApi.debugGet = null;
    StockController.clock = () => DateTime.now().millisecondsSinceEpoch;
    StockController.pollEvery = const Duration(seconds: 5);
  });

  group('EastmoneyApi parsing', () {
    test('parses Beijing times, zero opens and klines', () {
      expect(
        EastmoneyApi.parseBeijing('2026-11-10 09:30'),
        DateTime.utc(2026, 11, 10, 1, 30).millisecondsSinceEpoch,
      );
      expect(
        EastmoneyApi.parseBeijing('2026-11-10'),
        DateTime.utc(2026, 11, 9, 16).millisecondsSinceEpoch,
      );
      final t = EastmoneyApi.parseTrends({
        'data': {
          'name': 'X',
          'preClose': 9.5,
          'trends': ['2026-11-10 09:30,0.00,10.0,10.0,10.0,5,50.0,10.0'],
        },
      });
      expect(t.name, 'X');
      expect(t.decimals, 2);
      expect(t.bars.single.open, 10);
      expect(t.bars.single.amount, 50);
      expect(t.firstPreClose, 9.5);
      final five = EastmoneyApi.parseTrends({
        'data': {
          'preClose': 9.5,
          'hisPrePrices': [
            {'date': 20261105, 'prePrice': 9.1},
            {'date': 20261106, 'prePrice': 9.3},
          ],
          'trends': <String>[],
        },
      });
      expect(five.firstPreClose, 9.1);
      final k = EastmoneyApi.parseKlines('{"data":{"klines":["2026-11-10,1,2,3,0.5,10,20"]}}');
      expect(k.name, '');
      expect(k.bars.single.close, 2);
    });

    test('rejects malformed responses', () {
      expect(() => EastmoneyApi.parseKlines({'data': null}), throwsFormatException);
      expect(() => EastmoneyApi.parseKlines({'data': {}}), throwsFormatException);
      expect(() => EastmoneyApi.parseTrends({'data': {}}), throwsFormatException);
      expect(
        () => EastmoneyApi.parseKlines({
          'data': {
            'klines': ['2026-11-10,1,2'],
          },
        }),
        throwsFormatException,
      );
    });

    test('skips malformed rows but keeps the valid ones', () {
      final k = EastmoneyApi.parseKlines({
        'data': {
          'klines': [
            '2026-11-09,1,2,3,0.5,10,20',
            '2026-11-10,-,-,-,-,0,0',
            'bad-date,1,2,3,0.5,10,20',
          ],
        },
      });
      expect(k.bars, hasLength(1));
      expect(
        EastmoneyApi.parseKlines({
          'data': {'klines': <String>[]},
        }).bars,
        isEmpty,
      );
    });

    test('failures surface as null through safeCall', () async {
      fake.fail = true;
      Object? error;
      final r = await EastmoneyApi.kline(
        '1.600519',
        from: 'test',
        klt: 101,
        onError: (e) => error = e,
      );
      expect(r, isNull);
      expect(error, isNotNull);
      expect(await EastmoneyApi.trends('1.600519', from: 'test'), isNull);
    });
  });

  group('StockPage', () {
    Future<StockController> openPage(WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(414, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final controller = Get.put(StockController());
      addTearDown(() {
        Get.delete<StockController>(force: true);
        isLiveDark.value = false;
      });
      await tester.pumpWidget(
        GetMaterialApp(builder: FlutterSmartDialog.init(), home: StockPage()),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      return controller;
    }

    Future<void> closePage(WidgetTester tester) async {
      SmartDialog.dismiss(status: SmartStatus.allToast);
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpWidget(const SizedBox());
      Get.delete<StockController>(force: true);
      await tester.pump(const Duration(seconds: 3));
    }

    Future<void> tapText(WidgetTester tester, String text) async {
      await tester.ensureVisible(find.text(text).last);
      await tester.tap(find.text(text).last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
    }

    KChart chart(WidgetTester tester) => tester.widget<KChart>(find.byType(KChart));

    testWidgets('intraday loads on fixed slots with levels and polls new minutes', (tester) async {
      final c = await openPage(tester);
      expect(c.loading.value, isFalse);
      expect(c.chart.bars, hasLength(120));
      expect(find.text('Name 1.600519 600519'), findsOneWidget);
      expect(find.text(S.current.stockTrading), findsOneWidget);
      expect(chart(tester).slotAxis, isA<IntradayAxis>());
      expect(chart(tester).percentBase, 10);
      expect(chart(tester).mainRange, isNotNull);
      expect(c.levels.levels.map((l) => l.label), [
        S.current.stockPrevClose,
        S.current.stockLimitUp,
        S.current.stockLimitDown,
      ]);
      expect(c.chart.indicators.list.first, isA<AveragePrice>());

      fake.minutes = 125;
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      expect(c.chart.bars, hasLength(125));

      // A new day replaces the data instead of appending
      fake
        ..dayOffset = 1
        ..minutes = 3;
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      expect(c.chart.bars, hasLength(3));

      // Out of trading hours: no polling
      StockController.clock = () => DateTime.utc(2026, 11, 10, 12).millisecondsSinceEpoch;
      final before = fake.calls.length;
      await tester.pump(const Duration(seconds: 2));
      expect(fake.calls.length, before);
      await closePage(tester);
    });

    testWidgets('daily and weekly bars, quotes, limit marks and polling', (tester) async {
      final c = await openPage(tester);
      await tapText(tester, S.current.stockPeriodDay);
      await tester.pump(const Duration(milliseconds: 100));
      expect(c.period.value, StockPeriod.day);
      expect(chart(tester).slotAxis, isNull);
      expect(chart(tester).percentBase, isNull);
      expect(c.limitMarks.limit, PriceLimit.mainBoard);
      expect(c.levels.levels, isEmpty);
      expect(find.text('Daily 1.600519 600519'), findsOneWidget);
      final count = c.chart.bars.length;

      final prev = c.chart.bars[count - 2].close;
      expect(c.preClose.value, prev);

      fake.lastDailyClose = 12.5;
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      expect(c.chart.bars, hasLength(count));
      expect(c.chart.bars.last.close, 12.5);
      expect(c.lastPrice.value, 12.5);
      expect(c.preClose.value, prev);

      // A new trading day closes the last bar and appends one, without a reload
      fake.appendDays = 1;
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      expect(c.chart.bars, hasLength(count + 1));
      expect(fake.calls.last, 'kline/get 1.600519 101 2');
      expect(c.preClose.value, 12.5);
      fake.appendDays = 0;

      // Weekly bars: the quote still comes from daily bars
      await tapText(tester, S.current.stockPeriodWeek);
      expect(c.limitMarks.limit, isNull);
      expect(
        fake.calls.reversed.take(2),
        containsAll(['kline/get 1.600519 102 300', 'kline/get 1.600519 101 2']),
      );
      expect(c.lastPrice.value, 12.5);
      expect(c.preClose.value, prev);
      final weeks = c.chart.bars.length;
      fake.lastDailyClose = 13;
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      await tester.pump();
      expect(c.chart.bars, hasLength(weeks));
      expect(c.chart.bars.last.close, 13);
      expect(c.lastPrice.value, 13);

      // The weekly bar's date moves with each trading day: reload
      int loads() => fake.calls.where((c) => c == 'kline/get 1.600519 102 300').length;
      final before = loads();
      fake.shiftLastDays = 1;
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      await tester.pump();
      expect(loads(), before + 1);
      expect(c.chart.bars.last.time, greaterThan(c.chart.bars[weeks - 2].time + 86400000));

      // Adjustment is a paid feature
      await tapText(tester, S.current.stockAdjustNone);
      await tester.pumpAndSettle();
      await tester.tap(find.text(S.current.stockAdjustForward).last);
      await tester.pumpAndSettle();
      expect(c.adjust.value, StockPro.unlocked ? StockAdjust.forward : StockAdjust.none);
      await closePage(tester);
    });

    testWidgets('five-day is locked in the free edition', (tester) async {
      final c = await openPage(tester);
      await tapText(tester, S.current.stockPeriodFiveDay);
      await tester.pump(const Duration(milliseconds: 100));
      if (!StockPro.unlocked) {
        expect(c.period.value, StockPeriod.intraday);
        expect(find.text(S.current.proLockFeature), findsOneWidget);
      } else {
        expect(c.period.value, StockPeriod.fiveDay);
        // Charted against the close before the first day, quoted against yesterday's close
        expect(c.preClose.value, 10);
        expect(c.chartBase.value, 9.5);
        expect(chart(tester).percentBase, 9.5);
        expect(chart(tester).slotAxis, isNot(isA<IntradayAxis>()));
        expect(c.levels.levels.map((l) => l.price), [9.5]);
      }
      await closePage(tester);
    });

    testWidgets('five-day polling appends today and reloads on a new day', (tester) async {
      final c = await openPage(tester);
      c.period.value = StockPeriod.fiveDay;
      await c.load();
      expect(c.chart.bars, hasLength(120));
      expect(fake.calls.last, endsWith(' 5'));

      fake.minutes = 125;
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      expect(fake.calls.last, endsWith(' 1'), reason: 'polls today only');
      expect(c.chart.bars, hasLength(125));
      expect(c.lastPrice.value, c.chart.bars.last.close);

      // A new day shifts the window: all five days are loaded again
      fake
        ..dayOffset = 1
        ..minutes = 3;
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      await tester.pump();
      expect(fake.calls.last, endsWith(' 5'));
      expect(c.chart.bars, hasLength(3));
      await closePage(tester);
    });

    testWidgets('a poll answered after the page closed is dropped', (tester) async {
      final c = await openPage(tester);
      final gate = Completer<void>();
      final get = fake.get;
      EastmoneyApi.debugGet = (path, params) async {
        await gate.future;
        return get(path, params);
      };
      fake.minutes = 130;
      await tester.pump(const Duration(seconds: 1));
      c.onClose();
      gate.complete();
      await tester.pump();
      expect(c.chart.bars, hasLength(120));
      await tester.pumpWidget(const SizedBox());
      Get.delete<StockController>(force: true);
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('pauses in the background and reloads on resume', (tester) async {
      final c = await openPage(tester);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      final calls = fake.calls.length;
      await tester.pump(const Duration(seconds: 3));
      expect(fake.calls.length, calls, reason: 'no polling in the background');
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(fake.calls.length, calls + 1, reason: 'one reload on resume');
      expect(c.loading.value, isFalse);
      await closePage(tester);
    });

    testWidgets('switches markets, symbols and colors', (tester) async {
      final c = await openPage(tester);
      await tapText(tester, StockMarket.hk.label);
      expect(c.symbol.value.code, '00700');
      expect(c.redUp.value, isTrue);
      expect(c.levels.levels, hasLength(1)); // no limits in Hong Kong
      await tapText(tester, '09988');
      expect(c.symbol.value.code, '09988');
      await tapText(tester, StockMarket.us.label);
      expect(c.symbol.value.code, 'AAPL');
      expect(c.redUp.value, isFalse);
      expect(chart(tester).theme.up, KLineTheme.light().up);
      await tester.tap(find.byTooltip(S.current.stockRedUp));
      await tester.pump();
      expect(c.redUp.value, isTrue);
      // Re-selecting the current market / symbol / period is a no-op
      final calls = fake.calls.length;
      c
        ..selectMarket(StockMarket.us)
        ..selectSymbol(c.symbol.value)
        ..selectPeriod(StockPeriod.intraday)
        ..selectAdjust(StockAdjust.none);
      expect(fake.calls.length, calls);
      await closePage(tester);
    });

    testWidgets('missing previous close and failures with retry', (tester) async {
      fake.preClose = 0;
      final c = await openPage(tester);
      expect(c.preClose.value, isNull);
      expect(c.levels.levels, isEmpty);
      expect(c.mainRange, isNull);

      fake.fail = true;
      await c.load();
      await tester.pump();
      expect(c.hasError.value, isTrue);
      expect(find.text(S.current.liveTapToRetry), findsOneWidget);
      fake.fail = false;
      await tester.tap(find.text(S.current.liveTapToRetry));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(c.hasError.value, isFalse);
      await closePage(tester);
    });

    testWidgets('home entry opens the stock page', (tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          builder: FlutterSmartDialog.init(),
          getPages: pages,
          home: const HomePage(),
        ),
      );
      await tester.tap(find.text(S.current.homeStocks));
      await tester.pumpAndSettle();
      expect(find.byType(StockPage), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      Get.delete<StockController>(force: true);
      await tester.pump(const Duration(seconds: 3));
    });
  });

  group('stock samples', () {
    Future<void> open(WidgetTester tester, String id) async {
      await tester.binding.setSurfaceSize(const Size(1280, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          builder: FlutterSmartDialog.init(),
          home: SettingPage(entryId: id),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(S.current.controlsEquivalentCode));
      await tester.pumpAndSettle();
    }

    KChart chart(WidgetTester tester) => tester.widget<KChart>(find.byType(KChart).first);

    /// Scrolls to the middle first: at the top edge the sticky header would take the tap.
    Future<void> reveal(WidgetTester tester, Finder f) async {
      await Scrollable.ensureVisible(tester.element(f), alignment: 0.5);
      await tester.pumpAndSettle();
    }

    Future<void> toggle(WidgetTester tester, String label) async {
      final tile = find.widgetWithText(SwitchListTile, label);
      await reveal(tester, tile);
      await tester.tap(tile);
      await tester.pump();
    }

    Future<void> choose(WidgetTester tester, String current, String next) async {
      await reveal(tester, find.text(current).last);
      await tester.tap(find.text(current).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text(next).last);
      await tester.pumpAndSettle();
    }

    testWidgets('intraday sample switches markets and toggles every option', (tester) async {
      await open(tester, 'intraday');
      expect(chart(tester).slotAxis!.slotCount, 241);
      expect(chart(tester).controller.bars, hasLength(241));
      final range = chart(tester).mainRange;
      await tester.pump();
      expect(chart(tester).mainRange, range, reason: 'equal across rebuilds');

      await toggle(tester, S.current.intradayLimitsInRange);
      expect(chart(tester).mainRange, isNot(range));
      await toggle(tester, S.current.intradayLimits);
      await toggle(tester, S.current.intradayPercent);
      expect(chart(tester).yAxisPosition, YAxisPosition.outside);
      await toggle(tester, S.current.intradayAverage);
      expect(chart(tester).controller.indicators.list.whereType<AveragePrice>(), isEmpty);
      await toggle(tester, S.current.stockRedUp);
      expect(chart(tester).theme.up, KLineTheme.light().up);
      expect(find.textContaining('slotAxis: IntradayAxis(session)'), findsOneWidget);

      await toggle(tester, S.current.intradayLive);
      expect(chart(tester).controller.bars, hasLength(150));
      await tester.pump(const Duration(milliseconds: 650));
      expect(chart(tester).controller.bars, hasLength(152));
      await toggle(tester, S.current.intradayLive);
      expect(chart(tester).controller.bars, hasLength(241));

      await choose(tester, StockMarket.a.label, StockMarket.us.label);
      expect(chart(tester).slotAxis!.slotCount, 391);
      await choose(tester, StockMarket.us.label, StockMarket.hk.label);
      expect(chart(tester).slotAxis!.slotCount, 331);

      // Live simulation runs to the close and stops
      await toggle(tester, S.current.intradayLive);
      await tester.pump(const Duration(seconds: 60));
      expect(chart(tester).controller.bars, hasLength(331));
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('daily sample switches boards and marks', (tester) async {
      await open(tester, 'stock-daily');
      final marks = chart(tester).controller.overlays.whereType<LimitMarksOverlay>().single;
      expect(marks.limit, PriceLimit.mainBoard);
      expect(marks.upLabel, S.current.stockLimitUpShort);
      expect(
        [for (var i = 0; i < 240; i++) marks.stateAt(chart(tester).controller.bars, i)],
        containsAll([1, -1]),
      );
      await choose(tester, S.current.stockBoardMain, S.current.stockBoardGrowth);
      expect(marks.limit, PriceLimit.growth);
      expect(find.textContaining('PriceLimit.growth'), findsOneWidget);
      await toggle(tester, S.current.stockLimitUp);
      expect(marks.upLabel, isNull);
      await toggle(tester, S.current.stockLimitMarks);
      expect(marks.limit, isNull);
      await toggle(tester, S.current.stockRedUp);
      expect(chart(tester).theme.up, KLineTheme.light().up);
      await choose(tester, S.current.stockBoardGrowth, S.current.stockBoardSt);
      await tester.pumpWidget(const SizedBox());
    });
  });
}
