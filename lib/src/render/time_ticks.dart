import 'dart:math' as math;

import '../model/bar.dart';

/// Time axis tick tier: the highest time boundary crossed between two adjacent bars.
enum TimeTier { second, minute, fiveMinutes, fifteenMinutes, hour, sixHours, day, month, year }

const _min = 60000, _hour = 3600000, _day = 86400000;

/// Floor division, so negative timestamps before 1970 also land in the right bucket.
int _floorDiv(int a, int d) => a >= 0 ? a ~/ d : -((-a - 1) ~/ d) - 1;

/// (year, month 0..11, day 1..31) for day [days] since 1970-01-01, pure integer math, no DateTime.
(int, int, int) _civil(int days) {
  final z = days + 719468;
  final era = _floorDiv(z, 146097);
  final doe = z - era * 146097;
  final yoe = (doe - doe ~/ 1460 + doe ~/ 36524 - doe ~/ 146096) ~/ 365;
  final doy = doe - (365 * yoe + yoe ~/ 4 - yoe ~/ 100);
  final mp = (5 * doy + 2) ~/ 153;
  final day = doy - (153 * mp + 2) ~/ 5 + 1;
  final month = mp < 10 ? mp + 2 : mp - 10;
  final year = yoe + era * 400 + (month <= 1 ? 1 : 0);
  return (year, month, day);
}

/// "year * 12 + month index"
int _yearMonth(int days) {
  final (y, m, _) = _civil(days);
  return y * 12 + m;
}

/// Highest boundary crossed from [prev] to [cur] (both already in local-time ms); null within the
/// same second.
TimeTier? tierBetween(int prev, int cur) {
  final dp = _floorDiv(prev, _day), dc = _floorDiv(cur, _day);
  if (dc != dp) {
    final a = _yearMonth(dp), b = _yearMonth(dc);
    if (_floorDiv(a, 12) != _floorDiv(b, 12)) return TimeTier.year;
    if (a != b) return TimeTier.month;
    return TimeTier.day;
  }
  bool crossed(int unit) => _floorDiv(cur, unit) != _floorDiv(prev, unit);
  if (crossed(6 * _hour)) return TimeTier.sixHours;
  if (crossed(_hour)) return TimeTier.hour;
  if (crossed(15 * _min)) return TimeTier.fifteenMinutes;
  if (crossed(5 * _min)) return TimeTier.fiveMinutes;
  if (crossed(_min)) return TimeTier.minute;
  if (crossed(1000)) return TimeTier.second;
  return null;
}

/// Allowed intervals per tier (take one every N boundaries), tried from dense to sparse. All divide
/// the next higher unit, so picked ticks align with the higher tier.
const _strides = <TimeTier, List<int>>{
  TimeTier.year: [1, 2, 5, 10, 20, 50, 100, 200, 500, 1000],
  TimeTier.month: [1, 2, 3, 6],
  TimeTier.day: [1, 2, 5, 10, 15],
  TimeTier.sixHours: [1, 2],
  TimeTier.hour: [1, 2, 3],
  TimeTier.fifteenMinutes: [1, 2],
  TimeTier.fiveMinutes: [1, 2],
  TimeTier.minute: [1, 2],
  TimeTier.second: [1, 2, 5, 10, 15, 30],
};

/// Absolute ordinal of local time [local] at tier [tier] (year, month index, day of month, hours
/// since 1970, ...);
/// ticks are picked by modulo on it, so selected ticks do not jump with the visible start when
/// panning.
int _ordinal(int local, TimeTier tier) {
  if (tier.index >= TimeTier.day.index) {
    final (y, m, d) = _civil(_floorDiv(local, _day));
    return switch (tier) {
      TimeTier.year => y,
      TimeTier.month => y * 12 + m,
      _ => d - 1,
    };
  }
  return _floorDiv(local, switch (tier) {
    TimeTier.sixHours => 6 * _hour,
    TimeTier.hour => _hour,
    TimeTier.fifteenMinutes => 15 * _min,
    TimeTier.fiveMinutes => 5 * _min,
    TimeTier.minute => _min,
    _ => 1000,
  });
}

/// Picks ticks within [from]..[to]: higher tiers first, adjacent x at least [minSpacing] apart.
/// Returns (index, tier) sorted by index.
/// When a tier is too dense, takes one every N by absolute ordinal (e.g. even years only), so it
/// does not jump when panning.
/// Falls back to evenly spaced ticks when the visible range has no boundary (single bar, or all
/// within one second).
/// Time zone: [offsetOf] gives the local offset in ms for each UTC instant (for DST); otherwise the
/// fixed [offsetMs] is used.
List<(int, TimeTier)> pickTimeTicks(
  List<Bar> bars,
  int from,
  int to,
  double Function(int index) xOf,
  double minSpacing, {
  int offsetMs = 0,
  int Function(int utcMillis)? offsetOf,
}) {
  if (bars.isEmpty || to < from) return const [];
  final lo = from.clamp(0, bars.length - 1), hi = to.clamp(0, bars.length - 1);
  int local(int t) => t + (offsetOf?.call(t) ?? offsetMs);
  // Bucket by tier; each bucket is naturally sorted by index, saving a per-frame sort. Also record
  // the ordinals
  final buckets = List.generate(TimeTier.values.length, (_) => <(int, int)>[]);
  var prev = local(bars[lo == 0 ? 0 : lo - 1].time);
  for (var i = lo == 0 ? 1 : lo; i <= hi; i++) {
    final cur = local(bars[i].time);
    final t = tierBetween(prev, cur);
    if (t != null) buckets[t.index].add((i, _ordinal(cur, t)));
    prev = cur;
  }
  if (buckets.every((b) => b.isEmpty)) return _evenTicks(bars, lo, hi, xOf, minSpacing);
  final xs = <double>[]; // Selected x values, ascending
  final picked = <(int, TimeTier)>[];
  for (var tier = TimeTier.values.length - 1; tier >= 0; tier--) {
    final cands = buckets[tier];
    if (cands.isEmpty) continue;
    final strides = _strides[TimeTier.values[tier]]!;
    var chosen = cands;
    for (final k in strides) {
      chosen = k == 1
          ? cands
          : [
              for (final c in cands)
                if (c.$2 % k == 0) c,
            ];
      var ok = true;
      for (var j = 1; j < chosen.length && ok; j++) {
        ok = xOf(chosen[j].$1) - xOf(chosen[j - 1].$1) >= minSpacing;
      }
      if (ok) break;
    }
    for (final (i, _) in chosen) {
      final x = xOf(i);
      var a = 0, b = xs.length;
      while (a < b) {
        final mid = (a + b) >> 1;
        if (xs[mid] < x) {
          a = mid + 1;
        } else {
          b = mid;
        }
      }
      if (a > 0 && x - xs[a - 1] < minSpacing) continue;
      if (a < xs.length && xs[a] - x < minSpacing) continue;
      xs.insert(a, x);
      picked.add((i, TimeTier.values[tier]));
    }
  }
  picked.sort((a, b) => a.$1.compareTo(b.$1));
  return picked;
}

/// Evenly spaced ticks when there is no time boundary: modulo on absolute index (no jumping when
/// panning); tier is guessed from the bar interval for label format.
List<(int, TimeTier)> _evenTicks(
  List<Bar> bars,
  int lo,
  int hi,
  double Function(int index) xOf,
  double minSpacing,
) {
  final step = hi > lo ? (xOf(hi) - xOf(lo)).abs() / (hi - lo) : 0.0;
  final every = step > 0 ? math.max(1, (minSpacing / step).ceil()) : 1;
  final gap = hi > lo
      ? bars[hi].time - bars[hi - 1].time
      : (bars.length > 1 ? bars[1].time - bars[0].time : _day);
  final tier = gap >= _day
      ? TimeTier.day
      : gap >= _min
      ? TimeTier.minute
      : TimeTier.second;
  return [
    for (var i = lo; i <= hi; i++)
      if (i % every == 0) (i, tier),
  ];
}

String _two(int v) => v.toString().padLeft(2, '0');

/// Default tick labels: year `2026`, month `2026-11`, day `11-10`, hour:minute `13:05`, second
/// `13:05:30`. [offsetMs] as above.
String defaultTickLabel(int millis, TimeTier tier, {int offsetMs = 0}) {
  final d = DateTime.fromMillisecondsSinceEpoch(millis + offsetMs, isUtc: true);
  return switch (tier) {
    TimeTier.year => '${d.year}',
    TimeTier.month => '${d.year}-${_two(d.month)}',
    TimeTier.day => '${_two(d.month)}-${_two(d.day)}',
    TimeTier.second => '${_two(d.hour)}:${_two(d.minute)}:${_two(d.second)}',
    _ => '${_two(d.hour)}:${_two(d.minute)}',
  };
}
