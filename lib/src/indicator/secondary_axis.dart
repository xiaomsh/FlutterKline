import 'dart:ui';

import '../model/bar.dart';
import '../model/min_max.dart';
import '../panel/panel.dart';
import '../render/context.dart';
import 'indicator.dart';

/// Moves any indicator onto the main chart's second value axis: its range is computed separately
/// without squeezing prices, with ticks on the side opposite the main ticks.
/// Serializable whenever the wrapped indicator is (`{'kind': 'axis2', 'inner': {...}}`), so it is
/// saved/restored with saveState and computed in the background
/// The second axis always autofits visible data: range changes tween like the main axis, but
/// ignore manual y zoom/pan/lock;
/// with ticks on both sides the left one shows it, and dragging or scrolling over it doesn't zoom
/// the main axis
class SecondaryAxis extends Indicator {
  SecondaryAxis(this.inner);

  final Indicator inner;

  @override
  String get id => '${inner.id}@axis2';

  @override
  String get kind => 'axis2';

  @override
  PanelRef get target => PanelRef.mainSecondary;

  @override
  int get warmupBars => inner.warmupBars;

  @override
  int? get prependSettleBars => inner.prependSettleBars;

  @override
  void computeAll(List<Bar> bars, IndicatorStore store) => inner.computeAll(bars, store);

  @override
  void computeLast(List<Bar> bars, int index, IndicatorStore store) =>
      inner.computeLast(bars, index, store);

  @override
  void paint(Canvas canvas, RenderContext ctx, IndicatorStore store) =>
      inner.paint(canvas, ctx, store);

  @override
  MinMax range(IndicatorStore store, int start, int end) => inner.range(store, start, end);

  @override
  MinMax rangeInView(IndicatorStore store, int start, int end, double rightIndex) =>
      inner.rangeInView(store, start, end, rightIndex);

  @override
  void legendInto(List<LegendItem> out, RenderContext ctx, IndicatorStore store, int index) =>
      inner.legendInto(out, ctx, store, index);
}
