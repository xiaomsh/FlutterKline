import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:klinex/klinex.dart';

import '../../../../l10n/l10n.dart';
import '../../sample/sample_view.dart';
import '../../widgets/controls.dart';

/// Theme: light / dark base, up / down colors, indicator palette.
class ThemeSample extends SampleView {
  const ThemeSample({super.key});
  @override
  State<ThemeSample> createState() => _ThemeSampleState();
}

class _ThemeSampleState extends SampleViewState<ThemeSample> {
  String _base = 'follow', _palette = 'default';

  KLineTheme get _theme {
    final base = switch (_base) {
      'light' => KLineTheme.light(),
      'dark' => KLineTheme.dark(),
      _ => chartTheme,
    };
    return switch (_palette) {
      'ocean' => base.copyWith(up: const Color(0xFF2196F3), down: const Color(0xFFFF9800)),
      'warm' => base.copyWith(
        palette: const [Color(0xFFF08A5D), Color(0xFFB83B5E), Color(0xFF6A2C70)],
      ),
      _ => base,
    };
  }

  @override
  Widget buildChart(BuildContext context) {
    final theme = _theme;
    return frame(
      KChart(controller: controller, theme: theme, labels: chartLabels),
      theme: theme,
    );
  }

  @override
  List<Widget> buildSettings(BuildContext context) => [
    Choice(S.current.themeSampleBase, _base, {
      'follow': S.current.themeSampleBaseFollow,
      'light': 'KLineTheme.light()',
      'dark': 'KLineTheme.dark()',
    }, (v) => update(() => _base = v)),
    Choice(S.current.themeSamplePalette, _palette, {
      'default': S.current.themeSamplePaletteDefault,
      'ocean': S.current.themeSamplePaletteOcean,
      'warm': S.current.themeSamplePaletteWarm,
    }, (v) => update(() => _palette = v)),
    Text(S.current.themeSampleHint),
  ];

  @override
  String code() =>
      'final theme = KLineTheme.fromJson(\n'
      '${const JsonEncoder.withIndent('  ').convert(_theme.toJson())}\n);';
}
