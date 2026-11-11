import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:klinex/klinex.dart';

import '../../l10n/l10n.dart';
import '../../widget/back_to_latest_button.dart';
import '../../widget/live_style.dart';
import 'live_chart_overlay.dart';
import 'live_controller.dart';

/// The chart itself on the live page
class LiveChartView extends StatelessWidget {
  const LiveChartView({
    super.key,
    required this.mainFlex,
    required this.subFlex,
    required this.controller,
  });

  final double mainFlex;
  final double subFlex;
  final LiveController controller;

  @override
  Widget build(BuildContext context) {
    // Subscribes itself: reads the log scale, style and time zone toggles below
    return Obx(() {
      return Stack(
        children: [
          KChart(
            controller: controller.chart,
            theme: kChartTheme,
            labels: chartLabels,
            initialRightBlankRatio: kInitialRightBlankRatio,
            // Vertical drag only on the axis; the chart area leaves vertical scrolling to the page
            yPan: YPanMode.axis,
            mainFlex: mainFlex,
            subFlex: subFlex,
            logScale: controller.isLog.value,
            percentScale: controller.percent.value,
            outlierClampRatio: 0.5,
            animatePrice: true,
            series: controller.series,
            utcOffset: controller.utcOffset.value,
            yAxisPosition: controller.yAxisOutside.value
                ? YAxisPosition.outside
                : YAxisPosition.inside,
            autoFollow: controller.autoFollow.value,
            priceFormatter: fmtPrice,
            overlayBuilder: (con, ctx) => LiveChartOverlay(ctx: ctx, controller: controller),
            onLoadMore: controller.feed.loadMore,
          ),
          BackToLatestButton(
            controller: controller.chart,
            initialRightBlankRatio: kInitialRightBlankRatio,
          ),
        ],
      );
    });
  }
}
