import 'package:flutter/widgets.dart';

import '../controller.dart';
import '../debug.dart';

/// Calls onLoadMore once when scrolled to the oldest edge. Fires only once per batch of data;
/// the next page is allowed after a prepend lands or the data set changes.
class LoadMoreTrigger {
  /// Already requested for "oldest bar = this timestamp"; -1 = not requested. Bar count can't
  /// be used: live appends while parked at the edge shift the count, re-requesting the same
  /// page repeatedly.
  int _firedFor = -1;
  int _epoch = -1;

  /// When the host returns synchronously (locally cached pages), prependHistory re-enters here
  /// synchronously; without this guard, the whole history would be paged recursively in one
  /// frame.
  bool _inside = false;

  /// Moving this many bars away from the oldest edge counts as leaving; coming back re-arms
  /// once (so a previous failure or empty result can be retried).
  static const double _releaseBars = 12;

  void check(ChartController controller, VoidCallback? onLoadMore) {
    if (onLoadMore == null || controller.loadMorePaused || _inside) return;
    if (_epoch != controller.dataEpoch) {
      _epoch = controller.dataEpoch;
      _firedFor = -1;
    }
    final bars = controller.bars;
    if (bars.isEmpty) return;
    final vp = controller.viewport;
    if (vp.leftIndex > 3) {
      if (vp.leftIndex > _releaseBars) _firedFor = -1;
      return;
    }
    final oldest = bars.first.time;
    if (_firedFor == oldest) return;
    _firedFor = oldest;
    _inside = true;
    if (KlinexDebug.logData) KlinexDebug.data('onLoadMore', 'oldest=$oldest');
    try {
      onLoadMore();
    } finally {
      _inside = false;
    }
  }
}
