import 'package:flutter/foundation.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:klinex/klinex.dart';

import '../widget/binance_live_feed.dart';

/// Mirrors [BinanceLiveFeed] loading / error / has-data into .obs.
/// Call [syncFeedState] from the feed listener.
mixin FeedStateMixin on GetxController {
  /// Initial load in progress (no data yet).
  final loading = false.obs;

  /// Load failed (no data yet).
  final hasError = false.obs;

  /// Whether K-line data is present.
  final hasBars = false.obs;

  void syncFeedState(BinanceLiveFeed feed, ChartController chart) {
    loading.value = feed.loading;
    hasError.value = feed.error != null;
    hasBars.value = chart.bars.isNotEmpty;
  }

  /// Routes the feed's one-shot notices to toasts. Call once in onInit after creating the feed;
  /// hand the returned disposer to onClose.
  VoidCallback bindFeedNotice(BinanceLiveFeed feed) {
    void show() {
      final msg = feed.notice.value;
      if (msg == null) return;
      SmartDialog.showToast(msg);
      feed.clearNotice(); // Consume it so a rebuild doesn't show it again.
    }

    feed.notice.addListener(show);
    return () => feed.notice.removeListener(show);
  }
}
