import 'package:EyeTimer/providers/photo_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:provider/provider.dart';
import 'providers/dark_mode_notifier.dart';
import 'eye_timer_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  final darkModeNotifier = DarkModeNotifier();
  await darkModeNotifier.initialize();

  // Initialize foreground task
  FlutterForegroundTask.init(
    androidNotificationOptions: AndroidNotificationOptions(
      channelId: 'timer_channel',
      channelName: 'Timer Notifications',
      channelDescription: 'Timer notification channel',
      channelImportance: NotificationChannelImportance.HIGH,
      priority: NotificationPriority.HIGH,
      showBadge: true,
      showWhen: true,
      playSound: false,
      onlyAlertOnce: true,
    ),
    iosNotificationOptions: const IOSNotificationOptions(
      showNotification: true,
      playSound: false,
    ),
    foregroundTaskOptions: ForegroundTaskOptions(
      autoRunOnBoot: false,
      allowWifiLock: true,
      eventAction: ForegroundTaskEventAction.repeat(1000),
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
        ],
        child: EyeTimerApp(),
      ),
    ),
  );
}
