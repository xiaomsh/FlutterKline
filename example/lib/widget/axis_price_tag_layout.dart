import 'package:flutter/material.dart';

class PriceTagLayout {
  PriceTagLayout({
    required this.preferredCenter,
    required this.height,
    required this.price,
    required this.tieBreak,
    required this.builder,
  });

  final double preferredCenter;
  final double height;

  /// Price as printed on the tag (rounded by priceFormatter), used for sorting.
  final double price;

  /// Order for equal prices; smaller comes first.
  final int tieBreak;
  final Widget Function(double top) builder;
  double top = 0;
}

int byDisplayedPriceDesc(PriceTagLayout a, PriceTagLayout b) {
  final c = b.price.compareTo(a.price); // Higher price first = higher up.
  return c != 0 ? c : a.tieBreak.compareTo(b.tieBreak);
}

/// The price actually printed on the tag. Sort by it, not the raw double: the display value is
/// rounded, so raw sorting can show "80767.99 above 80768.00" in reverse order.
double displayPrice(double v, String Function(double) format) => double.tryParse(format(v)) ?? v;

/// When the panel is shorter than the tag the bounds invert and `clamp` throws ArgumentError;
/// fall back to pinning at the top.
double clampTop(double top, double height, double panelTop, double panelBottom) =>
    panelBottom - height <= panelTop ? panelTop : top.clamp(panelTop, panelBottom - height);

/// Non-overlapping stacking for a column of tags: push apart top-down, then pull back
/// bottom-up whatever overflows the bottom.
/// [items] must already be sorted top to bottom.
List<double> stackNonOverlapping({
  required List<({double center, double height})> items,
  required double top,
  required double bottom,
}) {
  final tops = List<double>.filled(items.length, 0);
  for (var i = 0; i < items.length; i++) {
    var t = clampTop(items[i].center - items[i].height / 2, items[i].height, top, bottom);
    if (i > 0) {
      final floor = tops[i - 1] + items[i - 1].height;
      if (t < floor) t = floor;
    }
    tops[i] = clampTop(t, items[i].height, top, bottom);
  }
  for (var i = items.length - 2; i >= 0; i--) {
    final maxTop = tops[i + 1] - items[i].height;
    if (tops[i] > maxTop) tops[i] = maxTop;
    tops[i] = clampTop(tops[i], items[i].height, top, bottom);
  }
  return tops;
}
