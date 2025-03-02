import 'package:EyeTimer/providers/photo_provider.dart';
import 'package:EyeTimer/providers/timer_provider.dart';
import 'package:EyeTimer/timer_notification.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_timezone/flutter_timezone.dart'; // flutter_timezone 별칭 그대로 사용
import 'package:timezone/data/latest.dart' as tz; // 시간대 데이터 초기화용
import 'package:timezone/timezone.dart' as tz; // 시간대 관련 함수 사용
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart'; // permission_handler 추가

import 'providers/dark_mode_notifier.dart';
import 'eye_timer_app.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

// 전역 TimerProvider 인스턴스 생성
final TimerProvider timerProvider = TimerProvider();

/// 알림 권한을 요청하는 함수 (permission_handler 사용)
Future<void> _requestNotificationPermission() async {
  // Android 13 이상에서는 알림 권한을 별도로 요청해야 함
  PermissionStatus status = await Permission.notification.status;
  if (!status.isGranted) {
    await Permission.notification.request();
  }
  // Android 12(API 31) 이상에서 정확한 알람(SCHEDULE_EXACT_ALARM) 권한은
  // AndroidManifest.xml에 선언 후, 필요시 사용자가 앱 설정에서 직접 허용해야 합니다.
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  final darkModeNotifier = DarkModeNotifier();
  await darkModeNotifier.initialize();
  MobileAds.instance.initialize();

  // 시간대 초기화
  tz.initializeTimeZones();
  final String timeZoneName = await FlutterTimezone.getLocalTimezone();
  tz.setLocalLocation(tz.getLocation(timeZoneName));

  // permission_handler로 알림 권한 요청
  await _requestNotificationPermission();

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
