// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a zh locale. All the
// messages from the main program should be duplicated here with the same
// function name.

// Ignore issues from commonly used lints in this file.
// ignore_for_file:unnecessary_brace_in_string_interps, unnecessary_new
// ignore_for_file:prefer_single_quotes,comment_references, directives_ordering
// ignore_for_file:annotate_overrides,prefer_generic_function_type_aliases
// ignore_for_file:unused_import, file_names, avoid_escaping_inner_quotes
// ignore_for_file:unnecessary_string_interpolations, unnecessary_string_escapes

import 'package:intl/intl.dart';
import 'package:intl/message_lookup_by_library.dart';

final messages = new MessageLookup();

typedef String MessageIfAbsent(String messageStr, List<dynamic> args);

class MessageLookup extends MessageLookupByLibrary {
  String get localeName => 'zh';

  static String m0(label, value) => "${label}：${value}";

  static String m1(index, close) => "第 ${index} 根 · 收 ${close}";

  static String m2(count) => "当前 ${count} 根；合成行情不需要联网。";

  static String m3(count) => "${count} 位";

  static String m4(price, time) => "下单价 ${price}（${time}）";

  static String m5(open, high, low, close) =>
      "点中：开 ${open}  高 ${high}  低 ${low}  收 ${close}";

  static String m6(count) => "往前加载 ${count} 根";

  static String m7(pages, count) => "已加载 ${pages} 页，共 ${count} 根。";

  static String m8(index) => "第 ${index} 条线";

  static String m9(index) => "线 ${index} 颜色";

  static String m10(index) => "周期 ${index}";

  static String m11(name, reason) => "${name} 参数未生效：${reason}";

  static String m12(reason) => "行情加载失败:${reason}";

  static String m13(min, max) => "锁定在 ${min} ~ ${max}";

  static String m14(start, end) => "可见 ${start} - ${end}";

  static String m15(ms) => "${ms} 毫秒";

  static String m16(count) => "KLINEX · 离线合成行情 · ${count} 根";

  static String m17(name) => "${name} 参数";

  static String m18(name) => "${name}（完整版）";

  static String m19(error) => "恢复失败：${error}";

  static String m20(day) => "${day}日";

  static String m21(year) => "${year}年";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "axisPositionBoth": MessageLookupByLibrary.simpleMessage("两侧"),
    "axisPositionHint": MessageLookupByLibrary.simpleMessage(
      "图内模式不占宽度，刻度叠在 K 线上；图外 / 左侧 / 两侧会让出刻度条。",
    ),
    "axisPositionInside": MessageLookupByLibrary.simpleMessage("右侧图内"),
    "axisPositionLabel": MessageLookupByLibrary.simpleMessage("价格轴位置"),
    "axisPositionLeft": MessageLookupByLibrary.simpleMessage("左侧"),
    "axisPositionOutside": MessageLookupByLibrary.simpleMessage("右侧图外"),
    "axisPositionWidth": MessageLookupByLibrary.simpleMessage("刻度条宽度"),
    "axisTagAsk": MessageLookupByLibrary.simpleMessage("卖"),
    "axisTagBid": MessageLookupByLibrary.simpleMessage("买"),
    "candleBorder": MessageLookupByLibrary.simpleMessage("蜡烛描边"),
    "candleFill": MessageLookupByLibrary.simpleMessage("填充"),
    "candleFillHollowDown": MessageLookupByLibrary.simpleMessage("跌空心"),
    "candleFillHollowUp": MessageLookupByLibrary.simpleMessage("涨空心"),
    "candleFillSolid": MessageLookupByLibrary.simpleMessage("实心"),
    "candleWickColor": MessageLookupByLibrary.simpleMessage("影线单独配色（灰）"),
    "chartChange": MessageLookupByLibrary.simpleMessage("涨跌幅"),
    "chartClose": MessageLookupByLibrary.simpleMessage("收"),
    "chartHigh": MessageLookupByLibrary.simpleMessage("高"),
    "chartLatest": MessageLookupByLibrary.simpleMessage("最新价"),
    "chartLow": MessageLookupByLibrary.simpleMessage("低"),
    "chartName": MessageLookupByLibrary.simpleMessage("K 线图"),
    "chartOpen": MessageLookupByLibrary.simpleMessage("开"),
    "chartRangeTo": MessageLookupByLibrary.simpleMessage("至"),
    "chartSeparator": MessageLookupByLibrary.simpleMessage("，"),
    "chartTime": MessageLookupByLibrary.simpleMessage("时间"),
    "chartVolume": MessageLookupByLibrary.simpleMessage("量"),
    "commonReset": MessageLookupByLibrary.simpleMessage("重置"),
    "commonSave": MessageLookupByLibrary.simpleMessage("保存"),
    "computeSampleAsync": MessageLookupByLibrary.simpleMessage(
      "后台 isolate 计算 asyncCompute",
    ),
    "computeSampleBusy": MessageLookupByLibrary.simpleMessage("后台计算中…"),
    "computeSampleHint": MessageLookupByLibrary.simpleMessage(
      "本页 10,000 根；全量计算达到 2,000 根才走后台，Web 按平台能力执行。",
    ),
    "computeSampleTriggerError": MessageLookupByLibrary.simpleMessage(
      "演示指标出错回调",
    ),
    "controlsCodeCopied": MessageLookupByLibrary.simpleMessage("代码已复制"),
    "controlsCopyCode": MessageLookupByLibrary.simpleMessage("复制代码"),
    "controlsEquivalentCode": MessageLookupByLibrary.simpleMessage("等价代码"),
    "controlsSliderValue": m0,
    "crosshairSampleCustomBuilder": MessageLookupByLibrary.simpleMessage(
      "自定义提示卡 tooltipBuilder",
    ),
    "crosshairSampleCustomTooltip": m1,
    "crosshairSampleHint": MessageLookupByLibrary.simpleMessage(
      "手机长按图表；桌面把鼠标移到图上。",
    ),
    "crosshairSampleShowTooltip": MessageLookupByLibrary.simpleMessage("显示提示"),
    "crosshairSampleSnap": MessageLookupByLibrary.simpleMessage(
      "吸附 crosshairSnap",
    ),
    "crosshairSampleSnapClose": MessageLookupByLibrary.simpleMessage("收盘价"),
    "crosshairSampleSnapFree": MessageLookupByLibrary.simpleMessage("跟随手指"),
    "crosshairSampleSnapOhlc": MessageLookupByLibrary.simpleMessage("开高低收最近价"),
    "crosshairSampleStyleCard": MessageLookupByLibrary.simpleMessage("浮动卡片"),
    "crosshairSampleStyleInline": MessageLookupByLibrary.simpleMessage(
      "图例上方一行",
    ),
    "crosshairSampleTooltipStyle": MessageLookupByLibrary.simpleMessage(
      "提示样式 tooltipStyle",
    ),
    "customSeriesSampleDots": MessageLookupByLibrary.simpleMessage("收盘价散点画法"),
    "customSeriesSampleHint": MessageLookupByLibrary.simpleMessage(
      "实现 MainSeries.paint：ctx 给坐标换算和可见范围，不用改库源码。",
    ),
    "customSeriesSampleRadius": MessageLookupByLibrary.simpleMessage("点半径"),
    "dataLimitCurrent": m2,
    "dataLimitInitial": MessageLookupByLibrary.simpleMessage("初始根数"),
    "dataLimitMaxBars": MessageLookupByLibrary.simpleMessage("历史上限 maxBars"),
    "dataLimitRegenerate": MessageLookupByLibrary.simpleMessage("重新生成"),
    "dataLimitUnlimited": MessageLookupByLibrary.simpleMessage("不限制"),
    "depthSampleBidSkew": MessageLookupByLibrary.simpleMessage("买盘厚度倍数"),
    "depthSampleLevels": MessageLookupByLibrary.simpleMessage("档数"),
    "depthSampleWithKline": MessageLookupByLibrary.simpleMessage("上方同时显示 K 线"),
    "formatSampleCustomLabels": MessageLookupByLibrary.simpleMessage(
      "自定义文案 labels",
    ),
    "formatSampleCustomTime": MessageLookupByLibrary.simpleMessage(
      "自定义时间格式 timeFormatter",
    ),
    "formatSampleDecimals": MessageLookupByLibrary.simpleMessage("价格小数位"),
    "formatSampleDecimalsOption": m3,
    "formatSampleHint": MessageLookupByLibrary.simpleMessage(
      "给了 timeFormatter 就由它负责时区；提示卡、图例的文案跟随 labels。",
    ),
    "formatSampleTimezone": MessageLookupByLibrary.simpleMessage(
      "时区 utcOffset",
    ),
    "gestureSampleAxisDrag": MessageLookupByLibrary.simpleMessage(
      "刻度条拖动缩放 axisDragScale",
    ),
    "gestureSampleAxisDragHint": MessageLookupByLibrary.simpleMessage(
      "开启后拖价格轴缩放价格、拖时间轴缩放时间；双击复位。",
    ),
    "gestureSampleBarTap": MessageLookupByLibrary.simpleMessage(
      "点 K 线取价 onBarTap",
    ),
    "gestureSampleBarTapHint": MessageLookupByLibrary.simpleMessage(
      "单击一根 K 线拿到这根的 Bar，交易页常用来把收盘价填进下单框。传了 onBarTap 就没有双击复位 y 轴。",
    ),
    "gestureSampleOrderPrice": m4,
    "gestureSampleTapped": m5,
    "gestureSampleYPan": MessageLookupByLibrary.simpleMessage("纵向平移 yPan"),
    "gestureSampleYPanAxis": MessageLookupByLibrary.simpleMessage("只在价格轴上"),
    "gestureSampleYPanChart": MessageLookupByLibrary.simpleMessage("整个主图"),
    "gestureSampleYPanNone": MessageLookupByLibrary.simpleMessage("不平移，让给外层滚动"),
    "gridSampleDash": MessageLookupByLibrary.simpleMessage("网格虚线 gridLineDash"),
    "gridSampleLineWidth": MessageLookupByLibrary.simpleMessage(
      "网格线宽 gridLineWidth",
    ),
    "gridSampleShowGrid": MessageLookupByLibrary.simpleMessage("显示网格 showGrid"),
    "gridSampleTextSize": MessageLookupByLibrary.simpleMessage(
      "刻度字号 axisTextSize",
    ),
    "historyAutoLoad": MessageLookupByLibrary.simpleMessage("滑到左侧自动加载"),
    "historyHint": MessageLookupByLibrary.simpleMessage("加载前先往历史方向拖一段，观察视口不跳。"),
    "historyLoadButton": m6,
    "historyStatus": m7,
    "homeLive": MessageLookupByLibrary.simpleMessage("实时行情"),
    "homeSamples": MessageLookupByLibrary.simpleMessage("配置大全"),
    "indicatorBollDesc": MessageLookupByLibrary.simpleMessage("布林线"),
    "indicatorColor": MessageLookupByLibrary.simpleMessage("颜色"),
    "indicatorEmaDesc": MessageLookupByLibrary.simpleMessage("指数移动平均线"),
    "indicatorFieldsLine": m8,
    "indicatorFieldsLineColor": m9,
    "indicatorFieldsPeriod": m10,
    "indicatorGroupMain": MessageLookupByLibrary.simpleMessage("主图"),
    "indicatorGroupSub": MessageLookupByLibrary.simpleMessage("副图"),
    "indicatorKdjDesc": MessageLookupByLibrary.simpleMessage("随机指标"),
    "indicatorLine": MessageLookupByLibrary.simpleMessage("指标线"),
    "indicatorLongPeriod": MessageLookupByLibrary.simpleMessage("长周期"),
    "indicatorMaDesc": MessageLookupByLibrary.simpleMessage("移动平均线"),
    "indicatorMacdDesc": MessageLookupByLibrary.simpleMessage("指数平滑异同移动平均线"),
    "indicatorParamSampleDSmooth": MessageLookupByLibrary.simpleMessage("D 平滑"),
    "indicatorParamSampleHint": MessageLookupByLibrary.simpleMessage(
      "参数一改指标 id 就变，整段重算；非法组合不生效并给出原因。",
    ),
    "indicatorParamSampleKSmooth": MessageLookupByLibrary.simpleMessage("K 平滑"),
    "indicatorParamSampleLongPeriod": MessageLookupByLibrary.simpleMessage(
      "长周期",
    ),
    "indicatorParamSamplePeriod": MessageLookupByLibrary.simpleMessage("周期"),
    "indicatorParamSampleShortPeriod": MessageLookupByLibrary.simpleMessage(
      "短周期",
    ),
    "indicatorParamSampleSignalPeriod": MessageLookupByLibrary.simpleMessage(
      "信号周期",
    ),
    "indicatorParamSampleStdDev": MessageLookupByLibrary.simpleMessage("标准差倍数"),
    "indicatorParamsNotApplied": m11,
    "indicatorPeriod": MessageLookupByLibrary.simpleMessage("周期"),
    "indicatorPeriodN": MessageLookupByLibrary.simpleMessage("周期 N"),
    "indicatorReferenceValue": MessageLookupByLibrary.simpleMessage("参考值"),
    "indicatorRsiDesc": MessageLookupByLibrary.simpleMessage("相对强弱指标"),
    "indicatorSettingsTitle": MessageLookupByLibrary.simpleMessage("指标设置"),
    "indicatorShortPeriod": MessageLookupByLibrary.simpleMessage("短周期"),
    "indicatorSignalPeriod": MessageLookupByLibrary.simpleMessage("移动平均周期"),
    "indicatorStdDevMultiplier": MessageLookupByLibrary.simpleMessage("标准差倍数"),
    "indicatorSwitchSampleHint": MessageLookupByLibrary.simpleMessage(
      "每个指标的参数在各自的“参数”页；完整版另有 40 个进阶指标。",
    ),
    "indicatorSwitchSampleMain": MessageLookupByLibrary.simpleMessage("主图叠加"),
    "indicatorSwitchSampleSub": MessageLookupByLibrary.simpleMessage(
      "副图 / 成交量",
    ),
    "indicatorWrDesc": MessageLookupByLibrary.simpleMessage("威廉指标"),
    "keyboardSampleEnable": MessageLookupByLibrary.simpleMessage(
      "启用键盘 keyboard",
    ),
    "keyboardSampleFocusHint": MessageLookupByLibrary.simpleMessage(
      "先点一下图表获得焦点。输入框有焦点时不会驱动图表。",
    ),
    "keyboardSampleShortcuts": MessageLookupByLibrary.simpleMessage(
      "左 / 右：平移\n上 / 下 或 + / -：缩放\nHome / End：最早 / 最新\nEsc：清除十字线",
    ),
    "language": MessageLookupByLibrary.simpleMessage("English"),
    "liveAutoFollow": MessageLookupByLibrary.simpleMessage("自动跟随最新"),
    "liveBookPrice": MessageLookupByLibrary.simpleMessage("盘口买卖价"),
    "liveChartSettings": MessageLookupByLibrary.simpleMessage("图表设置"),
    "liveChartType": MessageLookupByLibrary.simpleMessage("图表类型"),
    "liveConnecting": MessageLookupByLibrary.simpleMessage("连接中…"),
    "liveCountdown": MessageLookupByLibrary.simpleMessage("倒计时"),
    "liveGoToSettings": MessageLookupByLibrary.simpleMessage("去设置"),
    "liveHeikinAshi": MessageLookupByLibrary.simpleMessage(
      "平均K线 (Heikin-Ashi)",
    ),
    "liveIndicatorParams": MessageLookupByLibrary.simpleMessage("指标参数"),
    "liveInterval12h": MessageLookupByLibrary.simpleMessage("12小时"),
    "liveInterval15m": MessageLookupByLibrary.simpleMessage("15分"),
    "liveInterval1M": MessageLookupByLibrary.simpleMessage("月线"),
    "liveInterval1d": MessageLookupByLibrary.simpleMessage("日线"),
    "liveInterval1h": MessageLookupByLibrary.simpleMessage("1小时"),
    "liveInterval1m": MessageLookupByLibrary.simpleMessage("1分"),
    "liveInterval1w": MessageLookupByLibrary.simpleMessage("周线"),
    "liveInterval2h": MessageLookupByLibrary.simpleMessage("2小时"),
    "liveInterval30m": MessageLookupByLibrary.simpleMessage("30分"),
    "liveInterval3d": MessageLookupByLibrary.simpleMessage("3日"),
    "liveInterval3m": MessageLookupByLibrary.simpleMessage("3分"),
    "liveInterval4h": MessageLookupByLibrary.simpleMessage("4小时"),
    "liveInterval5m": MessageLookupByLibrary.simpleMessage("5分"),
    "liveInterval6h": MessageLookupByLibrary.simpleMessage("6小时"),
    "liveInterval8h": MessageLookupByLibrary.simpleMessage("8小时"),
    "liveIntervalMore": MessageLookupByLibrary.simpleMessage("更多"),
    "liveLastPrice": MessageLookupByLibrary.simpleMessage("最新成交价"),
    "liveLoadFailed": m12,
    "liveLogScale": MessageLookupByLibrary.simpleMessage("对数坐标"),
    "liveLogSegment": MessageLookupByLibrary.simpleMessage("日志分段"),
    "liveNoData": MessageLookupByLibrary.simpleMessage("接口无数据"),
    "livePercentScale": MessageLookupByLibrary.simpleMessage("百分比坐标"),
    "livePleaseRetry": MessageLookupByLibrary.simpleMessage("请重试"),
    "liveSectionChart": MessageLookupByLibrary.simpleMessage("图表"),
    "liveSectionChartHeight": MessageLookupByLibrary.simpleMessage("图表高度"),
    "liveSectionDisplay": MessageLookupByLibrary.simpleMessage("图表展示"),
    "liveSeriesArea": MessageLookupByLibrary.simpleMessage("面积图"),
    "liveSeriesCandle": MessageLookupByLibrary.simpleMessage("K线图"),
    "liveSeriesLine": MessageLookupByLibrary.simpleMessage("线形图"),
    "liveSwitchMarket": MessageLookupByLibrary.simpleMessage("切换市场"),
    "liveTapToRetry": MessageLookupByLibrary.simpleMessage("点击重试"),
    "liveTimeZone": MessageLookupByLibrary.simpleMessage("时区"),
    "liveTimeZoneDevice": MessageLookupByLibrary.simpleMessage("跟随设备"),
    "liveTimeZoneNewYork": MessageLookupByLibrary.simpleMessage("UTC-5 纽约(冬令)"),
    "liveTimeZoneShanghai": MessageLookupByLibrary.simpleMessage("UTC+8 上海"),
    "liveYAxisOutside": MessageLookupByLibrary.simpleMessage("Y轴价格外置"),
    "lockRangeHint": MessageLookupByLibrary.simpleMessage(
      "锁定后左右平移、推送新数据都不再自动缩放价格；拖价格轴缩放 / 平移照常叠加在锁定范围上。",
    ),
    "lockRangeLock": MessageLookupByLibrary.simpleMessage("锁定当前价格范围"),
    "lockRangeLockedAt": m13,
    "lockRangeStorageHint": MessageLookupByLibrary.simpleMessage(
      "随 saveState 存取，setBars 时自动解锁。",
    ),
    "netConnectTimeout": MessageLookupByLibrary.simpleMessage("连接超时"),
    "netConnectionFailed": MessageLookupByLibrary.simpleMessage("网络连接失败"),
    "netReceiveTimeout": MessageLookupByLibrary.simpleMessage("接收超时"),
    "netRequestCancelled": MessageLookupByLibrary.simpleMessage("请求已取消"),
    "netSendTimeout": MessageLookupByLibrary.simpleMessage("发送超时"),
    "netServerError": MessageLookupByLibrary.simpleMessage("服务返回异常"),
    "overlaySampleHint": MessageLookupByLibrary.simpleMessage(
      "overlayBuilder 每帧拿到 RenderContext（坐标换算、可见区），返回任意 Widget，跟着平移缩放走。",
    ),
    "overlaySampleLastBadge": MessageLookupByLibrary.simpleMessage("最新一根上方的标签"),
    "overlaySampleLatest": MessageLookupByLibrary.simpleMessage("最新"),
    "overlaySampleRangeBadge": MessageLookupByLibrary.simpleMessage("可见范围角标"),
    "overlaySampleVisibleRange": m14,
    "panelsSampleHint": MessageLookupByLibrary.simpleMessage(
      "拖出来的高度存在 ChartConfig.panelWeights 里，随 saveState 存取。",
    ),
    "panelsSampleMainFlex": MessageLookupByLibrary.simpleMessage(
      "主图权重 mainFlex",
    ),
    "panelsSampleResizable": MessageLookupByLibrary.simpleMessage(
      "拖动分隔条调高度 panelResizable",
    ),
    "panelsSampleSubFlex": MessageLookupByLibrary.simpleMessage(
      "每个副图权重 subFlex",
    ),
    "paramInputIntError": MessageLookupByLibrary.simpleMessage(
      "请输入有限正整数，不超过 100000",
    ),
    "paramInputNumberError": MessageLookupByLibrary.simpleMessage(
      "请输入有限正数，不超过 100000",
    ),
    "priceLineAnimateHint": MessageLookupByLibrary.simpleMessage(
      "价格动画让末根收盘和价格线在约 200 毫秒内滑到新值，只影响显示。",
    ),
    "priceLineAnimatePrice": MessageLookupByLibrary.simpleMessage(
      "价格动画 animatePrice",
    ),
    "priceLineAnimateRange": MessageLookupByLibrary.simpleMessage(
      "值域动画 animateRange",
    ),
    "priceLineBook": MessageLookupByLibrary.simpleMessage("盘口买卖价"),
    "priceLineCountdown": MessageLookupByLibrary.simpleMessage("倒计时"),
    "priceLineDataHint": MessageLookupByLibrary.simpleMessage(
      "这里的合成数据每 3 秒一根，倒计时按这个节奏走，盘口是模拟的。",
    ),
    "priceLineHighLow": MessageLookupByLibrary.simpleMessage(
      "最高 / 最低价标签 showHighLow",
    ),
    "priceLineOverlayHint": MessageLookupByLibrary.simpleMessage(
      "库里的 PriceLineOverlay 只画虚线。",
    ),
    "priceLinePriceType": MessageLookupByLibrary.simpleMessage("K 线价格类型"),
    "priceLinePriceTypeHint": MessageLookupByLibrary.simpleMessage(
      "合约行情可以按标记价、指数价画 K 线，这时左下角提示一句，免得和最新成交价弄混（这里只换提示，数据不变）。",
    ),
    "priceLineShowPrice": MessageLookupByLibrary.simpleMessage("最新价线 + 价签"),
    "priceLineStackHint": MessageLookupByLibrary.simpleMessage(
      "价签挤在一起时按价格从高到低排开，同价时 卖 → 现价 → 买；拖进历史时多一个参考价签。",
    ),
    "priceLineTagsHint": MessageLookupByLibrary.simpleMessage(
      "y 轴上的价签、收盘倒计时、盘口买一 / 卖一由 overlayBuilder 画（demo 的 AxisPriceTags）。",
    ),
    "priceLineTipIndex": MessageLookupByLibrary.simpleMessage("当前为指数价格 K 线"),
    "priceLineTipMark": MessageLookupByLibrary.simpleMessage("当前为标记价格 K 线"),
    "priceLineTypeIndex": MessageLookupByLibrary.simpleMessage("指数价"),
    "priceLineTypeLast": MessageLookupByLibrary.simpleMessage("最新价"),
    "priceLineTypeMark": MessageLookupByLibrary.simpleMessage("标记价"),
    "proGroupMain": MessageLookupByLibrary.simpleMessage("主图(完整版)"),
    "proGroupSub": MessageLookupByLibrary.simpleMessage("副图(完整版)"),
    "proIndicatorAd": MessageLookupByLibrary.simpleMessage("累积派发线"),
    "proIndicatorAlma": MessageLookupByLibrary.simpleMessage("阿尔诺·勒古均线"),
    "proIndicatorAo": MessageLookupByLibrary.simpleMessage("动量震荡"),
    "proIndicatorAroon": MessageLookupByLibrary.simpleMessage("阿隆指标"),
    "proIndicatorAtr": MessageLookupByLibrary.simpleMessage("真实波幅均值"),
    "proIndicatorBbw": MessageLookupByLibrary.simpleMessage("布林带宽"),
    "proIndicatorCci": MessageLookupByLibrary.simpleMessage("顺势指标"),
    "proIndicatorCho": MessageLookupByLibrary.simpleMessage("蔡金震荡指标"),
    "proIndicatorChop": MessageLookupByLibrary.simpleMessage("震荡度指数"),
    "proIndicatorCmf": MessageLookupByLibrary.simpleMessage("蔡金资金流"),
    "proIndicatorDc": MessageLookupByLibrary.simpleMessage("唐奇安通道"),
    "proIndicatorDema": MessageLookupByLibrary.simpleMessage("双重指数均线"),
    "proIndicatorDmi": MessageLookupByLibrary.simpleMessage("趋向指标"),
    "proIndicatorFisher": MessageLookupByLibrary.simpleMessage("费舍尔变换"),
    "proIndicatorHma": MessageLookupByLibrary.simpleMessage("赫尔均线"),
    "proIndicatorHv": MessageLookupByLibrary.simpleMessage("历史波动率"),
    "proIndicatorIchi": MessageLookupByLibrary.simpleMessage("一目均衡表"),
    "proIndicatorKama": MessageLookupByLibrary.simpleMessage("考夫曼自适应均线"),
    "proIndicatorKc": MessageLookupByLibrary.simpleMessage("肯特纳通道"),
    "proIndicatorLsma": MessageLookupByLibrary.simpleMessage("最小二乘均线"),
    "proIndicatorMfi": MessageLookupByLibrary.simpleMessage("资金流量指标"),
    "proIndicatorMtm": MessageLookupByLibrary.simpleMessage("动量指标"),
    "proIndicatorObv": MessageLookupByLibrary.simpleMessage("能量潮指标"),
    "proIndicatorPercentB": MessageLookupByLibrary.simpleMessage("布林 %B"),
    "proIndicatorPivot": MessageLookupByLibrary.simpleMessage("枢轴点"),
    "proIndicatorPpo": MessageLookupByLibrary.simpleMessage("价格震荡百分比"),
    "proIndicatorRoc": MessageLookupByLibrary.simpleMessage("变动率"),
    "proIndicatorSar": MessageLookupByLibrary.simpleMessage("抛物线转向"),
    "proIndicatorSt": MessageLookupByLibrary.simpleMessage("超级趋势"),
    "proIndicatorStd": MessageLookupByLibrary.simpleMessage("标准差"),
    "proIndicatorStoch": MessageLookupByLibrary.simpleMessage("随机指标"),
    "proIndicatorStochRsi": MessageLookupByLibrary.simpleMessage("随机相对强弱"),
    "proIndicatorTema": MessageLookupByLibrary.simpleMessage("三重指数均线"),
    "proIndicatorTrix": MessageLookupByLibrary.simpleMessage("三重指数平滑"),
    "proIndicatorVortex": MessageLookupByLibrary.simpleMessage("涡旋指标"),
    "proIndicatorVwma": MessageLookupByLibrary.simpleMessage("成交量加权均线"),
    "proIndicatorWma": MessageLookupByLibrary.simpleMessage("加权移动平均线"),
    "proIndicatorZigzag": MessageLookupByLibrary.simpleMessage("之字转向"),
    "proLockFeature": MessageLookupByLibrary.simpleMessage("完整版功能"),
    "proSampleAlerts": MessageLookupByLibrary.simpleMessage("价格报警"),
    "proSampleCompare": MessageLookupByLibrary.simpleMessage("对比叠加"),
    "proSampleDrawing": MessageLookupByLibrary.simpleMessage("画线"),
    "proSampleFills": MessageLookupByLibrary.simpleMessage("成交标"),
    "proSampleIndicators": MessageLookupByLibrary.simpleMessage("进阶指标"),
    "proSampleOrders": MessageLookupByLibrary.simpleMessage("订单线"),
    "proSamplePosition": MessageLookupByLibrary.simpleMessage("仓位和测量"),
    "proSampleReplay": MessageLookupByLibrary.simpleMessage("回放"),
    "proSampleSync": MessageLookupByLibrary.simpleMessage("多图联动"),
    "proSampleTransforms": MessageLookupByLibrary.simpleMessage("数据转换"),
    "proSeriesBaseline": MessageLookupByLibrary.simpleMessage("基准线"),
    "proSeriesColumn": MessageLookupByLibrary.simpleMessage("柱状图"),
    "proSeriesHiLo": MessageLookupByLibrary.simpleMessage("高-低"),
    "proSeriesHlcArea": MessageLookupByLibrary.simpleMessage("HLC区域"),
    "proSeriesMarkers": MessageLookupByLibrary.simpleMessage("带标记线"),
    "proSeriesOhlc": MessageLookupByLibrary.simpleMessage("美国线"),
    "proSeriesStep": MessageLookupByLibrary.simpleMessage("阶梯线"),
    "proSeriesVolCandle": MessageLookupByLibrary.simpleMessage("成交量蜡烛"),
    "realtimeAppend": MessageLookupByLibrary.simpleMessage("追加一根"),
    "realtimeAutoPush": MessageLookupByLibrary.simpleMessage("自动推送（每 5 次追加一根）"),
    "realtimeFollow": MessageLookupByLibrary.simpleMessage("跟随最新 autoFollow"),
    "realtimeHint": MessageLookupByLibrary.simpleMessage(
      "关掉跟随后往左拖一段，推送不会把视口拉回最新。",
    ),
    "realtimeInterval": MessageLookupByLibrary.simpleMessage("推送间隔"),
    "realtimeMillis": m15,
    "realtimeOneSecond": MessageLookupByLibrary.simpleMessage("1 秒"),
    "realtimeUpdateLast": MessageLookupByLibrary.simpleMessage("更新末根价格"),
    "sampleAutoPush": MessageLookupByLibrary.simpleMessage("自动推送"),
    "sampleAxisPositionDesc": MessageLookupByLibrary.simpleMessage(
      "右侧图内 / 图外、左侧、两侧，刻度条宽度。",
    ),
    "sampleAxisPositionTitle": MessageLookupByLibrary.simpleMessage("价格轴位置"),
    "sampleBackToLatest": MessageLookupByLibrary.simpleMessage("回到最新"),
    "sampleCandleDesc": MessageLookupByLibrary.simpleMessage(
      "实心 / 空心，影线和边框单独配色。",
    ),
    "sampleCandleTitle": MessageLookupByLibrary.simpleMessage("蜡烛样式"),
    "sampleCategoryAppearance": MessageLookupByLibrary.simpleMessage("外观"),
    "sampleCategoryCoordinates": MessageLookupByLibrary.simpleMessage("坐标"),
    "sampleCategoryData": MessageLookupByLibrary.simpleMessage("数据"),
    "sampleCategoryExtensions": MessageLookupByLibrary.simpleMessage("扩展"),
    "sampleCategoryIndicators": MessageLookupByLibrary.simpleMessage("指标"),
    "sampleCategoryInteraction": MessageLookupByLibrary.simpleMessage("交互"),
    "sampleCategoryMain": MessageLookupByLibrary.simpleMessage("主图"),
    "sampleCategoryPro": MessageLookupByLibrary.simpleMessage("完整版"),
    "sampleCategoryStorage": MessageLookupByLibrary.simpleMessage("存取"),
    "sampleComputeDesc": MessageLookupByLibrary.simpleMessage(
      "大数据量走后台 isolate；指标抛错时回调，不影响其他指标。",
    ),
    "sampleComputeTitle": MessageLookupByLibrary.simpleMessage("计算与出错"),
    "sampleCrosshairDesc": MessageLookupByLibrary.simpleMessage(
      "吸附方式、提示卡开关和自定义提示卡。",
    ),
    "sampleCrosshairTitle": MessageLookupByLibrary.simpleMessage("十字线"),
    "sampleCustomSeriesDesc": MessageLookupByLibrary.simpleMessage(
      "实现 MainSeries.paint，不改库源码。",
    ),
    "sampleCustomSeriesTitle": MessageLookupByLibrary.simpleMessage("自定义主图画法"),
    "sampleDataLimitDesc": MessageLookupByLibrary.simpleMessage(
      "整段灌数据 setBars，容量上限 maxBars 超出时丢最老的。",
    ),
    "sampleDataLimitTitle": MessageLookupByLibrary.simpleMessage("数据量和上限"),
    "sampleDepthDesc": MessageLookupByLibrary.simpleMessage(
      "DepthChart 独立价格轴，可单用也可和 K 线并排。",
    ),
    "sampleDepthTitle": MessageLookupByLibrary.simpleMessage("深度图"),
    "sampleFormatDesc": MessageLookupByLibrary.simpleMessage(
      "价格小数位、时区、自定义时间格式、图表文案语言。",
    ),
    "sampleFormatTitle": MessageLookupByLibrary.simpleMessage("格式化"),
    "sampleFrameStatus": m16,
    "sampleGesturesDesc": MessageLookupByLibrary.simpleMessage(
      "纵向平移的作用区域，刻度条拖动缩放，点 K 线取价。",
    ),
    "sampleGesturesTitle": MessageLookupByLibrary.simpleMessage("手势"),
    "sampleGridDesc": MessageLookupByLibrary.simpleMessage("网格显示、虚线、线宽，刻度字号。"),
    "sampleGridTitle": MessageLookupByLibrary.simpleMessage("网格和文字"),
    "sampleHistoryDesc": MessageLookupByLibrary.simpleMessage(
      "滑到左边触发 onLoadMore，prependHistory 往前接数据，视口不跳。",
    ),
    "sampleHistoryTitle": MessageLookupByLibrary.simpleMessage("历史分页"),
    "sampleIndicatorParamDesc": MessageLookupByLibrary.simpleMessage(
      "改参数和颜色，指标立刻按新参数重算。",
    ),
    "sampleIndicatorParamTitle": m17,
    "sampleIndicatorsDesc": MessageLookupByLibrary.simpleMessage(
      "内置 8 个指标的组合。",
    ),
    "sampleIndicatorsTitle": MessageLookupByLibrary.simpleMessage("指标开关"),
    "sampleKeyboardDesc": MessageLookupByLibrary.simpleMessage(
      "方向键平移缩放，Home / End 跳到两头。",
    ),
    "sampleKeyboardTitle": MessageLookupByLibrary.simpleMessage("键盘"),
    "sampleLockRangeDesc": MessageLookupByLibrary.simpleMessage(
      "把主图值域钉在当前范围，平移和推送都不再自动缩放。",
    ),
    "sampleLockRangeTitle": MessageLookupByLibrary.simpleMessage("锁定坐标"),
    "sampleLockedDescription": MessageLookupByLibrary.simpleMessage("完整版功能"),
    "sampleOverlayDesc": MessageLookupByLibrary.simpleMessage(
      "overlayBuilder 用普通 Widget 画在图上，跟着平移缩放。",
    ),
    "sampleOverlayTitle": MessageLookupByLibrary.simpleMessage("自定义叠加层"),
    "samplePanelsDesc": MessageLookupByLibrary.simpleMessage(
      "主图 / 副图权重，拖动分隔条调高度。",
    ),
    "samplePanelsTitle": MessageLookupByLibrary.simpleMessage("面板高度"),
    "samplePriceDesc": MessageLookupByLibrary.simpleMessage(
      "最新价线和价签、收盘倒计时、盘口买卖价、标记价提示、价格动画、可见区最高最低价标签。",
    ),
    "samplePriceSearchTerms": MessageLookupByLibrary.simpleMessage(
      "倒计时 盘口 标记价",
    ),
    "samplePriceTitle": MessageLookupByLibrary.simpleMessage("价格线"),
    "sampleRealtimeDesc": MessageLookupByLibrary.simpleMessage(
      "applyTick 同时间戳改末根、新时间戳追加；autoFollow 贴着最新。",
    ),
    "sampleRealtimeTitle": MessageLookupByLibrary.simpleMessage("实时推送"),
    "sampleResetPage": MessageLookupByLibrary.simpleMessage("重置本页"),
    "sampleScaleDesc": MessageLookupByLibrary.simpleMessage("三种坐标模式可以叠加。"),
    "sampleScaleTitle": MessageLookupByLibrary.simpleMessage("对数 / 百分比 / 反转"),
    "sampleSecondaryAxisDesc": MessageLookupByLibrary.simpleMessage(
      "量纲不同的指标叠到主图上，用自己的值域。",
    ),
    "sampleSecondaryAxisTitle": MessageLookupByLibrary.simpleMessage("第二条值轴"),
    "sampleSeriesDesc": MessageLookupByLibrary.simpleMessage(
      "免费三种 seriesStyle，完整版再加 MainSeries 实例。",
    ),
    "sampleSeriesTitle": MessageLookupByLibrary.simpleMessage("主图画法"),
    "sampleStorageDesc": MessageLookupByLibrary.simpleMessage(
      "saveState / restoreState 与 KLineTheme.toJson / fromJson。",
    ),
    "sampleStorageTitle": MessageLookupByLibrary.simpleMessage("整体存取"),
    "sampleThemeDesc": MessageLookupByLibrary.simpleMessage("明暗底板、涨跌色、指标色板。"),
    "sampleThemeTitle": MessageLookupByLibrary.simpleMessage("主题"),
    "sampleTimeAxisDesc": MessageLookupByLibrary.simpleMessage(
      "刻度落在换年 / 换月 / 换日 / 整点边界上。",
    ),
    "sampleTimeAxisTitle": MessageLookupByLibrary.simpleMessage("分级时间轴"),
    "sampleWatermarkDesc": MessageLookupByLibrary.simpleMessage(
      "underlayBuilder 画在 K 线下面。",
    ),
    "sampleWatermarkTitle": MessageLookupByLibrary.simpleMessage("水印"),
    "scaleModeHint": MessageLookupByLibrary.simpleMessage(
      "对数坐标值域非正时自动回退线性；百分比只改刻度标签（以屏幕最左一根收盘为 0%）。",
    ),
    "scaleModeInvert": MessageLookupByLibrary.simpleMessage("反转坐标 invertScale"),
    "scaleModeInvertHint": MessageLookupByLibrary.simpleMessage(
      "反转只作用主图，小值在上，拖动价格轴的方向跟着反过来。",
    ),
    "scaleModeLog": MessageLookupByLibrary.simpleMessage("对数坐标 logScale"),
    "scaleModePercent": MessageLookupByLibrary.simpleMessage(
      "百分比坐标 percentScale",
    ),
    "secondaryAxisBoth": MessageLookupByLibrary.simpleMessage("两侧（第二轴占左侧刻度条）"),
    "secondaryAxisHint": MessageLookupByLibrary.simpleMessage(
      "第二条值轴有自己的值域，不挤压价格；十字线同时给出两个读数。",
    ),
    "secondaryAxisNone": MessageLookupByLibrary.simpleMessage("不叠加"),
    "secondaryAxisOverlay": MessageLookupByLibrary.simpleMessage("叠到第二条值轴"),
    "secondaryAxisPercent": MessageLookupByLibrary.simpleMessage(
      "第二轴用 % 格式 secondaryFormatter",
    ),
    "secondaryAxisRight": MessageLookupByLibrary.simpleMessage("右侧（第二轴标在左缘内侧）"),
    "seriesArea": MessageLookupByLibrary.simpleMessage("面积"),
    "seriesCandle": MessageLookupByLibrary.simpleMessage("蜡烛"),
    "seriesHint": MessageLookupByLibrary.simpleMessage(
      "画法只决定“怎么画”；砖形图、新价线这类要改数据本身的，在完整版的“数据转换”里。",
    ),
    "seriesLabel": MessageLookupByLibrary.simpleMessage("主图画法"),
    "seriesLine": MessageLookupByLibrary.simpleMessage("折线"),
    "seriesProSuffix": m18,
    "settingDarkMode": MessageLookupByLibrary.simpleMessage("深色"),
    "settingLightMode": MessageLookupByLibrary.simpleMessage("浅色"),
    "settingMenuSearchHint": MessageLookupByLibrary.simpleMessage("搜索功能或 API"),
    "settingPageTitle": MessageLookupByLibrary.simpleMessage("Klinex 配置大全"),
    "settingSampleNotFound": MessageLookupByLibrary.simpleMessage(
      "没有这个样例，请从菜单选择",
    ),
    "storageSampleHint": MessageLookupByLibrary.simpleMessage(
      "先保存，再缩放、拖分隔条、换指标或主题，最后从文本恢复。行情数据不在存档里。",
    ),
    "storageSampleIndicatorsNotList": MessageLookupByLibrary.simpleMessage(
      "chart.indicators 必须是列表",
    ),
    "storageSampleJsonHint": MessageLookupByLibrary.simpleMessage("存档 JSON"),
    "storageSampleNeedChartTheme": MessageLookupByLibrary.simpleMessage(
      "需要包含 chart 和 theme 对象",
    ),
    "storageSampleRestore": MessageLookupByLibrary.simpleMessage("从文本恢复"),
    "storageSampleRestoreFailed": m19,
    "storageSampleRestored": MessageLookupByLibrary.simpleMessage("已恢复。"),
    "storageSampleSaved": MessageLookupByLibrary.simpleMessage(
      "已保存：缩放、指标、锁定坐标、面板高度和主题。",
    ),
    "storageSampleSwapIndicators": MessageLookupByLibrary.simpleMessage(
      "换一组指标",
    ),
    "storageSampleSwitchTheme": MessageLookupByLibrary.simpleMessage("切换主题"),
    "themeSampleBase": MessageLookupByLibrary.simpleMessage("底板"),
    "themeSampleBaseFollow": MessageLookupByLibrary.simpleMessage("跟随应用明暗"),
    "themeSampleHint": MessageLookupByLibrary.simpleMessage(
      "KLineTheme 可 toJson / fromJson，copyWith 只改需要的字段。",
    ),
    "themeSamplePalette": MessageLookupByLibrary.simpleMessage("配色"),
    "themeSamplePaletteDefault": MessageLookupByLibrary.simpleMessage("默认"),
    "themeSamplePaletteOcean": MessageLookupByLibrary.simpleMessage("蓝涨橙跌"),
    "themeSamplePaletteWarm": MessageLookupByLibrary.simpleMessage("暖色指标线"),
    "themeSwitchToDark": MessageLookupByLibrary.simpleMessage("切换深色"),
    "themeSwitchToLight": MessageLookupByLibrary.simpleMessage("切换浅色"),
    "timeAxisSampleCustomTick": MessageLookupByLibrary.simpleMessage(
      "自定义刻度文字 tickFormatter",
    ),
    "timeAxisSampleHint": MessageLookupByLibrary.simpleMessage(
      "刻度和竖网格跟着图平移，换日、换月的刻度加粗；缩放时自动挑一档不挤的间隔。砖形图这类时间间隔不均匀的数据建议打开。",
    ),
    "timeAxisSampleMonthNames": MessageLookupByLibrary.simpleMessage(
      "1月,2月,3月,4月,5月,6月,7月,8月,9月,10月,11月,12月",
    ),
    "timeAxisSampleTickDay": m20,
    "timeAxisSampleTickYear": m21,
    "timeAxisSampleTiered": MessageLookupByLibrary.simpleMessage(
      "分级时间轴 tieredTimeAxis",
    ),
    "timeAxisSampleTimezone": MessageLookupByLibrary.simpleMessage(
      "时区 utcOffset",
    ),
    "watermarkSampleHint": MessageLookupByLibrary.simpleMessage(
      "underlayBuilder 拿到 RenderContext，可按主图矩形定位；它在 K 线下面，不挡手势。",
    ),
    "watermarkSampleShow": MessageLookupByLibrary.simpleMessage("显示水印"),
    "watermarkSampleSize": MessageLookupByLibrary.simpleMessage("字号"),
  };
}
