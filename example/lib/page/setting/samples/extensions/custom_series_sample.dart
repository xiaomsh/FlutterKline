import 'package:flutter/material.dart';
import 'package:klinex/klinex.dart';

import '../../../../l10n/l10n.dart';
import '../../sample/sample_view.dart';
import '../../widgets/controls.dart';

/// Custom main series: implement MainSeries.paint.
class CustomSeriesSample extends SampleView {
  const CustomSeriesSample({super.key});
  @override
  State<CustomSeriesSample> createState() => _CustomSeriesSampleState();
}

class _CustomSeriesSampleState extends SampleViewState<CustomSeriesSample> {
  bool _custom = true;
  double _radius = 2;

  @override
  Widget buildChart(BuildContext context) => frame(
    KChart(
      controller: controller,
      theme: chartTheme,
      labels: chartLabels,
      series: _custom ? DotSeries(_radius) : null,
    ),
  );

  @override
  List<Widget> buildSettings(BuildContext context) => [
    Toggle(S.current.customSeriesSampleDots, _custom, (v) => update(() => _custom = v)),
    Slide(S.current.customSeriesSampleRadius, _radius, 1, 5, (v) => update(() => _radius = v)),
    Text(S.current.customSeriesSampleHint),
  ];

  @override
  String code() => _custom
      ? 'class DotSeries extends MainSeries {\n'
            '  const DotSeries(this.radius);\n'
            '  final double radius;\n'
            '  @override\n'
            "  String get kind => 'dots';\n"
            '  @override\n'
            '  bool get usesHighLow => false; // value range uses close only\n'
            '  @override\n'
            '  void paint(Canvas canvas, RenderContext ctx, SeriesPaintKit kit) {\n'
            '    final paint = ctx.pool.fill..color = ctx.theme.seriesLine;\n'
            '    for (var i = ctx.start; i <= ctx.end; i++) {\n'
            '      canvas.drawCircle(Offset(ctx.xOf(i), ctx.mainPanel.yOf(ctx.bars[i].close)), radius, paint);\n'
            '    }\n'
            '  }\n'
            '}\n'
            'KChart(series: const DotSeries(${_radius.toStringAsFixed(1)}), ...)'
      : 'KChart(series: null, ...) // uses seriesStyle';
}

/// Close price dots.
class DotSeries extends MainSeries {
  const DotSeries(this.radius);
  final double radius;

  @override
  String get kind => 'dots';

  @override
  bool get usesHighLow => false;

  @override
  void paint(Canvas canvas, RenderContext ctx, SeriesPaintKit kit) {
    final paint = ctx.pool.fill..color = ctx.theme.seriesLine;
    for (var i = ctx.start; i <= ctx.end; i++) {
      canvas.drawCircle(Offset(ctx.xOf(i), ctx.mainPanel.yOf(ctx.bars[i].close)), radius, paint);
    }
  }

  @override
  bool operator ==(Object other) => other is DotSeries && other.radius == radius;

  @override
  int get hashCode => Object.hash(DotSeries, radius);
}
