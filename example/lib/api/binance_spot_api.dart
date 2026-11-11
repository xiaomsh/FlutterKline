import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:klinex/klinex.dart';

import '../http/http_request.dart';
import '../model/data.dart';
import '../model/error.dart';
import 'api_base.dart';

/// Binance spot REST endpoints used by the K-line demo.
class BinanceSpotApi {
  static const String restBaseUrl = 'https://api.binance.com/api/v3';
  static const String wsUrl = 'wss://stream.binance.com:443/ws';

  static String toExchangeSymbol(String symbol) =>
      symbol.replaceAll(RegExp('[^A-Za-z0-9]'), '').toUpperCase();

  /// Test double: when non-null, [kline] uses it instead of sending a request.
  @visibleForTesting
  static Future<List<Bar>?> Function(String from, int? endTime)? debugKline;

  static Future<List<Bar>?> kline({
    required String from,
    required String symbol,
    required String interval,
    int? endTime,
    int limit = 500,
    CancelToken? cancelToken,
    void Function(ApiError error)? onError,
  }) {
    final fake = debugKline;
    if (fake != null) return fake(from, endTime);
    return safeCall(
      'binance.kline',
      () async {
        final params = <String, dynamic>{
          'symbol': toExchangeSymbol(symbol),
          'interval': interval,
          'limit': limit,
        };
        if (endTime != null) params['endTime'] = endTime;
        final response = await HttpUtils().request(
          '$restBaseUrl/klines',
          from: from,
          param: params,
          cancelToken: cancelToken,
        );
        return parseKlines(response.data);
      },
      onError: onError,
    );
  }

  static List<Bar> parseKlines(dynamic data) {
    if (data is! List) {
      throw const FormatException('Binance klines response is not a list');
    }
    final bars = <Bar>[];
    for (final row in data) {
      if (row is! List || row.length < 7) {
        throw const FormatException('Malformed Binance kline row');
      }
      bars.add(
        Bar(
          time: asInt(row[0]),
          open: asDouble(row[1]),
          high: asDouble(row[2]),
          low: asDouble(row[3]),
          close: asDouble(row[4]),
          vol: asDouble(row[5]),
        ),
      );
    }
    bars.sort((a, b) => a.time.compareTo(b.time));
    return bars;
  }
}
