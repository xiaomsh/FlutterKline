import 'package:flutter/material.dart';
import 'package:klinex/klinex.dart';

import '../../../../l10n/l10n.dart';
import '../../../../widget/indicator_configs.dart';
import '../../../../widget/indicator_detail_sheets.dart';
import '../../sample/sample_view.dart';
import '../../widgets/indicator_fields.dart';

/// Parameters and colors of built-in indicators: one widget, a parameter page per [name].
class IndicatorParamSample extends SampleView {
  const IndicatorParamSample(this.name, {super.key});

  /// MA / EMA / BOLL / MACD / KDJ / RSI / WR
  final String name;

  static const names = ['MA', 'EMA', 'BOLL', 'MACD', 'KDJ', 'RSI', 'WR'];
  static const mainNames = {'MA', 'EMA', 'BOLL'};

  @override
  State<IndicatorParamSample> createState() => _IndicatorParamSampleState();
}

class _IndicatorParamSampleState extends SampleViewState<IndicatorParamSample> {
  final _c = IndicatorConfigs();

  String get _name => widget.name;
  bool get _isMain => IndicatorParamSample.mainNames.contains(_name);

  @override
  ChartController createController() => super.createController()..indicators.setAll(_build());

  List<Indicator> _build() => _c.build(_isMain ? {_name} : {}, _isMain ? {} : {_name});

  void _changed() {
    controller.indicators.setAll(_build());
    update(() {});
  }

  /// Parameter and color specs (MA / EMA use the multi-line `lines`).
  (List<ParamSpec>, List<ColorSpec>) get _specs => switch (_name) {
    'BOLL' => (
      [
        ParamSpec(
          S.current.indicatorParamSamplePeriod,
          () => _c.bollPeriod,
          (v) => _c.bollPeriod = v.toInt(),
        ),
        ParamSpec(
          S.current.indicatorParamSampleStdDev,
          () => _c.bollK,
          (v) => _c.bollK = v.toDouble(),
          isInt: false,
        ),
      ],
      [
        for (final (i, label) in ['MID', 'UB', 'LB'].indexed)
          ColorSpec(label, () => _c.bollColors[i], (v) => _c.bollColors[i] = v),
      ],
    ),
    'MACD' => (
      [
        ParamSpec(
          S.current.indicatorParamSampleShortPeriod,
          () => _c.macdShort,
          (v) => _c.macdShort = v.toInt(),
        ),
        ParamSpec(
          S.current.indicatorParamSampleLongPeriod,
          () => _c.macdLong,
          (v) => _c.macdLong = v.toInt(),
        ),
        ParamSpec(
          S.current.indicatorParamSampleSignalPeriod,
          () => _c.macdSignal,
          (v) => _c.macdSignal = v.toInt(),
        ),
      ],
      [
        ColorSpec('DIF', () => _c.macdDif, (v) => _c.macdDif = v),
        ColorSpec('DEA', () => _c.macdDea, (v) => _c.macdDea = v),
      ],
    ),
    'KDJ' => (
      [
        ParamSpec(S.current.indicatorParamSamplePeriod, () => _c.kdjN, (v) => _c.kdjN = v.toInt()),
        ParamSpec(
          S.current.indicatorParamSampleKSmooth,
          () => _c.kdjM1,
          (v) => _c.kdjM1 = v.toInt(),
        ),
        ParamSpec(
          S.current.indicatorParamSampleDSmooth,
          () => _c.kdjM2,
          (v) => _c.kdjM2 = v.toInt(),
        ),
      ],
      [
        for (final (i, label) in ['K', 'D', 'J'].indexed)
          ColorSpec(label, () => _c.kdjColors[i], (v) => _c.kdjColors[i] = v),
      ],
    ),
    'RSI' => (
      [
        ParamSpec(
          S.current.indicatorParamSamplePeriod,
          () => _c.rsiPeriod,
          (v) => _c.rsiPeriod = v.toInt(),
        ),
      ],
      [ColorSpec('RSI', () => _c.rsiColor, (v) => _c.rsiColor = v)],
    ),
    'WR' => (
      [
        ParamSpec(
          S.current.indicatorParamSamplePeriod,
          () => _c.wrPeriod,
          (v) => _c.wrPeriod = v.toInt(),
        ),
      ],
      [ColorSpec('WR', () => _c.wrColor, (v) => _c.wrColor = v)],
    ),
    _ => (const <ParamSpec>[], const <ColorSpec>[]),
  };

  @override
  Widget buildChart(BuildContext context) =>
      frame(KChart(controller: controller, theme: chartTheme, labels: chartLabels));

  @override
  List<Widget> buildSettings(BuildContext context) {
    final (params, colors) = _specs;
    return [
      IndicatorFields(
        params: params,
        colors: colors,
        lines: switch (_name) {
          'MA' => _c.maLines,
          'EMA' => _c.emaLines,
          _ => null,
        },
        onChanged: _changed,
      ),
      if (_c.errors.value[_name] case final e?)
        Text(e, style: TextStyle(color: Theme.of(context).colorScheme.error)),
      Text(S.current.indicatorParamSampleHint),
    ];
  }

  @override
  String code() {
    final i = controller.indicators.list.firstOrNull;
    if (i == null) {
      return _c.errors.value.containsKey(_name)
          ? '// Invalid parameters; $_name is not added.'
          : '// All lines are off; $_name is not added.';
    }
    return switch (i) {
      Ma() => 'Ma(periods: ${i.periods}, colors: ${_colors(i.colors)})',
      Ema() => 'Ema(periods: ${i.periods}, colors: ${_colors(i.colors)})',
      Boll() => 'Boll(period: ${i.period}, k: ${i.k}, colors: ${_colors(i.colors)})',
      Macd() =>
        'Macd(short: ${i.short}, long: ${i.long}, signal: ${i.signal},\n'
            '  difColor: ${_color(i.difColor)}, deaColor: ${_color(i.deaColor)})',
      Kdj() => 'Kdj(n: ${i.n}, m1: ${i.m1}, m2: ${i.m2}, colors: ${_colors(i.colors)})',
      Rsi() => 'Rsi(period: ${i.periods.first}, color: ${_color(i.colors?.first)})',
      Wr() => 'Wr(period: ${i.periods.first}, color: ${_color(i.colors?.first)})',
      _ => '${i.runtimeType}()',
    };
  }
}

String _color(Color? c) =>
    c == null ? 'null' : 'Color(0x${c.toARGB32().toRadixString(16).toUpperCase()})';

String _colors(List<Color>? cs) => cs == null ? 'null' : '[${cs.map(_color).join(', ')}]';
