import 'dart:math' as math;

import 'package:klinex/klinex.dart';

/// Deterministic offline synthetic market data: the same index always yields the same bar, so
/// history loading and pushes are reproducible.
class SampleData {
  static const epoch = 1700000000000;
  static const interval = 60000;

  /// The bar at index [i] (may be negative, i.e. history before epoch).
  static Bar barAt(int i) {
    final open = 100 + 8 * math.sin(i / 31) + 3 * math.cos(i / 9);
    final close = open + 1.4 * math.sin(i * 1.7);
    return Bar(
      time: epoch + i * interval,
      open: open,
      high: math.max(open, close) + 0.8,
      low: math.min(open, close) - 0.8,
      close: close,
      vol: 500 + 300 * (1 + math.sin(i / 7)),
    );
  }

  /// [count] bars starting at index [start].
  static List<Bar> generate(int start, int count) => [
    for (var i = start; i < start + count; i++) barAt(i),
  ];

  /// [count] bars starting at index 0.
  static List<Bar> bars([int count = 600]) => generate(0, count);

  static int indexOf(Bar bar) => (bar.time - epoch) ~/ interval;
}
