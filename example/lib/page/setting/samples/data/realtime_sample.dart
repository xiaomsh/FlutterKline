import 'package:flutter/material.dart';
import 'package:klinex/klinex.dart';

import '../../../../l10n/l10n.dart';
import '../../sample/sample_view.dart';
import '../../widgets/controls.dart';

/// Real-time push: applyTick / autoFollow.
class RealtimeSample extends SampleView {
  const RealtimeSample({super.key});
  @override
  State<RealtimeSample> createState() => _RealtimeSampleState();
}

class _RealtimeSampleState extends SampleViewState<RealtimeSample>
    with SampleFeedMixin<RealtimeSample> {
  bool _auto = true, _follow = true;
  int _interval = 500;

  @override
  void initState() {
    super.initState();
    feed
      ..autoFollow = _follow
      ..autoPush(Duration(milliseconds: _interval));
  }

  void _schedule() => feed.autoPush(_auto ? Duration(milliseconds: _interval) : null);

  @override
  Widget buildChart(BuildContext context) => frame(
    KChart(controller: controller, theme: chartTheme, labels: chartLabels, autoFollow: _follow),
  );

  @override
  List<Widget> buildSettings(BuildContext context) => [
    Toggle(S.current.realtimeAutoPush, _auto, (v) {
      update(() => _auto = v);
      _schedule();
    }),
    Choice(
      S.current.realtimeInterval,
      _interval,
      {
        100: S.current.realtimeMillis(100),
        500: S.current.realtimeMillis(500),
        1000: S.current.realtimeOneSecond,
      },
      (v) {
        update(() => _interval = v);
        _schedule();
      },
    ),
    Toggle(S.current.realtimeFollow, _follow, (v) {
      update(() => _follow = v);
      feed.autoFollow = v;
    }),
    Wrap(
      spacing: 8,
      children: [
        FilledButton(
          onPressed: () => feed.push(append: true),
          child: Text(S.current.realtimeAppend),
        ),
        OutlinedButton(onPressed: feed.push, child: Text(S.current.realtimeUpdateLast)),
      ],
    ),
    const SizedBox(height: 8),
    Text(S.current.realtimeHint),
  ];

  @override
  String code() =>
      '// Same timestamp updates the last bar, a new timestamp appends\n'
      'socket.listen((bar) => controller.applyTick(bar));\n'
      'KChart(controller: controller, autoFollow: $_follow, ...)';
}
