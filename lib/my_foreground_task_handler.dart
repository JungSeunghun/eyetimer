// my_foreground_task_handler.dart
import 'dart:async';
import 'dart:isolate';
import 'dart:ui';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class MyForegroundTaskHandler extends TaskHandler {
  Duration currentDuration = Duration();
  Duration focusDuration = const Duration(minutes: 20);
  Duration breakDuration = const Duration(minutes: 5);
  bool isFocusMode = true;
  bool isPaused = false;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    // SharedPreferences에서 타이머 설정 불러오기
    final prefs = await SharedPreferences.getInstance();
    final focusMinutes = prefs.getInt('focusDuration_minutes') ?? 20;
    final focusSeconds = prefs.getInt('focusDuration_seconds') ?? 0;
    focusDuration = Duration(minutes: focusMinutes, seconds: focusSeconds);
    final breakMinutes = prefs.getInt('breakDuration_minutes') ?? 5;
    final breakSeconds = prefs.getInt('breakDuration_seconds') ?? 0;
    breakDuration = Duration(minutes: breakMinutes, seconds: breakSeconds);

    currentDuration = focusDuration;
    _playSoundNotification();
    _updateNotification();
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    if (!isPaused) {
      if (currentDuration > Duration(seconds: 0)) {
        // 시간이 남아있으면 초 단위로 차감
        currentDuration -= Duration(seconds: 1);
      } else {
        // 타이머 종료 시, 먼저 모드 전환 알림 소리 재생
        _playSoundNotification();
        // 모드 전환 및 해당 모드의 설정 시간으로 재설정
        isFocusMode = !isFocusMode;
        currentDuration = isFocusMode ? focusDuration : breakDuration;
      }

      _updateNotification();

      // UI로 남은 시간(초) 전송 (예: IsolateNameServer를 통한 전송)
      final sendPort = IsolateNameServer.lookupPortByName("timer_port");
      sendPort?.send(currentDuration.inSeconds);
    }
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    // 서비스 종료 시 별도 처리가 필요하면 추가합니다.
  }

  @override
  void onReceiveData(Object data) {
    if (data is String) {
      switch (data) {
        case 'pause':
          isPaused = true;
          _updateNotification(
            title: '일시정지',
            body: '현재 타이머가 일시정지 상태입니다.',
          );
          break;
        case 'resume':
          isPaused = false;
          _updateNotification();
          break;
        case 'stop':
          isPaused = false;
          isFocusMode = true;
          currentDuration = focusDuration;
          // FlutterForegroundTask의 내장 기능으로 서비스 종료 시 알림을 자동 처리합니다.
          break;
      }
    }
  }

  @override
  void onNotificationButtonPressed(String id) {}

  @override
  void onNotificationPressed() {}

  @override
  void onNotificationDismissed() {}

  /// _updateNotification: FlutterForegroundTask의 내장 알림 업데이트 기능 사용
  Future<void> _updateNotification({
    String? title,
    String? body,
  }) async {
    final notificationTitle = title ?? (isFocusMode ? '집중 시간' : '휴식 시간');
    final minutes = currentDuration.inMinutes;
    final seconds = currentDuration.inSeconds % 60;
    final notificationText = body ??
        (isFocusMode
            ? (seconds > 0
            ? '$minutes분 $seconds초 뒤, 눈이 편히 쉬도록 알려드릴게요.'
            : '$minutes분 뒤, 눈이 편히 쉬도록 알려드릴게요.')
            : (seconds > 0
            ? '$minutes분 $seconds초 동안 먼 곳을 바라보며 눈에 휴식을 선물하세요.'
            : '$minutes분 동안 먼 곳을 바라보며 눈에 휴식을 선물하세요.'));

    FlutterForegroundTask.updateService(
      notificationTitle: notificationTitle,
      notificationText: notificationText,
    );
  }

  /// _playSoundNotification: 모드 전환 시 단발성 소리 알림을 재생 (flutter_local_notifications 사용)
  Future<void> _playSoundNotification() async {
    final localNotifications = FlutterLocalNotificationsPlugin();

    // Android 초기화 설정
    const androidSettings = AndroidInitializationSettings('mipmap/launcher_icon');
    // iOS 초기화 설정: 알림 권한 요청 및 기본 옵션 지정
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await localNotifications.initialize(initializationSettings);

    // Android 알림 세부 설정 (autoCancel: true로 설정)
    const androidDetails = AndroidNotificationDetails(
      'mode_switch_channel',
      'Mode Switch Notifications',
      channelDescription: '모드 전환 시 재생되는 알림',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      autoCancel: true,
      // 커스텀 사운드 사용 시: sound: RawResourceAndroidNotificationSound('alert'),
    );
    // iOS 알림 세부 설정
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      // 커스텀 사운드를 사용하려면 sound 인자를 설정 (예: 'alert.aiff')
    );
    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // 알림 ID는 foreground 서비스 알림과 별개로 관리 (여기서는 1번 사용)
    await localNotifications.show(
      1,
      isFocusMode ? '집중 시간' : '휴식 시간',
      isFocusMode ? '집중 시간이 시작되었습니다.' : '휴식 시간이 시작되었습니다.',
      notificationDetails,
    );

    // 알림이 뜬 후 5초 뒤에 자동으로 취소 (iOS는 직접 취소 필요)
    Future.delayed(const Duration(seconds: 1), () async {
      await localNotifications.cancel(1);
    });
  }
}
