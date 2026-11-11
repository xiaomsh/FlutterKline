import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:klinex/klinex.dart';

import 'generated/l10n.dart';

export 'generated/l10n.dart';

/// Tooltip and semantics labels for [KChart] in the current app language. Read `S.current` in
/// `build` (not cached in fields): switching the language rebuilds the widget tree but does not
/// re-run controller setup.
KChartLabels get chartLabels => KChartLabels(
  time: S.current.chartTime,
  open: S.current.chartOpen,
  high: S.current.chartHigh,
  low: S.current.chartLow,
  close: S.current.chartClose,
  changePercent: S.current.chartChange,
  volume: S.current.chartVolume,
  chart: S.current.chartName,
  rangeTo: S.current.chartRangeTo,
  latest: S.current.chartLatest,
  separator: S.current.chartSeparator,
);

/// The demo speaks English by default and only changes language from the home page switch.
abstract final class AppLanguage {
  static const english = Locale('en');
  static const chinese = Locale('zh');

  static bool get isChinese => Get.locale?.languageCode == chinese.languageCode;

  /// Loads the strings before the rebuild, so widgets never read the previous language.
  static Future<void> change(Locale locale) async {
    await S.load(locale);
    await Get.updateLocale(locale);
  }

  static Future<void> toggle() => change(isChinese ? english : chinese);
}
