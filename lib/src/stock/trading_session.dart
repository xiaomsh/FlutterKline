import '../model/bar.dart';

const int _dayMs = Duration.millisecondsPerDay;
const int _minuteMs = Duration.millisecondsPerMinute;

Duration _beijing(int _) => const Duration(hours: 8);

/// US Eastern time: UTC-4 from the second Sunday of March 02:00 to the first Sunday of November
/// 02:00 (local), UTC-5 otherwise.
Duration usEasternOffset(int utcMillis) {
  final t = DateTime.fromMillisecondsSinceEpoch(utcMillis, isUtc: true);
  DateTime sunday(int month, int nth) {
    final first = DateTime.utc(t.year, month);
    return DateTime.utc(t.year, month, 1 + (7 - first.weekday) % 7 + 7 * (nth - 1));
  }

  final start = sunday(3, 2).add(const Duration(hours: 7));
  final end = sunday(11, 1).add(const Duration(hours: 6));
  final dst = !t.isBefore(start) && t.isBefore(end);
  return Duration(hours: dst ? -4 : -5);
}

/// Trading hours of an exchange, in exchange local time.
///
/// Intraday bars are labeled by their end minute (the 09:31 bar covers 09:30–09:31), so each
/// segment `(open, close)` yields slots `open+1 … close`; with [openingSlot] the very first
/// open minute (the opening auction print) gets its own slot too. Breaks and closed days take no
/// slots.
class TradingSession {
  TradingSession({
    required this.segments,
    required this.offsetAt,
    this.openingSlot = true,
    this.name = '',
  }) : assert(segments.isNotEmpty, 'segments must not be empty');

  /// Shanghai / Shenzhen: 09:30–11:30, 13:00–15:00 Beijing time; 241 slots.
  static final cnA = TradingSession(
    name: 'A',
    segments: const [(570, 690), (780, 900)],
    offsetAt: _beijing,
  );

  /// Hong Kong: 09:30–12:00, 13:00–16:00 Hong Kong time; 331 slots.
  static final hk = TradingSession(
    name: 'HK',
    segments: const [(570, 720), (780, 960)],
    offsetAt: _beijing,
  );

  /// NYSE / Nasdaq regular hours: 09:30–16:00 US Eastern time (DST aware); 391 slots.
  static final us = TradingSession(
    name: 'US',
    segments: const [(570, 960)],
    offsetAt: usEasternOffset,
  );

  final String name;

  /// `(open, close)` minutes since local midnight, ascending and non-overlapping.
  final List<(int, int)> segments;

  /// Exchange UTC offset at a UTC instant (handles DST).
  final Duration Function(int utcMillis) offsetAt;

  final bool openingSlot;

  /// Local minute of day for each slot.
  late final List<int> slotMinutes = [
    if (openingSlot) segments.first.$1,
    for (final (open, close) in segments)
      for (var m = open + 1; m <= close; m++) m,
  ];

  late final Map<int, int> _slotOfMinute = {
    for (var i = 0; i < slotMinutes.length; i++) slotMinutes[i]: i,
  };

  int get slotsPerDay => slotMinutes.length;

  /// Exchange wall-clock time of [utcMillis], as a UTC [DateTime] whose fields read local time.
  DateTime localTime(int utcMillis) => DateTime.fromMillisecondsSinceEpoch(
    utcMillis + offsetAt(utcMillis).inMilliseconds,
    isUtc: true,
  );

  /// Exchange-local trading day (days since 1970-01-01).
  int dayOf(int utcMillis) {
    final wall = utcMillis + offsetAt(utcMillis).inMilliseconds;
    return (wall / _dayMs).floor();
  }

  /// Slot of a bar time within its day; null outside the session.
  int? slotOf(int utcMillis) {
    final t = localTime(utcMillis);
    return _slotOfMinute[t.hour * 60 + t.minute];
  }

  /// UTC time of [slot] on trading day [day].
  int timeOf(int day, int slot) {
    final wall = day * _dayMs + slotMinutes[slot] * _minuteMs;
    final guess = offsetAt(wall).inMilliseconds;
    return wall - offsetAt(wall - guess).inMilliseconds;
  }

  /// Fractional slot of a local minute: exact for a slot minute, otherwise halfway before the next
  /// slot (used for ticks at boundaries such as the open without an opening slot).
  double slotAtMinute(int minute) {
    final exact = _slotOfMinute[minute];
    if (exact != null) return exact.toDouble();
    for (var i = 0; i < slotMinutes.length; i++) {
      if (slotMinutes[i] > minute) return i - 0.5;
    }
    return slotMinutes.length - 0.5;
  }

  /// Whether [utcMillis] falls inside trading hours on a weekday (holidays are not known).
  bool isTrading(int utcMillis) {
    final t = localTime(utcMillis);
    if (t.weekday > DateTime.friday) return false;
    final m = t.hour * 60 + t.minute;
    return segments.any((s) => m >= s.$1 && m <= s.$2);
  }

  /// `HH:mm` in exchange time, or `MM-dd HH:mm` with [date].
  String formatTime(int utcMillis, {bool date = false}) {
    final t = localTime(utcMillis);
    String p2(int v) => v.toString().padLeft(2, '0');
    final hm = '${p2(t.hour)}:${p2(t.minute)}';
    return date ? '${p2(t.month)}-${p2(t.day)} $hm' : hm;
  }

  /// `HH:mm` of a local minute of day.
  static String formatMinute(int minute) =>
      '${(minute ~/ 60).toString().padLeft(2, '0')}:${(minute % 60).toString().padLeft(2, '0')}';

  /// Aligns intraday bars to slots: bars outside the session are dropped, later bars replace
  /// earlier ones in the same slot, and minutes without trades become flat bars at the previous
  /// close (vol 0). Days before the last are filled to the close; the last day stops at its latest
  /// bar so the remaining slots stay empty. The first missing minutes use [preClose] (or the first
  /// bar's open).
  List<Bar> normalize(List<Bar> bars, {double? preClose}) {
    final n = slotsPerDay;
    final days = <int, List<Bar?>>{};
    for (final b in bars) {
      final s = slotOf(b.time);
      if (s == null) continue;
      (days[dayOf(b.time)] ??= List<Bar?>.filled(n, null))[s] = b;
    }
    final keys = days.keys.toList()..sort();
    final out = <Bar>[];
    var prev = preClose;
    for (final day in keys) {
      final row = days[day]!;
      final last = day == keys.last ? row.lastIndexWhere((b) => b != null) : n - 1;
      prev ??= row.firstWhere((b) => b != null)!.open;
      for (var s = 0; s <= last; s++) {
        final time = timeOf(day, s);
        final b = row[s];
        final p = prev!;
        out.add(
          b == null
              ? Bar(time: time, open: p, high: p, low: p, close: p)
              : (b.time == time ? b : b.copyWith(time: time)),
        );
        prev = out.last.close;
      }
    }
    return out;
  }

  @override
  String toString() => 'TradingSession($name)';
}
