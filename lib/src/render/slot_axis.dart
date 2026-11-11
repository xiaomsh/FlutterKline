import 'package:flutter/foundation.dart';

/// One time-axis tick of a [SlotAxis]: a vertical grid line plus a label at slot [slot]
/// (fractional slots sit between two bars).
@immutable
class SlotTick {
  const SlotTick(this.slot, this.label, {this.major = false});

  final double slot;
  final String label;

  /// Day separators and other strong boundaries: drawn as a solid line and kept when labels
  /// collide.
  final bool major;

  @override
  bool operator ==(Object other) =>
      other is SlotTick && other.slot == slot && other.label == label && other.major == major;

  @override
  int get hashCode => Object.hash(slot, label, major);

  @override
  String toString() => 'SlotTick($slot, $label${major ? ', major' : ''})';
}

/// Fixed-slot time axis (intraday charts): the plot is split into [slotCount] equal slots, bar
/// `i` sits in slot `i`, and the time axis shows [ticks] instead of following the bars.
/// Fixed-slot time axis (`KChart.slotAxis`), e.g. `IntradayAxis`. Implement `==` / `hashCode` by
/// value: the chart relayouts only when the axis changes, so equal instances can be created
/// inline in `build`.
abstract class SlotAxis {
  const SlotAxis();

  /// Number of slots the plot width is split into; bar `i` sits in slot `i`.
  int get slotCount;

  /// Grid lines and time labels, in slot coordinates.
  List<SlotTick> get ticks;
}
