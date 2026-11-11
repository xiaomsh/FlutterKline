# Changelog

## 0.0.1

First release.

### Chart

- `ChartController` as the single data source: `setBars`, `applyTick` (append / update last /
  backfill), `prependHistory` with the viewport kept anchored, `maxBars` history cap, interval
  aggregation through `BarAggregator`
- `KChart` widget with candles (solid / hollow), line and area series; log, percent, inverted and
  locked scales; secondary value axis (`SecondaryAxis`); four y-axis positions; tiered time axis;
  high / low marks; range animation
- Built-in indicators: MA, EMA, BOLL, VolOverlay, VOL, MAVol, MACD, KDJ, RSI, WR
- Plugin axes: custom `Indicator`, `OverlayPlugin` and `MainSeries`, plus `underlayBuilder` /
  `overlayBuilder` host layers and `DepthChart`
- Interaction: crosshair with snapping, fixed-line or card tooltip, axis drag zoom, y panning,
  resizable sub panels, bar taps, draggable price levels (`LevelDragController`), keyboard,
  mouse wheel and trackpad, auto follow, `scrollToLatest`
- Serialization: `IndicatorRegistry`, `ChartController.saveState` / `restoreState`,
  `KLineTheme.toJson` / `fromJson`
- Performance: incremental compute per tick, background isolate for full recomputes of 2000+ bars,
  chunked range caches released under memory pressure

### Internationalization

- No built-in translations: tooltip and accessibility texts default to English and are replaced
  through `KChartLabels`; time zone via `utcOffset`
- Full edition texts default to English as well, e.g. `IchimokuLabels` for the Ichimoku legend

### Demo

- Samples for every feature and a live Binance market page
- English and Chinese UI (Flutter Intl + GetX), English by default, switched from the top right
  of the home page
- `tool/coverage.sh` reports line coverage of the library and the demo (80% minimum)
