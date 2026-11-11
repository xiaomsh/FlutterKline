import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klinex/klinex.dart';

List<Bar> _bars(int n) => [
  for (var i = 0; i < n; i++)
    Bar(
      time: 1700000000000 + i * 60000,
      open: 100.0 + i * 0.5,
      high: 103.0 + i * 0.5,
      low: 98.0 + i * 0.5,
      close: 101.0 + i * 0.5,
      vol: 10,
    ),
];

ChartConfig _config({bool invert = false, bool log = false}) => ChartConfig(
  theme: KLineTheme.dark(),
  priceFormatter: (v) => v.toStringAsFixed(2),
  timeFormatter: (ms) => '$ms',
  invertScale: invert,
  logScale: log,
);

const _size = Size(400, 600);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final log in [false, true]) {
    test('invertScale flips the main panel only (log=$log)', () {
      final c = ChartController(indicators: [Vol()])..setBars(_bars(200));
      final normal = c.resolveLayout(_size, _config(log: log));
      c.dispose();
      final c2 = ChartController(indicators: [Vol()])..setBars(_bars(200));
      final inv = c2.resolveLayout(_size, _config(invert: true, log: log));
      final m = inv.mainPanel;
      expect(m.inverted, isTrue);
      expect(inv.panels[1].inverted, isFalse);
      // smaller values on top
      expect(m.yOf(m.range.min), closeTo(m.rect.top, 1e-6));
      expect(m.yOf(m.range.max), closeTo(m.rect.bottom, 1e-6));
      expect(m.valueAtFraction(0), closeTo(m.range.min, 1e-6));
      expect(m.minEdge, m.rect.top);
      for (final v in [m.range.min, (m.range.min + m.range.max) / 2, m.range.max]) {
        expect(m.valueOf(m.yOf(v)), closeTo(v, 1e-6));
      }
      // the same value is mirrored about the pane's midline vs. the non-inverted mapping
      final plain = PanelLayout(
        id: m.id,
        isMain: true,
        rect: m.rect,
        range: m.range,
        indicators: const [],
        logScale: log,
      );
      for (final v in [m.range.min * 1.01, (m.range.min + m.range.max) / 2, m.range.max * 0.99]) {
        expect(m.yOf(v) - m.rect.top, closeTo(m.rect.bottom - plain.yOf(v), 1e-6));
      }
      expect(normal.mainPanel.inverted, isFalse);
      c2.dispose();
    });
  }

  test('lockYRange freezes the main range while panning; manual zoom stacks on it', () {
    final c = ChartController()..setBars(_bars(500));
    final config = _config();
    final r0 = c.resolveLayout(_size, config).mainPanel.range;
    c.viewport.zoomY(2);
    final zoomed = c.resolveLayout(_size, config).mainPanel.range;
    expect(c.lockYRange(), isTrue);
    expect(c.viewport.yScale, 1.0);
    expect(c.viewport.lockedYRange!.min, zoomed.min);
    // no visual jump when locking
    var r = c.resolveLayout(_size, config).mainPanel.range;
    expect(r.min, closeTo(zoomed.min, 1e-9));
    expect(r.max, closeTo(zoomed.max, 1e-9));
    // pan to old data (much lower prices), range unchanged
    c.viewport.scroll(3000);
    r = c.resolveLayout(_size, config).mainPanel.range;
    expect(r.min, closeTo(zoomed.min, 1e-9));
    // manual zoom stacks on the locked range
    c.viewport.zoomY(0.5);
    r = c.resolveLayout(_size, config).mainPanel.range;
    expect(r.span, closeTo(zoomed.span * 2, 1e-6));
    // reset returns to the locked range
    c.viewport.resetYScale();
    r = c.resolveLayout(_size, config).mainPanel.range;
    expect(r.span, closeTo(zoomed.span, 1e-6));
    // unlocking returns to auto, following the visible area
    c.unlockYRange();
    r = c.resolveLayout(_size, config).mainPanel.range;
    expect(r.max, lessThan(r0.min));
    c.dispose();
  });

  test('lock survives saveState / restoreState and resets on setBars', () {
    final c = ChartController()..setBars(_bars(300));
    c.resolveLayout(_size, _config());
    c.lockYRange();
    c.viewport.zoomY(1.5);
    final saved = c.saveState();
    expect(saved['lockedY'], isA<List>());
    final d = ChartController()..setBars(_bars(300));
    d.restoreState(saved);
    expect(d.viewport.lockedYRange!.min, c.viewport.lockedYRange!.min);
    expect(d.viewport.yScale, closeTo(1.5, 1e-9));
    d.restoreState(ChartController().saveState());
    expect(d.viewport.lockedYRange, isNull);
    c.setBars(_bars(10));
    expect(c.viewport.lockedYRange, isNull);
    expect(c.lockYRange(), isTrue); // can lock once laid out
    final fresh = ChartController()..setBars(_bars(10));
    expect(fresh.lockYRange(), isFalse); // not painted yet
    c.dispose();
    d.dispose();
    fresh.dispose();
  });

  testWidgets('vertical drag follows the finger in inverted mode', (tester) async {
    Future<double> dragOffset(bool invert) async {
      final c = ChartController()..setBars(_bars(200));
      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 400,
            height: 600,
            child: KChart(
              controller: c,
              theme: KLineTheme.dark(),
              yPan: YPanMode.chart,
              invertScale: invert,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.dragFrom(const Offset(200, 200), const Offset(0, 80));
      await tester.pump(const Duration(seconds: 1));
      final o = c.viewport.yOffset;
      await tester.pumpWidget(const SizedBox());
      c.dispose();
      return o;
    }

    final normal = await dragOffset(false);
    final inverted = await dragOffset(true);
    expect(normal, greaterThan(0));
    expect(inverted, lessThan(0));
  });

  test('restoreState before setBars keeps the locked range and y zoom', () {
    final src = ChartController()..setBars(_bars(200));
    src.resolveLayout(_size, _config());
    src.lockYRange();
    src.viewport.zoomY(2);
    final saved = src.saveState();
    final c = ChartController()..restoreState(saved);
    c.setBars(_bars(200));
    expect(c.viewport.lockedYRange?.min, src.viewport.lockedYRange!.min);
    expect(c.viewport.yScale, src.viewport.yScale);
    // takes effect immediately when data exists; a later setBars unlocks as usual
    c.setBars(_bars(150));
    expect(c.viewport.lockedYRange, isNull);
    c.restoreState(saved);
    expect(c.viewport.lockedYRange?.min, src.viewport.lockedYRange!.min);
    src.dispose();
    c.dispose();
  });

  test('unlocking clears zoom made relative to the locked range', () {
    final c = ChartController()..setBars(_bars(200));
    c.resolveLayout(_size, _config());
    c.lockYRange();
    c.viewport
      ..zoomY(3)
      ..panY(20, 400);
    c.unlockYRange();
    expect(c.viewport.yScale, 1);
    expect(c.viewport.yOffset, 0);
    c.dispose();
  });
}
