import 'package:flutter/material.dart';
import 'package:klinex/klinex.dart';

import '../../../../l10n/l10n.dart';
import '../../sample/sample_view.dart';
import '../../widgets/controls.dart';

/// Lock the range: lockYRange / unlockYRange.
class LockRangeSample extends SampleView {
  const LockRangeSample({super.key});
  @override
  State<LockRangeSample> createState() => _LockRangeSampleState();
}

class _LockRangeSampleState extends SampleViewState<LockRangeSample>
    with SampleFeedMixin<LockRangeSample> {
  bool get _locked => controller.viewport.lockedYRange != null;

  @override
  Widget buildChart(BuildContext context) => frame(
    KChart(
      controller: controller,
      theme: chartTheme,
      labels: chartLabels,
      yPan: YPanMode.axis,
      autoFollow: true,
    ),
  );

  @override
  List<Widget> buildSettings(BuildContext context) {
    final range = controller.viewport.lockedYRange;
    return [
      Toggle(S.current.lockRangeLock, _locked, (v) {
        update(() => v ? controller.lockYRange() : controller.unlockYRange());
      }),
      Toggle(S.current.sampleAutoPush, feed.pushing, (v) {
        feed.autoPush(v ? const Duration(milliseconds: 300) : null);
      }),
      if (range != null)
        Text(
          S.current.lockRangeLockedAt(range.min.toStringAsFixed(2), range.max.toStringAsFixed(2)),
        ),
      Text(S.current.lockRangeHint),
      Text(S.current.lockRangeStorageHint),
    ];
  }

  @override
  String code() => _locked
      ? 'controller.lockYRange(); // pin the current main range\n'
            '// controller.unlockYRange() returns to auto'
      : 'controller.unlockYRange(); // range auto-fits the visible bars';
}
