import 'dart:async';
import 'dart:convert';

import 'package:klinex/klinex.dart';
import 'package:klinex_example/api/binance_spot_api.dart';
import 'package:klinex_example/socket/binance_public_ws.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// In-memory WebSocket: tests push frames through [incoming] and read control frames from [sent].
class FakeWsChannel implements WebSocketChannel {
  final incoming = StreamController<dynamic>();
  late final FakeWsSink _sink = FakeWsSink(this);

  List<Map<String, dynamic>> get sent => _sink.sent;

  bool get closed => _sink.closed;

  @override
  Stream<dynamic> get stream => incoming.stream;

  @override
  WebSocketSink get sink => _sink;

  @override
  Future<void> get ready => Future.value();

  @override
  String? get protocol => null;

  @override
  int? get closeCode => null;

  @override
  String? get closeReason => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeWsSink implements WebSocketSink {
  FakeWsSink(this.channel);

  final FakeWsChannel channel;
  final List<Map<String, dynamic>> sent = [];
  bool closed = false;

  @override
  void add(dynamic data) => sent.add(Map<String, dynamic>.from(jsonDecode(data as String) as Map));

  @override
  void addError(Object error, [StackTrace? stackTrace]) {}

  @override
  Future<void> addStream(Stream<dynamic> stream) => stream.forEach(add);

  @override
  Future<void> close([int? closeCode, String? closeReason]) async {
    closed = true;
    if (!channel.incoming.isClosed) unawaited(channel.incoming.close());
  }

  @override
  Future<void> get done => Future.value();
}

/// Fake Binance: REST pages come from [bars], sockets are [FakeWsChannel]s.
class FakeMarket {
  FakeMarket({this.count = 120});

  static const minute = 60000;
  static const start = 1700000000000;

  final int count;
  final List<FakeWsChannel> channels = [];
  final List<String> requests = [];

  /// Next REST answers: null = failure, otherwise served as-is. Empty queue = the default page.
  final List<List<Bar>?> queued = [];

  FakeWsChannel get socket => channels.last;

  int get lastTime => start + (count - 1) * minute;

  List<Bar> bars({int? endTime}) {
    final end = endTime ?? lastTime;
    return [
      for (var i = count - 1; i >= 0; i--)
        if (end - i * minute >= start - 1000 * minute)
          Bar(
            time: end - i * minute,
            open: 100.0 + i % 7,
            high: 110.0 + i % 5,
            low: 90.0 + i % 3,
            close: 101.0 + i % 9,
            vol: 10.0 + i,
          ),
    ];
  }

  void install() {
    BinanceSpotApi.debugKline = (from, endTime) async {
      requests.add(from);
      if (queued.isNotEmpty) return queued.removeAt(0);
      return bars(endTime: endTime);
    };
    BinancePublicWs.debugConnect = (uri) {
      final channel = FakeWsChannel();
      channels.add(channel);
      return channel;
    };
  }

  static void uninstall() {
    BinanceSpotApi.debugKline = null;
    BinancePublicWs.debugConnect = null;
  }

  void pushKline({
    String symbol = 'BTCUSDT',
    String interval = '1m',
    required int time,
    double close = 105,
  }) {
    socket.incoming.add(
      jsonEncode({
        'e': 'kline',
        's': symbol,
        'k': {
          't': time,
          'i': interval,
          'o': '100',
          'h': '${close + 5}',
          'l': '95',
          'c': '$close',
          'v': '3',
          'q': '300',
        },
      }),
    );
  }

  void pushBook({String symbol = 'BTCUSDT', double bid = 104, double ask = 106}) {
    socket.incoming.add(jsonEncode({'u': 1, 's': symbol, 'b': '$bid', 'a': '$ask'}));
  }
}
