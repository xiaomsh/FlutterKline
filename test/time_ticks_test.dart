import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klinex/klinex.dart';
import 'package:klinex/src/render/time_ticks.dart' show tierBetween;

int utc(int y, [int mo = 1, int d = 1, int h = 0, int mi = 0, int s = 0]) =>
    DateTime.utc(y, mo, d, h, mi, s).millisecondsSinceEpoch;

Bar bar(int t) => Bar(time: t, open: 1, high: 2, low: 0.5, close: 1.5, vol: 1);

void main() {
  test('tierBetween picks the highest boundary crossed', () {
    expect(tierBetween(utc(2025, 12, 31), utc(2026)), TimeTier.year);
    expect(tierBetween(utc(2026, 1, 31), utc(2026, 2, 1)), TimeTier.month);
    expect(tierBetween(utc(2026, 2, 1, 23), utc(2026, 2, 2, 1)), TimeTier.day);
    expect(tierBetween(utc(2026, 2, 1, 5, 59), utc(2026, 2, 1, 6)), TimeTier.sixHours);
    expect(tierBetween(utc(2026, 2, 1, 7, 59), utc(2026, 2, 1, 8)), TimeTier.hour);
    expect(tierBetween(utc(2026, 2, 1, 8, 14), utc(2026, 2, 1, 8, 15)), TimeTier.fifteenMinutes);
    expect(tierBetween(utc(2026, 2, 1, 8, 9), utc(2026, 2, 1, 8, 10)), TimeTier.fiveMinutes);
    expect(tierBetween(utc(2026, 2, 1, 8, 1), utc(2026, 2, 1, 8, 2)), TimeTier.minute);
    expect(tierBetween(utc(2026, 2, 1, 8, 1, 1), utc(2026, 2, 1, 8, 1, 2)), TimeTier.second);
    expect(tierBetween(utc(2026), utc(2026)), isNull);
    // skipped whole months (weekly bars, halts) still count as the highest level crossed
    expect(tierBetween(utc(2026, 1, 20), utc(2026, 3, 2)), TimeTier.month);
  });

  test('offset moves day boundaries to local time', () {
    // UTC 15:59 -> 16:00 is 23:59 -> 00:00 at +8, a day change
    final a = utc(2026, 3, 10, 15, 59), b = utc(2026, 3, 10, 16);
    expect(tierBetween(a, b), TimeTier.hour);
    const h8 = 8 * 3600000;
    expect(tierBetween(a + h8, b + h8), TimeTier.day);
    expect(defaultTickLabel(b, TimeTier.day, offsetMs: h8), '03-11');
  });

  test('pickTimeTicks prefers higher tiers and respects spacing', () {
    // hourly bars over three days: 24 per day, 10px each
    final bars = [for (var i = 0; i < 72; i++) bar(utc(2026, 1, 30) + i * 3600000)];
    double xOf(int i) => i * 10.0;

    final wide = pickTimeTicks(bars, 0, 71, xOf, 100);
    // day changes (1-31, 2-1; 2-1 is also a month change) are always picked; 2-1 is month
    expect(wide.map((t) => t.$1), containsAll([24, 48]));
    expect(wide.firstWhere((t) => t.$1 == 48).$2, TimeTier.month);
    expect(wide.firstWhere((t) => t.$1 == 24).$2, TimeTier.day);
    for (var k = 1; k < wide.length; k++) {
      expect(wide[k].$1 > wide[k - 1].$1, isTrue);
      expect(xOf(wide[k].$1) - xOf(wide[k - 1].$1), greaterThanOrEqualTo(100));
    }
    // with enough spacing, 6-hour boundaries are added too
    expect(wide.any((t) => t.$2 == TimeTier.sixHours), isTrue);

    // with very large spacing only higher levels remain
    final sparse = pickTimeTicks(bars, 0, 71, xOf, 300);
    expect(sparse.map((t) => t.$1), contains(48));
    expect(sparse.every((t) => t.$2.index >= TimeTier.sixHours.index), isTrue);
  });

  test('pickTimeTicks handles empty / clamped / single bar ranges', () {
    expect(pickTimeTicks(const [], 0, 10, (i) => 0, 50), isEmpty);
    // with no boundaries at all, fall back to evenly spaced ticks, no blanks
    expect(pickTimeTicks([bar(utc(2026))], 0, 0, (i) => 0, 50), [(0, TimeTier.day)]);
    final bars = [bar(utc(2025, 12, 31)), bar(utc(2026))];
    expect(pickTimeTicks(bars, -5, 99, (i) => i * 100.0, 50), [(1, TimeTier.year)]);
  });

  test('irregular bars (renko-like) tick at real boundaries, not fixed columns', () {
    // first 10 bars packed in one day, then one per day
    final times = [
      for (var i = 0; i < 10; i++) utc(2026, 5, 1, 9, i * 5),
      for (var d = 2; d < 12; d++) utc(2026, 5, d, 9),
    ];
    final bars = times.map(bar).toList();
    final ticks = pickTimeTicks(bars, 0, bars.length - 1, (i) => i * 20.0, 30);
    for (final (i, tier) in ticks) {
      if (i >= 10) expect(tier, TimeTier.day);
    }
    expect(ticks.first.$1, lessThan(10)); // minute-level ticks within the same day too
  });

  test('defaultTickLabel formats per tier', () {
    final t = utc(2026, 11, 10, 13, 5, 30);
    expect(defaultTickLabel(t, TimeTier.year), '2026');
    expect(defaultTickLabel(t, TimeTier.month), '2026-11');
    expect(defaultTickLabel(t, TimeTier.day), '11-10');
    expect(defaultTickLabel(t, TimeTier.hour), '13:05');
    expect(defaultTickLabel(t, TimeTier.second), '13:05:30');
  });

  testWidgets('KChart paints with tieredTimeAxis and syncs config', (tester) async {
    final c = ChartController()
      ..setBars([for (var i = 0; i < 500; i++) bar(utc(2026, 1, 1) + i * 900000)]);
    String? seen;
    String fmt(int ms, TimeTier t) {
      seen = t.name;
      return defaultTickLabel(ms, t);
    }

    Widget host(bool tiered) => MaterialApp(
      home: SizedBox(
        width: 400,
        height: 300,
        child: KChart(
          controller: c,
          theme: KLineTheme.dark(),
          tieredTimeAxis: tiered,
          utcOffset: Duration.zero,
          tickFormatter: fmt,
        ),
      ),
    );
    await tester.pumpWidget(host(false));
    expect(seen, isNull);
    await tester.pumpWidget(host(true));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(seen, isNotNull);
    c.dispose();
  });

  test('day / month / year boundaries match DateTime, including before 1970', () {
    const day = 86400000;
    for (var d = -800000; d < 800000; d += 997) {
      final a = DateTime.fromMillisecondsSinceEpoch(d * day, isUtc: true);
      final b = DateTime.fromMillisecondsSinceEpoch((d + 1) * day, isUtc: true);
      final want = a.year != b.year
          ? TimeTier.year
          : a.month != b.month
          ? TimeTier.month
          : TimeTier.day;
      expect(tierBetween(d * day + 5, (d + 1) * day + 5), want, reason: '$a');
    }
    // 1969-12-31 23:00 -> 1970-01-01 00:00 is a year change
    expect(tierBetween(-3600000, 0), TimeTier.year);
    expect(tierBetween(-60000 * 7, -60000 * 2), TimeTier.fiveMinutes);
  });

  test('per-bar offsets keep daily bars on their local day across DST', () {
    // daily bars at local midnight: first half offset +1h (DST), second half 0
    const h = 3600000;
    final bars = [
      for (var d = 0; d < 6; d++) bar(utc(2026, 10, 22 + d) - (d < 3 ? h : 0)),
    ];
    int offsetOf(int ms) => ms < utc(2026, 10, 25) ? h : 0;
    final ticks = pickTimeTicks(bars, 0, 5, (i) => i * 100.0, 50, offsetOf: offsetOf);
    expect(ticks.map((t) => t.$2), everyElement(TimeTier.day));
    expect(ticks.map((t) => t.$1), [1, 2, 3, 4, 5]);
    expect(
      [
        for (final (i, t) in ticks)
          defaultTickLabel(bars[i].time, t, offsetMs: offsetOf(bars[i].time)),
      ],
      ['10-23', '10-24', '10-25', '10-26', '10-27'],
    );
  });

  test('crowded tier picks by absolute ordinal, so panning does not flip the chosen years', () {
    final bars = [for (var y = 1990; y < 2030; y++) bar(utc(y))];
    // 10px per year, min spacing 25 -> take every few years, always the same set of years
    Set<int> years(int from, int to) => {
      for (final (i, _) in pickTimeTicks(bars, from, to, (i) => i * 10.0, 25))
        DateTime.fromMillisecondsSinceEpoch(bars[i].time, isUtc: true).year,
    };
    final a = years(1, 30), b = years(2, 31);
    expect(a.every((y) => y % 5 == 0), isTrue, reason: '$a');
    expect(b.every((y) => y % 5 == 0), isTrue, reason: '$b');
    expect(a.intersection(b), isNotEmpty);
  });

  test('no boundary in view falls back to evenly spaced ticks', () {
    final bars = [for (var i = 0; i < 40; i++) bar(utc(2026, 5, 1, 9) + i * 10)];
    final ticks = pickTimeTicks(bars, 0, 39, (i) => i * 10.0, 50);
    expect(ticks, isNotEmpty);
    expect(ticks.every((t) => t.$1 % 5 == 0), isTrue);
  });
}
