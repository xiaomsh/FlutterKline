import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:klinex/klinex.dart';

import '../http/http_request.dart';
import '../model/data.dart';
import '../model/error.dart';
import 'api_base.dart';

/// One trading day (or several) of minute points plus the quote header.
class IntradayData {
  const IntradayData({
    required this.name,
    required this.preClose,
    required this.decimals,
    required this.bars,
    double? firstPreClose,
  }) : firstPreClose = firstPreClose ?? preClose;

  final String name;
  final double preClose;

  /// Close before the first returned day: the percent base of multi-day charts. Equals
  /// [preClose] for one day.
  final double firstPreClose;
  final int decimals;

  /// Raw minute points, oldest first (not yet aligned to session slots).
  final List<Bar> bars;
}

/// Daily / weekly / monthly bars plus the stock name.
class KlineData {
  const KlineData({required this.name, required this.bars});

  final String name;
  final List<Bar> bars;
}

/// Eastmoney public quote endpoints (A-share, Hong Kong, US). Times are Beijing time; secid is
/// `<market>.<code>`, e.g. `1.600519`, `0.300750`, `116.00700`, `105.AAPL`.
class EastmoneyApi {
  static const String baseUrl = 'https://push2his.eastmoney.com/api/qt/stock';

  /// Test double: when non-null, requests return its result instead of hitting the network.
  @visibleForTesting
  static Future<dynamic> Function(String path, Map<String, dynamic> params)? debugGet;

  static Future<dynamic> _get(
    String path,
    Map<String, dynamic> params, {
    required String from,
    CancelToken? cancelToken,
  }) async {
    final fake = debugGet;
    if (fake != null) return fake(path, params);
    final response = await HttpUtils().request(
      '$baseUrl/$path',
      from: from,
      param: params,
      cancelToken: cancelToken,
    );
    return response.data;
  }

  /// Minute points of the last [days] trading days (1 = today, 5 = five-day chart).
  static Future<IntradayData?> trends(
    String secid, {
    required String from,
    int days = 1,
    CancelToken? cancelToken,
    void Function(ApiError error)? onError,
  }) => safeCall(
    'eastmoney.trends',
    () async => parseTrends(
      await _get(
        'trends2/get',
        {
          'secid': secid,
          'ndays': days,
          'iscr': 0,
          'fields1': 'f1,f2,f3,f4,f5,f6,f7,f8,f17',
          'fields2': 'f51,f52,f53,f54,f55,f56,f57,f58',
        },
        from: from,
        cancelToken: cancelToken,
      ),
    ),
    onError: onError,
  );

  /// Daily / weekly / monthly bars: [klt] 101 / 102 / 103; [fqt] 0 none, 1 forward adjusted,
  /// 2 backward adjusted.
  static Future<KlineData?> kline(
    String secid, {
    required String from,
    required int klt,
    int fqt = 0,
    int limit = 300,
    CancelToken? cancelToken,
    void Function(ApiError error)? onError,
  }) => safeCall(
    'eastmoney.kline',
    () async => parseKlines(
      await _get(
        'kline/get',
        {
          'secid': secid,
          'klt': klt,
          'fqt': fqt,
          'lmt': limit,
          'end': '20500101',
          'fields1': 'f1,f2,f3',
          'fields2': 'f51,f52,f53,f54,f55,f56,f57',
        },
        from: from,
        cancelToken: cancelToken,
      ),
    ),
    onError: onError,
  );

  static Map<String, dynamic> _data(dynamic body) {
    final json = body is String ? jsonDecode(body) : body;
    final data = json is Map ? json['data'] : null;
    if (data is! Map) throw const FormatException('Eastmoney response has no data');
    return data.cast<String, dynamic>();
  }

  /// `yyyy-MM-dd` or `yyyy-MM-dd HH:mm` in Beijing time to UTC milliseconds.
  static int parseBeijing(String s) {
    final t = DateTime.parse('${s.length == 10 ? '$s 00:00' : s}:00Z');
    return t.millisecondsSinceEpoch - const Duration(hours: 8).inMilliseconds;
  }

  static IntradayData parseTrends(dynamic body) {
    final data = _data(body);
    final rows = data['trends'];
    if (rows is! List) throw const FormatException('Eastmoney trends missing');
    final history = data['hisPrePrices'];
    final first = history is List && history.isNotEmpty && history.first is Map
        ? asDouble((history.first as Map)['prePrice'])
        : 0.0;
    return IntradayData(
      name: data['name']?.toString() ?? '',
      preClose: asDouble(data['preClose']),
      firstPreClose: first > 0 ? first : null,
      decimals: data['decimal'] is int ? data['decimal'] as int : 2,
      bars: _rows(rows),
    );
  }

  static KlineData parseKlines(dynamic body) {
    final data = _data(body);
    final rows = data['klines'];
    if (rows is! List) throw const FormatException('Eastmoney klines missing');
    return KlineData(
      name: data['name']?.toString() ?? '',
      bars: _rows(rows),
    );
  }

  /// Rows that fail to parse are skipped; a response without any valid row is an error.
  static List<Bar> _rows(List<dynamic> rows) {
    final bars = [
      for (final r in rows) ?_row(r.toString()),
    ];
    if (rows.isNotEmpty && bars.isEmpty) throw const FormatException('No valid Eastmoney rows');
    return bars;
  }

  /// trends: time, open, close, high, low, vol, amount, avg; klines: date, open, close, high,
  /// low, vol, amount. The opening auction print may report open 0.
  static Bar? _row(String row) {
    final f = row.split(',');
    if (f.length < 7) return null;
    final time = DateTime.tryParse(f[0].length == 10 ? '${f[0]} 00:00' : f[0]);
    final v = [for (var i = 1; i < 7; i++) double.tryParse(f[i])];
    if (time == null || v.contains(null)) return null;
    final [open!, close!, high!, low!, vol!, amount!] = v;
    return Bar(
      time: parseBeijing(f[0]),
      open: open > 0 ? open : close,
      close: close,
      high: high,
      low: low,
      vol: vol,
      amount: amount,
    );
  }
}
