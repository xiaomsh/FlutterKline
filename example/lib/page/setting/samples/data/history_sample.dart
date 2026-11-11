import 'package:flutter/material.dart';
import 'package:klinex/klinex.dart';

import '../../../../l10n/l10n.dart';
import '../../sample/sample_view.dart';
import '../../widgets/controls.dart';

/// History pagination: onLoadMore / prependHistory.
class HistorySample extends SampleView {
  const HistorySample({super.key});
  @override
  State<HistorySample> createState() => _HistorySampleState();
}

class _HistorySampleState extends SampleViewState<HistorySample>
    with SampleFeedMixin<HistorySample> {
  bool _paginate = true;

  @override
  int get initialBars => 300;

  @override
  Widget buildChart(BuildContext context) => frame(
    KChart(
      controller: controller,
      theme: chartTheme,
      labels: chartLabels,
      onLoadMore: _paginate ? feed.loadHistory : null,
    ),
  );

  @override
  List<Widget> buildSettings(BuildContext context) => [
    Toggle(S.current.historyAutoLoad, _paginate, (v) => update(() => _paginate = v)),
    FilledButton(onPressed: feed.loadHistory, child: Text(S.current.historyLoadButton(200))),
    const SizedBox(height: 8),
    Text(S.current.historyStatus(feed.pages, controller.bars.length)),
    Text(S.current.historyHint),
  ];

  @override
  String code() => _paginate
      ? 'Future<void> loadMore() async {\n'
            '  final older = await api.fetchBefore(controller.bars.first.time);\n'
            '  controller.prependHistory(older); // viewport shifts in the same frame, no jump\n'
            '}\n'
            'KChart(controller: controller, onLoadMore: loadMore, ...)'
      : 'KChart(controller: controller, onLoadMore: null, ...)\n'
            'controller.prependHistory(olderBars);';
}
