import 'package:flutter_test/flutter_test.dart';
import 'package:klinex/klinex.dart';

void main() {
  test('BOLL rejects a non-positive band multiplier', () {
    expect(() => Boll(k: -2), throwsRangeError);
    expect(() => Boll(k: 0), throwsRangeError);
    expect(() => Boll(k: double.nan), throwsRangeError);
    expect(Boll(k: 2.5).k, 2.5);
  });
}
