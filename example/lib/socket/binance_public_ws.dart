import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../api/binance_spot_api.dart';

typedef BinanceWsHandler = void Function(Map<String, dynamic> data);

/// Binance spot public market stream: replays subscriptions after reconnecting, with
/// exponential backoff up to 16 seconds.
class BinancePublicWs {
  BinancePublicWs._();

  static final BinancePublicWs instance = BinancePublicWs._();

  WebSocketChannel? _channel;
  bool _connecting = false;
  Timer? _pingTimer;
  Timer? _reconnectTimer;
  int _retry = 0;
  int _requestId = 0;
  DateTime _lastInbound = DateTime.now();

  static const _pingEvery = Duration(seconds: 15);
  static const _deadAfter = Duration(seconds: 45);

  final Map<String, List<BinanceWsHandler>> _handlers = {};
  final ValueNotifier<bool> connected = ValueNotifier(false);

  /// Test double: when non-null, [_connect] uses it instead of opening a real socket.
  @visibleForTesting
  static WebSocketChannel Function(Uri uri)? debugConnect;

  void subscribe(String stream, BinanceWsHandler handler, {required String from}) {
    final list = _handlers.putIfAbsent(stream, () => []);
    if (list.contains(handler)) return;
    final firstForStream = list.isEmpty;
    list.add(handler);
    debugPrint('[binance-ws] subscribe $stream <- $from (${list.length})');
    if (_channel == null) {
      // If a reconnect is scheduled, wait for it; otherwise every switch while offline
      // handshakes immediately and the backoff is useless.
      if (_reconnectTimer == null) _connect();
    } else if (firstForStream && connected.value) {
      _sendControl('SUBSCRIBE', [stream]);
    }
  }

  void unsubscribe(String stream, BinanceWsHandler handler) {
    final list = _handlers[stream];
    if (list == null) return;
    list.remove(handler);
    if (list.isEmpty) {
      _handlers.remove(stream);
      if (connected.value) _sendControl('UNSUBSCRIBE', [stream]);
      if (_handlers.isEmpty) _shutdown();
    }
  }

  void _shutdown() {
    _pingTimer?.cancel();
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _retry = 0;
    final channel = _channel;
    _channel = null;
    connected.value = false;
    channel?.sink.close();
  }

  Future<void> _connect() async {
    if (_connecting || _channel != null || _handlers.isEmpty) return;
    _connecting = true;
    WebSocketChannel? pending;
    try {
      final uri = Uri.parse(BinanceSpotApi.wsUrl);
      final channel = pending = (debugConnect ?? WebSocketChannel.connect)(uri);
      await channel.ready.timeout(const Duration(seconds: 15));
      // All subscriptions left during the handshake: keeping it is an idle socket plus heartbeat.
      if (_handlers.isEmpty) {
        channel.sink.close();
        return;
      }
      _channel = channel;
      pending = null;
      _lastInbound = DateTime.now();

      channel.stream.listen(
        (message) => _onMessage(message, channel),
        onError: (Object error) => _onDisconnected('error $error', from: channel),
        onDone: () => _onDisconnected('done', from: channel),
        cancelOnError: true,
      );

      _pingTimer?.cancel();
      _pingTimer = Timer.periodic(_pingEvery, (_) => _heartbeat());
      if (_handlers.isNotEmpty) {
        _sendControl('SUBSCRIBE', _handlers.keys.toList());
      }
      connected.value = true;
      debugPrint('[binance-ws] connected ${BinanceSpotApi.wsUrl}');
    } catch (error) {
      debugPrint('[binance-ws] connect failed: $error');
      // It may still connect after the handshake timeout: close it or it becomes an orphan.
      pending?.sink.close();
      _onDisconnected('connect failed');
    } finally {
      _connecting = false;
    }
  }

  void _onMessage(dynamic message, WebSocketChannel from) {
    if (!identical(from, _channel)) return;
    _lastInbound = DateTime.now();
    try {
      final decoded = jsonDecode(message as String);
      if (decoded is! Map) return;
      final envelope = Map<String, dynamic>.from(decoded);
      if (envelope['code'] != null) {
        debugPrint('[binance-ws] server error: ${envelope['code']} ${envelope['msg']}');
        return;
      }
      final payload = envelope['data'] is Map
          ? Map<String, dynamic>.from(envelope['data'] as Map)
          : envelope;
      final event = payload['e'];
      final symbol = payload['s'];
      if (symbol is! String) return;

      final String? stream;
      // bookTicker pushes have no `e` field; identify them by `u` (order book update id).
      if (event == null && payload['u'] != null && payload['b'] != null) {
        stream = '${symbol.toLowerCase()}@bookTicker';
      } else if (event == 'kline' && payload['k'] is Map) {
        final kline = Map<String, dynamic>.from(payload['k'] as Map);
        final interval = kline['i'];
        stream = interval is String ? '${symbol.toLowerCase()}@kline_$interval' : null;
      } else {
        return;
      }

      final handlers = stream == null ? null : _handlers[stream];
      if (handlers == null) return;
      // Only market data counts as connected: if the server closes us after a subscribe ack or
      // error frame, backoff must keep growing instead of reconnecting every second.
      _retry = 0;
      for (final handler in List<BinanceWsHandler>.of(handlers)) {
        try {
          handler(payload);
        } catch (error) {
          debugPrint('[binance-ws] $stream handler error: $error');
        }
      }
    } catch (error) {
      debugPrint('[binance-ws] message parse error: $error');
    }
  }

  void _onDisconnected(String reason, {WebSocketChannel? from}) {
    if (from != null && !identical(from, _channel)) return;
    if (_channel == null && !connected.value && _reconnectTimer != null) return;
    debugPrint('[binance-ws] disconnected: $reason');
    connected.value = false;
    _pingTimer?.cancel();
    _channel = null;
    if (_handlers.isEmpty) return;
    final delay = Duration(seconds: 1 << _retry.clamp(0, 4));
    _retry++;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () {
      // Clear on fire: if kept, the next failure is mistaken above for "reconnect pending" and
      // it never reconnects again.
      _reconnectTimer = null;
      _connect();
    });
  }

  void _heartbeat() {
    final channel = _channel;
    if (channel == null) return;
    if (DateTime.now().difference(_lastInbound) > _deadAfter) {
      _onDisconnected('heartbeat timeout', from: channel);
      channel.sink.close();
      return;
    }
    // Binance heartbeats use protocol ping frames; send a query too, to confirm the connection
    // is alive while the market is quiet.
    _sendControl('LIST_SUBSCRIPTIONS', const []);
  }

  void checkAlive() {
    if (_channel != null) {
      _heartbeat();
    } else if (_handlers.isNotEmpty && _reconnectTimer == null && !_connecting) {
      _connect();
    }
  }

  void _sendControl(String method, List<String> params) {
    _channel?.sink.add(
      jsonEncode({
        'method': method,
        'params': params,
        'id': ++_requestId,
      }),
    );
  }
}
