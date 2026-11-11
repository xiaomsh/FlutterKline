import 'package:flutter_test/flutter_test.dart';
import 'package:klinex/klinex.dart';

import 'package:klinex_example/widget/indicator_configs.dart';

void main() {
  test('an invalid MACD combination is skipped and reported, others still build', () {
    final cfg = IndicatorConfigs()
      ..macdShort = 30
      ..macdLong = 26;
    final built = cfg.build({'MA'}, {'MACD', 'RSI'});
    expect(built.whereType<Macd>(), isEmpty);
    expect(built.whereType<Ma>(), hasLength(1));
    expect(built.whereType<Rsi>(), hasLength(1));
    expect(cfg.errors.value['MACD'], contains('MACD'));
    cfg.macdShort = 12;
    expect(cfg.build({}, {'MACD'}).whereType<Macd>(), hasLength(1));
    expect(cfg.errors.value, isEmpty);
  });

  test('reset keeps the same line list so open detail sheets stay bound', () {
    final cfg = IndicatorConfigs();
    final lines = cfg.maLines;
    lines.first.period = 10;
    cfg.resetMa();
    expect(identical(cfg.maLines, lines), isTrue);
    expect(lines.first.period, 7);
    lines.first.period = 12;
    expect((cfg.build({'MA'}, {}).single as Ma).periods.first, 12);
  });
}
