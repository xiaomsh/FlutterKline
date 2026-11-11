import 'package:klinex_example/widget/axis_price_tag_layout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('stackNonOverlapping keeps tags ordered and inside the panel', () {
    final tops = stackNonOverlapping(
      items: const [
        (center: 50.0, height: 16.0),
        (center: 50.0, height: 36.0),
        (center: 50.0, height: 16.0),
      ],
      top: 0,
      bottom: 100,
    );

    expect(tops[0] + 16, lessThanOrEqualTo(tops[1]));
    expect(tops[1] + 36, lessThanOrEqualTo(tops[2]));
    expect(tops.first, greaterThanOrEqualTo(0));
    expect(tops.last + 16, lessThanOrEqualTo(100));
  });
}
