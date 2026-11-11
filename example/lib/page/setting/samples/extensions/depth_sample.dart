import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:klinex/klinex.dart';

import '../../../../l10n/l10n.dart';
import '../../sample/sample_view.dart';
import '../../widgets/controls.dart';

/// Depth chart: DepthChart has its own price axis; use it alone or next to the candles.
class DepthSample extends SampleView {
  const DepthSample({super.key});
  @override
  State<DepthSample> createState() => _DepthSampleState();
}

class _DepthSampleState extends SampleViewState<DepthSample> {
  bool _withKline = true;
  int _levels = 20;
  double _skew = 1;

  List<DepthLevel> _side(bool bid) => [
    for (var i = 1; i <= _levels; i++)
      DepthLevel(
        100 + (bid ? -i : i) * 0.1,
        10.0 + i * (bid ? _skew : 1) + 4 * math.sin(i / 3).abs(),
      ),
  ];

  @override
  Widget buildChart(BuildContext context) {
    final depth = DepthChart(theme: chartTheme, bids: _side(true), asks: _side(false));
    if (!_withKline) return ColoredBox(color: chartTheme.background, child: depth);
    return frame(
      KChart(controller: controller, theme: chartTheme, labels: chartLabels),
      footer: [SizedBox(height: 180, child: depth)],
    );
  }

  @override
  List<Widget> buildSettings(BuildContext context) => [
    Toggle(S.current.depthSampleWithKline, _withKline, (v) => update(() => _withKline = v)),
    Slide(
      S.current.depthSampleLevels,
      _levels.toDouble(),
      5,
      50,
      (v) => update(() => _levels = v.round()),
      divisions: 45,
    ),
    Slide(S.current.depthSampleBidSkew, _skew, 0.5, 3, (v) => update(() => _skew = v)),
  ];

  @override
  String code() =>
      'DepthChart(\n'
      '  theme: theme,\n'
      '  bids: [DepthLevel(price, amount), ...], // $_levels levels\n'
      '  asks: [DepthLevel(price, amount), ...],\n'
      ')';
}
