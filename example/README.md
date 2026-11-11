# klinex demo

English | [中文](README_zh.md)

Demo app for the chart library **klinex** (the repository root).

Live demo: <https://xiaomsh.github.io/FlutterKline/>

## Layout

| Path | Contents |
|------|------|
| `../` | The chart library; see its [README.md](../README.md) |
| `lib/` | The demo app: samples, live market and stock market |

## Samples

The UI is in English by default; switch between English and Chinese at the top right of the home
page (it does not follow the system language).

"Samples" on the home page uses deterministic offline data and needs no exchange network; "Live
market" shows real-time Binance data and "Stock market" A-share / Hong Kong / US quotes from
Eastmoney (intraday and daily / weekly / monthly bars). Light by default; switch to dark at the top right. On wide
screens the menu is on the left, the chart in the middle and the settings on the right; on narrow
screens the chart is on top, the settings below and the menu in a drawer.

Each feature is a standalone sample (`lib/page/setting/samples/`) with its own controller, data,
settings panel and equivalent code, sharing no state; switching or "Reset this page" rebuilds it.
Samples share the layout, data source and controls under `sample/`. Every page has its own URL,
e.g. [crosshair](https://xiaomsh.github.io/FlutterKline/#/setting/crosshair). Categories are data,
main series, coordinates, indicators, interaction, appearance, extensions, stocks, full edition
and storage, searchable by name or API. Full edition features show locked entries in the free demo.
The storage page saves indicators, zoom and theme, not the bars, and does not write to disk.

### Minimal integration

After adding `klinex` to your project, put this widget in a parent with a definite height; bars
must be in strictly increasing time order:

```dart
import 'package:flutter/material.dart';
import 'package:klinex/klinex.dart';

class ChartExample extends StatefulWidget {
  const ChartExample({super.key});
  @override
  State<ChartExample> createState() => _ChartExampleState();
}

class _ChartExampleState extends State<ChartExample> {
  final controller = ChartController(indicators: [Ma()]);

  @override
  void initState() {
    super.initState();
    controller.setBars([
      Bar(time: 1700000000000, open: 100, high: 103, low: 99, close: 102, vol: 500),
      Bar(time: 1700000060000, open: 102, high: 104, low: 101, close: 103, vol: 600),
    ]);
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 360,
    child: KChart(controller: controller, theme: KLineTheme.dark()),
  );

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
```

### Optional integration

These snippets work on the same controller, with no state management framework required:

```dart
controller.maxBars = 5000; // optional; without it history is never trimmed
controller.asyncCompute = true;
controller.onIndicatorError = (indicator, error, stack) {
  debugPrint('${indicator.id}: $error\n$stack');
};
controller.applyTick(latestBar);       // same timestamp updates the last bar, a new one appends
controller.prependHistory(olderBars);  // viewport offset compensated automatically
controller.indicators.setAll([Ma(periods: [7, 25]), Macd()]);

final chart = KChart(
  controller: controller,
  theme: KLineTheme.dark(),
  crosshairSnap: CrosshairSnap.close,
  axisDragScale: true,
  keyboard: true,
  onLoadMore: loadOlderBars,
);

final saved = controller.saveState();
controller.restoreState(saved);
final themeJson = KLineTheme.dark().toJson();
final restoredTheme = KLineTheme.fromJson(themeJson);
```

Themes, coordinates, panels, custom tooltips, extensions and commercial features can be tried one
by one in the web samples instead of piling up code in this README.

## Languages

The demo uses the [Flutter Intl](https://plugins.jetbrains.com/plugin/13666-flutter-intl) plugin
with GetX:

- Texts live in `lib/l10n/intl_en.arb` (English, the template) and `lib/l10n/intl_zh.arb`
  (Chinese); both must have the same keys (checked by `test/language_test.dart`)
- Generated code is in `lib/l10n/generated/`; the IDE plugin regenerates it when an ARB file is
  saved, or run `dart run intl_utils:generate`
- Read texts with `S.current.xxx` inside `build` only, never in `const` values or fields; switch
  the language with `AppLanguage.toggle()`
- The chart's own tooltip texts follow the current language via `KChart(labels: chartLabels)`

## Free and full editions

| Feature | Free | Full |
|------|:---:|:---:|
| Candles / line / area, log and percent scales | ✅ | ✅ |
| MA / EMA / BOLL / VOL / MACD / KDJ / RSI / WR | ✅ | ✅ |
| Depth chart, crosshair, legend, price line | ✅ | ✅ |
| Background isolate compute, incremental compute, chunked caches and other optimizations | ✅ | ✅ |
| Crosshair snapping, axis drag zoom, keyboard, tiered time axis, whole-config save / restore | ✅ | ✅ |
| Inverted / locked scales, secondary value axis | ✅ | ✅ |
| 40 advanced indicators (incl. ZigZag, pivot points) | | ✅ |
| 10 advanced main series (incl. Kagi, point & figure) + Heikin-Ashi | | ✅ |
| 32 drawing tools (incl. position, measure, anchored VWAP, freehand, XABCD / Elliott), multi-select and marquee | | ✅ |
| Order lines (drag to reprice, take profit / stop loss), price alert lines, fill markers | | ✅ |
| Renko, line break, range bars, Kagi, point & figure, interval aggregation, comparison overlay | | ✅ |
| Bar replay (tick interpolation, dimmed future, jump to date) | | ✅ |
| Linked charts | | ✅ |

All full edition entries exist in the demo; the free edition shows them locked.

## Market data

The demo uses the Binance Global Spot public REST API and WebSocket streams; no API key needed.
Symbols are passed as `btc_usdt` and the adapter converts them to Binance's `BTCUSDT`.

Binance public market data is not an open data service, and Binance Global may be unreachable in
some countries, regions or networks; in the US and elsewhere, adapt the feed to a locally
available service. The integration is in `lib/api/binance_spot_api.dart`,
`lib/socket/binance_public_ws.dart` and `lib/widget/binance_live_feed.dart`.

The stock page uses Eastmoney's public quote endpoints (`push2his.eastmoney.com`, no key needed;
quotes may be delayed and are for demonstration only). Symbols are Eastmoney ids such as
`1.600519` (Shanghai), `0.300750` (Shenzhen), `116.00700` (Hong Kong) and `105.AAPL` (US); the
page polls every 5 seconds during trading hours, pauses in the background and reloads on
resume. See `lib/api/eastmoney_api.dart` and
`lib/page/stock/`.

## Running the demo

Run these in `example/`:

```bash
flutter pub get
flutter run -d chrome
```

Publish the web demo (on develop; builds and commits to the gh-pages branch):

```bash
tool/deploy_web.sh
```

Library tests (from the repository root):

```bash
cd .. && flutter test
```

Line coverage of the library and the demo (fails if either is below 80%, or pass another
threshold):

```bash
tool/coverage.sh [min-percent]
```

On-device frame time benchmark (profile mode; results go to `benchmark/results/` and are compared
with the previous run):

```bash
tool/perf.sh <device-id> [device-name]
```
