import 'package:flutter/material.dart';
import 'package:klinex/klinex.dart';

import '../../../../l10n/l10n.dart';
import '../../sample/sample_view.dart';
import '../../sample/stock_sample_data.dart';
import '../../widgets/controls.dart';

/// Daily bars on trading days only, limit up / down marks and the red-up color convention.
class StockDailySample extends SampleView {
  const StockDailySample({super.key});
  @override
  State<StockDailySample> createState() => _StockDailySampleState();
}

class _StockDailySampleState extends SampleViewState<StockDailySample> {
  final _marks = LimitMarksOverlay();
  _Board _board = _Board.main;
  bool _showMarks = true, _labels = true, _redUp = true;

  @override
  ChartController createController() => ChartController(
    indicators: [
      Ma(periods: const [5, 10, 20]),
      Vol(),
    ],
    overlays: [_marks],
  )..setBars(StockSampleData.daily(240));

  @override
  void initState() {
    super.initState();
    _applyMarks();
  }

  void _applyMarks() => _marks
    ..limit = _showMarks ? _board.limit : null
    ..upLabel = _labels ? S.current.stockLimitUpShort : null
    ..downLabel = _labels ? S.current.stockLimitDownShort : null;

  void _setBoard(_Board b) {
    _board = b;
    controller.setBars(StockSampleData.daily(240, limit: b.limit));
    _applyMarks();
  }

  @override
  Widget buildChart(BuildContext context) {
    final theme = _redUp ? chartTheme.swapUpDown() : chartTheme;
    return frame(
      KChart(
        controller: controller,
        theme: theme,
        labels: chartLabels,
        tieredTimeAxis: true,
        utcOffset: const Duration(hours: 8),
        showHighLow: true,
      ),
      theme: theme,
    );
  }

  @override
  List<Widget> buildSettings(BuildContext context) => [
    Choice(S.current.stockLimitBoard, _board, {
      for (final b in _Board.values) b: b.label,
    }, (v) => update(() => _setBoard(v))),
    Toggle(S.current.stockLimitMarks, _showMarks, (v) {
      update(() => _showMarks = v);
      _applyMarks();
    }),
    Toggle(S.current.stockLimitUp, _labels, (v) {
      update(() => _labels = v);
      _applyMarks();
    }),
    Toggle(S.current.stockRedUp, _redUp, (v) => update(() => _redUp = v)),
    Text(S.current.stockDailyHint),
  ];

  @override
  String code() =>
      'final marks = LimitMarksOverlay(\n'
      '  limit: ${_showMarks ? 'PriceLimit.${_board.name == 'main' ? 'mainBoard' : _board.name}' : 'null'},\n'
      '${_labels ? "  upLabel: 'LU', downLabel: 'LD',\n" : ''}'
      ');\n'
      'final controller = ChartController(overlays: [marks])..setBars(dailyBars);\n'
      'KChart(\n'
      '  controller: controller,\n'
      '  theme: ${_redUp ? 'KLineTheme.light().swapUpDown()' : 'KLineTheme.light()'},\n'
      '  tieredTimeAxis: true,\n'
      '  utcOffset: const Duration(hours: 8),\n'
      ')';
}

enum _Board {
  main,
  growth,
  st;

  PriceLimit get limit => switch (this) {
    main => PriceLimit.mainBoard,
    growth => PriceLimit.growth,
    st => PriceLimit.st,
  };

  String get label => switch (this) {
    main => S.current.stockBoardMain,
    growth => S.current.stockBoardGrowth,
    st => S.current.stockBoardSt,
  };
}
