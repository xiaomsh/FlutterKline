import 'dart:async';

import 'package:flutter/material.dart';
import 'package:klinex/klinex.dart';

import '../../../../l10n/l10n.dart';
import '../../../stock/stock_symbols.dart';
import '../../sample/sample_view.dart';
import '../../sample/stock_sample_data.dart';
import '../../widgets/controls.dart';

/// Intraday chart: fixed minute slots of a trading session, average price line, previous-close
/// baseline with percent on the right axis, limit lines.
class IntradaySample extends SampleView {
  const IntradaySample({super.key});
  @override
  State<IntradaySample> createState() => _IntradaySampleState();
}

class _IntradaySampleState extends SampleViewState<IntradaySample> {
  static const _preClose = 10.0;
  static const _startMinutes = 150;

  final _levels = PriceLevelsOverlay();
  StockMarket _market = StockMarket.a;
  bool _average = true, _percent = true, _limits = true, _limitsInRange = false;
  bool _redUp = true, _live = false;
  late IntradayAxis _axis;
  late List<Bar> _day;
  Timer? _timer;

  TradingSession get _session => _market.session;

  @override
  ChartController createController() => ChartController(overlays: [_levels]);

  @override
  void initState() {
    super.initState();
    _loadMarket();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _loadMarket() {
    _axis = IntradayAxis(_session);
    _day = StockSampleData.intraday(
      _session,
      preClose: _preClose,
      volumeUnit: _market.volumeUnit,
    );
    _applyIndicators();
    controller.setBars(_day.take(_live ? _startMinutes : _day.length).toList());
  }

  void _applyIndicators() => controller.indicators.setAll([
    if (_average)
      AveragePrice(
        session: _session,
        volumeUnit: _market.volumeUnit,
        label: S.current.stockAverage,
      ),
    Vol(),
  ]);

  bool get _showLimits => _limits && _market == StockMarket.a;

  /// The overlay repaints only when the levels differ by value.
  void _applyLevels(KLineTheme theme) {
    final limit = PriceLimit.mainBoard;
    _levels.levels = [
      PriceLevel(_preClose, color: theme.axisText, label: S.current.stockPrevClose),
      if (_showLimits)
        PriceLevel(limit.up(_preClose), color: theme.up, label: S.current.stockLimitUp),
      if (_showLimits)
        PriceLevel(limit.down(_preClose), color: theme.down, label: S.current.stockLimitDown),
    ];
  }

  KLineTheme get _theme => _redUp ? chartTheme.swapUpDown() : chartTheme;

  void _setLive(bool v) {
    _live = v;
    _timer?.cancel();
    if (!v) {
      controller.setBars(_day);
      return;
    }
    controller.setBars(_day.take(_startMinutes).toList());
    _timer = Timer.periodic(const Duration(milliseconds: 300), (_) {
      final next = controller.bars.length;
      if (next >= _day.length) {
        _timer?.cancel();
        return;
      }
      controller.applyTick(_day[next]);
    });
  }

  @override
  Widget buildChart(BuildContext context) {
    final theme = _theme;
    _applyLevels(theme);
    final limit = PriceLimit.mainBoard;
    return frame(
      KChart(
        controller: controller,
        theme: theme,
        labels: chartLabels,
        seriesStyle: MainSeriesStyle.area,
        slotAxis: _axis,
        percentScale: _percent,
        percentBase: _preClose,
        percentRightOnly: true,
        mainRange: StockRange(
          symmetricAround: _preClose,
          include: _showLimits && _limitsInRange
              ? [limit.up(_preClose), limit.down(_preClose)]
              : const [],
        ),
        yAxisPosition: _percent ? YAxisPosition.both : YAxisPosition.outside,
        yAxisWidth: 52,
        timeFormatter: (ms) => _session.formatTime(ms),
      ),
      theme: theme,
    );
  }

  @override
  List<Widget> buildSettings(BuildContext context) => [
    Choice(
      S.current.intradayMarket,
      _market,
      {
        for (final m in StockMarket.values) m: m.label,
      },
      (v) => update(() {
        _market = v;
        _redUp = v.redUp;
        _loadMarket();
      }),
    ),
    Toggle(S.current.intradayAverage, _average, (v) {
      update(() => _average = v);
      _applyIndicators();
    }),
    Toggle(S.current.intradayPercent, _percent, (v) => update(() => _percent = v)),
    if (_market == StockMarket.a) ...[
      Toggle(S.current.intradayLimits, _limits, (v) => update(() => _limits = v)),
      Toggle(
        S.current.intradayLimitsInRange,
        _limitsInRange,
        (v) => update(() => _limitsInRange = v),
      ),
      Text(S.current.intradayRangeHint),
    ],
    Toggle(S.current.stockRedUp, _redUp, (v) => update(() => _redUp = v)),
    Toggle(S.current.intradayLive, _live, (v) => update(() => _setLive(v))),
    Text(S.current.intradayHint),
  ];

  @override
  String code() =>
      'final session = TradingSession.${switch (_market) {
        StockMarket.a => 'cnA',
        StockMarket.hk => 'hk',
        StockMarket.us => 'us',
      }};\n'
      'controller\n'
      '  ..indicators.setAll([${_average ? 'AveragePrice(session: session), ' : ''}Vol()])\n'
      '  ..setBars(session.normalize(minutes, preClose: preClose));\n'
      'KChart(\n'
      '  controller: controller,\n'
      '  theme: ${_redUp ? 'KLineTheme.light().swapUpDown()' : 'KLineTheme.light()'},\n'
      '  seriesStyle: MainSeriesStyle.area,\n'
      '  slotAxis: IntradayAxis(session),\n'
      '  percentScale: $_percent, percentBase: preClose, percentRightOnly: true,\n'
      '  yAxisPosition: YAxisPosition.${_percent ? 'both' : 'outside'},\n'
      '  mainRange: StockRange(symmetricAround: preClose'
      '${_limitsInRange && _limits && _market == StockMarket.a ? ', include: [up, down]' : ''}),\n'
      ')';
}
