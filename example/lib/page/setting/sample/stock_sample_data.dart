import 'dart:math' as math;

import 'package:klinex/klinex.dart';

/// Deterministic offline stock data for the stock samples: minute points laid on a session's
/// slots and daily bars on weekdays with occasional limit moves.
class StockSampleData {
  /// The samples' trading day: Tuesday 2026-11-10 in the exchange's time zone.
  static int day(TradingSession session) =>
      session.dayOf(DateTime.utc(2026, 11, 10, 12).millisecondsSinceEpoch);

  /// A full (or first [minutes]) trading day around [preClose]; vol is U-shaped (busy open and
  /// close) and [volumeUnit] scales the turnover so [Bar.amount] matches the price.
  static List<Bar> intraday(
    TradingSession session, {
    required double preClose,
    int? minutes,
    double volumeUnit = 1,
    int dayOffset = 0,
  }) {
    final n = session.slotsPerDay;
    final count = math.min(minutes ?? n, n);
    final d = day(session) + dayOffset;
    final phase = dayOffset * 1.7;
    var prev = preClose * (1 + 0.004 * math.sin(phase));
    return [
      for (var i = 0; i < count; i++)
        () {
          final x = i / n;
          final close =
              preClose *
              (1 +
                  0.012 * math.sin(i / 37 + phase) +
                  0.005 * math.sin(i / 7.3) +
                  0.015 * x * math.cos(phase));
          final open = prev;
          prev = close;
          final vol =
              (400 *
                      (1 + 3 * math.exp(-i / 12) + 2 * math.exp(-(n - i) / 15)) *
                      (1 + 0.3 * math.sin(i * 1.3)))
                  .roundToDouble();
          return Bar(
            time: session.timeOf(d, i),
            open: open,
            high: math.max(open, close) * 1.0006,
            low: math.min(open, close) * 0.9994,
            close: close,
            vol: vol,
            amount: (open + close) / 2 * vol * volumeUnit,
          );
        }(),
    ];
  }

  /// [count] daily bars on weekdays ending 2026-11-10 (Beijing midnight timestamps). Every ~40
  /// bars the price runs into the limit up for two days, every ~55 it hits the limit down.
  static List<Bar> daily(int count, {PriceLimit limit = PriceLimit.mainBoard}) {
    final days = <int>[];
    var t = DateTime.utc(2026, 11, 10);
    while (days.length < count) {
      if (t.weekday <= DateTime.friday) days.add(t.millisecondsSinceEpoch - 8 * 3600000);
      t = t.subtract(const Duration(days: 1));
    }
    double cents(num v) => (v * 100).round() / 100;
    final out = <Bar>[];
    var prev = 20.0;
    for (var i = 0; i < count; i++) {
      final up = i % 40 == 17 || i % 40 == 18;
      final down = i % 55 == 31;
      final drift = 0.025 * math.sin(i / 9) + 0.012 * math.sin(i * 2.1);
      final close = up
          ? limit.up(prev)
          : down
          ? limit.down(prev)
          : cents((prev * (1 + drift * limit.ratio * 4)).clamp(limit.down(prev), limit.up(prev)));
      final open = cents(
        (prev * (1 + 0.01 * math.sin(i * 1.3))).clamp(limit.down(prev), limit.up(prev)),
      );
      final high = up ? close : math.min(limit.up(prev), cents(math.max(open, close) * 1.012));
      final low = down ? close : math.max(limit.down(prev), cents(math.min(open, close) * 0.988));
      out.add(
        Bar(
          time: days[count - 1 - i],
          open: open,
          high: high,
          low: low,
          close: close,
          vol: (8e4 * (up || down ? 2.5 : 1 + 0.5 * math.sin(i / 5).abs())).roundToDouble(),
        ),
      );
      prev = close;
    }
    return out;
  }
}
