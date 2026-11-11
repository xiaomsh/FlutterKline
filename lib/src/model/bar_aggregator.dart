import 'dart:math' as math;

import 'bar.dart';

/// Buckets source-period bars by time into a larger period; set it on `ChartController.aggregator`.
/// Only the bucketing rule is needed: within a bucket, open is the first bar's, close the last
/// bar's, high/low are the extremes, volume is summed, and the bucket time is its start.
/// [bucketOf] must be monotonically non-decreasing (later time, later bucket) and must not return
/// a time later than the input.
abstract class BarAggregator {
  const BarAggregator();

  /// Returns the start time of the bucket that [time] falls into.
  int bucketOf(int time);

  /// Aggregates the whole range; [bars] must be sorted by time.
  List<Bar> aggregate(List<Bar> bars) {
    final out = <Bar>[];
    var i = 0;
    while (i < bars.length) {
      final t = bucketOf(bars[i].time);
      var j = i + 1;
      while (j < bars.length && bucketOf(bars[j].time) == t) {
        j++;
      }
      out.add(merge(bars, i, j, t));
      i = j;
    }
    return out;
  }

  /// Merges [bars] in [from, to) into one bar with time [time].
  static Bar merge(List<Bar> bars, int from, int to, int time) {
    final first = bars[from];
    var hi = first.high, lo = first.low, vol = first.vol;
    var amount = first.amount;
    for (var k = from + 1; k < to; k++) {
      final b = bars[k];
      hi = math.max(hi, b.high);
      lo = math.min(lo, b.low);
      vol += b.vol;
      amount = addAmount(amount, b.amount);
    }
    return Bar(
      time: time,
      open: first.open,
      high: hi,
      low: lo,
      close: bars[to - 1].close,
      vol: vol,
      amount: amount,
    );
  }
}
