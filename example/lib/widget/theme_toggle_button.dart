import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../l10n/l10n.dart';
import 'live_style.dart';

/// Light / dark toggle at the AppBar's top right; the icon flips with [isLiveDark].
class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final dark = isLiveDark.value;
      return IconButton(
        tooltip: dark ? S.current.themeSwitchToLight : S.current.themeSwitchToDark,
        iconSize: 18,
        color: LiveStyle.textPrimary,
        icon: Icon(dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
        onPressed: toggleLiveTheme,
      );
    });
  }
}
