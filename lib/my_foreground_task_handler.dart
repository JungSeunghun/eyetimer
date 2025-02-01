// my_foreground_task_handler.dart
import 'dart:async';
import 'dart:isolate';
import 'dart:ui';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MyForegroundTaskHandler extends TaskHandler {
  Duration currentDuration = Duration();
  Duration focusDuration = const Duration(minutes: 20);
  Duration breakDuration = const Duration(minutes: 5);
  bool isFocusMode = true;
  bool isPaused = false;

  // 첫 업데이트와 모드 전환 여부를 추적하기 위한 변수들
  bool _firstNotification = true;
  bool _lastIsFocusMode = true;

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
    // onStart에서는 알림 업데이트를 하지 않습니다.
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    if (!isPaused) {
      // 시간이 남아있으면 초 단위로 차감
      if (currentDuration > Duration(seconds: 0)) {
        currentDuration -= Duration(seconds: 1);
      } else {
        // 타이머 종료 시 모드 전환 및 해당 모드의 설정 시간으로 재설정
        isFocusMode = !isFocusMode;
        currentDuration = isFocusMode ? focusDuration : breakDuration;
      }

      // onRepeatEvent에서는 기본적으로 silent 조건을 현재 남은 초에 따라 전달하지만,
      // 아래 _updateNotification 내부에서 첫 업데이트 및 모드 전환 시 silent를 false로 처리합니다.
      _updateNotification(silent: currentDuration.inSeconds > 0);

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
            silent: false,
            title: '일시정지',
            body: '현재 타이머가 일시정지 상태입니다.',
          );
          break;
        case 'resume':
          isPaused = false;
          _updateNotification(silent: false);
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
    required bool silent,
    String? title,
    String? body,
  }) async {
    // 첫 업데이트거나 모드가 전환되었으면 silent를 false로 강제
    if (_firstNotification || _lastIsFocusMode != isFocusMode) {
      silent = false;
    }

    final notificationTitle = title ?? (isFocusMode ? '집중 시간' : '쉬는 시간');
    final minutes = currentDuration.inMinutes;
    final seconds = currentDuration.inSeconds % 60;
    final notificationText = body ??
        (isFocusMode
            ? (seconds > 0
            ? '$minutes분 $seconds초 뒤, 눈이 편안해질 수 있도록 알려드릴게요.'
            : '$minutes분 뒤, 눈이 편안해질 수 있도록 알려드릴게요.')
            : (seconds > 0
            ? '$minutes분 $seconds초 동안 창밖을 바라보며 마음과 눈에 휴식을 선물하세요.'
            : '$minutes분 동안 창밖을 바라보며 마음과 눈에 휴식을 선물하세요.'));

    // FlutterForegroundTask의 내장 알림 업데이트 함수 사용
    FlutterForegroundTask.updateService(
      notificationTitle: notificationTitle,
      notificationText: notificationText,
      // silent 옵션에 따라 playSound를 제어할 수 있다면 여기서 처리합니다.
      // playSound: !silent,
    );

    // 업데이트 후 상태값 저장
    _firstNotification = false;
    _lastIsFocusMode = isFocusMode;
  }
}
