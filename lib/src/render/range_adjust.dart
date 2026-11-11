import '../model/min_max.dart';

/// Adjusts the main range after data, indicators and padding are merged (`KChart.mainRange`),
/// e.g. `StockRange`. Implement `==` / `hashCode` by value: the chart relayouts only when the
/// adjustment changes, so equal instances can be created inline in `build`.
abstract class RangeAdjust {
  const RangeAdjust();

  MinMax apply(MinMax range);
}
