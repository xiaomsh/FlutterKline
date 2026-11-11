import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;

import '../l10n/l10n.dart';
import '../model/error.dart';
import 'header_interceptor.dart';

/// Dio wrapper.
class HttpUtils {
  late final Dio _dio;

  static HttpUtils? _instance;

  factory HttpUtils() {
    if (_instance == null) {
      throw Exception("HttpUtils must be initialized by calling HttpUtils.init() first.");
    }
    return _instance!;
  }

  HttpUtils._internal();

  /// Exposed so tests can swap the transport (`dio.httpClientAdapter`).
  @visibleForTesting
  Dio get dio => _dio;

  /// Synchronous and never throws. No response cache on purpose: when offline /kline must fail
  /// instead of passing off a stale page of candles as live, or the caller can't tell and the
  /// retry entry never appears.
  static void init() {
    if (_instance != null) return;

    final options = BaseOptions(
      receiveTimeout: const Duration(seconds: 60),
      connectTimeout: const Duration(seconds: 60),
      responseType: ResponseType.json,
    );

    final instance = HttpUtils._internal();
    instance._dio = Dio(options);
    instance._dio.interceptors.add(HeadersInterceptor());

    _instance = instance;
  }

  /// [from] = who issued the request. `path` in logs only says which endpoint was hit, not
  /// "who fired this one", which is exactly what duplicate or uncancelled requests need.
  Future<Response> request(
    String path, {
    required String from,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? param,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    Options requestOptions = options ?? Options();
    requestOptions.extra = {...?requestOptions.extra, 'logFrom': from};
    if (headers != null) {
      requestOptions.headers = {
        ...?requestOptions.headers,
        ...headers,
      };
    }
    try {
      return await _dio.get(
        path,
        queryParameters: param,
        options: requestOptions,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _toApiError(e);
    }
  }

  /// Converts a DioException into an ApiError to throw.
  ApiError _toApiError(DioException e) {
    if (e.type == DioExceptionType.cancel) {
      return ApiError(kind: ApiErrorType.cancelled, message: S.current.netRequestCancelled);
    }
    // A response with a bad status is `server`, and code is the real HTTP status;
    // everything else (timeout, unreachable, certificate) never reached the server: `network`,
    // code left empty.
    if (e.type == DioExceptionType.badResponse) {
      return ApiError(
        kind: ApiErrorType.server,
        message: S.current.netServerError,
        code: e.response?.statusCode,
      );
    }
    return ApiError(
      kind: ApiErrorType.network,
      message: switch (e.type) {
        DioExceptionType.connectionTimeout => S.current.netConnectTimeout,
        DioExceptionType.sendTimeout => S.current.netSendTimeout,
        DioExceptionType.receiveTimeout => S.current.netReceiveTimeout,
        _ => S.current.netConnectionFailed,
      },
    );
  }
}
