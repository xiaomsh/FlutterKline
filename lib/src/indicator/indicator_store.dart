import 'dart:math' as math;
import 'dart:typed_data';

import '../model/block_min_max.dart';
import '../model/min_max.dart';

/// One series: a grow-only buffer, a fixed-length view, and a block min/max cache.
class _Series {
  Float64List buf;
  Float64List view;
  final BlockMinMaxCache cache = BlockMinMaxCache();

  _Series(this.buf, this.view);
}

/// Data computed by one indicator: named output series plus stored hidden recurrence state, so
/// `Indicator.computeLast` can read i-1 and compute one exact step.
/// [series] returns fixed-length views: write by index only and fetch fresh each time (old views
/// are invalid after a resize).
class IndicatorStore {
  int _length = 0;
  final Map<String, _Series> _series = {};

  int get length => _length;

  /// Resizes every series to [n]; new tail slots are filled with NaN.
  void resize(int n) {
    if (n == _length) return;
    final old = _length;
    for (final s in _series.values) {
      if (n > s.buf.length) {
        var cap = s.buf.length < 8 ? 16 : s.buf.length * 2;
        while (cap < n) {
          cap *= 2;
        }
        s.buf = Float64List(cap)..setRange(0, old, s.buf);
      }
      if (n > old) s.buf.fillRange(old, n, double.nan);
      if (n < old) s.cache.invalidateFrom(n);
      s.view = Float64List.sublistView(s.buf, 0, n);
    }
    _length = n;
  }

  void clear() {
    _series.clear();
    _length = 0;
  }

  /// The series for [key], created and filled with NaN on first access.
  List<double> series(String key) => _seriesOf(key).view;

  _Series _seriesOf(String key) => _series.putIfAbsent(key, () {
    final buf = Float64List(math.max(_length, 16))..fillRange(0, _length, double.nan);
    return _Series(buf, Float64List.sublistView(buf, 0, _length));
  });

  /// Min/max of [key] over the range (inclusive), skipping NaN, using the block cache.
  MinMax rangeOf(String key, int start, int end) {
    final s = _series[key];
    if (s == null) return MinMax.empty;
    final v = s.view;
    final (double lo, double hi) = s.cache.minMax(start, end, v.length, (i) => v[i], (i) => v[i]);
    return lo > hi ? MinMax.empty : MinMax(lo, hi);
  }

  /// Invalidates the block cache from [index] on; call after writing.
  void invalidateFrom(int index) {
    for (final s in _series.values) {
      s.cache.invalidateFrom(index);
    }
  }

  /// Frees the block caches of all series (call under memory pressure); values are unaffected.
  void releaseCaches() {
    for (final s in _series.values) {
      s.cache.release();
    }
  }

  /// After prepending [k] bars, shifts computed values right by [k] slots and fills the first [k]
  /// with NaN for recomputation (the copy half of incremental prepend recompute, see
  /// `Indicator.prependSettleBars`).
  void shiftRight(int k) {
    if (k <= 0) return;
    final old = _length;
    resize(old + k); // Pad the tail with NaN and grow as needed
    for (final s in _series.values) {
      final v = s.view;
      v.setRange(k, old + k, v); // Typed data setRange handles overlapping ranges correctly
      v.fillRange(0, k, double.nan);
      s.cache.invalidateFrom(0);
    }
  }

  /// After trimming [k] bars from the oldest end, shifts computed values left by [k] slots
  /// (recurrence state is kept, so incremental computing continues as usual).
  void dropFront(int k) {
    if (k <= 0) return;
    final n = math.max(0, _length - k);
    for (final s in _series.values) {
      if (n > 0) s.buf.setRange(0, n, s.buf, k);
      s.view = Float64List.sublistView(s.buf, 0, n);
      s.cache.invalidateFrom(0);
    }
    _length = n;
  }

  /// Safety valve for incremental prepend recompute: matches only if [src] and this store agree on
  /// [from, to) (NaN counts as equal; all-NaN does not count). On mismatch the caller falls back to
  /// a full recompute, so a wrong settle-length guess only costs CPU, never correctness.
  bool matchesRange(IndicatorStore src, int from, int to) {
    var compared = 0;
    for (final e in src._series.entries) {
      final mine = _series[e.key];
      if (mine == null) return false;
      final a = mine.view, b = e.value.view;
      if (to > a.length || to > b.length) return false;
      for (var i = from; i < to; i++) {
        final x = a[i], y = b[i];
        if (x.isNaN && y.isNaN) continue;
        if (x.isNaN != y.isNaN) return false;
        if ((x - y).abs() > math.max(1e-9, x.abs() * 1e-9)) return false;
        compared++;
      }
    }
    return compared > 0;
  }

  /// Copies the first [count] slots of [src] into this store (including hidden recurrence series).
  /// Pairs with [shiftRight]: the prefix is filled from the sub-range recompute, the suffix keeps
  /// the shifted old values.
  void copyPrefixFrom(IndicatorStore src, int count) {
    for (final e in src._series.entries) {
      final dst = _seriesOf(e.key).view;
      final s = e.value.view;
      final m = math.min(count, math.min(dst.length, s.length));
      dst.setRange(0, m, s);
    }
    invalidateFrom(0);
  }

  /// Exports all series (including hidden recurrence state) as standalone compact buffers for
  /// passing back across isolates;
  /// each has length [length] and shares no internal buffer.
  Map<String, Float64List> exportSeries() => {
    for (final e in _series.entries) e.key: Float64List.fromList(e.value.view),
  };

  /// Takes over this store wholesale with series computed in a background isolate (including hidden
  /// recurrence state) and sets the length to [length]. `Indicator.computeLast` can then continue
  /// incrementally from the state at [length]-1.
  void adoptSeries(int length, Map<String, Float64List> series) {
    _series.clear();
    _length = length;
    for (final e in series.entries) {
      var buf = e.value;
      if (buf.length < length) {
        buf = Float64List(length)
          ..setRange(0, e.value.length, e.value)
          ..fillRange(e.value.length, length, double.nan);
      }
      _series[e.key] = _Series(buf, Float64List.sublistView(buf, 0, length));
    }
  }

  double value(String key, int index) {
    final s = _series[key];
    if (s == null || index < 0 || index >= s.view.length) return double.nan;
    return s.view[index];
  }

  /// Values of all series at bar [index], for the tooltip card and snapshots.
  Map<String, double> valuesAt(int index) => {
    for (final e in _series.entries)
      if (index >= 0 && index < e.value.view.length) e.key: e.value.view[index],
  };
}

/// Period-like parameters must be positive integers, otherwise window computation divides by zero,
/// goes out of bounds, or yields NaN; reject them in the constructor rather than letting bad
/// parameters reach the compute loop.
