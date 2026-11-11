import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';

import 'http/http_request.dart';
import 'l10n/l10n.dart';
import 'page/home/home_page.dart';
import 'route.dart';
import 'theme/theme_style.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HttpUtils.init();
  await S.load(AppLanguage.english);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      defaultTransition: Transition.cupertino,
      theme: ThemeStyle.lightTheme,
      darkTheme: ThemeStyle.darkTheme,
      themeMode: ThemeMode.light,
      locale: AppLanguage.english,
      fallbackLocale: AppLanguage.english,
      supportedLocales: S.delegate.supportedLocales,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: FlutterSmartDialog.init(),
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        dragDevices: {
          PointerDeviceKind.touch,
          PointerDeviceKind.mouse,
          PointerDeviceKind.trackpad,
        },
      ),
      getPages: pages,
      home: const HomePage(),
    );
  }
}
