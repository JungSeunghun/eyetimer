import 'package:flutter/services.dart';

class TimerNotification {
  static const MethodChannel _channel =
  MethodChannel('com.eyetimer.timerActivity');

  /// 타이머 알림 시작: title과 message를 전달합니다.
  static Future<void> startTimer(String title, String message) async {
    try {
      await _channel.invokeMethod('startTimer', {
        'title': title,
        'message': message,
      });
    } catch (e) {
      print("Error starting timer: $e");
    }
  }

  /// 타이머 알림 업데이트: title과 message를 전달합니다.
  static Future<void> updateTimer(String title, String message) async {
    try {
      await _channel.invokeMethod('updateTimer', {
        'title': title,
        'message': message,
      });
    } catch (e) {
      print("Error updating timer: $e");
    }
  }

  /// 타이머 알림 종료
  static Future<void> endTimer() async {
    try {
      await _channel.invokeMethod('endTimer');
    } catch (e) {
      print("Error ending timer: $e");
    }
  }

  /// 타이머 일시정지: title과 message를 전달합니다.
  static Future<void> pauseTimer(String title, String message) async {
    try {
      await _channel.invokeMethod('pauseTimer', {
        'title': title,
        'message': message,
      });
    } catch (e) {
      print("Error pausing timer: $e");
    }
  }

  /// 타이머 재개: title과 message를 전달합니다.
  static Future<void> resumeTimer(String title, String message) async {
    try {
      await _channel.invokeMethod('resumeTimer', {
        'title': title,
        'message': message,
      });
    } catch (e) {
      print("Error resuming timer: $e");
    }
  }

  /// 타이머 모드 전환 시: 소리와 진동이 포함된 알림 호출
  static Future<void> switchTimer(String title, String message) async {
    try {
      await _channel.invokeMethod('switchTimer', {
        'title': title,
        'message': message,
      });
    } catch (e) {
      print("Error switching timer: $e");
    }
  }
}
