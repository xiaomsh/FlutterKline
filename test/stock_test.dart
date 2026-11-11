import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klinex/klinex.dart';
import 'package:klinex/src/indicator/compute_worker.dart';

/// Stock support: trading sessions, intraday slot axis, average price, price levels, limits,
/// red-up theme and the KChart parameters behind them.

int bj(int y, int mo, int d, int h, int mi) =>
    DateTime.utc(y, mo, d, h, mi).subtract(const Duration(hours: 8)).millisecondsSinceEpoch;

Bar bar(int time, double close, {double vol = 10, double? amount, double? open}) => Bar(
  time: time,
  open: open ?? close,
  high: close + 0.1,
  low: close - 0.1,
  close: close,
  vol: vol,
  amount: amount,
);

/// One A-share day up to [slots] minutes (2026-11-10), a gentle sine walk around 10.
List<Bar> aShareDay(int slots, {int day = 10}) {
  final s = TradingSession.cnA;
  final d = s.dayOf(bj(2026, 11, day, 10, 0));
  return [
    for (var i = 0; i < slots; i++)
      bar(s.timeOf(d, i), 10 + 0.3 * (i % 40) / 40, vol: 100 + i.toDouble()),
  ];
}

class _DayAxis extends SlotAxis {
  @override
  int get slotCount => 482;

  @override
  List<SlotTick> get ticks => const [
    SlotTick(0, '11-09', major: true),
    SlotTick(240.5, '11-10', major: true),
    SlotTick(120, '11:30/13:00'),
    SlotTick(360, ''),
  ];
}

void main() {
  group('TradingSession', () {
    test('slot counts match the exchanges', () {
      expect(TradingSession.cnA.slotsPerDay, 241);
      expect(TradingSession.hk.slotsPerDay, 331);
      expect(TradingSession.us.slotsPerDay, 391);
      expect(TradingSession.cnA.toString(), 'TradingSession(A)');
    });

    test('US Eastern DST boundaries', () {
      int utc(int mo, int d, int h, int mi) =>
          DateTime.utc(2026, mo, d, h, mi).millisecondsSinceEpoch;
      expect(usEasternOffset(utc(1, 15, 12, 0)), const Duration(hours: -5));
      expect(usEasternOffset(utc(7, 1, 12, 0)), const Duration(hours: -4));
      // 2026-03-08 is the second Sunday of March; 02:00 EST = 07:00 UTC
      expect(usEasternOffset(utc(3, 8, 6, 59)), const Duration(hours: -5));
      expect(usEasternOffset(utc(3, 8, 7, 0)), const Duration(hours: -4));
      // 2026-11-01 is the first Sunday of November; 02:00 EDT = 06:00 UTC
      expect(usEasternOffset(utc(11, 1, 5, 59)), const Duration(hours: -4));
      expect(usEasternOffset(utc(11, 1, 6, 0)), const Duration(hours: -5));
    });

    test('slotOf / timeOf map minutes, skip breaks and round-trip', () {
      final s = TradingSession.cnA;
      expect(s.slotOf(bj(2026, 11, 10, 9, 30)), 0);
      expect(s.slotOf(bj(2026, 11, 10, 9, 31)), 1);
      expect(s.slotOf(bj(2026, 11, 10, 11, 30)), 120);
      expect(s.slotOf(bj(2026, 11, 10, 13, 0)), isNull);
      expect(s.slotOf(bj(2026, 11, 10, 13, 1)), 121);
      expect(s.slotOf(bj(2026, 11, 10, 15, 0)), 240);
      expect(s.slotOf(bj(2026, 11, 10, 15, 1)), isNull);
      final day = s.dayOf(bj(2026, 11, 10, 9, 30));
      for (final slot in [0, 1, 120, 121, 240]) {
        expect(s.slotOf(s.timeOf(day, slot)), slot);
        expect(s.dayOf(s.timeOf(day, slot)), day);
      }
      // US in summer: 09:30 ET = 13:30 UTC
      final us = TradingSession.us;
      final summer = DateTime.utc(2026, 7, 1, 13, 30).millisecondsSinceEpoch;
      expect(us.slotOf(summer), 0);
      expect(us.timeOf(us.dayOf(summer), 0), summer);
      final winter = DateTime.utc(2026, 1, 15, 14, 30).millisecondsSinceEpoch;
      expect(us.slotOf(winter), 0);
      expect(us.timeOf(us.dayOf(winter), 390), winter + 390 * 60000);
    });

    test('isTrading and formatTime', () {
      final s = TradingSession.cnA;
      expect(s.isTrading(bj(2026, 11, 10, 10, 0)), isTrue);
      expect(s.isTrading(bj(2026, 11, 10, 12, 0)), isFalse);
      expect(s.isTrading(bj(2026, 11, 14, 10, 0)), isFalse); // Saturday
      expect(s.formatTime(bj(2026, 11, 10, 9, 5)), '09:05');
      expect(s.formatTime(bj(2026, 11, 10, 14, 30), date: true), '11-10 14:30');
      expect(TradingSession.formatMinute(780), '13:00');
    });

    test('normalize fills gaps, drops out-of-session bars and keeps the tail empty', () {
      final s = TradingSession.cnA;
      final out = s.normalize([
        bar(bj(2026, 11, 10, 9, 31), 10.2),
        bar(bj(2026, 11, 10, 12, 0), 99), // lunch break
        bar(bj(2026, 11, 10, 9, 34) + 15000, 10.4), // seconds are trimmed
      ], preClose: 10);
      expect(out.length, 5);
      expect(out[0].close, 10); // opening slot from the previous close
      expect(out[0].vol, 0);
      expect(out[1].close, 10.2);
      expect(out[2].close, 10.2);
      expect(out[3].close, 10.2);
      expect(out[4].close, 10.4);
      expect(out[4].time, bj(2026, 11, 10, 9, 34));
      expect(out.every((b) => s.slotOf(b.time) != null), isTrue);
    });

    test('normalize completes earlier days and uses the first open without preClose', () {
      final s = TradingSession.cnA;
      final out = s.normalize([
        bar(bj(2026, 11, 10, 9, 31), 10.2, open: 10.1),
        bar(bj(2026, 11, 9, 9, 30), 9.8),
        bar(bj(2026, 11, 9, 10, 0), 9.9),
      ]);
      expect(out.length, 241 + 2);
      expect(out.first.close, 9.8);
      expect(out[240].close, 9.9); // filled to the close
      expect(out[241].close, 9.9); // next day's open slot carries the last close
      expect(out.last.close, 10.2);
      expect(s.normalize(const []), isEmpty);
    });
  });

  group('IntradayAxis', () {
    test('A-share ticks at open, hours, lunch break and close', () {
      final axis = IntradayAxis(TradingSession.cnA);
      expect(axis.slotCount, 241);
      expect(
        [for (final t in axis.ticks) t.label],
        [
          '09:30',
          '10:30',
          '11:30/13:00',
          '14:00',
          '15:00',
        ],
      );
      expect([for (final t in axis.ticks) t.slot], [0, 60, 120, 180, 240]);
      expect(axis, IntradayAxis(TradingSession.cnA));
      expect(axis.hashCode, IntradayAxis(TradingSession.cnA).hashCode);
      expect(axis == IntradayAxis(TradingSession.cnA, stepMinutes: 30), isFalse);
      expect(axis == IntradayAxis(TradingSession.hk), isFalse);
    });

    test('HK and US ticks', () {
      final hk = IntradayAxis(TradingSession.hk).ticks;
      expect(hk.map((t) => t.label), contains('12:00/13:00'));
      expect(hk.last.slot, 330);
      final us = IntradayAxis(TradingSession.us, stepMinutes: 120).ticks;
      expect(us.map((t) => t.label).toList(), ['09:30', '11:30', '13:30', '15:30', '16:00']);
    });

    test('sessions without an opening slot tick between slots', () {
      final s = TradingSession(
        segments: const [(570, 690)],
        offsetAt: (_) => Duration.zero,
        openingSlot: false,
      );
      expect(s.slotsPerDay, 120);
      expect(s.slotAtMinute(570), -0.5);
      expect(s.slotAtMinute(2000), 119.5);
      final ticks = sessionDayTicks(s, offset: 120, openLabel: '11-10', openMajor: true);
      expect(ticks.first, const SlotTick(119.5, '11-10', major: true));
      expect(ticks.first.hashCode, const SlotTick(119.5, '11-10', major: true).hashCode);
      expect(ticks.first.toString(), contains('major'));
      expect(ticks.last.toString(), 'SlotTick(239.0, 11:30)');
    });
  });

  group('AveragePrice', () {
    List<double> run(Indicator ind, List<Bar> bars) {
      final store = IndicatorStore()..resize(bars.length);
      ind.computeAll(bars, store);
      final out = List<double>.of(store.series('avg'));
      // Incremental step equals the full computation
      ind.computeLast(bars, bars.length - 1, store);
      expect(store.series('avg').last, out.last);
      return out;
    }

    test('uses amount when present, close × vol otherwise', () {
      final avg = run(AveragePrice(volumeUnit: 100), [
        bar(bj(2026, 11, 10, 9, 30), 10, vol: 1, amount: 1000),
        bar(bj(2026, 11, 10, 9, 31), 12, vol: 1),
      ]);
      expect(avg[0], closeTo(10, 1e-9));
      expect(avg[1], closeTo((1000 + 1200) / 200, 1e-9));
    });

    test('zero volume shows the close until trades arrive; resets per day', () {
      final ind = AveragePrice(session: TradingSession.cnA, label: '均价');
      expect(ind.seriesLabels, ['均价']);
      expect(ind.id, contains('A'));
      expect(ind.target, PanelRef.main);
      expect(ind.seriesLineWidth, 1);
      expect(ind.warmupBars, 2);
      expect(ind.seriesColors.single, const Color(0xFFF0A732));
      final avg = run(ind, [
        bar(bj(2026, 11, 9, 14, 59), 9, vol: 0),
        bar(bj(2026, 11, 9, 15, 0), 8, vol: 0),
        bar(bj(2026, 11, 10, 9, 30), 11),
        bar(bj(2026, 11, 10, 9, 31), 13),
      ]);
      expect(avg[0], 9);
      expect(avg[1], 9);
      expect(avg[2], 11);
      expect(avg[3], 12);
      // Without a session the average spans both days
      final flat = run(AveragePrice(), [
        bar(bj(2026, 11, 9, 15, 0), 10),
        bar(bj(2026, 11, 10, 9, 30), 20),
      ]);
      expect(flat[1], 15);
    });
  });

  group('limits and ranges', () {
    test('PriceLimit rounds half up like the exchange', () {
      expect(PriceLimit.mainBoard.up(10.45), 11.50);
      expect(PriceLimit.mainBoard.down(10.45), 9.41);
      expect(PriceLimit.growth.up(10), 12);
      expect(PriceLimit.st.down(10), 9.5);
      expect(PriceLimit.bse.up(10), 13);
      expect(PriceLimit.mainBoard.isLimitUp(10.45, 11.5), isTrue);
      expect(PriceLimit.mainBoard.isLimitUp(10.45, 11.49), isFalse);
      expect(PriceLimit.mainBoard.isLimitDown(10.45, 9.41), isTrue);
      // Beyond the limit: IPO day without limits, unadjusted ex-rights day
      expect(PriceLimit.mainBoard.isLimitUp(10, 14), isFalse);
      expect(PriceLimit.mainBoard.isLimitDown(20, 12), isFalse);
      expect(PriceLimit.mainBoard.isLimitUp(0, 0.01), isFalse);
      expect(const PriceLimit(0.1), PriceLimit.mainBoard);
      expect(const PriceLimit(0.1).hashCode, PriceLimit.mainBoard.hashCode);
      expect(const PriceLimit(0.1, decimals: 3) == PriceLimit.mainBoard, isFalse);
    });

    test('StockRange is symmetric around the base and includes levels', () {
      expect(
        StockRange(symmetricAround: 10).apply(const MinMax(9.8, 10.5)).toString(),
        'MinMax(9.5, 10.5)',
      );
      const withLimits = StockRange(
        symmetricAround: 10,
        include: [11, 9, double.nan],
        margin: 0,
      );
      expect(withLimits.apply(const MinMax(9.8, 10.5)).toString(), 'MinMax(9.0, 11.0)');
      expect(
        withLimits,
        const StockRange(symmetricAround: 10, include: [11, 9, double.nan], margin: 0),
      );
      final padded = StockRange(include: [11]).apply(const MinMax(9, 10));
      expect(padded.min, 9);
      expect(padded.max, closeTo(11.06, 1e-9));
      final flat = StockRange(symmetricAround: 10).apply(const MinMax(10, 10));
      expect(flat.min, closeTo(9.99, 1e-9));
      expect(flat.max, closeTo(10.01, 1e-9));
      expect(StockRange(symmetricAround: 10).apply(MinMax.empty).span, closeTo(0.02, 1e-9));
      expect(
        StockRange(include: [12], margin: 0).apply(const MinMax(9, 10)).toString(),
        'MinMax(9.0, 12.0)',
      );
      expect(
        StockRange(symmetricAround: 0).apply(const MinMax(9, 10)).toString(),
        'MinMax(9.0, 10.0)',
      );
      expect(const StockRange(symmetricAround: 10), const StockRange(symmetricAround: 10));
      expect(
        const StockRange(include: [1, 2]).hashCode,
        StockRange(include: [1, 2]).hashCode,
      );
      expect(const StockRange(include: [1]) == const StockRange(include: [2]), isFalse);
      expect(const StockRange(margin: 0) == const StockRange(), isFalse);
      expect(const StockRange(symmetricAround: 1).toString(), contains('around: 1'));
    });

    test('LimitMarksOverlay detects limit closes from the previous close', () {
      final o = LimitMarksOverlay();
      final bars = [bar(0, 10), bar(1, 11), bar(2, 9.9), bar(3, 10)];
      expect(o.stateAt(bars, 0), 0);
      expect(o.stateAt(bars, 1), 1);
      expect(o.stateAt(bars, 2), -1);
      expect(o.stateAt(bars, 3), 0);
      expect(o.stateAt(bars, 9), 0);
      o.limit = PriceLimit.growth;
      expect(o.stateAt(bars, 1), 0);
      o.limit = PriceLimit.growth;
      o
        ..upLabel = 'U'
        ..downLabel = 'D';
      expect((o.upLabel, o.downLabel), ('U', 'D'));
      o.limit = null;
      expect(o.stateAt(bars, 1), 0);
      o.limit = PriceLimit.growth;
      o.dispose();
      o.limit = PriceLimit.st;
      expect(o.limit, PriceLimit.growth);
    });

    test('PriceLevel equality and overlay updates', () {
      const a = PriceLevel(10, color: Color(0xFF000000), label: 'x');
      expect(a, const PriceLevel(10, color: Color(0xFF000000), label: 'x'));
      expect(a.hashCode, const PriceLevel(10, color: Color(0xFF000000), label: 'x').hashCode);
      final o = PriceLevelsOverlay();
      expect(o.levels, isEmpty);
      o.levels = [a];
      o.levels = [a];
      expect(o.levels, [a]);
      o.dispose();
      o.levels = const [];
      expect(o.levels, [a]);
    });
  });

  group('model and theme', () {
    test('Bar amount survives copyWith, aggregation and isolate packing', () {
      final b = bar(0, 10, amount: 100);
      expect(b.copyWith(close: 11).amount, 100);
      expect(b.toString(), contains('a:100'));
      expect(bar(0, 10).toString(), isNot(contains('a:')));
      expect(addAmount(null, null), isNull);
      expect(addAmount(1, null), 1);
      expect(BarAggregator.merge([b, bar(1, 11, amount: 5)], 0, 2, 0).amount, 105);
      expect(BarAggregator.merge([bar(0, 1), bar(1, 1)], 0, 2, 0).amount, isNull);
      final packed = packBars([b, bar(1, 10)]);
      expect(packed.length, 14);
      expect(packed[6], 100);
      expect(packed[13].isNaN, isTrue);
    });

    test('swapUpDown swaps candle colors including wicks and borders', () {
      final base = KLineTheme.light().copyWith(upWick: const Color(0xFF000001));
      final red = base.swapUpDown();
      expect(red.up, base.down);
      expect(red.down, base.up);
      expect(red.downWick, const Color(0xFF000001));
      expect(red.upWick, isNull);
      expect(red.swapUpDown().up, base.up);
    });

    test('fixedSlots pins the viewport and ignores scroll / zoom', () {
      final vp = ChartViewport()
        ..attach(482)
        ..setBarCount(100);
      vp.fixedSlots = 241;
      expect(vp.fixedSlots, 241);
      expect(vp.barWidth, 2);
      expect(vp.rightIndex, 240.5);
      expect(vp.indexToX(0), 1);
      vp.scroll(200);
      vp.zoomAt(100, 2);
      expect(vp.rightIndex, 240.5);
      expect(vp.barWidth, 2);
      expect(vp.visibleRange(), (0, 99));
      vp.fixedSlots = 241;
      vp.fixedSlots = null;
      expect(vp.fixedSlots, isNull);
      expect(vp.rightIndex, lessThan(240.5));
    });
  });

  group('KChart intraday', () {
    Widget host(ChartController c, {SlotAxis? axis, bool rightOnly = true, double? base = 10}) =>
        MaterialApp(
          home: Center(
            child: SizedBox(
              width: 600,
              height: 400,
              child: KChart(
                controller: c,
                theme: KLineTheme.dark().swapUpDown(),
                seriesStyle: MainSeriesStyle.area,
                yAxisPosition: YAxisPosition.both,
                percentScale: true,
                percentBase: base,
                percentRightOnly: rightOnly,
                mainRange: const StockRange(symmetricAround: 10, include: [11, 9]),
                slotAxis: axis,
              ),
            ),
          ),
        );

    testWidgets('fixed slots, levels, limit marks, average price and crosshair', (tester) async {
      final c = ChartController(
        indicators: [AveragePrice(session: TradingSession.cnA)],
        overlays: [
          PriceLevelsOverlay(
            levels: const [
              PriceLevel(10, color: Color(0xFF888888), label: 'Prev'),
              PriceLevel(11, color: Color(0xFFFF0000), label: 'Up', dashed: false),
              PriceLevel(9, color: Color(0xFF00FF00)),
              PriceLevel(50, color: Color(0xFF00FF00)),
              PriceLevel(double.nan, color: Color(0xFF00FF00)),
            ],
          ),
          LimitMarksOverlay(upLabel: 'LU', downLabel: 'LD'),
        ],
      );
      addTearDown(c.dispose);
      final day = aShareDay(120);
      c.setBars([
        ...day.take(60),
        day[60].copyWith(close: 11, high: 11),
        day[61].copyWith(close: 9.9, low: 9.9),
        ...day.skip(62),
      ]);
      final axis = IntradayAxis(TradingSession.cnA);
      await tester.pumpWidget(host(c, axis: axis));
      await tester.pump();
      expect(c.viewport.fixedSlots, 241);
      final width = c.viewport.width;
      expect(c.viewport.barWidth, closeTo(width / 241, 1e-9));

      final g = await tester.startGesture(tester.getCenter(find.byType(KChart)));
      await tester.pump(const Duration(milliseconds: 600));
      await g.moveBy(const Offset(-40, 0));
      await tester.pump();
      expect(c.crosshair.value, isNotNull);
      await g.up();
      await tester.pump();

      // Multi-day style axis with major separators, then back to a free viewport
      await tester.pumpWidget(host(c, axis: _DayAxis(), rightOnly: false, base: null));
      await tester.pump();
      expect(c.viewport.fixedSlots, 482);
      await tester.pumpWidget(host(c));
      await tester.pump();
      expect(c.viewport.fixedSlots, isNull);
      expect(tester.takeException(), isNull);
    });

    testWidgets('empty chart with a fixed base still labels the axes', (tester) async {
      final c = ChartController();
      addTearDown(c.dispose);
      await tester.pumpWidget(host(c, axis: IntradayAxis(TradingSession.us)));
      await tester.pump();
      expect(c.viewport.fixedSlots, 391);
      expect(tester.takeException(), isNull);
    });
  });
}
