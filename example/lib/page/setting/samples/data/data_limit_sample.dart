import 'package:flutter/material.dart';
import 'package:klinex/klinex.dart';

import '../../../../l10n/l10n.dart';
import '../../sample/sample_view.dart';
import '../../widgets/controls.dart';

/// Data size and capacity limit: setBars / maxBars.
class DataLimitSample extends SampleView {
  const DataLimitSample({super.key});
  @override
  State<DataLimitSample> createState() => _DataLimitSampleState();
}

class _DataLimitSampleState extends SampleViewState<DataLimitSample>
    with SampleFeedMixin<DataLimitSample> {
  int _initial = 600;

  @override
  Widget buildChart(BuildContext context) =>
      frame(KChart(controller: controller, theme: chartTheme, labels: chartLabels));

  @override
  List<Widget> buildSettings(BuildContext context) => [
    Choice(
      S.current.dataLimitInitial,
      _initial,
      const {200: '200', 600: '600', 2000: '2,000', 10000: '10,000'},
      (v) {
        update(() => _initial = v);
        feed.reset(v);
      },
    ),
    Choice<int>(
      S.current.dataLimitMaxBars,
      feed.maxBars ?? 0,
      {0: S.current.dataLimitUnlimited, 1000: '1,000', 5000: '5,000', 12000: '12,000'},
      (v) => feed.setMaxBars(v == 0 ? null : v),
    ),
    FilledButton(onPressed: () => feed.reset(_initial), child: Text(S.current.dataLimitRegenerate)),
    const SizedBox(height: 8),
    Text(S.current.dataLimitCurrent(controller.bars.length)),
  ];

  @override
  String code() =>
      'final controller = ChartController();\n'
      'controller.maxBars = ${feed.maxBars}; // drops the oldest when exceeded\n'
      'controller.setBars(bars); // $_initial synthetic bars on this page';
}
