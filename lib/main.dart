import 'package:EyeTimer/providers/photo_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';

import 'providers/dark_mode_notifier.dart';
import 'eye_timer_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  final darkModeNotifier = DarkModeNotifier();
  await darkModeNotifier.initialize();

  MobileAds.instance.initialize();

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('ko')],
      path: 'assets/translations', // 번역 파일 위치
      fallbackLocale: const Locale('en'),
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => darkModeNotifier),
          ChangeNotifierProvider(create: (_) => PhotoProvider()),
        ],
        child: EyeTimerApp(),
      ),
    ),
  );
}
