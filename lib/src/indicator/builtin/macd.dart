import 'dart:ui';

import '../../model/bar.dart';
import '../../model/min_max.dart';
import '../../panel/panel.dart';
import '../../render/context.dart';
import '../indicator.dart';
import 'ema.dart';

/// MACD (DIF / DEA lines + histogram) in its own sub-panel. EMA chains are stored as hidden
/// series, so each incremental step is O(1) and exact.
class Macd extends Indicator {
  final int short, long, signal;
  final Color? difColor, deaColor;
  final double lineWidth;

  Macd({
    this.short = 12,
    this.long = 26,
    this.signal = 9,
    this.difColor,
    this.deaColor,
    this.lineWidth = 1,
  }) {
    checkPositivePeriod(short, 'short');
    checkPositivePeriod(long, 'long');
    checkPositivePeriod(signal, 'signal');
    if (short >= long) {
      throw RangeError('Macd: short ($short) must be < long ($long)');
    }
  }

  late final String _legendHeader = 'MACD($short,$long,$signal)';

  @override
  String get id => 'macd($short,$long,$signal)';

  @override
  PanelRef get target => const PanelRef.own();

  @override
  int get warmupBars => 2;

  /// Two chained EMA stages (fast/slow + signal); settle length is the sum of both.
  @override
  int? get prependSettleBars => Indicator.settleForSmoothing(long + signal);

  void _at(List<Bar> bars, int i, IndicatorStore store) {
    final emaS = store.series('macd_emas');
    final emaL = store.series('macd_emal');
    final dif = store.series('macd_dif');
    final dea = store.series('macd_dea');
    final hist = store.series('macd_hist');
    final c = bars[i].close;
    // Seed the first bar with a NaN previous value: the chains naturally yield emaS=emaL=c
    // and dif=dea=hist=0, so no separate i==0 special case is needed.
    double prevOf(List<double> s) => i == 0 ? double.nan : s[i - 1];
    emaS[i] = emaStep(prevOf(emaS), c, short);
    emaL[i] = emaStep(prevOf(emaL), c, long);
    dif[i] = emaS[i] - emaL[i];
    dea[i] = emaStep(prevOf(dea), dif[i], signal);
    hist[i] = (dif[i] - dea[i]) * 2;
  }

  @override
  void computeAll(List<Bar> bars, IndicatorStore store) {
    for (var i = 0; i < bars.length; i++) {
      _at(bars, i, store);
    }
  }

  @override
  void computeLast(List<Bar> bars, int index, IndicatorStore store) {
    _at(bars, index, store);
  }

  @override
  void paint(Canvas canvas, RenderContext ctx, IndicatorStore store) {
    final hist = store.series('macd_hist');
    final up = ctx.pool.stroke..color = ctx.theme.up;
    ctx.vbars(canvas, hist, 0, up, (i, v) => v >= 0);
    final down = ctx.pool.stroke..color = ctx.theme.down;
    ctx.vbars(canvas, hist, 0, down, (i, v) => v < 0);

    paintSeriesLines(
      canvas,
      ctx,
      store,
      const ['macd_dif', 'macd_dea'],
      colors: difColor == null && deaColor == null
          ? null
          : [
              difColor ?? ctx.theme.lineColor(0),
              deaColor ?? ctx.theme.lineColor(1),
            ],
      lineWidth: lineWidth,
    );
  }

  @override
  MinMax range(IndicatorStore store, int start, int end) => seriesRange(
    store,
    const ['macd_dif', 'macd_dea', 'macd_hist'],
    start,
    end,
  ).include(0);

  @override
  void legendInto(
    List<LegendItem> out,
    RenderContext ctx,
    IndicatorStore store,
    int index,
  ) {
    out.add((_legendHeader, ctx.theme.axisText));
    legendOfKeys(
      out,
      ctx,
      store,
      index,
      const ['DIF', 'DEA'],
      const ['macd_dif', 'macd_dea'],
      colors: difColor == null && deaColor == null
          ? null
          : [
              difColor ?? ctx.theme.lineColor(0),
              deaColor ?? ctx.theme.lineColor(1),
            ],
    );
    final hist = store.value('macd_hist', index);
    if (!hist.isNaN) {
      out.add((
        'MACD:${ctx.formatValue(ctx.panel, hist)}',
        hist >= 0 ? ctx.theme.up : ctx.theme.down,
      ));
    }
  }
}
