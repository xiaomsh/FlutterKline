import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klinex/klinex.dart';
import 'package:klinex/src/render/overlay_painter.dart';

/// A layer's repaint signal is the union of its plugins' repaintOn, so "who shares a layer with
/// whom" means "who gets repainted by whose jitter". Drawing geometry/dashes are rebuilt every
/// frame and must be split into their own layer.

List<Bar> bars(int n) => [
  for (var i = 0; i < n; i++)
    Bar(
      time: 1700000000000 + i * 60000,
      open: 100,
      high: 101,
      low: 99,
      close: 100.5,
    ),
];

ChartConfig cfg() => ChartConfig(
  theme: KLineTheme.light(),
  priceFormatter: (v) => v.toStringAsFixed(2),
  timeFormatter: (ms) => '$ms',
);

/// Counts how many times a painter is notified to repaint during [act].
int repaintsDuring(OverlayPainter p, VoidCallback act) {
  var n = 0;
  void listener() => n++;
  p.addListener(listener);
  act();
  p.removeListener(listener);
  return n;
}

void main() {
  _hostOverlayTapTest();
  TestWidgetsFlutterBinding.ensureInitialized();
}

/// Paint-only painter layers that don't handle events must not swallow taps on the host overlay.
///
/// `RenderCustomPaint.hitTestSelf` treats "painter.hitTest returns null" as a hit
/// (`?? true` in the source), and CustomPainter's default implementation returns exactly null. The
/// top painters sit above overlayBuilder, so without IgnorePointer, buttons/markers the host puts
/// in the overlay don't respond to taps at all, and the cause is hard to find.
void _hostOverlayTapTest() {
  testWidgets('widgets in overlayBuilder receive taps (top painters do not block)', (tester) async {
    final c = ChartController()..setBars(bars(120));
    addTearDown(c.dispose);
    var tapped = 0;

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox(
            width: 400,
            height: 300,
            child: KChart(
              controller: c,
              theme: KLineTheme.light(),
              overlayBuilder: (_, ctx) => Align(
                alignment: Alignment.center,
                child: GestureDetector(
                  onTap: () => tapped++,
                  child: Container(width: 40, height: 40, color: const Color(0xFF00FF00)),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Container));
    // let the double-tap recognizer's timer expire
    await tester.pump(const Duration(milliseconds: 400));
    expect(tapped, 1);
  });
}
