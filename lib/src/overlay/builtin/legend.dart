import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import '../../controller.dart';
import '../../indicator/indicator.dart';
import '../../render/context.dart';
import '../overlay_plugin.dart';

/// Per-panel indicator legend: a row of "name:value" at the panel's top-left, showing values of the
/// crosshair bar (otherwise the latest bar).
class IndicatorLegendOverlay extends OverlayPlugin {
  IndicatorLegendOverlay({
    this.fontSize = 10,
    this.rowHeight = 14,
    this.chipGap = 8,
    this.inset = const Offset(6, 3),
    this.rightReserve = 70,
    this.hideOnCrosshair = false,
    this.mainCrosshairInset,
  });

  final double fontSize;
  final double rowHeight;

  /// Hides the legend while the crosshair is shown.
  final bool hideOnCrosshair;

  /// Distance the main legend moves down while the crosshair is shown (room for the host's tooltip
  /// row); the host passes the measured height.
  final ValueListenable<double>? mainCrosshairInset;

  /// Horizontal gap between legends.
  final double chipGap;

  /// Top-left offset of the first legend within the panel.
  final Offset inset;

  /// Width reserved on the panel's right (where scale labels are).
  final double rightReserve;

  final List<LegendItem> _scratch = [];
  final Map<Color, TextStyle> _styles = {};

  /// Repaints whenever the crosshair moves, on its own layer, so it does not drag same-layer
  /// plugins like price lines and trade lines into repainting.
  @override
  String get layerKey => 'legend';

  /// Sub-panel legends use a single line only (panels are short; wrapping would eat half the
  /// indicator area); chips that do not fit
  /// are simply not drawn. Layout reserves this line at the sub-panel top, see [ChartController].
  double get subPanelReserve => inset.dy + rowHeight;

  @override
  List<Listenable> repaintOn(ChartController controller) => [
    controller.crosshair,
    controller.dataRevision,
    controller.tooltipInset,
    ?mainCrosshairInset,
  ];

  @override
  void paint(Canvas canvas, RenderContext ctx) {
    if (ctx.isEmpty) return;
    final crosshairActive = ctx.controller.crosshair.value != null;
    if (hideOnCrosshair && crosshairActive) return;
    final bars = ctx.bars;
    final ci = ctx.controller.crosshairIndex();
    final index = (ci >= 0 ? ci : bars.length - 1).clamp(0, bars.length - 1);

    for (final panel in ctx.panels) {
      if (panel.indicators.isEmpty) continue;
      ctx.usePanel(panel);
      final left = panel.rect.left + inset.dx;
      // The last line must fit entirely within this panel: legends push down line by line, so with
      // 5+ main indicators or frequent wrapping on narrow screens they would spill into the
      // sub-panel below (L3 only clips to the whole widget, which does not stop it).
      final maxY = panel.rect.bottom - rowHeight;
      var x = left;
      var y = panel.rect.top + inset.dy;
      if (panel.isMain && crosshairActive) {
        y += (mainCrosshairInset?.value ?? 0) + ctx.controller.tooltipInset.value;
      }
      // Bottom reserved area is allocated bottom-up (ratios share a source with padBottom in
      // layout): legends of in-band indicators (e.g. volume bars) sit at the top of their own band,
      // not in the top row
      var bandTop = panel.rect.bottom;
      for (final ind in panel.indicators) {
        final band = panel.isMain ? ind.mainBottomReserveFraction : 0.0;
        if (band > 0) {
          bandTop -= panel.rect.height * band;
        } else if (y > maxY) {
          break;
        }
        _scratch.clear();
        // Indicators on the secondary value axis format readouts with that axis's format
        final sec = panel.secondary;
        ctx.usePanel(sec != null && ind.target.isSecondaryAxis ? sec : panel);
        ind.legendInto(_scratch, ctx, ctx.controller.storeOf(ind), index);
        if (_scratch.isEmpty) continue;
        // In-band indicators use their own cursor and do not advance the top x/y after drawing.
        var cx = band > 0 ? left : x;
        var cy = band > 0 ? bandTop : y;
        var clipped = false;
        for (final (text, color) in _scratch) {
          final tp = ctx.pool.text(
            text,
            _styles.putIfAbsent(color, () => TextStyle(color: color, fontSize: fontSize)),
          );
          // Wrap if it would run into the scale label area
          if (cx + tp.width > panel.rect.right - rightReserve && cx > left) {
            // Sub-panel/in-band have one line only: skip remaining chips rather than eat the
            // indicator area
            if (!panel.isMain || band > 0) {
              clipped = true;
              break;
            }
            cx = left;
            cy += rowHeight;
          }
          if (cy > maxY) {
            clipped = true;
            break;
          }
          tp.paint(canvas, Offset(cx, cy));
          cx += tp.width + chipGap;
        }
        if (band > 0) continue;
        if (clipped && !panel.isMain) break;
        x = cx;
        y = cy;
        if (panel.isMain) {
          x = left;
          y += rowHeight;
        }
      }
    }
    ctx.usePanel(ctx.mainPanel);
  }
}
