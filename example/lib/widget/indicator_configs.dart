import 'package:flutter/material.dart';
import 'package:klinex/klinex.dart';

import '../l10n/l10n.dart';
import 'indicator_line_cfg.dart';

/// Palette for the color dropdown (matches the color picker in flutter_app indicator settings).
const List<Color> kIndicatorPalette = [
  Color(0xFFF0A732), // Orange
  Color(0xFF4A90E2), // Blue
  Color(0xFFB569D4), // Purple
  Color(0xFF6A0DAD), // Dark purple
  Color(0xFF7ED66C), // Light green
  Color(0xFFA61D45), // Wine red
  Color(0xFFE24AA5), // Rose
  Color(0xFF3FD6A9), // Teal
  Color(0xFF1673FF), // Bright blue
  Color(0xFFFF7A00), // Bright orange
];

/// Indicator params/colors hub: detail sheets read and write it, build() yields klinex
/// indicators. Not persisted (resets on restart, per this project's "no local storage" rule).
class IndicatorConfigs {
  IndicatorConfigs() {
    resetMa();
    resetEma();
    resetBoll();
    resetMacd();
    resetKdj();
    resetRsi();
    resetWr();
  }

  static const int maxLines = 10;

  /// Multi-line configs. Reset mutates in place, so references held by detail sheets stay valid.
  final List<LineCfg> maLines = [];
  final List<LineCfg> emaLines = [];

  late int bollPeriod;
  late double bollK;
  late List<Color> bollColors; // MID / UB / LB

  late int macdShort, macdLong, macdSignal;
  late Color macdDif, macdDea;

  late int kdjN, kdjM1, kdjM2;
  late List<Color> kdjColors; // K / D / J

  late int rsiPeriod;
  late Color rsiColor;

  late int wrPeriod;
  late Color wrColor;

  static void resetLines(List<LineCfg> lines, List<int> periods) {
    lines
      ..clear()
      ..addAll([
        for (var i = 0; i < maxLines; i++)
          LineCfg(
            on: i < periods.length,
            period: i < periods.length ? periods[i] : null,
            color: kIndicatorPalette[i % kIndicatorPalette.length],
          ),
      ]);
  }

  void resetMa() => resetLines(maLines, const [7, 25, 99]);

  void resetEma() => resetLines(emaLines, const [7, 25, 99]);

  void resetBoll() {
    bollPeriod = 20;
    bollK = 2;
    bollColors = [
      kIndicatorPalette[0],
      kIndicatorPalette[1],
      kIndicatorPalette[2],
    ];
  }

  void resetMacd() {
    macdShort = 12;
    macdLong = 26;
    macdSignal = 9;
    macdDif = kIndicatorPalette[0];
    macdDea = kIndicatorPalette[1];
  }

  void resetKdj() {
    kdjN = 9;
    kdjM1 = 3;
    kdjM2 = 3;
    kdjColors = [
      kIndicatorPalette[0],
      kIndicatorPalette[1],
      kIndicatorPalette[2],
    ];
  }

  void resetRsi() {
    rsiPeriod = 14;
    rsiColor = kIndicatorPalette[0];
  }

  void resetWr() {
    wrPeriod = 14;
    wrColor = kIndicatorPalette[2];
  }

  (List<int>, List<Color>) _active(List<LineCfg> lines) {
    final periods = <int>[];
    final colors = <Color>[];
    for (final l in lines) {
      final p = l.period;
      if (l.on && p != null && p > 0) {
        periods.add(p);
        colors.add(l.color);
      }
    }
    return (periods, colors);
  }

  /// Indicators skipped in the last [build] due to invalid params, with reasons
  /// (e.g. MACD short period not below the long one).
  final errors = ValueNotifier<Map<String, String>>(const {});
  final Map<String, String> _found = {};

  /// Constructors throw [ArgumentError] for invalid combinations: skip that indicator and record
  /// it in [errors]; others proceed.
  Indicator? _guard(String name, Indicator Function() make) {
    try {
      return make();
      // User-edited params boundary; library constructors report invalid combos via ArgumentError.
      // ignore: avoid_catching_errors
    } on ArgumentError catch (e) {
      _found[name] = S.current.indicatorParamsNotApplied(name, '${e.message}');
      return null;
    }
  }

  /// Builds indicators from the current config + selection (new params = new id, full recompute).
  List<Indicator> build(Set<String> main, Set<String> sub) {
    _found.clear();
    final (maP, maC) = _active(maLines);
    final (emaP, emaC) = _active(emaLines);
    final out = [
      if (main.contains('MA') && maP.isNotEmpty) ?_guard('MA', () => Ma(periods: maP, colors: maC)),
      if (main.contains('EMA') && emaP.isNotEmpty)
        ?_guard('EMA', () => Ema(periods: emaP, colors: emaC)),
      if (main.contains('BOLL'))
        ?_guard('BOLL', () => Boll(period: bollPeriod, k: bollK, colors: bollColors)),
      // VOL draws translucent volume bars at the bottom of the main chart, not in a sub panel.
      if (sub.contains('VOL')) VolOverlay(),
      if (sub.contains('MACD'))
        ?_guard(
          'MACD',
          () => Macd(
            short: macdShort,
            long: macdLong,
            signal: macdSignal,
            difColor: macdDif,
            deaColor: macdDea,
          ),
        ),
      if (sub.contains('KDJ'))
        ?_guard('KDJ', () => Kdj(n: kdjN, m1: kdjM1, m2: kdjM2, colors: kdjColors)),
      if (sub.contains('RSI')) ?_guard('RSI', () => Rsi(period: rsiPeriod, color: rsiColor)),
      if (sub.contains('WR')) ?_guard('WR', () => Wr(period: wrPeriod, color: wrColor)),
    ];
    errors.value = Map.unmodifiable(_found);
    return out;
  }
}
