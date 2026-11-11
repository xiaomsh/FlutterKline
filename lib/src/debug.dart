import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

/// Diagnostic log switches, all off by default; when off each probe is just a bool check. To
/// investigate, enable what you need before runApp, e.g. `KlinexDebug.enableAll()`;
/// gesture arena / repaint channel / paint timing logs share one timeline and read interleaved
class KlinexDebug {
  KlinexDebug._();

  /// Compile-time master switch: always false in release, so every `if (KlinexDebug.logX)` and its
  /// string building are tree-shaken.
  /// To fully disable in debug / profile: `--dart-define=KLINEX_NO_LOG=true`
  static const bool available = !kReleaseMode && !bool.fromEnvironment('KLINEX_NO_LOG');

  static bool _logPaint = false;
  static bool _logChannel = false;
  static bool _logGesture = false;
  static bool _logRebuild = false;
  static bool _logData = false;

  /// Repaint + timing of each canvas layer.
  static bool get logPaint => available && _logPaint;
  static set logPaint(bool v) => _logPaint = v;

  /// Every notification on a repaint channel (viewport / crosshair / drawings / ...).
  static bool get logChannel => available && _logChannel;
  static set logChannel(bool v) => _logChannel = v;

  /// Gesture arena and callbacks: recognizer entry checks, accept/reject, pan/scale/long-press
  /// callbacks.
  static bool get logGesture => available && _logGesture;
  static set logGesture(bool v) => _logGesture = v;

  /// Widget-layer rebuilds (build / underlayBuilder / overlayBuilder / tooltip).
  static bool get logRebuild => available && _logRebuild;
  static set logRebuild(bool v) => _logRebuild = v;

  /// Data mutation entry points and _bump sources (see [data]).
  static bool get logData => available && _logData;
  static set logData(bool v) => _logData = v;

  static void enableAll() {
    logPaint = true;
    logChannel = true;
    logGesture = true;
    logRebuild = true;
    logData = true;
  }

  static void disableAll() {
    logPaint = false;
    logChannel = false;
    logGesture = false;
    logRebuild = false;
    logData = false;
  }

  static bool get anyEnabled =>
      available && (_logPaint || _logChannel || _logGesture || _logRebuild || _logData);

  /// Output sink. Defaults to [debugPrint] (throttled; order preserved but may be delayed); for raw
  /// timing use `print`.
  static void Function(String line) sink = debugPrint;

  static final Stopwatch _clock = Stopwatch()..start();

  /// Cumulative count per probe; use with [mark] / [dumpCounters] to count "how many repaints this
  /// action caused".
  static final Map<String, int> counters = <String, int>{};

  /// Cumulative time per paint layer (µs).
  static final Map<String, int> micros = <String, int>{};

  static int _frame = 0;
  static bool _frameHooked = false;

  /// Counts frames itself. Can't read SchedulerBinding.currentFrameTimeStamp, which asserts and
  /// throws outside a frame
  /// (pointer events are dispatched outside frames).
  static void _ensureFrameHook() {
    if (_frameHooked) return;
    _frameHooked = true;
    try {
      SchedulerBinding.instance.addPersistentFrameCallback((_) => _frame++);
    } catch (_) {
      // Without a binding (pure Dart tests) frames aren't counted, but logs still print.
    }
  }

  static String _frameTag() {
    _ensureFrameHook();
    return _frame.toString().padLeft(5);
  }

  static void _emit(String tag, String detail) {
    sink(
      '[klx ${(_clock.elapsedMicroseconds / 1000).toStringAsFixed(1).padLeft(9)}ms '
      'f=${_frameTag()}] ${tag.padRight(5)} $detail',
    );
  }

  static void _count(String key) => counters[key] = (counters[key] ?? 0) + 1;

  // ---- Probes ----

  /// A canvas layer finished painting: [layer] layer name, [us] duration.
  static void paint(String layer, int us) {
    _count('PAINT $layer');
    micros[layer] = (micros[layer] ?? 0) + us;
    _emit('PAINT', '${layer.padRight(22)} ${(us / 1000).toStringAsFixed(2)}ms');
  }

  /// A repaint channel fired.
  static void channel(String name, [String detail = '']) {
    _count('CHAN $name');
    _emit('CHAN', '${name.padRight(22)} $detail');
  }

  /// Gesture arena event: recognizer entry/yield/accept/reject.
  static void arena(String who, String what) {
    _count('ARENA $who.$what');
    _emit('ARENA', '${who.padRight(22)} $what');
  }

  /// Gesture callback.
  static void gesture(String what, [String detail = '']) {
    _count('GEST $what');
    _emit('GEST', '${what.padRight(22)} $detail');
  }

  /// Data mutation entry points (setBars / applyTick / appendBar / updateLast / replaceAt /
  /// prependHistory) and the source of every _bump. Use this to find
  /// "who mutates data every frame".
  static void data(String op, [String detail = '']) {
    _count('DATA $op');
    _emit('DATA', '${op.padRight(22)} $detail');
  }

  /// Widget rebuild.
  static void rebuild(String what, [String detail = '']) {
    _count('BUILD $what');
    _emit('BUILD', '${what.padRight(22)} $detail');
  }

  /// Manual separator: log one before each action so logs can be split per action.
  /// If [reset] is true, also clears counters to measure this segment alone. No-op when all off.
  static void mark(String label, {bool reset = true}) {
    if (!anyEnabled) return;
    if (reset) {
      counters.clear();
      micros.clear();
    }
    sink('[klx ======== $label ========]');
  }

  /// Prints cumulative counts/durations since the last [mark], most first.
  static void dumpCounters() {
    if (!anyEnabled) return;
    final keys = counters.keys.toList()..sort((a, b) => counters[b]!.compareTo(counters[a]!));
    sink('[klx -------- totals --------]');
    for (final k in keys) {
      final layer = k.startsWith('PAINT ') ? k.substring(6) : null;
      final us = layer == null ? null : micros[layer];
      sink(
        '[klx] ${counters[k].toString().padLeft(5)}x  $k'
        '${us == null ? '' : '   ${(us / 1000).toStringAsFixed(1)}ms total'}',
      );
    }
  }
}
