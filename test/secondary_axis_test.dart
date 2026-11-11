import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klinex/klinex.dart';
import 'package:klinex/src/widget/kchart_config.dart';

List<Bar> _bars(int n) => [
  for (var i = 0; i < n; i++)
    Bar(
      time: 1700000000000 + i * 60000,
      open: 1000.0 + i + (i % 5),
      high: 1006.0 + i + (i % 5),
      low: 995.0 + i + (i % 5),
      close: 1001.0 + i + (i % 3),
      vol: 10,
    ),
];

ChartConfig _config() => ChartConfig(
  theme: KLineTheme.dark(),
  priceFormatter: (v) => v.toStringAsFixed(2),
  timeFormatter: (ms) => '$ms',
);

const _size = Size(500, 400);

class _Extra extends OverlayPlugin {
  MinMax extra = MinMax.empty;
  @override
  List<Listenable> repaintOn(ChartController controller) => const [];
  @override
  void paint(Canvas canvas, RenderContext ctx) {}
  @override
  MinMax secondaryRange(ChartController controller, int start, int end) => extra;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('SecondaryAxis keeps price range untouched and gets its own axis', () {
    final plain = ChartController()..setBars(_bars(300));
    final p0 = plain.resolveLayout(_size, _config()).mainPanel.range;
    final c = ChartController(indicators: [SecondaryAxis(Rsi())])
      ..asyncCompute = false
      ..setBars(_bars(300));
    final ctx = c.resolveLayout(_size, _config());
    expect(ctx.panels.length, 1, reason: 'no sub panel');
    final main = ctx.mainPanel;
    expect(main.range.min, closeTo(p0.min, 1e-9));
    expect(main.range.max, closeTo(p0.max, 1e-9));
    final sec = main.secondary!;
    expect(sec.isSecondary, isTrue);
    expect(sec.rect, main.rect);
    expect(sec.range.max, lessThanOrEqualTo(110));
    expect(sec.range.min, greaterThanOrEqualTo(-10));
    // manual scaling or locking of the main axis does not touch the second axis
    c.viewport.zoomY(3);
    final zoomed = c.resolveLayout(_size, _config()).mainPanel;
    expect(zoomed.secondary!.range.min, closeTo(sec.range.min, 1e-9));
    c.lockYRange();
    c.viewport.scroll(400);
    final locked = c.resolveLayout(_size, _config()).mainPanel;
    expect(locked.secondary, isNotNull);
    // wrapped indicator serializes, so the whole can be saved/loaded and computed in background
    final saved = c.saveState()['indicators'] as List;
    expect(saved.single, {
      'kind': 'axis2',
      'inner': {
        'kind': 'rsi',
        'periods': [14],
        'lineWidth': 1.0,
      },
    });
    final back = IndicatorRegistry.fromJson((saved.single as Map).cast())!;
    expect(back, isA<SecondaryAxis>());
    expect(back.id, SecondaryAxis(Rsi()).id);
    expect(
      IndicatorRegistry.fromJson({
        'kind': 'axis2',
        'inner': {'kind': 'nope'},
      }),
      isNull,
    );
    expect(SecondaryAxis(Rsi()).target.isMain, isTrue);
    expect(SecondaryAxis(Rsi()).target.isSecondaryAxis, isTrue);
    plain.dispose();
    c.dispose();
  });

  test('overlay secondaryRange feeds the axis; relayout picks up changes', () {
    final extra = _Extra();
    final c = ChartController(overlays: [extra])..setBars(_bars(100));
    expect(c.resolveLayout(_size, _config()).mainPanel.secondary, isNull);
    extra.extra = const MinMax(5, 15);
    c.relayout();
    final sec = c.resolveLayout(_size, _config()).mainPanel.secondary!;
    expect(sec.range.min, lessThan(5));
    expect(sec.range.max, greaterThan(15));
    expect(sec.yOf(15), lessThan(sec.yOf(5)));
    c.dispose();
  });

  test('second axis follows invertScale and uses secondaryFormatter', () {
    final c = ChartController(indicators: [SecondaryAxis(Rsi())])
      ..asyncCompute = false
      ..setBars(_bars(200));
    final config = _config()
      ..invertScale = true
      ..secondaryFormatter = (v) => 'S${v.round()}';
    final ctx = c.resolveLayout(_size, config);
    final sec = ctx.mainPanel.secondary!;
    expect(sec.inverted, isTrue);
    expect(sec.yOf(sec.range.min), closeTo(sec.rect.top, 1e-6));
    expect(ctx.formatAxisValue(sec, 50), 'S50');
    expect(ctx.formatAxisValue(ctx.mainPanel, 50), '50.00');
    c.dispose();
  });

  for (final pos in YAxisPosition.values) {
    testWidgets('paints with second axis and crosshair ($pos)', (tester) async {
      final c = ChartController(indicators: [Ma(), SecondaryAxis(Rsi())])
        ..asyncCompute = false
        ..setBars(_bars(300));
      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 500,
            height: 400,
            child: KChart(controller: c, theme: KLineTheme.dark(), yAxisPosition: pos),
          ),
        ),
      );
      c.crosshair.value = CrosshairState(time: c.bars[250].time, position: const Offset(250, 100));
      await tester.pump();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      c.dispose();
    });
  }

  test('KChart.secondaryFormatter reaches ChartConfig and resyncs', () {
    final c = ChartController();
    String pct(double v) => '${v.round()}%';
    KChart chart(PriceFormatter? f) =>
        KChart(controller: c, theme: KLineTheme.dark(), secondaryFormatter: f);
    final config = buildChartConfig(chart(pct), (ms) => '$ms');
    expect(config.secondaryFormatter, same(pct));
    final before = config.layoutRevision.value;
    syncChartConfig(config, chart(null), chart(pct), (ms) => '$ms');
    expect(config.secondaryFormatter, isNull);
    expect(config.layoutRevision.value, greaterThan(before));
    c.dispose();
  });
}
