import 'dart:collection';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/painting.dart';

/// Reuses Paint / TextPainter / Float32List across frames; one per controller.
class PaintPool {
  /// Shared stroke paint; callers set color and stroke width each time.
  final Paint stroke = Paint()
    ..style = PaintingStyle.stroke
    ..isAntiAlias = true;

  /// Shared fill paint.
  final Paint fill = Paint()..style = PaintingStyle.fill;

  /// Shared scratch Path for polylines, one user at a time: reset, build, draw (drawing
  /// snapshots it, so reusing it right after is fine).
  final Path scratchPath = Path();

  // ---- Shared Float32List (grows, never shrinks) ----

  Float32List _buf = Float32List(1024);

  /// A view of length [n] over the shared buffer; only one at a time: finish drawing before
  /// requesting the next.
  Float32List floats(int n) {
    if (n > _buf.length) {
      var cap = _buf.length;
      while (cap < n) {
        cap *= 2;
      }
      _buf = Float32List(cap);
    }
    return Float32List.sublistView(_buf, 0, n);
  }

  // ---- TextPainter cache (LRU) ----

  static const int _textCacheCap = 300;
  final LinkedHashMap<_TextKey, TextPainter> _texts = LinkedHashMap();

  /// Returns a laid-out TextPainter; callers must not call layout() on it again.
  TextPainter text(String s, TextStyle style) {
    final key = _TextKey(s, style);
    final hit = _texts.remove(key);
    if (hit != null) {
      _texts[key] = hit; // LRU: move to the end
      return hit;
    }
    final tp = TextPainter(
      text: TextSpan(text: s, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    _texts[key] = tp;
    if (_texts.length > _textCacheCap) {
      // Evictions must dispose: TextPainter holds a native Paragraph, and merely removing it
      // means dragging the crosshair (price label changing per pixel) keeps creating native
      // resources that wait on the GC finalizer.
      _texts.remove(_texts.keys.first)?.dispose();
    }
    return tp;
  }

  /// Releases all cached TextPainters (with their underlying Paragraphs); call when the chart
  /// is hidden (e.g. switching tabs) to save GPU memory.
  void clear() {
    for (final tp in _texts.values) {
      tp.dispose();
    }
    _texts.clear();
  }

  /// Draws a horizontal dashed line with a single drawRawPoints.
  void drawDashedHLine(
    Canvas canvas,
    double y,
    double x0,
    double x1,
    Paint paint, {
    double dash = 4,
    double gap = 4,
  }) {
    if (x1 <= x0) return;
    final step = dash + gap;
    // If the theme's dash params are unreasonable (non-positive dash, period under 1px), draw a
    // solid line; otherwise the segment count could be too large to allocate.
    if (!(dash > 0) || !(step >= 1)) {
      canvas.drawLine(Offset(x0, y), Offset(x1, y), paint);
      return;
    }
    // Capacity is estimated with ceil and the submit is truncated to what was written: the
    // estimate and the accumulation are different float computations that can differ by one at
    // the boundary; one extra overflows and throws (the layer goes blank for a frame), one fewer
    // draws leftovers in the buffer as ghost segments.
    final pts = floats((((x1 - x0) / step).ceil() + 1) * 4);
    var i = 0;
    for (var x = x0; x < x1 && i + 4 <= pts.length; x += step) {
      pts[i++] = x;
      pts[i++] = y;
      pts[i++] = (x + dash) < x1 ? (x + dash) : x1;
      pts[i++] = y;
    }
    if (i == 0) return;
    canvas.drawRawPoints(
      PointMode.lines,
      i == pts.length ? pts : Float32List.sublistView(pts, 0, i),
      paint,
    );
  }

  /// Vertical version of [drawDashedHLine].
  void drawDashedVLine(
    Canvas canvas,
    double x,
    double y0,
    double y1,
    Paint paint, {
    double dash = 4,
    double gap = 4,
  }) {
    if (y1 <= y0) return;
    final step = dash + gap;
    if (!(dash > 0) || !(step >= 1)) {
      canvas.drawLine(Offset(x, y0), Offset(x, y1), paint);
      return;
    }
    final pts = floats((((y1 - y0) / step).ceil() + 1) * 4);
    var i = 0;
    for (var y = y0; y < y1 && i + 4 <= pts.length; y += step) {
      pts[i++] = x;
      pts[i++] = y;
      pts[i++] = x;
      pts[i++] = (y + dash) < y1 ? (y + dash) : y1;
    }
    if (i == 0) return;
    canvas.drawRawPoints(
      PointMode.lines,
      i == pts.length ? pts : Float32List.sublistView(pts, 0, i),
      paint,
    );
  }

  /// Draws [s] in a rounded box; [anchor] is the box's top-left (adjusted by [alignRight] /
  /// [centerX]). Returns the box rect.
  Rect drawBoxedLabel(
    Canvas canvas,
    String s,
    TextStyle style,
    Offset anchor,
    Color bg, {
    bool alignRight = false,
    bool centerX = false,
    double hPad = 4,
    double vPad = 2,
  }) {
    final tp = text(s, style);
    var left = anchor.dx;
    if (alignRight) left -= tp.width + hPad * 2;
    if (centerX) left -= tp.width / 2 + hPad;
    final rect = Rect.fromLTWH(
      left,
      anchor.dy,
      tp.width + hPad * 2,
      tp.height + vPad * 2,
    );
    fill.color = bg;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(2)),
      fill,
    );
    tp.paint(canvas, Offset(rect.left + hPad, rect.top + vPad));
    return rect;
  }
}

class _TextKey {
  const _TextKey(this.text, this.style);

  final String text;
  final TextStyle style;

  @override
  bool operator ==(Object other) => other is _TextKey && other.text == text && other.style == style;

  @override
  int get hashCode => Object.hash(text, style);
}
