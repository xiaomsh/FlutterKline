import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../pro/live_pro.dart';
import '../../widget/indicator_selector.dart';
import 'live_controller.dart';

/// Main chart indicator selector
class LiveMainIndicatorSelector extends StatelessWidget {
  const LiveMainIndicatorSelector({
    super.key,
    required this.controller,
  });

  final LiveController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      controller.indRev.value; // Dependency: refresh highlight on indicator toggle
      return IndicatorSelector(
        options: LiveController.mainOptions,
        locked: LivePro.unlocked ? const {} : LivePro.mainOptions.toSet(),
        selected: controller.main,
        onToggle: (k) => controller.toggleIndicator(controller.main, k),
      );
    });
  }
}
