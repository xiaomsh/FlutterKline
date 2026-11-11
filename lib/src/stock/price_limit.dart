import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import '../controller.dart';
import '../model/bar.dart';
import '../overlay/overlay_plugin.dart';
import '../render/context.dart';

/// Daily price limits (China A-share style): limit = previous close × (1 ± [ratio]), rounded half
/// up to [decimals].
@immutable
class PriceLimit {
  const PriceLimit(this.ratio, {this.decimals = 2})
    : assert(ratio > 0 && ratio < 1, 'ratio must be within (0, 1)');

  /// Main board ±10%.
  static const mainBoard = PriceLimit(0.10);

  /// ChiNext / STAR Market ±20%.
  static const growth = PriceLimit(0.20);

  /// Risk-warning (ST) stocks ±5%.
  static const st = PriceLimit(0.05);

  /// Beijing Stock Exchange ±30%.
  static const bse = PriceLimit(0.30);

  final double ratio;
  final int decimals;

  double _round(double v) {
    final f = math.pow(10, decimals).toDouble();
    // The epsilon absorbs binary error so 10.45 × 1.1 = 11.495 rounds up like the exchange does.
    return (v * f + 1e-7).roundToDouble() / f;
  }

  double up(double preClose) => _round(preClose * (1 + ratio));

  double down(double preClose) => _round(preClose * (1 - ratio));

  /// Whether [close] equals the limit up from [preClose] (within half a tick). Closes beyond the
  /// limit are not limit moves: no-limit days (IPOs) or unadjusted ex-rights days.
  bool isLimitUp(double preClose, double close) => _at(up, preClose, close);

  bool isLimitDown(double preClose, double close) => _at(down, preClose, close);

  bool _at(double Function(double) limit, double preClose, double close) =>
      preClose > 0 && (close - limit(preClose)).abs() < 0.5 * math.pow(10, -decimals);

  @override
  bool operator ==(Object other) =>
      other is PriceLimit && other.ratio == ratio && other.decimals == decimals;

  @override
  int get hashCode => Object.hash(ratio, decimals);
}

/// Marks bars that closed at the limit up (triangle above the high) or limit down (below the
/// low), judged from the previous bar's close — meant for daily bars. Optional [upLabel] /
/// [downLabel] are drawn next to the triangle. Colors default to the theme's up / down. A null
/// [limit] draws nothing (markets without limits).
class LimitMarksOverlay extends OverlayPlugin {
  LimitMarksOverlay({
    this._limit = PriceLimit.mainBoard,
    this._upLabel,
    this._downLabel,
    this.upColor,
    this.downColor,
  });

  final ValueNotifier<int> _rev = ValueNotifier(0);
  PriceLimit? _limit;
  String? _upLabel;
  String? _downLabel;
  final Color? upColor;
  final Color? downColor;
  bool _disposed = false;

  PriceLimit? get limit => _limit;

  set limit(PriceLimit? v) => _set(() => _limit = v, v == _limit);

  String? get upLabel => _upLabel;

  set upLabel(String? v) => _set(() => _upLabel = v, v == _upLabel);

  String? get downLabel => _downLabel;

  set downLabel(String? v) => _set(() => _downLabel = v, v == _downLabel);

  void _set(VoidCallback apply, bool same) {
    if (_disposed || same) return;
    apply();
    _rev.value++;
  }

  @override
  String get layerKey => 'limitMarks';

  @override
  List<Listenable> repaintOn(ChartController controller) => [
    _rev,
    controller.dataRevision,
    controller.viewport,
  ];

  /// Limit state of bar [i] in [bars]: 1 up, -1 down, 0 neither (the first bar has no reference).
  int stateAt(List<Bar> bars, int i) {
    final limit = _limit;
    if (limit == null || i <= 0 || i >= bars.length) return 0;
    final pre = bars[i - 1].close;
    final c = bars[i].close;
    if (limit.isLimitUp(pre, c)) return 1;
    if (limit.isLimitDown(pre, c)) return -1;
    return 0;
  }

  @override
  void paint(Canvas canvas, RenderContext ctx) {
    if (ctx.isEmpty || _limit == null) return;
    final panel = ctx.mainPanel;
    final bars = ctx.bars;
    final size = math.min(8.0, math.max(4.0, ctx.barWidth * 0.8));
    final fill = ctx.pool.fill;
    for (var i = math.max(ctx.start, 1); i <= ctx.end; i++) {
      final state = stateAt(bars, i);
      if (state == 0) continue;
      final x = ctx.xOf(i);
      final up = state > 0;
      final color = up ? (upColor ?? ctx.theme.up) : (downColor ?? ctx.theme.down);
      final tip = up ? panel.yOf(bars[i].high) - 3 : panel.yOf(bars[i].low) + 3;
      final base = up ? tip - size : tip + size;
      final path = Path()
        ..moveTo(x, tip)
        ..lineTo(x - size / 2, base)
        ..lineTo(x + size / 2, base)
        ..close();
      canvas.drawPath(path, fill..color = color);
      final label = up ? upLabel : downLabel;
      if (label == null) continue;
      final tp = ctx.pool.text(label, ctx.theme.axisStyle.copyWith(color: color));
      final ty = up ? base - tp.height - 1 : base + 1;
      tp.paint(canvas, Offset(x - tp.width / 2, ty));
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _rev.dispose();
  }
}
