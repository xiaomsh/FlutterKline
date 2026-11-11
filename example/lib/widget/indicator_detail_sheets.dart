import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import 'indicator_configs.dart';
import 'indicator_line_cfg.dart';
import 'indicator_setting_rows.dart';
import 'live_sheet.dart';
import 'live_style.dart';

/// MA/EMA: up to 10 lines, each row toggle + value + color (matches flutter_app).
Future<void> showLinesDetail(
  BuildContext context,
  String name,
  List<LineCfg> lines,
  VoidCallback reset,
  VoidCallback onChanged,
) {
  return showLiveSheet(context, (ctx, setSheet) {
    void changed() {
      onChanged();
      setSheet(() {});
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        LiveSheetHeader(
          title: name,
          onReset: () {
            reset();
            changed();
          },
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  S.current.indicatorLine,
                  style: TextStyle(fontSize: 13, color: LiveStyle.textTertiary),
                ),
              ),
              SizedBox(
                width: 120,
                child: Text(
                  S.current.indicatorReferenceValue,
                  textAlign: TextAlign.right,
                  style: TextStyle(fontSize: 13, color: LiveStyle.textTertiary),
                ),
              ),
              SizedBox(
                width: 96,
                child: Text(
                  S.current.indicatorColor,
                  textAlign: TextAlign.right,
                  style: TextStyle(fontSize: 13, color: LiveStyle.textTertiary),
                ),
              ),
            ],
          ),
        ),
        for (final l in lines)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
            child: Row(
              children: [
                SizedBox(
                  width: 22,
                  height: 22,
                  child: Checkbox(
                    value: l.on,
                    activeColor: LiveStyle.brand,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    onChanged: (v) {
                      l.on = v ?? false;
                      changed();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    name,
                    style: TextStyle(fontSize: 15, color: LiveStyle.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Spacer(),
                numField(
                  width: 110,
                  value: l.period,
                  // Typing only rebuilds indicators (live preview), not setSheet: a sheet
                  // rebuild remounts the field by ValueKey and loses cursor and focus.
                  onChanged: (v) {
                    l.period = v;
                    onChanged();
                  },
                ),
                const SizedBox(width: 10),
                colorDropdown(l.color, (c) {
                  l.color = c;
                  changed();
                }),
              ],
            ),
          ),
        const SizedBox(height: 12),
      ],
    );
  }, scrollable: true);
}

/// BOLL: period/multiplier + MID/UB/LB colors.
Future<void> showBollDetail(
  BuildContext context,
  IndicatorConfigs cfg,
  VoidCallback onChanged,
) {
  return showLiveSheet(context, (ctx, setSheet) {
    void changed() {
      onChanged();
      setSheet(() {});
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        LiveSheetHeader(
          title: 'BOLL',
          onReset: () {
            cfg.resetBoll();
            changed();
          },
        ),
        paramRow(S.current.indicatorPeriod, cfg.bollPeriod, (v) {
          cfg.bollPeriod = v;
          onChanged();
        }),
        // The std-dev multiplier is conventionally decimal (default 2; 1.5 / 2.5 are common).
        // paramRow(int) + bollK.round() used to silently truncate, turning 2.5 into 2.
        numParamRow(S.current.indicatorStdDevMultiplier, cfg.bollK, false, (v) {
          cfg.bollK = v.toDouble();
          onChanged();
        }),
        Divider(height: 20, color: LiveStyle.divider),
        lineColorHeader(),
        for (final (i, label) in const ['MID', 'UB', 'LB'].indexed)
          colorRow(label, cfg.bollColors[i], (c) {
            cfg.bollColors[i] = c;
            changed();
          }),
        const SizedBox(height: 12),
      ],
    );
  }, scrollable: true);
}

/// MACD: short/long/signal periods + DIF/DEA colors (matches the mockup).
Future<void> showMacdDetail(
  BuildContext context,
  IndicatorConfigs cfg,
  VoidCallback onChanged,
) {
  return showLiveSheet(context, (ctx, setSheet) {
    void changed() {
      onChanged();
      setSheet(() {});
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        LiveSheetHeader(
          title: 'MACD',
          onReset: () {
            cfg.resetMacd();
            changed();
          },
        ),
        paramRow(S.current.indicatorShortPeriod, cfg.macdShort, (v) {
          cfg.macdShort = v;
          onChanged();
        }),
        paramRow(S.current.indicatorLongPeriod, cfg.macdLong, (v) {
          cfg.macdLong = v;
          onChanged();
        }),
        paramRow(S.current.indicatorSignalPeriod, cfg.macdSignal, (v) {
          cfg.macdSignal = v;
          onChanged();
        }),
        IndicatorErrorText(cfg.errors, 'MACD'),
        Divider(height: 20, color: LiveStyle.divider),
        lineColorHeader(),
        colorRow('DIF', cfg.macdDif, (c) {
          cfg.macdDif = c;
          changed();
        }),
        colorRow('DEA', cfg.macdDea, (c) {
          cfg.macdDea = c;
          changed();
        }),
        const SizedBox(height: 12),
      ],
    );
  }, scrollable: true);
}

/// KDJ: N/M1/M2 + K/D/J colors.
Future<void> showKdjDetail(
  BuildContext context,
  IndicatorConfigs cfg,
  VoidCallback onChanged,
) {
  return showLiveSheet(context, (ctx, setSheet) {
    void changed() {
      onChanged();
      setSheet(() {});
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        LiveSheetHeader(
          title: 'KDJ',
          onReset: () {
            cfg.resetKdj();
            changed();
          },
        ),
        paramRow(S.current.indicatorPeriodN, cfg.kdjN, (v) {
          cfg.kdjN = v;
          onChanged();
        }),
        paramRow('M1', cfg.kdjM1, (v) {
          cfg.kdjM1 = v;
          onChanged();
        }),
        paramRow('M2', cfg.kdjM2, (v) {
          cfg.kdjM2 = v;
          onChanged();
        }),
        Divider(height: 20, color: LiveStyle.divider),
        lineColorHeader(),
        for (final (i, label) in const ['K', 'D', 'J'].indexed)
          colorRow(label, cfg.kdjColors[i], (c) {
            cfg.kdjColors[i] = c;
            changed();
          }),
        const SizedBox(height: 12),
      ],
    );
  }, scrollable: true);
}

/// Generic detail with one period + one color (RSI/WR/CCI; OBV has color only).
Future<void> showSingleDetail(
  BuildContext context,
  String name,
  int Function()? getPeriod,
  void Function(int)? setPeriod,
  Color Function() getColor,
  void Function(Color) setColor,
  VoidCallback reset,
  VoidCallback onChanged,
) {
  return showLiveSheet(context, (ctx, setSheet) {
    void changed() {
      onChanged();
      setSheet(() {});
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        LiveSheetHeader(
          title: name,
          onReset: () {
            reset();
            changed();
          },
        ),
        if (getPeriod != null && setPeriod != null)
          paramRow(S.current.indicatorPeriod, getPeriod(), (v) {
            setPeriod(v);
            onChanged();
          }),
        Divider(height: 20, color: LiveStyle.divider),
        lineColorHeader(),
        colorRow(name, getColor(), (c) {
          setColor(c);
          changed();
        }),
        const SizedBox(height: 12),
      ],
    );
  }, scrollable: true);
}

/// Generic param item (integer or decimal).
class ParamSpec {
  final String label;
  final num Function() get;
  final void Function(num) set;
  final bool isInt;

  ParamSpec(this.label, this.get, this.set, {this.isInt = true});
}

/// Generic color item.
class ColorSpec {
  final String label;
  final Color Function() get;
  final void Function(Color) set;

  ColorSpec(this.label, this.get, this.set);
}

/// Generic indicator detail: param rows + color rows + reset (shared by new indicators so each
/// needs no page of its own).
Future<void> showSpecDetail(
  BuildContext context,
  String name,
  VoidCallback reset,
  VoidCallback onChanged,
  List<ParamSpec> params,
  List<ColorSpec> colors, {
  Widget? error,
}) {
  return showLiveSheet(context, (ctx, setSheet) {
    void changed() {
      onChanged();
      setSheet(() {});
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        LiveSheetHeader(
          title: name,
          onReset: () {
            reset();
            changed();
          },
        ),
        for (final p in params)
          numParamRow(p.label, p.get(), p.isInt, (v) {
            p.set(v);
            onChanged();
          }),
        ?error,
        if (colors.isNotEmpty) ...[
          Divider(height: 20, color: LiveStyle.divider),
          lineColorHeader(),
          for (final c in colors)
            colorRow(c.label, c.get(), (v) {
              c.set(v);
              changed();
            }),
        ],
        const SizedBox(height: 12),
      ],
    );
  }, scrollable: true);
}

/// Shared indicator param validation: non-empty, finite, positive, at most 100,000.
/// The cap matters: '1e999' parses to Infinity and a later toInt() throws.
num? parseIndicatorParam(String s) {
  final v = num.tryParse(s.trim());
  if (v == null || !v.isFinite || v <= 0 || v > 100000) return null;
  return v;
}

/// Hint shown when invalid params prevent building the indicator; refreshes with the config's
/// `errors` (no field rebuild, no focus loss).
class IndicatorErrorText extends StatelessWidget {
  const IndicatorErrorText(this.errors, this.name, {super.key});
  final ValueListenable<Map<String, String>> errors;
  final String name;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder(
    valueListenable: errors,
    builder: (_, errors, _) {
      final e = errors[name];
      if (e == null) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        child: Text(e, style: const TextStyle(fontSize: 13, color: Color(0xFFEF5350))),
      );
    },
  );
}
