import 'package:flutter/material.dart';

import '../widget/live_style.dart';

/// Global Material theme; only handles light/dark for built-in Material widgets.
/// Chart colors come from `LiveStyle` / `kChartTheme`; both are driven by the same `isLiveDark`.
class ThemeStyle {
  ThemeStyle._();

  static final lightTheme = _build(
    base: ThemeData.light(),
    palette: LivePalette.light,
  );

  static final darkTheme = _build(
    base: ThemeData.dark(),
    palette: LivePalette.dark,
  );

  static ThemeData _build({required ThemeData base, required LivePalette palette}) {
    return base.copyWith(
      scaffoldBackgroundColor: palette.bgPrimary,
      canvasColor: palette.bgPrimary,
      dividerColor: palette.divider,
      appBarTheme: AppBarTheme(
        backgroundColor: palette.bgPrimary,
        surfaceTintColor: palette.bgPrimary,
        foregroundColor: palette.textPrimary,
      ),
      textTheme: base.textTheme.apply(
        fontFamily: "PlusJakartaSans",
        bodyColor: palette.textPrimary,
        displayColor: palette.textPrimary,
      ),
      iconTheme: IconThemeData(color: palette.textPrimary),
      dialogTheme: DialogThemeData(backgroundColor: palette.bgPrimary),
      bottomSheetTheme: BottomSheetThemeData(backgroundColor: palette.bgPrimary),
      sliderTheme: base.sliderTheme.copyWith(
        activeTrackColor: palette.brand,
        thumbColor: palette.brand,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: palette.textPrimary,
        unselectedLabelColor: palette.textTertiary,
      ),
      toggleButtonsTheme: ToggleButtonsThemeData(
        selectedColor: palette.brand,
        borderColor: palette.divider,
      ),
    );
  }
}
