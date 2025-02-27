import 'package:EyeTimer/providers/photo_provider.dart';
import 'package:EyeTimer/providers/timer_provider.dart';
import 'package:EyeTimer/timer_notification.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz;

import 'providers/dark_mode_notifier.dart';
import 'eye_timer_app.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

// 전역 TimerProvider 인스턴스 생성
final TimerProvider timerProvider = TimerProvider();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  final darkModeNotifier = DarkModeNotifier();
  await darkModeNotifier.initialize();
  MobileAds.instance.initialize();

  tz.initializeTimeZones();

  AndroidInitializationSettings android =
  const AndroidInitializationSettings("@mipmap/launcher_icon");
  DarwinInitializationSettings ios = const DarwinInitializationSettings(
    requestSoundPermission: true,
    requestBadgePermission: true,
    requestAlertPermission: true,
  );

  InitializationSettings settings =
  InitializationSettings(android: android, iOS: ios);
  await flutterLocalNotificationsPlugin.initialize(settings);

  // 알림 권한 요청 코드 추가
  flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>()
      ?.requestNotificationsPermission();

  TimerNotification.channel.setMethodCallHandler((call) async {
    if (call.method == "onPauseNotification") {
      print("Received onPauseNotification from native");
      timerProvider.pauseTimer();
    } else if (call.method == "onResumeNotification") {
      print("Received onResumeNotification from native");
      timerProvider.resumeTimer();
    }
  });

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('ko')],
      path: 'assets/translations', // 번역 파일 위치
      fallbackLocale: const Locale('en'),
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => darkModeNotifier),
          ChangeNotifierProvider(create: (_) => PhotoProvider()),
          ChangeNotifierProvider<TimerProvider>.value(value: timerProvider),
        ],
        child: EyeTimerApp(),
      ),
    ),
  );
}
