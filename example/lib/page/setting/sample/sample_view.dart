import 'package:flutter/material.dart';
import 'package:klinex/klinex.dart';

import 'sample_data.dart';
import 'sample_feed.dart';
import 'sample_layout.dart';

/// The sample chart theme follows the app brightness.
KLineTheme sampleTheme(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark ? KLineTheme.dark() : KLineTheme.light();

/// One sample per catalog feature: it creates its own controller, chart, settings panel and
/// equivalent code, sharing no state with other samples. Reset = the shell rebuilds the whole
/// sample with a new key.
abstract class SampleView extends StatefulWidget {
  const SampleView({super.key});
}

abstract class SampleViewState<T extends SampleView> extends State<T> {
  /// The sample's own controller, disposed with the sample.
  late final ChartController controller = createController();

  /// Defaults to 600 synthetic bars + MA / MACD; samples override as needed.
  ChartController createController() =>
      ChartController(indicators: [Ma(), Macd()])..setBars(SampleData.bars());

  /// The chart area, usually `frame(KChart(...))`.
  Widget buildChart(BuildContext context);

  /// Controls in the settings panel.
  List<Widget> buildSettings(BuildContext context) => const [];

  /// Code equivalent to the current settings; an empty string hides it.
  String code() => '';

  /// Changes settings: refreshes the chart, panel and equivalent code.
  void update(VoidCallback change) => setState(change);

  KLineTheme get chartTheme => sampleTheme(context);

  /// Wraps the common frame (background, bar count, back to latest); [theme] defaults to
  /// [chartTheme].
  Widget frame(Widget chart, {KLineTheme? theme, List<Widget> footer = const []}) =>
      SampleChartFrame(
        controller: controller,
        theme: theme ?? chartTheme,
        footer: footer,
        child: chart,
      );

  @override
  Widget build(BuildContext context) =>
      SampleLayout(chart: buildChart(context), settings: buildSettings(context), code: code());

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}

/// Mixin for samples needing push / history / limit: [feed] drives [controller] and data changes
/// refresh the panel.
mixin SampleFeedMixin<T extends SampleView> on SampleViewState<T> {
  late final SampleFeed feed = createFeed();

  /// Initial bar count.
  int get initialBars => 600;

  SampleFeed createFeed() => SampleFeed(controller, initial: initialBars);

  @override
  ChartController createController() => ChartController(indicators: [Ma(), Macd()]);

  @override
  void initState() {
    super.initState();
    feed.addListener(_changed);
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    feed
      ..removeListener(_changed)
      ..dispose();
    super.dispose();
  }
}
