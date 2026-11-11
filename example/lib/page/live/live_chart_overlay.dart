import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:klinex/klinex.dart';

import '../../widget/axis_price_tags.dart';
import 'live_controller.dart';

/// Chart overlay: y-axis price tags (last price, countdown, best bid/ask)
class LiveChartOverlay extends StatelessWidget {
  const LiveChartOverlay({super.key, required this.ctx, required this.controller});

  final RenderContext ctx;
  final LiveController controller;

  @override
  Widget build(BuildContext context) {
    // Wraps its own Obx: this is called by klinex's ListenableBuilder, outside any Obx; without
    // it the toggles below are not subscribed and only refresh on the next tick or pan
    return Obx(() {
      // Toggles must be read synchronously in the Obx builder; inside the ValueListenableBuilder
      // below they would not be subscribed
      final showPrice = controller.showPrice.value;
      final showCountdown = controller.showCountdown.value;
      final showBook = controller.showBookPrice.value;
      return ValueListenableBuilder(
        valueListenable: controller.feed.book,
        builder: (_, book, _) => AxisPriceTags(
          ctx: ctx,
          showPrice: showPrice,
          // After an interval switch, until new data lands the chart shows old-interval bars, so a
          // countdown for the new interval would be wrong
          showCountdown: showCountdown && controller.feed.showsCurrentSeries,
          calendarMonths: controller.feed.interval == '1M' ? 1 : null,
          book: showBook ? book : null,
        ),
      );
    });
  }
}
