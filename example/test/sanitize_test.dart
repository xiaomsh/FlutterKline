import 'package:klinex_example/model/data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klinex/klinex.dart';

Bar bar(int i, {double o = 100, double h = 101, double l = 99, double c = 100}) =>
    Bar(time: 1700000000000 + i * 60000, open: o, high: h, low: l, close: c);

void main() {
  test('sanitizeSpikes clamps a junk wick, keeps normal bars untouched', () {
    final bars = [
      bar(0),
      bar(1, h: 999999), // bad tick: wick far beyond the body and neighbors
      bar(2),
      bar(3, l: 0.001), // bad tick: lower wick breaks through the floor
      bar(4),
    ];
    final out = sanitizeSpikes(bars);
    expect(out[1].high, 101, reason: 'clamped to the reference high (neighbor/body extreme)');
    expect(out[3].low, 99, reason: 'clamped to the reference low');
    expect(out[0].high, 101);
    expect(out[2].low, 99);
    expect(out[4].close, 100);
    // The input list is not modified.
    expect(bars[1].high, 999999);
  });

  test('sanitizeSpikes keeps legitimate large moves (within factor)', () {
    final bars = [
      bar(0),
      bar(1, o: 100, c: 140, h: 150, l: 98),
      bar(2, o: 140, c: 145, h: 148, l: 139),
    ];
    final out = sanitizeSpikes(bars);
    expect(out[1].high, 150, reason: 'real moves within the 5x threshold stay untouched');
  });

  test('sanitizeTick clamps against prev bar + own body', () {
    final prev = bar(0);
    final t = sanitizeTick(bar(1, h: 88888, l: 0.01), prev);
    expect(t.high, 101);
    expect(t.low, 99);
    final ok = sanitizeTick(bar(1, h: 103, l: 97), prev);
    expect(ok.high, 103);
    expect(ok.low, 97);
    // No previous bar: only the body is the reference.
    final solo = sanitizeTick(bar(0, o: 100, c: 102, h: 99999, l: 100), null);
    expect(solo.high, 102);
  });
}
