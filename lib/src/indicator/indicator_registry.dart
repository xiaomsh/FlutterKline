import 'dart:ui';

import 'builtin/boll.dart';
import 'builtin/ema.dart';
import 'builtin/kdj.dart';
import 'builtin/ma.dart';
import 'builtin/macd.dart';
import 'builtin/rsi.dart';
import 'builtin/vol.dart';
import 'builtin/wr.dart';
import 'indicator.dart';
import 'secondary_axis.dart';

/// Serialization registry for indicator configs: maps kind to (fromParams factory, toParams
/// serializer). The host decides where to store it; the library only handles the JSON round
/// trip. Third-party indicators are added via [register]; unregistered kinds are skipped on
/// deserialization (older versions reading newer indicators don't crash).
class IndicatorRegistry {
  IndicatorRegistry._();

  static final Map<String, Indicator Function(Map<String, dynamic>)> _from = {
    'ma': (p) => Ma(periods: _ints(p['periods'], [7, 25, 99]), colors: _cs(p), lineWidth: _w(p)),
    'ema': (p) => Ema(periods: _ints(p['periods'], [12, 26]), colors: _cs(p), lineWidth: _w(p)),
    'boll': (p) =>
        Boll(period: _i(p['period'], 20), k: _d(p['k'], 2), colors: _cs(p), lineWidth: _w(p)),
    'vol-overlay': (p) =>
        VolOverlay(heightFraction: _d(p['heightFraction'], 0.2), opacity: _d(p['opacity'], 0.35)),
    'vol': (_) => Vol(),
    'mavol': (p) => MaVol(periods: _ints(p['periods'], [5, 10]), colors: _cs(p), lineWidth: _w(p)),
    'macd': (p) => Macd(
      short: _i(p['short'], 12),
      long: _i(p['long'], 26),
      signal: _i(p['signal'], 9),
      difColor: _c(p['difColor']),
      deaColor: _c(p['deaColor']),
      lineWidth: _w(p),
    ),
    'kdj': (p) => Kdj(
      n: _i(p['n'], 9),
      m1: _i(p['m1'], 3),
      m2: _i(p['m2'], 3),
      colors: _cs(p),
      lineWidth: _w(p),
    ),
    'rsi': (p) => Rsi(periods: _ints(p['periods'], [14]), colors: _cs(p), lineWidth: _w(p)),
    'wr': (p) => Wr(periods: _ints(p['periods'], [14]), colors: _cs(p), lineWidth: _w(p)),
  };

  static final Map<String, Map<String, dynamic> Function(Indicator)> _to = {
    'ma': (i) => _pcl((i as Ma).periods, i.colors, i.lineWidth),
    'ema': (i) => _pcl((i as Ema).periods, i.colors, i.lineWidth),
    'boll': (i) => {'period': (i as Boll).period, 'k': i.k, ..._cl(i.colors, i.lineWidth)},
    'vol-overlay': (i) => {
      'heightFraction': (i as VolOverlay).heightFraction,
      'opacity': i.opacity,
    },
    'vol': (_) => const {},
    'mavol': (i) => _pcl((i as MaVol).periods, i.colors, i.lineWidth),
    'macd': (i) => {
      'short': (i as Macd).short,
      'long': i.long,
      'signal': i.signal,
      if (i.difColor != null) 'difColor': i.difColor!.toARGB32(),
      if (i.deaColor != null) 'deaColor': i.deaColor!.toARGB32(),
      'lineWidth': i.lineWidth,
    },
    'kdj': (i) => {'n': (i as Kdj).n, 'm1': i.m1, 'm2': i.m2, ..._cl(i.colors, i.lineWidth)},
    'rsi': (i) => _pcl((i as Rsi).periods, i.colors, i.lineWidth),
    'wr': (i) => _pcl((i as Wr).periods, i.colors, i.lineWidth),
  };

  /// Registers serialization for a third-party indicator (kind matches [Indicator.kind]).
  static void register(
    String kind, {
    required Indicator Function(Map<String, dynamic> params) fromParams,
    required Map<String, dynamic> Function(Indicator indicator) toParams,
  }) {
    _from[kind] = fromParams;
    _to[kind] = toParams;
    _registered[kind] = fromParams;
  }

  /// Factories registered later. The background compute isolate has its own static table,
  /// so these are sent along with each job.
  static final Map<String, Indicator Function(Map<String, dynamic>)> _registered = {};

  static Map<String, Indicator Function(Map<String, dynamic>)> get registered => _registered;

  /// Installs, inside an isolate, the factories registered later on the main isolate
  /// (deserialization only).
  static void installFactories(Map<String, Indicator Function(Map<String, dynamic>)> factories) {
    _from.addAll(factories);
  }

  /// `{'kind': ..., ...params}`; throws [ArgumentError] for unregistered kinds (the host
  /// must [register] its own indicators before serializing them).
  static Map<String, dynamic> toJson(Indicator indicator) {
    if (indicator is SecondaryAxis) {
      return {'kind': indicator.kind, 'inner': toJson(indicator.inner)};
    }
    final to = _to[indicator.kind];
    if (to == null) {
      throw ArgumentError('unregistered indicator kind: ${indicator.kind}');
    }
    return {'kind': indicator.kind, ...to(indicator)};
  }

  /// Whether the kind is serializable (required for background computation across isolates).
  /// Returns false for unregistered custom indicators; callers fall back to synchronous
  /// computation on the main isolate.
  static bool isSerializable(String kind) => _to.containsKey(kind);

  /// Whether this indicator can be serialized; for [SecondaryAxis], checks the wrapped one.
  static bool canSerialize(Indicator indicator) =>
      indicator is SecondaryAxis ? canSerialize(indicator.inner) : isSerializable(indicator.kind);

  /// Deserializes one entry; returns null for unregistered kinds (forward compatible:
  /// silently skipped).
  static Indicator? fromJson(Map<String, dynamic> json) {
    if (json['kind'] == 'axis2') {
      final inner = json['inner'];
      final ind = inner is Map ? fromJson(inner.cast<String, dynamic>()) : null;
      return ind == null ? null : SecondaryAxis(ind);
    }
    final kind = json['kind'];
    return kind is String ? _from[kind]?.call(json) : null;
  }

  static List<Map<String, dynamic>> toJsonList(List<Indicator> indicators) => [
    for (final i in indicators) toJson(i),
  ];

  /// Skips broken entries (wrong type, out-of-range params) so one bad entry doesn't ruin the
  /// whole restore.
  static List<Indicator> fromJsonList(List<dynamic> json) {
    final out = <Indicator>[];
    for (final e in json) {
      if (e is! Map) continue;
      try {
        final ind = fromJson(e.cast<String, dynamic>());
        if (ind != null) out.add(ind);
      } catch (_) {}
    }
    return out;
  }
}

// ---- JSON helpers ----

List<int> _ints(dynamic v, List<int> def) =>
    v == null ? def : [for (final x in v as List) (x as num).toInt()];

int _i(dynamic v, int def) => (v as num?)?.toInt() ?? def;

double _d(dynamic v, double def) => (v as num?)?.toDouble() ?? def;

double _w(Map<String, dynamic> p, [double def = 1]) => _d(p['lineWidth'], def);

Color? _c(dynamic v) => v == null ? null : Color(v as int);

List<Color>? _cs(Map<String, dynamic> p) {
  final v = p['colors'];
  return v == null ? null : [for (final x in v as List) Color(x as int)];
}

Map<String, dynamic> _cl(List<Color>? colors, double lineWidth) => {
  if (colors != null) 'colors': [for (final c in colors) c.toARGB32()],
  'lineWidth': lineWidth,
};

Map<String, dynamic> _pcl(List<int> periods, List<Color>? colors, double lineWidth) => {
  'periods': periods,
  ..._cl(colors, lineWidth),
};
