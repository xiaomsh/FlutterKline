import 'package:klinex/klinex.dart';

class BaseResult {
  int rc;
  String mc;
  dynamic result;

  BaseResult({
    required this.rc,
    required this.mc,
    required this.result,
  });

  factory BaseResult.fromJson(Map<String, dynamic> json) {
    return BaseResult(
      rc: json["rc"] ?? 0,
      mc: json["mc"] ?? "",
      result: json["result"],
    );
  }
}

double asDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}

int asInt(dynamic value) {
  if (value == null) return 0;
  if (value is double) return value.toInt();
  if (value is int) return value;
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

class LiveData {
  final String symbol;
  final int time;
  final double close, open, high, low, qty, vol;

  LiveData({
    required this.symbol,
    required this.time,
    required this.close,
    required this.open,
    required this.high,
    required this.low,
    required this.qty,
    required this.vol,
  });

  factory LiveData.fromBinanceKlineJson(Map<String, dynamic> json) {
    final kline = Map<String, dynamic>.from(json['k'] as Map);
    return LiveData(
      symbol: json['s'] as String,
      time: asInt(kline['t']),
      close: asDouble(kline['c']),
      open: asDouble(kline['o']),
      high: asDouble(kline['h']),
      low: asDouble(kline['l']),
      qty: asDouble(kline['v']),
      vol: asDouble(kline['q']),
    );
  }
}

extension LiveDataToBarExtension on LiveData {
  Bar toBar() {
    return Bar(
      time: time,
      open: open,
      high: [high, open, close].reduce((a, b) => a > b ? a : b),
      low: [low, open, close].reduce((a, b) => a < b ? a : b),
      close: close,
      vol: qty,
    );
  }
}

double _max3(double a, double b, double c) => a > b ? (a > c ? a : c) : (b > c ? b : c);

double _min3(double a, double b, double c) => a < b ? (a < c ? a : c) : (b < c ? b : c);

/// asDouble yields 0 for missing fields, and spot prices can't be <= 0: drop such bars entirely,
/// or one of them plunges straight to 0 on the chart.
bool hasPrices(Bar b) => b.open > 0 && b.high > 0 && b.low > 0 && b.close > 0;

/// Spike filter: a wick beyond [factor] times the reference (body extremes and the two
/// neighbors' extremes) is bad data and is clamped back; bars missing prices are dropped.
/// Otherwise one bad wick on an illiquid pair squashes all other bars.
List<Bar> sanitizeSpikes(List<Bar> raw, {double factor = 5.0}) {
  final bars = raw.every(hasPrices) ? raw : raw.where(hasPrices).toList();
  final out = List<Bar>.of(bars);
  for (var i = 0; i < out.length; i++) {
    final e = out[i];
    final bodyHigh = e.open > e.close ? e.open : e.close;
    final bodyLow = e.open < e.close ? e.open : e.close;
    // Neighbors always come from the raw bars, not out: out[i-1] may already be cleaned while
    // out[i+1] is still raw, and mixing them makes the result depend on iteration order.
    final prevHigh = i > 0 ? bars[i - 1].high : bodyHigh;
    final nextHigh = i < bars.length - 1 ? bars[i + 1].high : bodyHigh;
    final prevLow = i > 0 ? bars[i - 1].low : bodyLow;
    final nextLow = i < bars.length - 1 ? bars[i + 1].low : bodyLow;
    final refHigh = _max3(bodyHigh, prevHigh, nextHigh);
    final refLow = _min3(bodyLow, prevLow, nextLow);
    var high = e.high, low = e.low;
    if (refHigh > 0 && high > refHigh * factor) high = refHigh;
    if (low > 0 && refLow > 0 && low < refLow / factor) low = refLow;
    if (high != e.high || low != e.low) {
      out[i] = e.copyWith(high: high, low: low);
    }
  }
  return out;
}

/// Spike filter for a single live tick (reference = own body extremes + previous wick extremes).
Bar sanitizeTick(Bar bar, Bar? prev, {double factor = 5.0}) {
  final bodyHigh = bar.open > bar.close ? bar.open : bar.close;
  final bodyLow = bar.open < bar.close ? bar.open : bar.close;
  final refHigh = prev == null || prev.high < bodyHigh ? bodyHigh : prev.high;
  final refLow = prev == null || prev.low > bodyLow ? bodyLow : prev.low;
  var high = bar.high, low = bar.low;
  if (refHigh > 0 && high > refHigh * factor) high = refHigh;
  if (low > 0 && refLow > 0 && low < refLow / factor) low = refLow;
  if (high == bar.high && low == bar.low) return bar;
  return bar.copyWith(high: high, low: low);
}
