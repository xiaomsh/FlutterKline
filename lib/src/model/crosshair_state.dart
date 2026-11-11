import 'dart:ui';

/// The bar selected by the crosshair. Anchored by timestamp rather than index, so prepending
/// history or replacing bars doesn't shift it; get the current index via
/// `ChartController.crosshairIndex()`.
class CrosshairState {
  const CrosshairState({required this.time, required this.position, this.timeOnly = false});

  /// Timestamp of the selected bar (ms).
  final int time;

  /// Finger position within the chart.
  final Offset position;

  /// For a linked crosshair, only the vertical line (time) is meaningful.
  final bool timeOnly;
}
