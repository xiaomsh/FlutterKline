import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:klinex_example/l10n/l10n.dart';
import 'package:klinex_example/main.dart';

Map<String, dynamic> _arb(String name) =>
    jsonDecode(File('lib/l10n/$name').readAsStringSync()) as Map<String, dynamic>;

/// Message keys of an ARB file, without `@@locale` and `@key` metadata entries.
Set<String> _keys(Map<String, dynamic> arb) => arb.keys.where((k) => !k.startsWith('@')).toSet();

/// `Get.updateLocale` reassembles the app and runs its own warm-up frame. Tapping inside
/// `runAsync` keeps that frame from starting inside the fake-async microtask flush of a pump.
Future<void> _switchLanguage(WidgetTester tester, String label) async {
  await tester.runAsync(() => tester.tap(find.text(label)));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('home page defaults to English and the switch toggles Chinese and back', (
    tester,
  ) async {
    Get.testMode = true;
    addTearDown(() async {
      Get.locale = AppLanguage.english;
      Get.reset();
      await S.load(AppLanguage.english);
    });
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    final english = (
      homeSamples: S.current.homeSamples,
      homeLive: S.current.homeLive,
      language: S.current.language,
    );
    expect(AppLanguage.isChinese, isFalse);
    expect(find.text(english.homeSamples), findsOneWidget);
    expect(find.text(english.homeLive), findsOneWidget);
    expect(find.text(english.language), findsOneWidget);

    await _switchLanguage(tester, english.language);
    expect(AppLanguage.isChinese, isTrue);
    expect(find.text('配置大全'), findsOneWidget);
    expect(find.text('实时行情'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(find.text(english.homeSamples), findsNothing);
    expect(S.current.homeSamples, '配置大全');

    await _switchLanguage(tester, 'English');
    expect(AppLanguage.isChinese, isFalse);
    expect(find.text(english.homeSamples), findsOneWidget);
    expect(find.text(english.homeLive), findsOneWidget);
    expect(find.text(english.language), findsOneWidget);
    expect(find.text('配置大全'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  test('English and Chinese ARB files have the same keys and no empty Chinese value', () {
    final en = _arb('intl_en.arb');
    final zh = _arb('intl_zh.arb');
    expect(en['@@locale'], 'en');
    expect(zh['@@locale'], 'zh');
    final enKeys = _keys(en);
    final zhKeys = _keys(zh);
    expect(enKeys, isNotEmpty);
    expect(zhKeys.difference(enKeys), isEmpty, reason: 'keys only in intl_zh.arb');
    expect(enKeys.difference(zhKeys), isEmpty, reason: 'keys only in intl_en.arb');
    for (final key in zhKeys) {
      final value = zh[key];
      expect(value, isA<String>(), reason: key);
      expect((value as String).trim(), isNotEmpty, reason: key);
    }
  });
}
