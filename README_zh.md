# klinex

[English](README.md) | 中文

纯 Flutter K 线图表库，零三方依赖。

在线演示：<https://xiaomsh.github.io/FlutterKline/>，演示工程在 [example/](example/)。

## 快速上手

```dart
// 1. 创建 controller（唯一数据源）
final controller = ChartController(
  indicators: [
    Ma(periods: [7, 25, 99]),
    Boll(),
    Vol(), MaVol(periods: [5, 10]),
    Macd(),
  ],
);

// 2. 喂数据
controller.setBars(bars);              // 首屏 / 切周期
controller.applyTick(tickBar);         // 实时推送（自动分派 追加/更新末根/回补）
controller.prependHistory(older);      // 上拉加载（视口自动锚定）

// 3. 放入 UI
KChart(
  controller: controller,
  theme: KLineTheme.dark(),
  // priceFormatter 不传时：至少 2 位小数、至少 4 位有效数字（60000.00 / 1.234 / 0.00001234）
  onLoadMore: () async {
    final older = await api.fetchHistory(...);
    controller.prependHistory(older);
  },
);

// 4. 释放（宿主 State.dispose）
controller.dispose();
```

## 三条插件轴

### 1. 自定义指标（Indicator）

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

加入即可：`ChartController(indicators: [MyRsi(), ...])`，零改核心文件。

### 2. 自定义叠加层（OverlayPlugin）

```dart
class WatermarkOverlay extends OverlayPlugin {
  @override
  List<Listenable> repaintOn(ChartController c) => [c.viewport]; // 滚动时跟随

  @override
  void paint(Canvas canvas, RenderContext ctx) {
    // 画水印...
  }
}
```

通过 `ChartController(overlays: [WatermarkOverlay()])` 挂载。

### 3. 自定义主图画法（MainSeries）

```dart
class DotSeries extends MainSeries {
  @override String get kind => 'dot';
  @override bool get usesHighLow => false; // 只画收盘价，影线不撑值域

  @override
  void paint(Canvas canvas, RenderContext ctx, SeriesPaintKit kit) {
    // 每根收盘价画一个点...
  }
}
```

通过 `KChart(series: DotSeries())` 使用。画法只决定"怎么画"；砖形图、新价线这类要改数据本身的，
是完整版的数据转换，不是画法。

## 内置指标

**主图叠加**：MA / EMA / BOLL / VolOverlay（主图底部量柱）

**独立副图**：MACD / KDJ / RSI / WR

**共享 'vol' 副图**：VOL + MAVol

## 内置主图画法

K线（实心 / 涨空心 / 跌空心）/ 线形 / 面积

## 性能门槛（perf_test 回归守卫）

| 场景 | 实测 |
|------|------|
| 10k 根 × 11 指标全量计算 | ≈ 27ms（≥2000 根默认放到后台 isolate，主线程不掉帧） |
| 单 tick 增量计算 | ≈ 6µs |
| 平移每帧布局 | ≈ 0.05ms |
| 拖十字线时 K 线层重绘 | **0 次** |

## 序列化（指标配置持久化）

```dart
// 保存
final json = [for (final i in controller.indicators.list) IndicatorRegistry.toJson(i)];

// 恢复
controller.indicators.setAll(IndicatorRegistry.fromJsonList(json));
```

第三方指标通过 `IndicatorRegistry.register(...)` 注册（注册的指标同样走后台 isolate 计算）。

整张图的配置（指标、缩放、`maxBars`、各叠加层自己的状态）一次存取：

```dart
final state = controller.saveState(); // 可直接 jsonEncode
controller.restoreState(state);

final themeJson = theme.toJson();
final restored = KLineTheme.fromJson(themeJson);
```

叠加层要参与存取，覆写 `OverlayPlugin.stateKey` / `saveState` / `restoreState`。
先 `restoreState` 再拉数据也行：没有数据时锁定范围和纵向缩放会留到下一次 `setBars` 之后生效。

## 其他功能

坐标与显示：

- **对数坐标**：`KChart(logScale: true)`
- **反转坐标**：`KChart(invertScale: true)` 主图小值在上、大值在下，纵向拖动方向跟着反过来
- **锁定坐标**：`controller.lockYRange()` 把主图值域锁在当前显示的范围，平移和新数据都不再自动缩放价格，手动缩放 / 平移照常叠加；`unlockYRange()` 回到自动（锁定期间的手动缩放一并清掉），随 `saveState` 存取，`setBars` 时自动解锁
- **第二条值轴**：`SecondaryAxis(Rsi())` 把任意指标叠到主图上、用自己的值域，不挤压价格；刻度标在主刻度对侧（`both` 时占左侧刻度条），十字线和图例同时给两个读数，`KChart(secondaryFormatter:)` 定格式；包着的指标能序列化时随 `saveState` 存取、走后台计算。插件实现 `secondaryRange` 也能用这条轴，数据变了调 `controller.relayout()`
- **百分比坐标**：`KChart(percentScale: true)`
- **值域动画**：`KChart(animateRange: true)` 数据驱动的值域补间
- **y 轴位置**：`KChart(yAxisPosition: ...)`，`outside` 右侧让出一条（默认）、`inside` 叠在图内、`left` 放左侧、`both` 左右两侧都标
- **最高 / 最低价标注**：`KChart(showHighLow: true)` 标出可见区的极值
- **主题细节**：`KLineTheme` 的 `showGrid` 关网格，`upWick` / `downWick` 单独配影线色，`upBorder` / `downBorder` 给实体描边，`highLowText` 设极值标注颜色
- **分级时间轴**：`KChart(tieredTimeAxis: true)` 刻度和竖网格落在换年 / 换月 / 换日 / 整点等边界上，跟着图平移，换日换月的刻度加粗；`tickFormatter` 自定义文字（收到原始 UTC 毫秒），`tickMinSpacing` 调刻度间距；跟设备时区时按每根自己的偏移找边界，跨夏令时也对。砖形图这类时间间隔不均匀的数据建议打开
- **十字线提示**：默认在主图左上角、指标图例上方固定一行开高低收和涨跌（图例让位，不跟手指跳），`tooltipStyle: KChartTooltipStyle.card` 换成浮动卡片，`tooltipBuilder` 完全自定义
- **时间与语言**：`utcOffset` 指定时区（默认跟设备），库不内置多语言，提示卡和无障碍文案默认英文，其它语言传 `labels: KChartLabels(time: '时间', ...)`；默认时间格式按周期自动选日期 / 时分 / 时分秒
- **无障碍**：图表自带 `Semantics` 描述（可见区间和最新价），文案同样走 `labels`

交互：

- **十字线吸附**：`KChart(crosshairSnap: CrosshairSnap.close)`，可选跟手指 / 吸收盘价 / 吸最近的开高低收
- **刻度条拖动缩放**：`KChart(axisDragScale: true)`，价格刻度上纵向拖缩放价格，时间轴上横向拖缩放时间
- **y 轴平移**：`KChart(yPan: YPanMode.axis)` 在刻度条上纵向拖平移值域，`YPanMode.chart` 整个主图都能拖；默认 `none` 让给外层滚动
- **y 轴缩小下限**：`KChart(yFitValues: () => [orderPrice, stopPrice])` 手动缩小 y 轴时保证这些价位还在图里
- **副图高度**：`KChart(panelResizable: true)` 拖分隔条改高度，`panelWeights` 给初始权重
- **点击 K 线**：`KChart(onBarTap: (bar) { ... })`，传了就没有双击复位 y 轴；点在最新一根右侧留白、最老一根左侧空处不回调
- **拖价位线改价**：`KChart(levelDrag: LevelDragController(onDrop: (level, price) { ... }))`，宿主设 `levels`，线自己在 `overlayBuilder` 里按 `draggingId` / `previewPrice` 画；拖出主图、松手价没变、被系统取消（来电、宿主拦截）都不调 `onDrop`
- **键盘**：鼠标点过图表后，左右键平移（Shift 一次 10%），上下键和 +/- 缩放，Home / End 跳到最早 / 最新（End 同时恢复 autoFollow），Esc 收十字线；带 Ctrl / Cmd / Alt 的组合键不处理，画线独占时只响应 Esc；`KChart(keyboard: false)` 关掉
- **autoFollow**：`KChart(autoFollow: true)` 贴右缘跟随最新一根

扩展与数据：

- **宿主图层**：`underlayBuilder` 在网格和主图之间（水印），`overlayBuilder` 在最上层（订单按钮、标注），都拿 `RenderContext` 换算坐标
- **深度图**：`DepthChart`
- **周期合成**：`controller.aggregator = MyAggregator()`（继承 `BarAggregator`，只写 `bucketOf`）之后，`setBars` / `applyTick` / `prependHistory` 直接喂源周期 K 线，控制器自己合成：推送只重算末根所在的桶，往前加载会修正边界那个桶，源数据在 `sourceBars`
- **历史上限**：`controller.maxBars = 5000`，追加超出时从最老的一头裁掉，到上限后往前加载不再插入；默认不限
- **指标出错**：`controller.onIndicatorError` 收到自定义指标抛的错，不设时 debug 下打印
- **后台计算**：≥2000 根的全量重算自动放到后台 isolate，`controller.computing` 供宿主显示遮罩；`asyncCompute = false` 可强制同步
- **内存**：系统内存紧张时 KChart 自动释放可重建的值域缓存；宿主也可以手动调 `controller.releaseCaches()`

## 与其它 Flutter K 线库对比

结论来自源码阅读（2026-11），不采信各库 README 的自述。klinex 一栏写「免费 / 完整」时，斜杠前是免费版，后是完整版。

| | klinex | FlexiKline | swm | candlesticks | Pipsend | chen |
|---|---|---|---|---|---|---|
| 运行时三方依赖 | 无 | 5 个 | 1 个 | 无 | 1 个 | 无 |
| 分层重绘 | 每层独立 RepaintBoundary | 2 层 | 2 层 | 部分 | ❌ | ❌ |
| 拖十字线重绘 K 线 | ❌ 从不 | ❌ | ❌ | 重建整树 | ✅ | ✅ |
| 增量指标 | 全部，与全量逐根对拍 | 脏尾段重算 | 73 个里 10 个 | 无指标 | ❌ | ❌ |
| 后台 isolate | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |
| 极限缩小聚合 | ✅ | ❌ | ✅（默认关） | ❌ | ❌ | ❌ |
| 脏数据（乱序、NaN、重复） | 自动清洗 | 只有 debug assert | 乱序抛异常 | NaN 整屏空白 | ❌ | 部分 |
| 内置指标 | 10 / 50 | 0（在另一个包） | 73 | 0 | 16 | 7 |
| 主图画法 | 3 / 13 + 平均 K 线 | 7 | 6 | 1 | 4 | 2 |
| 画线工具 | — / 32 | 19 | 约 17 | 0 | 13 | 8 |
| 画线撤销 / 多选 | — / ✅ ✅ | ❌ ❌ | ✅ ❌ | ❌ | ❌ | ❌ |
| 对数 / 百分比坐标 | ✅ ✅ | ❌ ❌ | ✅ ✅ | ✅ ❌ | ❌ | ❌ |
| 嵌在滚动页 / TabBarView | ✅ 有回归测试 | ✅ | 部分 | ❌ | ❌ | ❌ |
| 键盘 | ✅ | 只有 Esc | ❌ | ❌ | ❌ | ❌ |
| 深度图 | ✅ | ❌ | ❌ | ❌ | ❌ | ✅ |
| 回放 / 多图联动 | — / ✅ ✅ | ❌ | ❌ / 只同步十字线 | ❌ | ✅ ❌ | ❌ |
| 整体状态存取 | ✅ | ✅ | 只有画线 | ❌ | 只有画线 | ❌ |
| 测试用例 | 286 / 516 | 约 1500 | 约 220 | 12 | 约 51 | 0 |

## 完整版

完整版额外提供下面这些，性能和免费版完全一样：

- **进阶指标 40 个**：WMA / SAR / SuperTrend / Keltner / Donchian / VWAP / Ichimoku / Volume Profile / DEMA / TEMA / Hull / VWMA / KAMA / ALMA / LSMA / 枢轴点 / ZigZag / StochRSI / Stochastic / CCI / OBV / ATR / DMI / MFI / CMF / ROC / MTM / TRIX / Aroon / 标准差 / 历史波动率 / A/D / 蔡金震荡 / 布林 %B / 布林带宽 / Vortex / Choppiness / AO / PPO / Fisher
- **进阶主图画法 10 种 + 平均 K 线**：美国线 / 成交量蜡烛 / 阶梯 / 基准线 / HLC 区域 / 高-低 / 柱状 / 带标记 / Kagi / 点数图，Heikin-Ashi
- **画线工具 32 种**：趋势线 / 延伸线 / 射线 / 箭头 / 水平线 / 水平线段 / 垂直线段 / 十字线 / 平行通道 / 价格线 / 三浪 / 五浪 / 矩形 / 椭圆 / 三角形 / 斐波那契回撤 / 斐波那契扩展 / 斐波那契扇形 / 斐波那契时间周期 / 斐波那契通道 / 安德鲁音叉 / 线性回归通道 / 江恩扇形 / 锚定 VWAP / 手绘 / XABCD / ABCD / 艾略特推动浪 / 艾略特调整浪 / 文字 / 仓位（止盈止损、盈亏比）/ 测量，支持拖动编辑、磁吸（关 / 弱 / 强三档）、多选与框选整体拖动、撤销重做、置顶置底，`DrawingSet.onChange` 回调增删改（多端同步用），跟着 `saveState` 一起存取
- **订单线**：委托线、持仓线、止盈止损的现成画法（拖动改价用的是免费版的 `LevelDragController`）
- **价格报警线**：上穿 / 下穿 / 穿越触发回调，可拖动改价，触发一次或持续
- **成交标**：买 / 卖 / 强平标记，同一根同方向合并，可点中
- **数据转换**：砖形图（可按 ATR 定砖）、新价线、固定波幅 K 线（Range bars）、Kagi、点数图（Point & Figure）、小周期合成大周期（含实时合成）；Kagi、点数图配 `KagiSeries` / `PointFigureSeries` 画
- **对比叠加**：别的品种按涨跌幅换算叠到主图上，或按原始价格挂到主图第二条值轴（`CompareAxis.secondary`）
- **K 线回放**：逐根回放，播放 / 暂停 / 单步 / 按根或日期跳转 / 倍速，末根可按 开→低→高→收 逐跳长出，未来区域压暗
- **多图联动**：按时间同步视口和十字线

完整版通过 `package:klinex/pro.dart` 引入，启动时调一次 `KlinexPro.install()`。
完整版里的文字同样默认英文，例如 Ichimoku 图例用 `Ichimoku(labels: IchimokuLabels(tenkan: '转换', ...))` 换成其它语言。
