import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:klinex/klinex.dart';

import '../../l10n/l10n.dart';
import '../../pro/stock_pro.dart';
import '../../widget/live_style.dart';
import '../../widget/pro_lock.dart';
import '../../widget/theme_toggle_button.dart';
import 'stock_controller.dart';
import 'stock_symbols.dart';

/// Stock market page backed by Eastmoney: A-share / Hong Kong / US symbols, intraday and
/// daily / weekly / monthly bars, polling while the market is open.
class StockPage extends StatelessWidget {
  StockPage({super.key});

  final StockController controller = Get.find();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      isLiveDark.value;
      final theme = controller.redUp.value ? kChartTheme.swapUpDown() : kChartTheme;
      return Scaffold(
        backgroundColor: LiveStyle.bgPrimary,
        appBar: AppBar(
          backgroundColor: LiveStyle.bgPrimary,
          foregroundColor: LiveStyle.textPrimary,
          elevation: 0.5,
          centerTitle: true,
          title: Text(S.current.stockTitle),
          actions: [
            IconButton(
              tooltip: S.current.stockRedUp,
              icon: Icon(
                Icons.swap_vert,
                color: controller.redUp.value ? theme.up : LiveStyle.textSecondary,
              ),
              onPressed: () => controller.redUp.toggle(),
            ),
            const ThemeToggleButton(),
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Tabs<StockMarket>(
                values: StockMarket.values,
                selected: controller.market,
                label: (m) => m.label,
                onTap: controller.selectMarket,
              ),
              _Tabs<StockSymbol>(
                values: controller.market.symbols,
                selected: controller.symbol.value,
                label: (s) => s.code,
                onTap: controller.selectSymbol,
                small: true,
              ),
              _Quote(controller: controller, theme: theme),
              _PeriodRow(controller: controller),
              SizedBox(
                height: 380,
                child: _Chart(controller: controller, theme: theme),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  S.current.stockDataSource,
                  style: TextStyle(fontSize: 11, color: LiveStyle.textTertiary),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

class _Tabs<T> extends StatelessWidget {
  const _Tabs({
    required this.values,
    required this.selected,
    required this.label,
    required this.onTap,
    this.small = false,
    this.locked,
  });

  final List<T> values;
  final T selected;
  final String Function(T) label;
  final void Function(T) onTap;
  final bool small;
  final bool Function(T)? locked;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          for (final v in values)
            InkWell(
              onTap: () => onTap(v),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: small ? 6 : 10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label(v),
                      style: TextStyle(
                        fontSize: small ? 12 : 14,
                        fontWeight: v == selected ? FontWeight.w600 : FontWeight.normal,
                        color: v == selected ? LiveStyle.brand : LiveStyle.textSecondary,
                      ),
                    ),
                    if (locked?.call(v) ?? false) ...[
                      const SizedBox(width: 2),
                      const ProLockIcon(),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Quote extends StatelessWidget {
  const _Quote({required this.controller, required this.theme});

  final StockController controller;
  final KLineTheme theme;

  @override
  Widget build(BuildContext context) => Obx(_build);

  Widget _build() {
    final last = controller.lastPrice.value;
    final pc = controller.preClose.value;
    final digits = controller.decimals.value;
    final change = last != null && pc != null && pc > 0 ? last - pc : null;
    final color = change == null || change == 0
        ? LiveStyle.textPrimary
        : (change > 0 ? theme.up : theme.down);
    final sign = change != null && change > 0 ? '+' : '';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${controller.name.value} ${controller.symbol.value.code}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, color: LiveStyle.textSecondary),
                ),
                Text(
                  last?.toStringAsFixed(digits) ?? '--',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w600, color: color),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                controller.trading ? S.current.stockTrading : S.current.stockClosed,
                style: TextStyle(fontSize: 11, color: LiveStyle.textTertiary),
              ),
              if (change != null)
                Text(
                  '$sign${change.toStringAsFixed(digits)}  '
                  '$sign${(change / pc! * 100).toStringAsFixed(2)}%',
                  style: TextStyle(fontSize: 14, color: color),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PeriodRow extends StatelessWidget {
  const _PeriodRow({required this.controller});

  final StockController controller;

  @override
  Widget build(BuildContext context) => Obx(_build);

  Widget _build() {
    final intraday = controller.period.value.isIntraday;
    return Row(
      children: [
        Expanded(
          child: _Tabs<StockPeriod>(
            values: StockPeriod.values,
            selected: controller.period.value,
            label: (p) => p.label,
            onTap: controller.selectPeriod,
            small: true,
            locked: (p) => p == StockPeriod.fiveDay && !StockPro.unlocked,
          ),
        ),
        if (!intraday)
          PopupMenuButton<StockAdjust>(
            tooltip: '',
            onSelected: controller.selectAdjust,
            itemBuilder: (_) => [
              for (final a in StockAdjust.values)
                PopupMenuItem(
                  value: a,
                  child: Row(
                    children: [
                      Text(a.label),
                      if (a != StockAdjust.none && !StockPro.unlocked) ...[
                        const SizedBox(width: 4),
                        const ProLockIcon(),
                      ],
                    ],
                  ),
                ),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Text(
                controller.adjust.value.label,
                style: TextStyle(fontSize: 12, color: LiveStyle.textSecondary),
              ),
            ),
          ),
      ],
    );
  }
}

class _Chart extends StatelessWidget {
  const _Chart({required this.controller, required this.theme});

  final StockController controller;
  final KLineTheme theme;

  @override
  Widget build(BuildContext context) => Obx(_build);

  Widget _build() {
    final axis = controller.axis.value;
    final intraday = axis != null;
    final session = controller.market.session;
    final digits = controller.decimals.value;
    final fiveDay = controller.period.value == StockPeriod.fiveDay;
    return Stack(
      children: [
        KChart(
          controller: controller.chart,
          theme: theme,
          labels: chartLabels,
          seriesStyle: intraday ? MainSeriesStyle.area : MainSeriesStyle.candle,
          slotAxis: axis,
          percentScale: intraday,
          percentBase: controller.chartBase.value,
          percentRightOnly: true,
          mainRange: intraday ? controller.mainRange : null,
          yAxisPosition: intraday ? YAxisPosition.both : YAxisPosition.outside,
          yAxisWidth: intraday ? 52 : 56,
          mainPaddingTop: intraday ? 24 : 28,
          showHighLow: !intraday,
          tieredTimeAxis: !intraday,
          utcOffset: const Duration(hours: 8),
          priceFormatter: (v) => v.toStringAsFixed(digits),
          timeFormatter: intraday
              ? (ms) => session.formatTime(ms, date: fiveDay)
              : (ms) => _date(ms),
        ),
        if (controller.loading.value && controller.chart.bars.isEmpty)
          const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        if (controller.hasError.value)
          Center(
            child: TextButton(onPressed: controller.load, child: Text(S.current.liveTapToRetry)),
          ),
      ],
    );
  }

  static String _date(int ms) {
    final t = DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true).add(const Duration(hours: 8));
    String p2(int v) => v.toString().padLeft(2, '0');
    return '${t.year}-${p2(t.month)}-${p2(t.day)}';
  }
}
