import 'package:EyeTimer/providers/photo_provider.dart';
import 'package:EyeTimer/providers/timer_provider.dart';
import 'package:audio_service/audio_service.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz;

import 'audio_player_task.dart';
import 'providers/dark_mode_notifier.dart';
import 'eye_timer_app.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

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

  InitializationSettings settings = InitializationSettings(android: android, iOS: ios);
  await flutterLocalNotificationsPlugin.initialize(settings);

  final audioHandler = await AudioService.init(
    builder: () => MyAudioHandler(),
    config: AudioServiceConfig(
      androidNotificationChannelId: 'white_noise_channel',
      androidNotificationChannelName: 'White Noise',
      androidNotificationChannelDescription: 'White noise playback service',
      androidNotificationIcon: 'mipmap/launcher_icon',
      androidNotificationOngoing: true,
    ),
  );

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('ko')],
      path: 'assets/translations', // 번역 파일 위치
      fallbackLocale: const Locale('en'),
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => darkModeNotifier),
          ChangeNotifierProvider(create: (_) => PhotoProvider()),
          ChangeNotifierProvider(create: (_) {
            final timerProvider = TimerProvider();
            timerProvider.setAudioHandler(audioHandler);
            return timerProvider;
          }),
          // AudioHandler를 전역으로 사용하기 위해 Provider에 등록합니다.
          Provider<MyAudioHandler>.value(value: audioHandler),
        ],
        child: EyeTimerApp(),
      ),
    ),
  );
}
