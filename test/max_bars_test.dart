import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klinex/klinex.dart';

/// maxBars: history cap. Appends past it trim the oldest end; prepends only fill free slots.
/// Indicators and viewport shift left to match.

const t0 = 1700000000000;

List<Bar> walk(int n, {int from = 0}) {
  final rnd = math.Random(3);
  var close = 100.0;
  return [
    for (var i = 0; i < from + n; i++)
      () {
        final open = close;
        close = math.max(1.0, close + (rnd.nextDouble() - 0.5) * 4);
        return Bar(
          time: t0 + i * 60000,
          open: open,
          high: math.max(open, close) + 1,
          low: math.min(open, close) - 1,
          close: close,
          vol: 100 + rnd.nextDouble() * 100,
        );
      }(),
  ].sublist(from);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('appending past the cap trims the oldest end; length never exceeds the cap', () {
    final all = walk(300);
    final c = ChartController()..maxBars = 100;
    c.setBars(all.sublist(0, 100));
    for (var i = 100; i < 164; i++) {
      c.appendBar(all[i]);
      expect(c.bars.length, 100);
    }
    expect(c.bars.first.time, all[64].time);
    expect(c.bars.last.time, all[163].time);
    c.dispose();
  });

  test('non-positive maxBars throws in release too', () {
    final c = ChartController();
    expect(() => c.maxBars = 0, throwsArgumentError);
    expect(() => c.maxBars = -1, throwsArgumentError);
    expect(c.maxBars, isNull);
    c.dispose();
  });

  test('clears the crosshair when its selected bar is trimmed', () {
    final all = walk(300);
    final c = ChartController()..maxBars = 100;
    c.setBars(all.sublist(0, 100));
    c.crosshair.value = CrosshairState(time: all[10].time, position: Offset.zero);
    c.appendBar(all[100]);
    expect(c.crosshair.value, isNotNull);
    for (var i = 101; i < 111; i++) {
      c.appendBar(all[i]);
    }
    expect(c.crosshair.value, isNull);
    c.dispose();
  });

  test('setBars over the cap keeps only the newest', () {
    final all = walk(500);
    final c = ChartController()..maxBars = 100;
    c.setBars(all);
    expect(c.bars.length, 100);
    expect(c.bars.first.time, all[400].time);
    c.dispose();
  });

  test('prepend only fills free slots; nothing is inserted once at the cap', () {
    final all = walk(300);
    final c = ChartController()..maxBars = 100;
    c.setBars(all.sublist(200));
    c.prependHistory(all.sublist(150, 200));
    expect(c.bars.length, 100);
    expect(c.bars.first.time, all[200].time);

    final d = ChartController()..maxBars = 100;
    d.setBars(all.sublist(240));
    d.prependHistory(all.sublist(100, 240));
    expect(d.bars.length, 100);
    // What remains is the part adjacent to existing data, not the oldest
    expect(d.bars.first.time, all[200].time);
    c.dispose();
    d.dispose();
  });

  test('lowering maxBars trims immediately', () {
    final c = ChartController()..setBars(walk(300));
    c.maxBars = 120;
    expect(c.bars.length, 120);
    c.dispose();
  });

  test('indicator values of the remaining part match the untrimmed ones', () {
    final all = walk(400);
    final capped = ChartController(indicators: [Ma(), Macd(), Rsi()])..maxBars = 200;
    final full = ChartController(indicators: [Ma(), Macd(), Rsi()]);
    capped.setBars(all.sublist(0, 200));
    full.setBars(all.sublist(0, 200));
    for (var i = 200; i < 400; i++) {
      capped.appendBar(all[i]);
      full.appendBar(all[i]);
    }
    expect(capped.bars.length, 200);
    final offset = full.bars.length - capped.bars.length;
    for (final ind in capped.indicators.list) {
      for (final i in [0, capped.bars.length ~/ 2, capped.bars.length - 1]) {
        final a = capped.storeOf(ind).valuesAt(i);
        final b = full
            .storeOf(full.indicators.list.firstWhere((e) => e.id == ind.id))
            .valuesAt(
              i + offset,
            );
        for (final k in b.keys) {
          final x = a[k]!, y = b[k]!;
          if (x.isNaN || y.isNaN) {
            expect(x.isNaN, y.isNaN, reason: '${ind.id}.$k @ $i');
          } else {
            expect(x, closeTo(y, 1e-9), reason: '${ind.id}.$k @ $i');
          }
        }
      }
    }
    capped.dispose();
    full.dispose();
  });

  test('viewport shifts left when all trimmed bars are off-screen; visible bars unchanged', () {
    final all = walk(600);
    final c = ChartController()..maxBars = 300;
    c.viewport.attach(400);
    c.setBars(all.sublist(0, 300));
    c.viewport.scroll(200);
    int rightTime() => c.bars[c.viewport.rightIndex.round().clamp(0, c.bars.length - 1)].time;
    final before = rightTime();
    for (var i = 300; i < 364; i++) {
      c.appendBar(all[i]);
    }
    expect(c.bars.length, 300);
    expect(rightTime(), before);
    c.dispose();
  });

  test('trim mid background compute: result discarded, recomputed on trimmed data', () async {
    final all = walk(3000);
    final bg = ChartController(indicators: [Ma(), Macd()]);
    bg.setBars(all);
    bg.maxBars = 1000;
    for (var i = 0; i < 400 && bg.computing.value; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    expect(bg.computing.value, isFalse);
    final ref = ChartController(indicators: [Ma(), Macd()])
      ..asyncCompute = false
      ..setBars(all.sublist(2000));
    expect(bg.bars.length, ref.bars.length);
    for (final ind in ref.indicators.list) {
      final a = bg.storeOf(ind).valuesAt(999), b = ref.storeOf(ind).valuesAt(999);
      for (final k in b.keys) {
        expect(a[k], closeTo(b[k]!, 1e-9), reason: '${ind.id}.$k');
      }
    }
    bg.dispose();
    ref.dispose();
  });
}
