import 'bar.dart';

/// Time to fractional index: linearly interpolated between bars, extrapolated by the average
/// interval beyond both ends

double avgPeriodMsOf(List<Bar> bars) {
  if (bars.length < 2) return 60000;
  return (bars.last.time - bars.first.time) / (bars.length - 1);
}

double timeToIndex(List<Bar> bars, num time) {
  if (bars.isEmpty) return 0;
  final avg = avgPeriodMsOf(bars);
  if (time <= bars.first.time) return (time - bars.first.time) / avg;
  if (time >= bars.last.time) {
    return (bars.length - 1) + (time - bars.last.time) / avg;
  }
  var lo = 0, hi = bars.length - 1;
  while (lo + 1 < hi) {
    final mid = (lo + hi) >> 1;
    if (bars[mid].time <= time) {
      lo = mid;
    } else {
      hi = mid;
    }
  }
  return lo + (time - bars[lo].time) / (bars[hi].time - bars[lo].time);
}

double indexToTime(List<Bar> bars, double index) {
  if (bars.isEmpty) return 0;
  final avg = avgPeriodMsOf(bars);
  if (index <= 0) return bars.first.time + index * avg;
  if (index >= bars.length - 1) {
    return bars.last.time + (index - (bars.length - 1)) * avg;
  }
  final lo = index.floor();
  return bars[lo].time + (bars[lo + 1].time - bars[lo].time) * (index - lo);
}
