import 'package:flutter/widgets.dart';

import '../debug.dart';
import '../render/context.dart';
import '../render/grid_painter.dart';
import '../render/indicator_painter.dart';
import '../render/overlay_painter.dart';
import '../render/series_painter.dart';

/// Chart layers from bottom to top: grid, host bottom layer, main series, indicators, in-plot
/// axis labels, overlay plugins, host top layer, top plugins, tooltip. Each layer has its own
/// RepaintBoundary, so only the layer whose channel changed repaints.
class ChartLayers extends StatelessWidget {
  const ChartLayers({
    super.key,
    required this.grid,
    required this.plotLabels,
    required this.series,
    required this.indicators,
    required this.overlayLayers,
    required this.overlayTopLayers,
    required this.overlayRev,
    required this.resolve,
    required this.underlayBuilder,
    required this.overlayBuilder,
    required this.tooltip,
  });

  final GridPainter grid;

  /// Axis labels inside the plot area, drawn above indicators and below overlay plugins.
  final GridPainter plotLabels;
  final SeriesPainter series;
  final IndicatorPainter indicators;
  final List<OverlayPainter> overlayLayers;
  final List<OverlayPainter> overlayTopLayers;

  /// Rebuild tick for the two host widget layers.
  final Listenable overlayRev;
  final RenderContext Function() resolve;
  final Widget Function(BuildContext context, RenderContext ctx)? underlayBuilder;
  final Widget Function(BuildContext context, RenderContext ctx)? overlayBuilder;

  /// null = no tooltip.
  final Widget? tooltip;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: RepaintBoundary(child: CustomPaint(painter: grid)),
        ),
        if (underlayBuilder != null)
          Positioned.fill(
            child: RepaintBoundary(
              child: ListenableBuilder(
                listenable: overlayRev,
                builder: (context, _) {
                  if (KlinexDebug.logRebuild) KlinexDebug.rebuild('underlayBuilder');
                  return underlayBuilder!(context, resolve());
                },
              ),
            ),
          ),
        Positioned.fill(
          child: RepaintBoundary(child: CustomPaint(painter: series)),
        ),
        Positioned.fill(
          child: RepaintBoundary(child: CustomPaint(painter: indicators)),
        ),
        Positioned.fill(
          child: RepaintBoundary(child: CustomPaint(painter: plotLabels)),
        ),
        for (final layer in overlayLayers)
          Positioned.fill(
            child: RepaintBoundary(child: CustomPaint(painter: layer)),
          ),
        if (overlayBuilder != null)
          Positioned.fill(
            child: RepaintBoundary(
              child: ListenableBuilder(
                listenable: overlayRev,
                builder: (context, _) {
                  if (KlinexDebug.logRebuild) KlinexDebug.rebuild('overlayBuilder');
                  return overlayBuilder!(context, resolve());
                },
              ),
            ),
          ),
        for (final layer in overlayTopLayers)
          Positioned.fill(
            child: IgnorePointer(
              child: RepaintBoundary(child: CustomPaint(painter: layer)),
            ),
          ),
        if (tooltip != null) Positioned.fill(child: IgnorePointer(child: tooltip)),
      ],
    );
  }
}
