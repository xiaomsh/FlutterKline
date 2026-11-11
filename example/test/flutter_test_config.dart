import 'dart:async';

import 'package:klinex_example/l10n/l10n.dart';

/// Every test reads strings through `S.current`, which only exists after a language is loaded.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  await S.load(AppLanguage.english);
  await testMain();
}
