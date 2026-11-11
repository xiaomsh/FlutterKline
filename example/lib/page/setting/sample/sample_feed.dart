import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:klinex/klinex.dart';

import 'sample_data.dart';

/// Feeds synthetic data to a controller: reset, push, load history, timed push, capacity limit.
/// With [transform] set (whole-series transforms such as Renko), every change recomputes the whole
/// series and calls setBars, keeping the viewport anchor and zoom.
class SampleFeed extends ChangeNotifier {
  SampleFeed(this.controller, {int initial = 600, this.transform}) {
    reset(initial);
  }

  final ChartController controller;

  /// Whole-series transform of the source; null feeds the source directly (incremental path).
  List<Bar> Function(List<Bar> source)? transform;

  /// Returning true pauses all data operations (e.g. during replay).
  bool Function()? blocked;

  /// Whether to stick to the latest bar after a whole-series transform (same as KChart.autoFollow).
  bool autoFollow = false;

  /// Source data (1 bar = 1 minute), read-only.
  final List<Bar> source = [];
  int? _maxBars;
  int pages = 0;
  int _tick = 0, _pushCount = 0;
  Timer? _timer;

  Duration? _every;
  int _barOpenedAt = DateTime.now().millisecondsSinceEpoch;

  int? get maxBars => _maxBars;
  bool get pushing => _timer != null;

  /// Real-time duration of one bar while auto-pushing (a bar is appended every 5 pushes), null when
  /// not pushing. Synthetic timestamps are not current, so the demo countdown follows this pace.
  Duration? get barDuration => _every == null ? null : _every! * 5;

  /// Real milliseconds elapsed since the last bar was appended.
  int get msSinceBarOpen => DateTime.now().millisecondsSinceEpoch - _barOpenedAt;
  bool get _blocked => blocked?.call() ?? false;

  void reset(int count) {
    if (_blocked) return;
    source
      ..clear()
      ..addAll(SampleData.bars(count));
    pages = 0;
    _tick = 0;
    _pushCount = 0;
    reload();
  }

  /// Rebuilds everything from the current source and transform.
  void reload() {
    _trim();
    controller
      ..maxBars = _maxBars
      ..setBars(transform?.call(source) ?? source);
    notifyListeners();
  }

  void setMaxBars(int? value) {
    if (_blocked) return;
    _maxBars = value;
    controller.maxBars = value;
    _trim();
    notifyListeners();
  }

  /// Appends a new bar when [append] is true, otherwise updates the last bar's price.
  void push({bool append = false}) {
    if (_blocked || source.isEmpty) return;
    _tick++;
    final Bar bar;
    if (append) {
      bar = SampleData.barAt(SampleData.indexOf(source.last) + 1);
      source.add(bar);
      _barOpenedAt = DateTime.now().millisecondsSinceEpoch;
    } else {
      final last = source.last;
      final close = last.close + math.sin(_tick * 1.1) * 0.5;
      bar = last.copyWith(
        high: close > last.high ? close : last.high,
        low: close < last.low ? close : last.low,
        close: close,
        vol: last.vol + 10,
      );
      source[source.length - 1] = bar;
    }
    if (transform == null) {
      controller.applyTick(bar);
    } else {
      _replace(transform!(source));
    }
    _trim();
    notifyListeners();
  }

  /// Loads [count] older bars; stops loading once [maxBars] is reached.
  void loadHistory([int count = 200]) {
    if (_blocked || source.isEmpty) return;
    if (_maxBars != null && source.length >= _maxBars!) return;
    final older = SampleData.generate(SampleData.indexOf(source.first) - count, count);
    source.insertAll(0, older);
    pages++;
    if (transform == null) {
      controller.prependHistory(older);
    } else {
      _replace(transform!(source));
    }
    _trim();
    notifyListeners();
  }

  /// Pushes every [every] (a bar is appended every 5 pushes); null stops.
  void autoPush(Duration? every) {
    _timer?.cancel();
    _every = every;
    // Restart the count of 5 so the countdown matches the next append
    _pushCount = 0;
    _barOpenedAt = DateTime.now().millisecondsSinceEpoch;
    _timer = every == null
        ? null
        : Timer.periodic(every, (_) => push(append: ++_pushCount % 5 == 0));
    notifyListeners();
  }

  void _trim() {
    if (_maxBars != null && source.length > _maxBars!) {
      source.removeRange(0, source.length - _maxBars!);
    }
  }

  void _replace(List<Bar> bars) {
    final vp = controller.viewport;
    final old = controller.bars;
    final anchor = old.isEmpty ? null : indexToTime(old, vp.rightIndex);
    final follow = autoFollow && vp.atLatest;
    final blank = vp.rightIndex - (old.length - 1);
    final barWidth = vp.barWidth, yScale = vp.yScale, yOffset = vp.yOffset;
    // setBars clears the crosshair (new dataset semantics); here it is only a recompute of the same
    // data, so the crosshair must not vanish on every push while the user is reading values
    final crosshair = controller.crosshair.value;
    controller.setBars(bars);
    if (crosshair != null && bars.isNotEmpty && crosshair.time >= bars.first.time) {
      controller.crosshair.value = crosshair;
    }
    vp.restoreScales(barWidth: barWidth, yScale: yScale, yOffset: yOffset);
    if (controller.bars.isNotEmpty && anchor != null) {
      vp.setRightIndex(
        follow ? controller.bars.length - 1 + blank : timeToIndex(controller.bars, anchor),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timer = null;
    super.dispose();
  }
}
