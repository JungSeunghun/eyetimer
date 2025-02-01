import 'package:EyeTimer/providers/photo_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:provider/provider.dart';
import 'my_foreground_task_handler.dart';
import 'providers/dark_mode_notifier.dart';
import 'eye_timer_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
    ),
    iosNotificationOptions: const IOSNotificationOptions(
      showNotification: true,
      playSound: true,
    ),
    foregroundTaskOptions: ForegroundTaskOptions(
      autoRunOnBoot: false,
      allowWifiLock: true,
      eventAction: ForegroundTaskEventAction.repeat(1000),
    ),
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => darkModeNotifier),
        ChangeNotifierProvider(create: (_) => PhotoProvider()),
      ],
      child: EyeTimerApp(),
    ),
  );
}

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(MyForegroundTaskHandler());
}

