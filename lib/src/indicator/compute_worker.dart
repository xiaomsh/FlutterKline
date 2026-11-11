import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show visibleForTesting;

import '../model/bar.dart';
import 'indicator.dart';
import 'indicator_registry.dart';

/// Slots per bar after packing: time, open, high, low, close, vol, amount (NaN when absent)
const int _stride = 7;

/// Packs bars into a compact [Float64List] (ms timestamps are far below 2^53, so doubles lose no
/// precision); only one buffer crosses the isolate boundary
Float64List packBars(List<Bar> bars) {
  final out = Float64List(bars.length * _stride);
  var j = 0;
  for (final b in bars) {
    out[j++] = b.time.toDouble();
    out[j++] = b.open;
    out[j++] = b.high;
    out[j++] = b.low;
    out[j++] = b.close;
    out[j++] = b.vol;
    out[j++] = b.amount ?? double.nan;
  }
  return out;
}

List<Bar> _unpackBars(Float64List d, int count) => [
  for (var i = 0, o = 0; i < count; i++, o += _stride)
    Bar(
      time: d[o].toInt(),
      open: d[o + 1],
      high: d[o + 2],
      low: d[o + 3],
      close: d[o + 4],
      vol: d[o + 5],
      amount: d[o + 6].isNaN ? null : d[o + 6],
    ),
];

/// Long-lived background isolate that runs [Indicator.computeAll] off the UI thread. Indicators
/// are sent as registry specs (kind + params) and rebuilt inside;
/// bars and results travel as [Float64List]; failures are thrown to the caller and the controller
/// falls back to sync computation, so correctness doesn't depend on the isolate
class IndicatorComputeWorker {
  Isolate? _isolate;
  SendPort? _tx;
  final ReceivePort _rx = ReceivePort();

  /// Two notification ports for unexpected isolate death. Must be separate from [_rx]: onError's
  /// `[error, stack]` has the same shape as a result `[jobId, series]` and would be taken as a
  /// result
  final ReceivePort _exit = ReceivePort();
  final ReceivePort _error = ReceivePort();

  Completer<void>? _ready;
  final Map<int, Completer<Map<String, Map<String, Float64List>>>> _pending = {};
  int _seq = 0;
  bool _disposed = false;
  bool _dead = false;

  Future<void> _ensureSpawned() {
    final existing = _ready;
    if (existing != null) return existing.future;
    final ready = _ready = Completer<void>();
    _rx.listen(_onMessage);
    _exit.listen((_) => _die('worker isolate exited'));
    _error.listen((_) => _die('worker isolate crashed'));
    Isolate.spawn(
          _workerMain,
          _rx.sendPort,
          onExit: _exit.sendPort,
          onError: _error.sendPort,
        )
        .then((iso) {
          _isolate = iso;
          if (_disposed) iso.kill(priority: Isolate.immediate);
        })
        .catchError((Object e, StackTrace s) {
          if (!ready.isCompleted) ready.completeError(e, s);
        });
    return ready.future;
  }

  /// The isolate is gone: fails all in-flight requests so the controller recomputes synchronously
  /// and falls back permanently; otherwise awaits hang forever and "computing" never clears
  void _die(String why) {
    if (_dead) return;
    _dead = true;
    final ready = _ready;
    if (ready != null && !ready.isCompleted) ready.completeError(StateError(why));
    for (final c in _pending.values) {
      if (!c.isCompleted) c.completeError(StateError(why));
    }
    _pending.clear();
  }

  /// Simulates an unexpected isolate exit: tests can't kill the isolate they spawned, so this
  /// takes the same onExit path
  @visibleForTesting
  void debugSimulateExit() => _die('worker isolate exited (simulated)');

  void _onMessage(dynamic msg) {
    if (msg is SendPort) {
      _tx = msg;
      final ready = _ready;
      if (ready != null && !ready.isCompleted) ready.complete();
      return;
    }
    if (msg is List && msg.length == 2) {
      final jobId = msg[0] as int;
      _pending.remove(jobId)?.complete(_castResults(msg[1]));
    }
  }

  static Map<String, Map<String, Float64List>> _castResults(dynamic raw) {
    final out = <String, Map<String, Float64List>>{};
    (raw as Map).forEach((k, v) {
      out[k as String] = (v as Map).cast<String, Float64List>();
    });
    return out;
  }

  /// Computes [specs] in the background; results are keyed by indicator id, then series key. [bars]
  /// are packed synchronously here (before any suspension), so the snapshot can't tear with
  /// concurrent edits
  Future<Map<String, Map<String, Float64List>>> compute(
    List<Bar> bars,
    List<Map<String, dynamic>> specs,
  ) async {
    if (_disposed) throw StateError('IndicatorComputeWorker disposed');
    if (_dead) throw StateError('IndicatorComputeWorker isolate is gone');
    final packed = packBars(bars);
    final count = bars.length;
    await _ensureSpawned();
    if (_disposed) throw StateError('IndicatorComputeWorker disposed');
    if (_dead) throw StateError('IndicatorComputeWorker isolate is gone');
    final jobId = ++_seq;
    final c = Completer<Map<String, Map<String, Float64List>>>();
    _pending[jobId] = c;
    _tx!.send([jobId, packed, count, specs, IndicatorRegistry.registered]);
    return c.future;
  }

  void dispose() {
    _disposed = true;
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
    _rx.close();
    _exit.close();
    _error.close();
    for (final c in _pending.values) {
      if (!c.isCompleted) c.completeError(StateError('IndicatorComputeWorker disposed'));
    }
    _pending.clear();
  }
}

void _workerMain(SendPort tx) {
  final rx = ReceivePort();
  tx.send(rx.sendPort);
  rx.listen((msg) {
    if (msg is! List || msg.length != 5) return;
    final jobId = msg[0] as int;
    // Replying matters above all: no exception may swallow the response, or the main isolate's
    // await hangs forever with computing stuck at true. The main side recomputes whatever is
    // missing.
    final out = <String, Map<String, Float64List>>{};
    try {
      final packed = msg[1] as Float64List;
      final count = msg[2] as int;
      final specsRaw = msg[3] as List;
      final factories = msg[4] as Map<String, Indicator Function(Map<String, dynamic>)>;
      IndicatorRegistry.installFactories(factories);
      final bars = _unpackBars(packed, count);
      for (final raw in specsRaw) {
        try {
          final spec = (raw as Map).cast<String, dynamic>();
          final ind = IndicatorRegistry.fromJson(spec);
          if (ind == null) continue;
          final store = IndicatorStore()..resize(bars.length);
          ind.computeAll(bars, store);
          out[ind.id] = store.exportSeries();
        } catch (_) {
          // One bad indicator (param deserialization / compute throws) doesn't drag down others
        }
      }
    } catch (_) {
      // Unpack failures etc.: reply with empty results; the main isolate recomputes each indicator
      // synchronously
    }
    tx.send([jobId, out]);
  });
}
