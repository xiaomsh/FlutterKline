import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klinex_example/api/api_base.dart';
import 'package:klinex_example/api/binance_spot_api.dart';
import 'package:klinex_example/http/http_request.dart';
import 'package:klinex_example/l10n/l10n.dart';
import 'package:klinex_example/model/error.dart';

/// Answers every request with [respond]; records what was sent.
class FakeAdapter implements HttpClientAdapter {
  FakeAdapter(this.respond);

  final Future<ResponseBody> Function(RequestOptions options) respond;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    requests.add(options);
    return respond(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody jsonBody(Object data, {int status = 200}) => ResponseBody.fromString(
  jsonEncode(data),
  status,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  },
);

void main() {
  late FakeAdapter adapter;
  late HttpClientAdapter original;

  setUpAll(HttpUtils.init);

  setUp(() => original = HttpUtils().dio.httpClientAdapter);

  tearDown(() {
    HttpUtils().dio.httpClientAdapter = original;
    onApiError = null;
  });

  void serve(Future<ResponseBody> Function(RequestOptions options) respond) {
    adapter = FakeAdapter(respond);
    HttpUtils().dio.httpClientAdapter = adapter;
  }

  test('kline sends the exchange symbol and parses the rows', () async {
    serve(
      (_) async => jsonBody([
        [2000, '2', '3', '1', '2.5', '20', 2999],
        [1000, '1', '2', '0.5', '1.5', '10', 1999],
      ]),
    );
    final bars = await BinanceSpotApi.kline(
      from: 'test',
      symbol: 'btc_usdt',
      interval: '1m',
      endTime: 5000,
    );
    expect(bars!.map((b) => b.time), [1000, 2000]);
    final sent = adapter.requests.single;
    expect(sent.queryParameters, containsPair('symbol', 'BTCUSDT'));
    expect(sent.queryParameters, containsPair('endTime', 5000));
    expect(sent.extra['logFrom'], 'test');
    expect(sent.headers.containsKey(Headers.contentTypeHeader), isFalse);
  });

  test('a bad status becomes a server error with the HTTP code', () async {
    serve((_) async => jsonBody({'msg': 'nope'}, status: 503));
    final seen = <ApiError>[];
    onApiError = (path, e) => seen.add(e);
    ApiError? error;
    final bars = await BinanceSpotApi.kline(
      from: 'test',
      symbol: 'btc_usdt',
      interval: '1m',
      onError: (e) => error = e,
    );
    expect(bars, isNull);
    expect(error!.kind, ApiErrorType.server);
    expect(error!.code, 503);
    expect(error!.message, S.current.netServerError);
    expect(seen, hasLength(1));
  });

  test('transport failures map to network messages', () async {
    final cases = {
      DioExceptionType.connectionTimeout: S.current.netConnectTimeout,
      DioExceptionType.sendTimeout: S.current.netSendTimeout,
      DioExceptionType.receiveTimeout: S.current.netReceiveTimeout,
      DioExceptionType.connectionError: S.current.netConnectionFailed,
    };
    for (final MapEntry(key: type, value: message) in cases.entries) {
      serve((options) async => throw DioException(requestOptions: options, type: type));
      Object? thrown;
      try {
        await HttpUtils().request('https://x.test/a', from: 'test', headers: {'X-A': '1'});
      } catch (e) {
        thrown = e;
      }
      expect(thrown, isA<ApiError>().having((e) => e.message, 'message', message));
      expect((thrown as ApiError).kind, ApiErrorType.network);
      expect(adapter.requests.single.headers['X-A'], '1');
    }
  });

  test('cancellation is reported to onError only, not to the global hook', () async {
    serve(
      (options) async => throw DioException(
        requestOptions: options,
        type: DioExceptionType.cancel,
      ),
    );
    final seen = <ApiError>[];
    onApiError = (path, e) => seen.add(e);
    ApiError? error;
    await BinanceSpotApi.kline(
      from: 'test',
      symbol: 'btc_usdt',
      interval: '1m',
      onError: (e) => error = e,
    );
    expect(error!.cancelled, isTrue);
    expect(error!.message, S.current.netRequestCancelled);
    expect(seen, isEmpty);
  });

  test('malformed payloads become parse errors', () async {
    serve((_) async => jsonBody({'not': 'a list'}));
    ApiError? error;
    final bars = await BinanceSpotApi.kline(
      from: 'test',
      symbol: 'btc_usdt',
      interval: '1m',
      onError: (e) => error = e,
    );
    expect(bars, isNull);
    expect(error!.kind, ApiErrorType.parse);
    expect(error.toString(), contains('not a list'));
  });
}
