import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:klinex/klinex.dart';

import '../../l10n/l10n.dart';
import '../../socket/binance_public_ws.dart';
import '../../widget/live_interval_bar.dart';
import '../../widget/live_style.dart';
import '../../widget/theme_toggle_button.dart';
import 'live_chart_view.dart';
import 'live_controller.dart';
import 'live_main_indicator_selector.dart';
import 'live_sheets.dart';
import 'live_sub_indicator_selector.dart';

/// Live market page: interval bar, chart, indicator bar. All state lives in [LiveController]
class LivePage extends StatelessWidget {
  LivePage({super.key});

  final LiveController controller = Get.find();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // LiveStyle is a plain global getter; reading isLiveDark here rebuilds the whole page tree
      // on theme change
      isLiveDark.value;
      return Scaffold(
        backgroundColor: LiveStyle.bgPrimary,
        appBar: AppBar(
          backgroundColor: LiveStyle.bgPrimary,
          foregroundColor: LiveStyle.textPrimary,
          elevation: 0.5,
          centerTitle: true,
          title: _SymbolSwitcher(controller: controller),
          actions: [
            ValueListenableBuilder<bool>(
              valueListenable: BinancePublicWs.instance.connected,
              builder: (_, connected, _) => connected
                  ? const SizedBox.shrink()
                  : Center(
                      child: Text(
                        S.current.liveConnecting,
                        style: TextStyle(fontSize: 11, color: LiveStyle.down),
                      ),
                    ),
            ),
            // Diagnostics: print a separator plus counts/timings of the last segment. Only shown
            // when logging is enabled
            if (KlinexDebug.anyEnabled)
              IconButton(
                tooltip: S.current.liveLogSegment,
                icon: const Icon(Icons.speaker_notes_outlined, size: 18),
                onPressed: () {
                  KlinexDebug.dumpCounters();
                  KlinexDebug.mark('next segment');
                },
              ),
            const ThemeToggleButton(),
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              _IntervalRow(controller: controller),
              _Chart(controller: controller),
              _IndicatorRow(controller: controller),
            ],
          ),
        ),
      );
    });
  }
}

class _SymbolSwitcher extends StatelessWidget {
  const _SymbolSwitcher({required this.controller});

  final LiveController controller;

  @override
  Widget build(BuildContext context) => PopupMenuButton<String>(
    tooltip: S.current.liveSwitchMarket,
    onSelected: controller.setSymbol,
    itemBuilder: (_) => [
      for (final s in LiveController.symbols)
        PopupMenuItem(value: s, child: Text(symbolDisplayName(s))),
    ],
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.menu, size: 16),
        const SizedBox(width: 6),
        Obx(
          () => Text(
            symbolDisplayName(controller.symbol.value),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}

/// Interval | settings
class _IntervalRow extends StatelessWidget {
  const _IntervalRow({required this.controller});

  final LiveController controller;

  @override
  Widget build(BuildContext context) => Container(
    height: 32,
    decoration: BoxDecoration(
      border: Border(bottom: BorderSide(width: 0.5, color: LiveStyle.divider)),
    ),
    child: Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Obx(
              () => LiveIntervalBar(
                selected: controller.interval.value,
                showCount: 5,
                onSelected: controller.setInterval,
              ),
            ),
          ),
        ),
        IconButton(
          tooltip: S.current.liveChartSettings,
          visualDensity: VisualDensity.compact,
          onPressed: () => showLiveSettings(context, controller),
          icon: Icon(Icons.settings_outlined, size: 16, color: LiveStyle.textPrimary),
        ),
      ],
    ),
  );
}

/// Loading / retry on failure / chart
class _Chart extends StatelessWidget {
  const _Chart({required this.controller});

  final LiveController controller;

  @override
  Widget build(BuildContext context) => Obx(() {
    if (controller.loading.value && !controller.hasBars.value) {
      return const SizedBox(height: 330, child: Center(child: CircularProgressIndicator()));
    }
    if (controller.hasError.value && !controller.hasBars.value) {
      return SizedBox(
        height: 330,
        child: Center(
          child: TextButton(
            onPressed: controller.feed.resync,
            child: Text(
              '${controller.feed.error ?? ''}\n${S.current.liveTapToRetry}',
              textAlign: TextAlign.center,
              style: TextStyle(color: LiveStyle.textSecondary),
            ),
          ),
        ),
      );
    }
    controller.indRev.value; // Dependency: indicator count affects the height
    // Symbol / interval switched but new data not landed yet: the chart still shows the old
    // series, so cover it instead of letting it pose as the new market under the new title
    final stale = controller.loading.value && !controller.feed.showsCurrentSeries;
    // Adjustable main height + 64 per sub panel + time axis
    return SizedBox(
      height: controller.chartHeight.value + 64.0 * controller.subPanelCount + 22,
      width: double.infinity,
      child: Stack(
        children: [
          LiveChartView(
            mainFlex: controller.chartHeight.value,
            subFlex: 64,
            controller: controller,
          ),
          if (stale)
            Positioned.fill(
              child: ColoredBox(
                color: LiveStyle.bgPrimary.withValues(alpha: 0.7),
                child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
            ),
        ],
      ),
    );
  });
}

/// Main indicators | sub indicators
class _IndicatorRow extends StatelessWidget {
  const _IndicatorRow({required this.controller});

  final LiveController controller;

  @override
  Widget build(BuildContext context) => Container(
    height: 30,
    decoration: BoxDecoration(
      border: Border(top: BorderSide(width: 0.5, color: LiveStyle.divider)),
    ),
    child: Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: LiveMainIndicatorSelector(controller: controller),
          ),
        ),
        Container(width: 1, height: 12, color: LiveStyle.divider),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: LiveSubIndicatorSelector(controller: controller),
          ),
        ),
      ],
    ),
  );
}
