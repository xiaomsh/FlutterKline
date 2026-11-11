# klinex 演示工程

[English](README.md) | 中文

图表库 **klinex**（仓库根目录）的演示工程。

在线演示：<https://xiaomsh.github.io/FlutterKline/>

## 目录

| 路径 | 内容 |
|------|------|
| `../` | 图表库本体，用法见 [README.md](../README.md) |
| `lib/` | 演示工程：配置大全、实时行情 |

## 配置大全

界面默认英文，首页右上角可手动切换中文 / English（不跟随系统语言）。

首页进入「配置大全」，使用确定性离线行情，不依赖交易所网络；「实时行情」入口展示 Binance
实时数据。默认浅色，右上角可切换深色。宽屏左侧菜单、中间图表、右侧配置；窄屏图表在上、
配置在下，菜单收进抽屉。

每个功能是一个独立示例（`lib/page/setting/samples/`），自带控制器、数据、设置面板和等价代码，
彼此不共享状态；切换或「重置本页」都会重建该示例。示例共用 `sample/` 下的布局、数据源和控件。
每页有自己的地址，例如 [十字线配置](https://xiaomsh.github.io/FlutterKline/#/setting/crosshair)。
分类为数据、主图、坐标、指标、交互、外观、扩展、完整版、存取，支持按名称或 API 搜索。
完整版能力在免费演示中显示带锁入口。存取页保存指标、缩放和主题，不保存行情数组，也不写入磁盘。

### 最小集成

在项目中引入 `klinex` 后，将以下组件放进有明确高度的父容器；行情按时间严格递增：

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

### 按需集成

下面片段在同一个控制器上使用，不需要引入状态管理框架：

```dart
controller.maxBars = 5000; // 可选；不设置则不裁剪历史
controller.asyncCompute = true;
controller.onIndicatorError = (indicator, error, stack) {
  debugPrint('${indicator.id}: $error\n$stack');
};
controller.applyTick(latestBar);       // 末根同时间戳更新，新时间戳追加
controller.prependHistory(olderBars);  // 自动补偿视口偏移
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

更多主题、坐标、面板、自定义提示卡、扩展和商业功能在 Web 配置大全逐项体验，不在 README 堆叠大段代码。

## 多语言

演示工程用 [Flutter Intl](https://plugins.jetbrains.com/plugin/13666-flutter-intl) 插件 + GetX：

- 文案在 `lib/l10n/intl_en.arb`（英文，模板）和 `lib/l10n/intl_zh.arb`（中文），两份的键必须一致（`test/language_test.dart` 会检查）
- 生成代码在 `lib/l10n/generated/`，IDE 插件保存 ARB 时自动生成；命令行用 `dart run intl_utils:generate`
- 代码里用 `S.current.xxx` 取文字，只在 `build` 里读，不要存进 `const` 或字段；切换语言调 `AppLanguage.toggle()`
- 图表自身的提示卡文字通过 `KChart(labels: chartLabels)` 跟随当前语言

## 免费版和完整版

| 功能 | 免费版 | 完整版 |
|------|:---:|:---:|
| K 线 / 线形 / 面积，对数、百分比坐标 | ✅ | ✅ |
| MA / EMA / BOLL / VOL / MACD / KDJ / RSI / WR | ✅ | ✅ |
| 深度图、十字线、图例、价格线 | ✅ | ✅ |
| 后台 isolate 计算、增量计算、分块缓存等性能优化 | ✅ | ✅ |
| 十字线吸附、刻度条拖动缩放、键盘操作、分级时间轴、整体配置存取 | ✅ | ✅ |
| 反转 / 锁定坐标、主图第二条值轴 | ✅ | ✅ |
| 进阶指标 40 个（含 ZigZag、枢轴点） | | ✅ |
| 进阶主图画法 10 种（含 Kagi、点数图）+ 平均 K 线 | | ✅ |
| 画线工具 32 种（含仓位、测量、锚定 VWAP、手绘、XABCD / 艾略特），多选框选 | | ✅ |
| 订单线（拖线改价、止盈止损）、价格报警线、成交标 | | ✅ |
| 砖形图、新价线、Range bars、Kagi、点数图、小周期合成大周期、对比叠加 | | ✅ |
| K 线回放（逐跳插值、遮暗未来、跳到日期） | | ✅ |
| 多图联动 | | ✅ |

演示工程里完整版的入口都在，免费版显示带锁。

## 行情源

演示工程使用 Binance Global Spot 公共 REST API 和 WebSocket 行情，不需要 API 密钥。币对以 `btc_usdt` 形式传入，适配层会转换为 Binance 的 `BTCUSDT` 格式。

Binance 公共行情不是开源数据服务，且 Binance Global 在部分国家、地区或网络环境可能无法访问；美国等地区请按当地可用服务调整行情适配。接入实现位于 `lib/api/binance_spot_api.dart`、`lib/socket/binance_public_ws.dart` 和 `lib/widget/binance_live_feed.dart`。

## 运行演示

以下命令都在 `example/` 下执行：

```bash
flutter pub get
flutter run -d chrome
```

发布 H5 演示（在 develop 上，构建后提交到 gh-pages 分支）：

```bash
tool/deploy_web.sh
```

库的测试（在仓库根目录）：

```bash
cd .. && flutter test
```

库和演示工程的行覆盖率（任一低于 80% 时返回失败，可传其它门槛）：

```bash
tool/coverage.sh [门槛百分比]
```

真机帧时间基准（profile 模式，结果存到 `benchmark/results/` 并和上一次对比）：

```bash
tool/perf.sh <设备 id> [设备名]
```
