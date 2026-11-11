import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klinex/klinex.dart';

void main() {
  tearDown(KlinexDebug.disableAll);

  test('all diagnostic flags off by default', () {
    expect(KlinexDebug.logPaint, isFalse);
    expect(KlinexDebug.logChannel, isFalse);
    expect(KlinexDebug.logGesture, isFalse);
    expect(KlinexDebug.logRebuild, isFalse);
    expect(KlinexDebug.logData, isFalse);
    expect(KlinexDebug.anyEnabled, isFalse);
  });

  test('available is the compile-time master switch, always false in release', () {
    // Tests run in debug, so this can only lock in "the switch follows kReleaseMode".
    expect(KlinexDebug.available, !kReleaseMode);
  });

  test('enableAll has no effect while the master switch is off', () {
    KlinexDebug.enableAll();
    // Only turns on when the master switch is on (debug); when off it still reads back false.
    expect(KlinexDebug.logPaint, KlinexDebug.available);
    expect(KlinexDebug.anyEnabled, KlinexDebug.available);
  });

  test('no output after disableAll', () {
    final lines = <String>[];
    final prev = KlinexDebug.sink;
    KlinexDebug.sink = lines.add;
    addTearDown(() => KlinexDebug.sink = prev);

    KlinexDebug.disableAll();
    if (KlinexDebug.logPaint) KlinexDebug.paint('L1', 100);
    KlinexDebug.mark('段');
    KlinexDebug.dumpCounters();
    expect(lines, isEmpty, reason: 'after disabling, mark/dumpCounters must also stay silent');
  });
}
