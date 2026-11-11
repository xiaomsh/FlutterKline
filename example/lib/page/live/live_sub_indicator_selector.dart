import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../pro/live_pro.dart';
import '../../widget/indicator_selector.dart';
import 'live_controller.dart';

/// Sub chart indicator selector
class LiveSubIndicatorSelector extends StatelessWidget {
  const LiveSubIndicatorSelector({
    super.key,
    required this.controller,
  });

  final LiveController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      controller.indRev.value;
      return IndicatorSelector(
        options: LiveController.subOptions,
        locked: LivePro.unlocked ? const {} : LivePro.subOptions.toSet(),
        selected: controller.sub,
        onToggle: (k) => controller.toggleIndicator(controller.sub, k),
      );
    });
  }
}
