import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import '../controller.dart';
import '../overlay/overlay_plugin.dart';
import '../render/context.dart';

/// A horizontal price line on the main panel (previous close, limit up / down, cost price).
@immutable
class PriceLevel {
  const PriceLevel(
    this.price, {
    required this.color,
    this.label,
    this.dashed = true,
    this.width = 0.8,
  });

  final double price;
  final Color color;

  /// Drawn at the plot's left edge above the line; null draws the line only.
  final String? label;
  final bool dashed;
  final double width;

  @override
  bool operator ==(Object other) =>
      other is PriceLevel &&
      other.price == price &&
      other.color == color &&
      other.label == label &&
      other.dashed == dashed &&
      other.width == width;

  @override
  int get hashCode => Object.hash(price, color, label, dashed, width);
}

/// Draws [levels] across the main panel; levels outside the current range are skipped. To make
/// sure they are in range, add them through `KChart.mainRange` (see `StockRange`).
class PriceLevelsOverlay extends OverlayPlugin {
  PriceLevelsOverlay({this._levels = const []});

  final ValueNotifier<int> _rev = ValueNotifier(0);
  List<PriceLevel> _levels;
  bool _disposed = false;

  List<PriceLevel> get levels => _levels;

  set levels(List<PriceLevel> v) {
    if (_disposed || listEquals(v, _levels)) return;
    _levels = v;
    _rev.value++;
  }

  @override
  String get layerKey => 'priceLevels';

  @override
  List<Listenable> repaintOn(ChartController controller) => [
    _rev,
    controller.dataRevision,
    controller.viewport,
  ];

  @override
  void paint(Canvas canvas, RenderContext ctx) {
    final panel = ctx.mainPanel;
    final rect = panel.rect;
    for (final l in _levels) {
      if (!l.price.isFinite) continue;
      final y = panel.yOf(l.price);
      if (y < rect.top || y > rect.bottom) continue;
      final paint = ctx.pool.stroke
        ..color = l.color
        ..strokeWidth = l.width;
      if (l.dashed) {
        ctx.pool.drawDashedHLine(canvas, y, rect.left, rect.right, paint);
      } else {
        canvas.drawLine(Offset(rect.left, y), Offset(rect.right, y), paint);
      }
      final label = l.label;
      if (label == null) continue;
      final tp = ctx.pool.text(label, ctx.theme.axisStyle.copyWith(color: l.color));
      final ty = y - tp.height - 1 < rect.top ? y + 1 : y - tp.height - 1;
      tp.paint(canvas, Offset(rect.left + 4, ty));
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _rev.dispose();
  }
}
