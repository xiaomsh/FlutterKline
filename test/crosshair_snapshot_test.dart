import 'package:flutter_test/flutter_test.dart';
import 'package:klinex/src/model/bar.dart';
import 'package:klinex/src/widget/kchart.dart';

void main() {
  test('CrosshairSnapshot.lazy evaluates indicator values on demand once', () {
    var calls = 0;
    final snapshot = CrosshairSnapshot.lazy(
      index: 0,
      bar: const Bar(time: 1, open: 1, high: 2, low: 0.5, close: 1.5, vol: 3),
      position: Offset.zero,
      indicatorValuesLoader: () {
        calls++;
        return {
          'ma': {'ma5': 1.23},
        };
      },
    );

    expect(calls, 0);
    expect(snapshot.index, 0);
    expect(snapshot.bar.close, 1.5);
    expect(calls, 0);

    expect(snapshot.indicatorValues['ma']?['ma5'], 1.23);
    expect(calls, 1);

    expect(snapshot.indicatorValues['ma']?['ma5'], 1.23);
    expect(calls, 1);
  });
}
