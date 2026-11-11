import 'package:flutter/foundation.dart';

import 'bar.dart';
import 'block_min_max.dart';
import 'min_max.dart';

/// The kind of the latest change; layer caches can skip changes outside the visible range.
enum DataChange { none, setAll, append, updateLast, prepend, replace, trimFront }

/// Bar container with input validation: non-finite values and ordering violations are dropped;
/// high/low that don't enclose open/close are clamped. [bars] is exposed without copying and
/// is read-only.
class DataSource {
  final List<Bar> _bars = [];

  /// Incremented on every change; used as a cache key (controller notifications are coalesced
  /// per frame and may lag).
  int _mutations = 0;

  int get mutations => _mutations;

  DataChange _lastChange = DataChange.none;

  DataChange get lastChange => _lastChange;

  int _lastChangeIndex = -1;

  int get lastChangeIndex => _lastChangeIndex;

  /// Read-only. Not wrapped in UnmodifiableListView because every indicator reads `bars[i]` for
  /// every bar, and the indirection adds up over 10k*27 reads. Mutating it externally bypasses
  /// ordering sanitization and block cache invalidation, silently producing wrong results.
  List<Bar> get bars => _bars;

  int get length => _bars.length;

  bool get isEmpty => _bars.isEmpty;

  /// Replaces everything (symbol/interval switch). Input is sanitized by [_sanitize] first.
  void setAll(List<Bar> value) {
    // Copy first if passed [bars] itself: otherwise clear then addAll would add back an empty
    // list.
    final src = _sanitize(identical(value, _bars) ? List.of(value) : value, 'setAll');
    _bars
      ..clear()
      ..addAll(src);
    _mutated(DataChange.setAll, 0);
  }

  /// Appends a newer bar; dropped if time doesn't increase (ordering is the shared premise of
  /// binary search, time mapping and block caches). Prints a warning in debug; behavior matches
  /// release. Returns whether it was appended.
  bool append(Bar bar) {
    if (_bars.isNotEmpty && bar.time <= _bars.last.time) {
      assert(_warn('append dropped: bar.time must be > last.time'));
      return false;
    }
    if (!_finite(bar)) {
      assert(_warn('append dropped: contains NaN/Inf'));
      return false;
    }
    if (!_ohlcValid(bar)) assert(_warn('append fixed: bad high/low or vol < 0'));
    _bars.add(_fixOhlc(bar));
    _mutated(DataChange.append, _bars.length - 1);
    return true;
  }

  /// Overwrites the last bar; dropped if the time doesn't match. Returns whether it was updated.
  bool updateLast(Bar bar) {
    if (_bars.isEmpty || bar.time != _bars.last.time) {
      assert(_warn('updateLast dropped: bar.time must be == last.time'));
      return false;
    }
    if (!_finite(bar)) {
      assert(_warn('updateLast dropped: contains NaN/Inf'));
      return false;
    }
    if (!_ohlcValid(bar)) assert(_warn('updateLast fixed: bad high/low or vol < 0'));
    _bars[_bars.length - 1] = _fixOhlc(bar);
    _mutated(DataChange.updateLast, _bars.length - 1);
    return true;
  }

  /// Prepends history, trimming any tail that overlaps existing data (paged APIs often include
  /// the boundary bar). Returns the number of bars actually inserted. [limit] caps how many are
  /// inserted; the oldest extras are dropped.
  int prepend(List<Bar> older, {int? limit}) {
    if (limit != null && limit <= 0) return 0;
    if (older.isEmpty) return 0;
    var list = _sanitize(older, 'prepend');
    if (list.isEmpty) return 0;
    if (_bars.isNotEmpty) {
      final firstTime = _bars.first.time;
      var n = list.length;
      while (n > 0 && list[n - 1].time >= firstTime) {
        n--;
      }
      if (n == 0) return 0;
      if (n < list.length) list = list.sublist(0, n);
    }
    if (limit != null && list.length > limit) list = list.sublist(list.length - limit);
    _bars.insertAll(0, list);
    _mutated(DataChange.prepend, 0);
    return list.length;
  }

  /// Removes [count] bars from the oldest end; returns the number actually removed.
  int trimFront(int count) {
    final k = count.clamp(0, _bars.length);
    if (k == 0) return 0;
    _bars.removeRange(0, k);
    _mutated(DataChange.trimFront, 0);
    return k;
  }

  /// Replaces one bar in place (time must match); dropped if out of range or time mismatches.
  /// Returns whether it was replaced.
  bool replaceAt(int index, Bar bar) {
    if (index < 0 || index >= _bars.length || _bars[index].time != bar.time) {
      assert(_warn('replaceAt dropped: index out of range or time mismatch'));
      return false;
    }
    if (!_finite(bar)) {
      assert(_warn('replaceAt dropped: contains NaN/Inf'));
      return false;
    }
    if (!_ohlcValid(bar)) assert(_warn('replaceAt fixed: bad high/low or vol < 0'));
    _bars[index] = _fixOhlc(bar);
    _mutated(DataChange.replace, index);
    return true;
  }

  /// Min/max of high/low (or close only) over the visible range via the block cache,
  /// O(range/64 + 128); computed on every pan frame.
  MinMax rangeOf(int start, int end, {bool closeOnly = false}) {
    final (double lo, double hi) = closeOnly
        ? _closeCache.minMax(start, end, _bars.length, (i) => _bars[i].close, (i) => _bars[i].close)
        : _hlCache.minMax(start, end, _bars.length, (i) => _bars[i].low, (i) => _bars[i].high);
    return lo > hi ? MinMax.empty : MinMax(lo, hi);
  }

  /// Binary search by timestamp; returns -1 if not found.
  int indexOfTime(int time) {
    var lo = 0, hi = _bars.length - 1;
    while (lo <= hi) {
      final mid = (lo + hi) >> 1;
      final t = _bars[mid].time;
      if (t == time) return mid;
      if (t < time) {
        lo = mid + 1;
      } else {
        hi = mid - 1;
      }
    }
    return -1;
  }

  /// Prints the drop reason to the console in debug (called inside assert, stripped in
  /// release).
  static bool _warn(String message) {
    debugPrint('klinex DataSource: $message');
    return true;
  }

  /// NaN/±Inf check, also active in release: bad values are irreversible once stored (one NaN
  /// breaks the whole visible min/max), so they're blocked at the entry.
  static bool _finite(Bar b) =>
      b.open.isFinite && b.high.isFinite && b.low.isFinite && b.close.isFinite && b.vol.isFinite;

  /// high/low must enclose open/close and volume must be non-negative, also in release
  /// (otherwise candles/wicks flip, volume bars invert, and indicators produce invalid values).
  static bool _ohlcValid(Bar b) =>
      b.high >= b.open && b.high >= b.close && b.low <= b.open && b.low <= b.close && b.vol >= 0;

  /// Clamps high/low to the smallest range enclosing open/close instead of dropping the bar;
  /// like [_finite] and ordering sanitization, debug and release behave the same.
  static Bar _fixOhlc(Bar b) {
    var h = b.high, l = b.low;
    if (b.open > h) h = b.open;
    if (b.close > h) h = b.close;
    if (b.open < l) l = b.open;
    if (b.close < l) l = b.close;
    // Clamp negative volume to 0; prices remain usable, so keep the bar.
    final v = b.vol < 0 ? 0.0 : b.vol;
    return h == b.high && l == b.low && v == b.vol ? b : b.copyWith(high: h, low: l, vol: v);
  }

  /// Sanitizes batch input: removes NaN/Inf, fixes high/low, sorts, and keeps the last bar per
  /// timestamp. A first pass checks if it's already clean, so normal data costs one scan and
  /// zero allocations.
  static List<Bar> _sanitize(List<Bar> src, String where) {
    var clean = true;
    for (var i = 0; i < src.length; i++) {
      if (!_finite(src[i]) || !_ohlcValid(src[i]) || (i > 0 && src[i].time <= src[i - 1].time)) {
        clean = false;
        break;
      }
    }
    if (clean) return src;

    assert(_warn('$where invalid input (NaN/Inf, high<low, vol<0, unsorted time), sanitized'));
    final ok = [
      for (final b in src)
        if (_finite(b)) _fixOhlc(b),
    ];
    // List.sort isn't stable; equal timestamps must keep input order so the last one is kept.
    final order = List<int>.generate(ok.length, (i) => i)
      ..sort((a, b) {
        final c = ok[a].time.compareTo(ok[b].time);
        return c != 0 ? c : a.compareTo(b);
      });
    final out = <Bar>[];
    for (final i in order) {
      final b = ok[i];
      // For the same timestamp the last bar wins (typical of duplicate pushes/boundary bars).
      if (out.isNotEmpty && out.last.time == b.time) {
        out[out.length - 1] = b;
      } else {
        out.add(b);
      }
    }
    return out;
  }

  final BlockMinMaxCache _hlCache = BlockMinMaxCache();
  final BlockMinMaxCache _closeCache = BlockMinMaxCache();

  /// Releases the range block caches (call under memory pressure); rebuilt on demand on the
  /// next query.
  void releaseCaches() {
    _hlCache.release();
    _closeCache.release();
  }

  void _mutated(DataChange change, int index) {
    _mutations++;
    _lastChange = change;
    _lastChangeIndex = index;
    switch (change) {
      case DataChange.append:
        break; // The new tail lies after all built blocks
      case DataChange.updateLast:
      case DataChange.replace:
        _hlCache.invalidateFrom(index);
        _closeCache.invalidateFrom(index);
      case DataChange.setAll:
      case DataChange.prepend:
      case DataChange.trimFront:
      case DataChange.none:
        _hlCache.invalidateAll();
        _closeCache.invalidateAll();
    }
  }

  // Debug asserts are kept only for contracts that can be neither dropped nor recovered;
  // droppable violations are actually dropped above, avoiding split semantics of throwing in
  // debug vs silently dropping in release.
}
