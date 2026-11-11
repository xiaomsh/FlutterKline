import 'dart:math' as math;

import 'package:flutter/gestures.dart' show DeviceGestureSettings;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klinex/klinex.dart';

List<Bar> genBars(int n) {
  final rnd = math.Random(1);
  final bars = <Bar>[];
  var close = 100.0;
  for (var i = 0; i < n; i++) {
    final open = close;
    close = (open + (rnd.nextDouble() - 0.5) * 4).clamp(1.0, double.infinity);
    bars.add(
      Bar(
        time: 1700000000000 + i * 60000,
        open: open,
        high: math.max(open, close) + 1,
        low: math.min(open, close) - 1,
        close: close,
        vol: 100 + rnd.nextDouble() * 500,
      ),
    );
  }
  return bars;
}

/// Puts KChart in a horizontal TabBarView (like the "Quotes|News" top-level tabs in
/// flutter_app / demo): when swiping the chart horizontally, the outer same-axis scrollable
/// competes for the gesture. Guards CondHorizontalDragRecognizer's "claim the arena once
/// horizontal intent is clear": chart pans, tab does not page.
class _TabHost extends StatefulWidget {
  const _TabHost({required this.controller, required this.onTab, this.deviceTouchSlop});

  final ChartController controller;
  final void Function(TabController) onTab;

  /// Simulates device gesture settings (Android system touchSlop ~8 logical px): the outer
  /// Scrollable and the chart recognizer both read it via MediaQuery, reproducing the device race.
  final double? deviceTouchSlop;

  @override
  State<_TabHost> createState() => _TabHostState();
}

class _TabHostState extends State<_TabHost> with SingleTickerProviderStateMixin {
  late final TabController tab;

  @override
  void initState() {
    super.initState();
    tab = TabController(length: 2, vsync: this);
    widget.onTab(tab);
  }

  @override
  void dispose() {
    tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    home: Scaffold(
      body: Builder(
        builder: (context) {
          Widget body = SizedBox(
            width: 400,
            height: 600,
            child: TabBarView(
              controller: tab,
              children: [
                KChart(controller: widget.controller, theme: KLineTheme.dark()),
                const Center(child: Text('资讯')),
              ],
            ),
          );
          final slop = widget.deviceTouchSlop;
          if (slop != null) {
            body = MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(gestureSettings: DeviceGestureSettings(touchSlop: slop)),
              child: body,
            );
          }
          return body;
        },
      ),
    ),
  );
}

void main() {
  // Note: horizontal claim vs the outer TabBarView is an arena timing race on real devices;
  // synthetic gesture timing in widget tests is deterministic and the child (chart) always wins,
  // so this assertion passes with or without the fix. It is a smoke test (nesting does not crash,
  // chart pans in tests) and cannot guard the fix itself. The real regression guard is the
  // "vertical swipe yields" test below (it bites).
  testWidgets('smoke: nested in horizontal TabBarView pans, tab stays put', (tester) async {
    final controller = ChartController()..setBars(genBars(300));
    late TabController tab;
    await tester.pumpWidget(_TabHost(controller: controller, onTab: (t) => tab = t));
    await tester.pump();

    final before = controller.viewport.rightIndex;
    // step-by-step swipe (down, per-frame moveBy, up): closer to a real device than tester.drag,
    // giving the outer Scrollable a chance to win the arena; the tab stays only if the claim works.
    final g = await tester.startGesture(tester.getCenter(find.byType(KChart)));
    for (var i = 0; i < 12; i++) {
      await g.moveBy(const Offset(10, 0));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await g.up();
    await tester.pumpAndSettle();

    expect(tab.index, 0, reason: 'outer tab should not page: chart claimed horizontal intent');
    expect(
      controller.viewport.rightIndex,
      lessThan(before),
      reason: 'chart should pan toward history',
    );

    controller.dispose();
  });

  testWidgets('wins slop race under Android-like device touchSlop (8px)', (tester) async {
    // On real devices (Android) the outer Scrollable gets the system touchSlop (~8px) via
    // MediaQuery.gestureSettings, while the recognizer falls back to kTouchSlop=18px: unless the
    // chart takes slop from the same source, the outer wins at 8px: "tests pass, device still
    // pages".
    // This test injects DeviceGestureSettings(touchSlop: 8) to reproduce the race, and bites:
    // removing kchart's gestureSettings pass-down or hardcoding kTouchSlop as threshold fails it.
    final controller = ChartController()..setBars(genBars(300));
    late TabController tab;
    await tester.pumpWidget(
      _TabHost(controller: controller, onTab: (t) => tab = t, deviceTouchSlop: 8),
    );
    await tester.pump();

    final before = controller.viewport.rightIndex;
    final g = await tester.startGesture(tester.getCenter(find.byType(KChart)));
    // 10px per step: one step crosses the device slop (8) but not kTouchSlop (18);
    // with mismatched thresholds the outer tab crosses first
    for (var i = 0; i < 12; i++) {
      await g.moveBy(const Offset(10, 0));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await g.up();
    await tester.pumpAndSettle();

    expect(tab.index, 0, reason: 'outer tab should still not page under device slop');
    expect(
      controller.viewport.rightIndex,
      lessThan(before),
      reason: 'chart should pan toward history',
    );

    controller.dispose();
  });

  testWidgets('slow diagonal swipe claims within 7 steps (14px) before full slop', (tester) async {
    // Measured on a real iOS device: slow swipes took 335~364ms from press to chart motion
    // (dx ~19 / dy ~15 at claim),
    // the finger pushes for a third of a second with no motion: subjectively a "gesture conflict".
    //
    // Both gates hit slow swipes: the threshold must reach the full device slop (iOS falls back
    // to kTouchSlop=18px),
    // and direction strictly compared cumulative |dx| > |dy| (slow fingers jitter, dy accumulates,
    // dx must first catch up with it). After lowering to slop*0.6 with 0.8 direction tolerance:
    //   (2, 1.5)px per step; at step 6 dx=12 > 10.8 and 12 > 9*0.8, claim
    // The old rule needed step 10 (dx=20 to pass 18). Asserts <=7 steps; old code fails.
    final controller = ChartController()..setBars(genBars(300));
    late TabController tab;
    await tester.pumpWidget(_TabHost(controller: controller, onTab: (t) => tab = t));
    await tester.pump();

    final before = controller.viewport.rightIndex;
    final g = await tester.startGesture(tester.getCenter(find.byType(KChart)));
    var steps = 0;
    for (var i = 0; i < 12; i++) {
      await g.moveBy(const Offset(2, 1.5));
      await tester.pump(const Duration(milliseconds: 16));
      steps = i + 1;
      if (controller.viewport.rightIndex != before) break;
    }
    await g.up();
    await tester.pumpAndSettle();

    expect(
      controller.viewport.rightIndex,
      lessThan(before),
      reason: 'slow diagonal swipes must also pan the chart',
    );
    expect(
      steps,
      lessThanOrEqualTo(7),
      reason: 'claim should not wait for 18px total: 2px/step, should start within 7 steps = 14px',
    );
    expect(tab.index, 0, reason: 'outer tab should not page');

    controller.dispose();
  });

  testWidgets('clearly vertical slow swipe still yields to outer vertical scroll', (tester) async {
    // Lower threshold + tolerance must not eat outer vertical scroll: step (1, 4)px, dy = 4*dx,
    // so |dx| > |dy|*0.8 never holds; hDrag does not claim and the chart stays still.
    final controller = ChartController()..setBars(genBars(300));
    late TabController tab;
    await tester.pumpWidget(_TabHost(controller: controller, onTab: (t) => tab = t));
    await tester.pump();

    final before = controller.viewport.rightIndex;
    final g = await tester.startGesture(tester.getCenter(find.byType(KChart)));
    for (var i = 0; i < 20; i++) {
      await g.moveBy(const Offset(1, 4));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await g.up();
    await tester.pumpAndSettle();

    expect(
      controller.viewport.rightIndex,
      before,
      reason: 'chart should not pan on a mostly vertical swipe',
    );
    expect(tab.index, 0);

    controller.dispose();
  });

  testWidgets('vertical drag still yields to an outer scrollable', (tester) async {
    // Vertical drags are still not claimed (vertical dominates), outer vertical scroll works; an
    // outer ListView catches it to assert the chart did not swallow it (viewport not shifted).
    final controller = ChartController()..setBars(genBars(300));
    final scrollController = ScrollController();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            controller: scrollController,
            children: [
              const SizedBox(height: 200),
              SizedBox(
                height: 400,
                child: KChart(controller: controller, theme: KLineTheme.dark()),
              ),
              const SizedBox(height: 800),
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    final rightBefore = controller.viewport.rightIndex;
    await tester.drag(find.byType(KChart), const Offset(0, -160), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(scrollController.offset, greaterThan(0), reason: 'outer vertical scroll should work');
    expect(
      controller.viewport.rightIndex,
      rightBefore,
      reason: 'vertical swipe should not be taken by the chart as a horizontal pan',
    );

    controller.dispose();
    scrollController.dispose();
  });
}
