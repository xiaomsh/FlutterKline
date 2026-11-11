import 'package:flutter/material.dart';
import 'package:klinex/klinex.dart';

import '../../../l10n/l10n.dart';
import '../widgets/controls.dart';
import 'sample_entry.dart';

/// Context the shell gives a sample: the current entry and the reset callback.
class SampleScope extends InheritedWidget {
  const SampleScope({super.key, required this.entry, required this.onReset, required super.child});
  final SampleEntry entry;
  final VoidCallback onReset;

  static SampleScope? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SampleScope>();

  @override
  bool updateShouldNotify(SampleScope oldWidget) => entry.id != oldWidget.entry.id;
}

/// Common sample layout: chart left and panel right on wide screens, stacked on narrow ones.
class SampleLayout extends StatelessWidget {
  const SampleLayout({super.key, required this.chart, this.settings = const [], this.code = ''});
  final Widget chart;
  final List<Widget> settings;
  final String code;

  static const panelWidth = 340.0;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final panel = SamplePanel(settings: settings, code: code);
      if (c.maxWidth >= 860) {
        return Row(
          children: [
            Expanded(child: chart),
            const VerticalDivider(width: 1),
            SizedBox(width: panelWidth, child: panel),
          ],
        );
      }
      return Column(
        children: [
          Expanded(flex: 3, child: chart),
          const Divider(height: 1),
          Expanded(flex: 2, child: panel),
        ],
      );
    },
  );
}

/// Settings panel: title, reset, description, controls and equivalent code.
class SamplePanel extends StatelessWidget {
  const SamplePanel({super.key, required this.settings, required this.code});
  final List<Widget> settings;
  final String code;

  @override
  Widget build(BuildContext context) {
    final scope = SampleScope.of(context);
    final text = Theme.of(context).textTheme;
    return Material(
      key: const ValueKey('sample-panel'),
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          if (scope != null)
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Row(
                children: [
                  Expanded(child: Text(scope.entry.title, style: text.titleMedium)),
                  IconButton(
                    tooltip: S.current.sampleResetPage,
                    icon: const Icon(Icons.restart_alt),
                    onPressed: scope.onReset,
                  ),
                ],
              ),
            ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (scope != null && scope.entry.description.isNotEmpty) ...[
                  Text(scope.entry.description, style: text.bodySmall),
                  const SizedBox(height: 12),
                ],
                ...settings,
                if (code.isNotEmpty) CodeBlock(code),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Chart frame: theme background, bar count, back to latest.
class SampleChartFrame extends StatelessWidget {
  const SampleChartFrame({
    super.key,
    required this.controller,
    required this.theme,
    required this.child,
    this.footer = const [],
  });
  final ChartController controller;
  final KLineTheme theme;
  final Widget child;

  /// Extra content below the chart (depth chart, synced charts, etc.).
  final List<Widget> footer;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: theme.background,
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: ValueListenableBuilder(
                  valueListenable: controller.dataRevision,
                  builder: (_, _, _) => Text(
                    S.current.sampleFrameStatus(controller.bars.length),
                    style: TextStyle(color: theme.axisText, fontSize: 12),
                  ),
                ),
              ),
              TextButton(
                // Only scrollToLatest restores auto-follow; setRightIndex just moves and would not
                // follow new bars
                onPressed: controller.viewport.scrollToLatest,
                child: Text(S.current.sampleBackToLatest),
              ),
            ],
          ),
        ),
        Expanded(child: child),
        ...footer,
      ],
    ),
  );
}
