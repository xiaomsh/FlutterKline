# klinex

[![](https://img.shields.io/pub/v/klinex.svg?color=blue)](https://pub.dev/packages/klinex)
[![](https://img.shields.io/github/last-commit/xiaomsh/FlutterKline?color=yellow)](https://github.com/xiaomsh/FlutterKline)

English | [中文](README_zh.md)

A pure Flutter candlestick (K-line) chart library with zero third-party dependencies.

Live demo: <https://xiaomsh.github.io/FlutterKline/>. The demo app lives in [example/](example/).

#### Installation

```yaml
dependencies:
  klinex: ^0.1.0
```

## Quick start

```dart
// 1. Create the controller (the single source of truth)
final controller = ChartController(
  indicators: [
    Ma(periods: [7, 25, 99]),
    Boll(),
    Vol(), MaVol(periods: [5, 10]),
    Macd(),
  ],
);

// 2. Feed data
controller.setBars(bars);              // first screen / interval switch
controller.applyTick(tickBar);         // live push (append / update last / backfill, dispatched automatically)
controller.prependHistory(older);      // load older history (viewport stays anchored)

// 3. Put it in the UI
KChart(
  controller: controller,
  theme: KLineTheme.dark(),
  // Without priceFormatter: at least 2 decimals and 4 significant digits (60000.00 / 1.234 / 0.00001234)
  onLoadMore: () async {
    final older = await api.fetchHistory(...);
    controller.prependHistory(older);
  },
);

// 4. Release (in the host State.dispose)
controller.dispose();
```

## Three plugin axes

### 1. Custom indicators (Indicator)

```dart
class MyRsi extends Indicator {
  @override String get id => 'myrsi(14)';
  @override PanelRef get target => PanelRef.own();
  @override int get warmupBars => 14;

  @override void computeAll(List<Bar> bars, IndicatorStore store) { ... }
  @override void computeLast(List<Bar> bars, int index, IndicatorStore store) { ... }
  @override void paint(Canvas canvas, RenderContext ctx, IndicatorStore store) { ... }
  @override MinMax range(IndicatorStore store, int start, int end) { ... }
}
```

Just add it: `ChartController(indicators: [MyRsi(), ...])`, no core files touched.

### 2. Custom overlays (OverlayPlugin)

```dart
class WatermarkOverlay extends OverlayPlugin {
  @override
  List<Listenable> repaintOn(ChartController c) => [c.viewport]; // follow scrolling

  @override
  void paint(Canvas canvas, RenderContext ctx) {
    // draw the watermark...
  }
}
```

Mount it with `ChartController(overlays: [WatermarkOverlay()])`.

### 3. Custom main series (MainSeries)

```dart
class DotSeries extends MainSeries {
  @override String get kind => 'dot';
  @override bool get usesHighLow => false; // close only; wicks do not stretch the range

  @override
  void paint(Canvas canvas, RenderContext ctx, SeriesPaintKit kit) {
    // draw a dot at each close...
  }
}
```

Use it with `KChart(series: DotSeries())`. A series only decides how bars are drawn; renko,
line break and other charts that change the data itself are data transforms in the full edition.

## Built-in indicators

**Main chart overlays**: MA / EMA / BOLL / VolOverlay (volume bars at the bottom of the main chart)

**Own sub panels**: MACD / KDJ / RSI / WR

**Shared 'vol' sub panel**: VOL + MAVol

## Built-in main series

Candles (solid / hollow up / hollow down) / line / area

## Stocks (A-share / Hong Kong / US)

```dart
final session = TradingSession.cnA; // also .hk and .us (DST aware)
controller
  ..indicators.setAll([AveragePrice(session: session, volumeUnit: 100), Vol()])
  ..setBars(session.normalize(minuteBars, preClose: preClose));

KChart(
  controller: controller,
  theme: KLineTheme.light().swapUpDown(), // red up, green down
  seriesStyle: MainSeriesStyle.area,
  slotAxis: IntradayAxis(session), // 241 fixed minute slots, lunch break without a gap
  percentScale: true,
  percentBase: preClose, // change against the previous close
  percentRightOnly: true, // prices on the left, percent on the right
  yAxisPosition: YAxisPosition.both,
  mainRange: StockRange(symmetricAround: preClose), // previous close stays in the middle
)
```

- **Trading sessions**: `TradingSession` presets for A-share (241 slots), Hong Kong (331) and US (391, DST aware); `normalize` aligns minute bars to the slots, fills minutes without trades and drops points outside the session; `isTrading` / `formatTime` work in exchange time
- **Intraday axis**: `slotAxis` fixes the x axis to the session's minutes (no scrolling or zooming, slots after the latest minute stay empty) with ticks at the open, every hour, the lunch break (`11:30/13:00`) and the close; implement `SlotAxis` for other layouts
- **Average price**: `AveragePrice` = Σamount / Σvolume since the open (uses `Bar.amount` when present), reset every trading day; `volumeUnit` converts lots to shares
- **Price lines and limits**: `PriceLevelsOverlay` draws the previous close and limit lines; `PriceLimit` computes limit prices with exchange rounding (±10% / ±20% / ±5% / ±30%); `LimitMarksOverlay` marks daily bars closing exactly at the limit price (days without limits, such as IPO days, are not marked); `StockRange(include: [...])` stretches the range to fit given prices
- **Colors**: `KLineTheme.swapUpDown()` switches to red up / green down
- Days off and breaks take no space anywhere, since the x axis is indexed by bar

## Performance gates (perf_test regression guard)

| Scenario | Measured |
|------|------|
| Full compute, 10k bars × 11 indicators | ≈ 27ms (≥ 2000 bars run in a background isolate by default; no dropped frames) |
| Incremental compute per tick | ≈ 6µs |
| Layout per frame while panning | ≈ 0.05ms |
| Candle layer repaints while dragging the crosshair | **0** |

## Serialization (persisting indicator config)

```dart
// Save
final json = [for (final i in controller.indicators.list) IndicatorRegistry.toJson(i)];

// Restore
controller.indicators.setAll(IndicatorRegistry.fromJsonList(json));
```

Third-party indicators register with `IndicatorRegistry.register(...)` (registered indicators are
computed in the background isolate too).

Save and restore the whole chart config (indicators, zoom, `maxBars`, each overlay's own state)
in one go:

```dart
final state = controller.saveState(); // ready for jsonEncode
controller.restoreState(state);

final themeJson = theme.toJson();
final restored = KLineTheme.fromJson(themeJson);
```

To take part, an overlay overrides `OverlayPlugin.stateKey` / `saveState` / `restoreState`.
Restoring before data arrives is fine: a locked range and vertical zoom apply after the next
`setBars`.

## More features

Coordinates and display:

- **Log scale**: `KChart(logScale: true)`
- **Inverted scale**: `KChart(invertScale: true)` puts small values on top; vertical drag direction flips with it
- **Locked range**: `controller.lockYRange()` freezes the main chart's value range at what is shown, so panning and new data no longer rescale prices; manual zoom / pan still apply. `unlockYRange()` returns to auto (and clears manual zoom made while locked). Saved with `saveState`; `setBars` unlocks
- **Secondary value axis**: `SecondaryAxis(Rsi())` overlays any indicator on the main chart with its own range, without squeezing prices. Ticks go on the side opposite the main ticks (the left strip with `both`); the crosshair and legend show both readings, and `KChart(secondaryFormatter:)` formats them. If the wrapped indicator is serializable it is saved with `saveState` and computed in the background. Plugins implementing `secondaryRange` can use the axis too; call `controller.relayout()` when their data changes
- **Percent scale**: `KChart(percentScale: true)`
- **Range animation**: `KChart(animateRange: true)` tweens data-driven range changes
- **Y axis position**: `KChart(yAxisPosition: ...)`: `outside` reserves a strip on the right (default), `inside` overlays it, `left` puts it on the left, `both` labels both sides
- **High / low marks**: `KChart(showHighLow: true)` marks the visible extremes
- **Theme details**: in `KLineTheme`, `showGrid` turns the grid off, `upWick` / `downWick` color the wicks, `upBorder` / `downBorder` outline the bodies, `highLowText` colors the high / low marks
- **Tiered time axis**: `KChart(tieredTimeAxis: true)` puts ticks and vertical grid lines on year / month / day / hour boundaries that move with the chart, with day and month ticks bold. `tickFormatter` customizes the text (receives raw UTC milliseconds) and `tickMinSpacing` the spacing. With the device time zone, each bar's own offset is used, so DST changes are handled. Recommended for unevenly spaced data such as renko
- **Crosshair tooltip**: by default a fixed OHLC + change line at the top left of the main chart, above the indicator legend (the legend makes room instead of jumping with the finger). `tooltipStyle: KChartTooltipStyle.card` switches to a floating card, `tooltipBuilder` replaces it entirely
- **Time and language**: `utcOffset` sets the time zone (device by default). The library ships no translations: tooltip and accessibility texts default to English; pass `labels: KChartLabels(time: 'Zeit', ...)` for other languages. The default time format follows the interval (date / hh:mm / hh:mm:ss)
- **Accessibility**: the chart has a `Semantics` description (visible range and latest price), also driven by `labels`

Interaction:

- **Crosshair snapping**: `KChart(crosshairSnap: CrosshairSnap.close)`: follow the finger / snap to close / snap to the nearest of OHLC
- **Drag the axes to zoom**: `KChart(axisDragScale: true)`: drag vertically on the price axis to zoom prices, horizontally on the time axis to zoom time
- **Y panning**: `KChart(yPan: YPanMode.axis)` pans the range by dragging the price axis, `YPanMode.chart` anywhere on the main chart; the default `none` leaves vertical drags to an outer scroll view
- **Y zoom-out floor**: `KChart(yFitValues: () => [orderPrice, stopPrice])` keeps these prices visible when zooming the y axis manually
- **Sub panel height**: `KChart(panelResizable: true)` lets users drag the dividers; `panelWeights` sets the initial weights
- **Bar taps**: `KChart(onBarTap: (bar) { ... })`; when set, double tap no longer resets the y axis. Taps in the blank space right of the newest bar or left of the oldest are not reported
- **Drag a price line to change the price**: `KChart(levelDrag: LevelDragController(onDrop: (level, price) { ... }))`. The host sets `levels` and draws the lines in `overlayBuilder` from `draggingId` / `previewPrice`. `onDrop` is not called when the drag leaves the main chart, the price did not change, or the system cancelled it (incoming call, host interception)
- **Keyboard**: after the chart was clicked, left / right pan (Shift for 10%), up / down and +/- zoom, Home / End jump to the oldest / newest (End also restores autoFollow), Esc hides the crosshair. Combinations with Ctrl / Cmd / Alt are ignored, and only Esc works while a drawing tool owns gestures. `KChart(keyboard: false)` turns it off
- **autoFollow**: `KChart(autoFollow: true)` sticks to the right edge and follows the newest bar

Extensions and data:

- **Host layers**: `underlayBuilder` sits between the grid and the main chart (watermarks), `overlayBuilder` on top (order buttons, annotations); both get a `RenderContext` for coordinate conversion
- **Depth chart**: `DepthChart`
- **Interval aggregation**: after `controller.aggregator = MyAggregator()` (extend `BarAggregator` and only write `bucketOf`), feed source-interval bars to `setBars` / `applyTick` / `prependHistory` and the controller aggregates them: a push only recomputes the last bucket, loading older history fixes the boundary bucket, and the source data is in `sourceBars`
- **History cap**: `controller.maxBars = 5000` trims the oldest bars when appending past the cap; once at the cap, older pages are no longer inserted. Unlimited by default
- **Indicator errors**: `controller.onIndicatorError` receives errors thrown by custom indicators; without it they are printed in debug builds
- **Background compute**: full recomputes of ≥ 2000 bars run in a background isolate automatically; `controller.computing` lets the host show a mask, and `asyncCompute = false` forces synchronous compute
- **Memory**: under system memory pressure KChart drops rebuildable range caches; hosts can also call `controller.releaseCaches()`

## Comparison with other Flutter K-line libraries

From reading the source code (2026-11), not the libraries' own READMEs. Where klinex shows
"free / full", the first value is the free edition and the second the full edition.

| | klinex | FlexiKline | swm | candlesticks | Pipsend | chen |
|---|---|---|---|---|---|---|
| Runtime dependencies | none | 5 | 1 | none | 1 | none |
| Layered repaint | per layer, each with its own RepaintBoundary | 2 layers | 2 layers | partial | ❌ | ❌ |
| Crosshair drag repaints candles | ❌ never | ❌ | ❌ | rebuilds the tree | ✅ | ✅ |
| Incremental indicators | all, checked against full compute | dirty-tail recompute | 10 of 73 | no indicators | ❌ | ❌ |
| Background isolate | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Aggregation when zoomed far out | ✅ | ❌ | ✅ (off by default) | ❌ | ❌ | ❌ |
| Bad data (unsorted, NaN, duplicates) | cleaned | debug assert only | throws on unsorted | blank screen on NaN | ❌ | partial |
| Built-in indicators | 10 / 50 | 0 (separate package) | 73 | 0 | 16 | 7 |
| Main series | 3 / 13 + Heikin-Ashi | 7 | 6 | 1 | 4 | 2 |
| Drawing tools | — / 32 | 19 | ~17 | 0 | 13 | 8 |
| Drawing undo / multi-select | — / ✅ ✅ | ❌ ❌ | ✅ ❌ | ❌ | ❌ | ❌ |
| Log / percent scale | ✅ ✅ | ❌ ❌ | ✅ ✅ | ✅ ❌ | ❌ | ❌ |
| Nested in scroll views / TabBarView | ✅ with tests | ✅ | partial | ❌ | ❌ | ❌ |
| Keyboard | ✅ | Esc only | ❌ | ❌ | ❌ | ❌ |
| Depth chart | ✅ | ❌ | ❌ | ❌ | ❌ | ✅ |
| Replay / linked charts | — / ✅ ✅ | ❌ | ❌ / crosshair only | ❌ | ✅ ❌ | ❌ |
| Save / restore whole state | ✅ | ✅ | drawings only | ❌ | drawings only | ❌ |
| Tests | 306 / 546 | ~1500 | ~220 | 12 | ~51 | 0 |

## Full edition

The full edition adds the following, with exactly the same performance as the free edition:

- **40 advanced indicators**: WMA / SAR / SuperTrend / Keltner / Donchian / VWAP / Ichimoku / Volume Profile / DEMA / TEMA / Hull / VWMA / KAMA / ALMA / LSMA / Pivot points / ZigZag / StochRSI / Stochastic / CCI / OBV / ATR / DMI / MFI / CMF / ROC / MTM / TRIX / Aroon / Standard deviation / Historical volatility / A/D / Chaikin oscillator / Bollinger %B / Bollinger bandwidth / Vortex / Choppiness / AO / PPO / Fisher
- **10 advanced main series + Heikin-Ashi**: OHLC bars / volume candles / step line / baseline / HLC area / high-low / columns / line with markers / Kagi / point & figure, plus Heikin-Ashi
- **32 drawing tools**: trend line / extended line / ray / arrow / horizontal line / horizontal ray / vertical segment / cross line / parallel channel / price line / three waves / five waves / rectangle / ellipse / triangle / Fibonacci retracement / Fibonacci extension / Fibonacci fan / Fibonacci time zones / Fibonacci channel / Andrews' pitchfork / linear regression channel / Gann fan / anchored VWAP / freehand / XABCD / ABCD / Elliott impulse wave / Elliott correction wave / text / position (take profit, stop loss, risk-reward) / measure. Drag editing, magnet (off / weak / strong), multi-select and marquee selection with group drag, undo / redo, bring to front / send to back, `DrawingSet.onChange` callbacks for add / change / remove (multi-device sync), saved with `saveState`
- **Order lines**: ready-made pending order, position and take-profit / stop-loss lines (drag-to-reprice uses the free edition's `LevelDragController`)
- **Price alert lines**: fire callbacks on cross up / cross down / any cross, draggable, once or repeating
- **Fill markers**: buy / sell / liquidation markers, merged per bar and side, tappable
- **Data transforms**: renko (optionally ATR-sized boxes), line break, range bars, Kagi, point & figure, aggregating small intervals into larger ones (including live); draw Kagi and point & figure with `KagiSeries` / `PointFigureSeries`
- **Comparison overlay**: other symbols scaled to percent change on the main chart, or in raw prices on the main chart's secondary axis (`CompareAxis.secondary`)
- **Bar replay**: bar-by-bar replay with play / pause / step / jump to bar or date / speed; the last bar can grow tick by tick (open → low → high → close), and the future is dimmed
- **Linked charts**: viewports and crosshairs synced by time
- **Five-day intraday**: `MultiDayAxis` lays several trading days on fixed slots with dated separators; the average price restarts every day
- **Price adjustment**: `PriceAdjuster` applies dividends, bonus shares and rights issues (`ExRights`) to daily bars, forward or backward

Import the full edition with `package:klinex/pro.dart` and call `KlinexPro.install()` once at startup.
Its texts default to English as well; for example, Ichimoku legend labels can be replaced with
`Ichimoku(labels: IchimokuLabels(tenkan: 'Tenkan-sen', ...))`.
