import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:klinex/klinex.dart';

import '../l10n/l10n.dart';

/// Single source of truth for dark / light. Chart UI colors are driven by this global Rx instead
/// of Theme.of(context); not persisted, so a restart goes back to light
final RxBool isLiveDark = false.obs;

void toggleLiveTheme() {
  isLiveDark.value = !isLiveDark.value;
  Get.changeThemeMode(isLiveDark.value ? ThemeMode.dark : ThemeMode.light);
}

/// A chart UI palette. Dark matches klinex's `KLineTheme.dark()` so the canvas and surrounding
/// widgets share one color family
class LivePalette {
  const LivePalette({
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.bgPrimary,
    required this.divider,
    required this.inputFill,
    required this.brand,
    required this.brandAlert,
    required this.up,
    required this.down,
  });

  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color bgPrimary;
  final Color divider;
  final Color inputFill;
  final Color brand;
  final Color brandAlert;
  final Color up;
  final Color down;

  static const light = LivePalette(
    textPrimary: Color(0xFF13161C),
    textSecondary: Color(0xFF717C95),
    textTertiary: Color(0xFFA6AEC1),
    bgPrimary: Color(0xFFFFFFFF),
    divider: Color(0xFFF1F2F5),
    inputFill: Color(0xFFF1F2F5),
    brand: Color(0xFF195EFF),
    brandAlert: Color(0x33195EFF),
    up: Color(0xFF2CA85D),
    down: Color(0xFFEB464F),
  );

  static const dark = LivePalette(
    textPrimary: Color(0xFFE8ECF4),
    textSecondary: Color(0xFF8A93A6),
    textTertiary: Color(0xFF5E6779),
    bgPrimary: Color(0xFF141822),
    divider: Color(0xFF232834),
    inputFill: Color(0xFF1E2430),
    brand: Color(0xFF4C82FF),
    brandAlert: Color(0x334C82FF),
    up: Color(0xFF33B86B),
    down: Color(0xFFF4555F),
  );
}

LivePalette get livePalette => isLiveDark.value ? LivePalette.dark : LivePalette.light;

/// Accessors for the chart UI palette. Getters rather than constants so theme switches apply
/// immediately, which means widgets using them cannot be const.
class LiveStyle {
  LiveStyle._();

  static Color get textPrimary => livePalette.textPrimary;

  static Color get textSecondary => livePalette.textSecondary;

  static Color get textTertiary => livePalette.textTertiary;

  static Color get bgPrimary => livePalette.bgPrimary;

  static Color get divider => livePalette.divider;

  static Color get inputFill => livePalette.inputFill;

  static Color get brand => livePalette.brand;

  static Color get brandAlert => livePalette.brandAlert;

  static Color get up => livePalette.up;

  static Color get down => livePalette.down;
}

/// Chart theme shared across the app. One cached instance per mode; do not copyWith in build:
/// KLineTheme has no value equality, so every new instance triggers a full repaint
final KLineTheme _chartThemeLight = KLineTheme.light().copyWith(
  crosshairDash: [4, 4],
);
final KLineTheme _chartThemeDark = KLineTheme.dark().copyWith(
  crosshairDash: [4, 4],
);

KLineTheme get kChartTheme => isLiveDark.value ? _chartThemeDark : _chartThemeLight;

/// Initial right blank ratio. KChart and BackToLatestButton must use the same value
const double kInitialRightBlankRatio = 0.1;

/// All intervals (in API order).
const List<String> liveAllIntervals = [
  '1m',
  '3m',
  '5m',
  '15m',
  '30m',
  '1h',
  '2h',
  '4h',
  '6h',
  '8h',
  '12h',
  '1d',
  '3d',
  '1w',
  '1M',
];

/// Display order: common intervals first (matching flutter_app's default), the rest go to "More".
const List<String> liveSortedIntervals = [
  '15m',
  '1h',
  '4h',
  '1d',
  '1w',
  '1m',
  '3m',
  '5m',
  '30m',
  '2h',
  '6h',
  '8h',
  '12h',
  '3d',
  '1M',
];

String intervalLabel(String interval) => switch (interval) {
  '1m' => S.current.liveInterval1m,
  '3m' => S.current.liveInterval3m,
  '5m' => S.current.liveInterval5m,
  '15m' => S.current.liveInterval15m,
  '30m' => S.current.liveInterval30m,
  '1h' => S.current.liveInterval1h,
  '2h' => S.current.liveInterval2h,
  '4h' => S.current.liveInterval4h,
  '6h' => S.current.liveInterval6h,
  '8h' => S.current.liveInterval8h,
  '12h' => S.current.liveInterval12h,
  '1d' => S.current.liveInterval1d,
  '3d' => S.current.liveInterval3d,
  '1w' => S.current.liveInterval1w,
  '1M' => S.current.liveInterval1M,
  _ => interval,
};

/// Symbol display name: btc_usdt is shown as BTC/USDT.
String symbolDisplayName(String symbol) => symbol.replaceAll('_', '/').toUpperCase();

/// Adaptive decimal places for crypto prices.
String fmtPrice(double? v) {
  if (v == null) return '--';
  final a = v.abs();
  if (a >= 1000) return v.toStringAsFixed(2);
  if (a >= 1) return v.toStringAsFixed(3);
  return v.toStringAsFixed(6);
}

/// Compact volume (K/M/B).
String fmtCompact(double? v) {
  if (v == null) return '--';
  final a = v.abs();
  if (a >= 1e9) return '${(v / 1e9).toStringAsFixed(2)}B';
  if (a >= 1e6) return '${(v / 1e6).toStringAsFixed(2)}M';
  if (a >= 1e3) return '${(v / 1e3).toStringAsFixed(2)}K';
  return v.toStringAsFixed(2);
}

/// Change rate: [rate] is a fraction (0.0123 is shown as +1.23%).
String fmtRate(double? rate) {
  if (rate == null) return '--';
  final v = rate * 100;
  return '${v >= 0 ? '+' : ''}${v.toStringAsFixed(2)}%';
}
