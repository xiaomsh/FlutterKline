import 'dart:convert';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:klinex/klinex.dart';

/// IndicatorRegistry: every built-in indicator keeps its id (incl. params) after JSON round-trip;
/// custom params and colors preserved; unregistered kinds silently skipped.

List<Indicator> customized() => [
  Ma(periods: [5, 20], colors: const [Color(0xFF112233)], lineWidth: 2),
  Ema(periods: [9]),
  Boll(period: 26, k: 2.5),
  VolOverlay(heightFraction: 0.15, opacity: 0.5),
  Vol(),
  MaVol(periods: [7, 14]),
  Macd(short: 10, long: 20, signal: 7, difColor: const Color(0xFF445566)),
  Kdj(n: 14, m1: 5, m2: 5),
  Rsi(periods: [6, 12, 24]),
  Wr(periods: [10]),
];

void main() {
  test('all builtins round-trip through real JSON with identical ids', () {
    final list = customized();
    // real string encode/decode, not just passing a Map
    final encoded = jsonEncode(IndicatorRegistry.toJsonList(list));
    final restored = IndicatorRegistry.fromJsonList(jsonDecode(encoded) as List<dynamic>);

    expect(restored.length, list.length);
    for (var i = 0; i < list.length; i++) {
      expect(restored[i].id, list[i].id, reason: 'id mismatch for ${list[i].kind}');
      expect(restored[i].kind, list[i].kind);
      // serialize again: params (incl. color/width) must match field by field
      expect(
        IndicatorRegistry.toJson(restored[i]),
        IndicatorRegistry.toJson(list[i]),
        reason: 'params drift for ${list[i].kind}',
      );
    }
  });

  test('unknown kind is skipped; unregistered instance throws on toJson', () {
    final restored = IndicatorRegistry.fromJsonList([
      {
        'kind': 'ma',
        'periods': [7],
      },
      {'kind': 'from-the-future'},
    ]);
    expect(restored.length, 1);
    expect(restored.single.id, 'ma(7)');

    expect(() => IndicatorRegistry.toJson(_Custom()), throwsArgumentError);

    // usable after registration
    IndicatorRegistry.register('custom-x', fromParams: (_) => _Custom(), toParams: (_) => const {});
    expect(IndicatorRegistry.toJson(_Custom())['kind'], 'custom-x');
    expect(IndicatorRegistry.fromJson(const {'kind': 'custom-x'}), isA<_Custom>());
  });
}

class _Custom extends Indicator {
  @override
  String get id => 'custom-x';
  @override
  PanelRef get target => PanelRef.main;
  @override
  void computeAll(List<Bar> bars, IndicatorStore store) {}
  @override
  void computeLast(List<Bar> bars, int index, IndicatorStore store) {}
  @override
  void paint(Canvas canvas, RenderContext ctx, IndicatorStore store) {}
  @override
  MinMax range(IndicatorStore store, int start, int end) => MinMax.empty;
}
