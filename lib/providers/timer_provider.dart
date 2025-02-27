import 'dart:async';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../timer_notification.dart';

class TimerProvider extends ChangeNotifier {
  static const String focusDurationMinutesKey = 'focusDuration_minutes';
  static const String focusDurationSecondsKey = 'focusDuration_seconds';
  static const String breakDurationMinutesKey = 'breakDuration_minutes';
  static const String breakDurationSecondsKey = 'breakDuration_seconds';

  // 타이머 상태 저장용 키
  static const String timerEndTimeKey = 'timer_end_time';
  static const String timerIsFocusModeKey = 'timer_is_focus_mode';
  static const String timerPausedKey = 'timer_paused';
  static const String timerRemainingDurationKey = 'timer_remaining_duration';

  Duration focusDuration = const Duration(minutes: 20);
  Duration breakDuration = const Duration(minutes: 5);
  late Duration currentDuration = focusDuration;

  bool isTimerRunning = false;
  bool isPaused = false;
  bool isFocusMode = true;
  Timer? _timer;

  TimerProvider() {
    loadDurations();
  }

  Future<void> loadDurations() async {
    final prefs = await SharedPreferences.getInstance();
    final focusMinutes = prefs.getInt(focusDurationMinutesKey) ?? 20;
    final focusSeconds = prefs.getInt(focusDurationSecondsKey) ?? 0;
    focusDuration = Duration(minutes: focusMinutes, seconds: focusSeconds);
    final breakMinutes = prefs.getInt(breakDurationMinutesKey) ?? 5;
    final breakSeconds = prefs.getInt(breakDurationSecondsKey) ?? 0;
    breakDuration = Duration(minutes: breakMinutes, seconds: breakSeconds);

    // 타이머 상태 복원
    final timerEndTimeMillis = prefs.getInt(timerEndTimeKey);
    final paused = prefs.getBool(timerPausedKey) ?? false;
    if (timerEndTimeMillis != null) {
      if (paused) {
        // 일시정지 상태라면 저장된 남은 시간을 사용
        final remainingSeconds = prefs.getInt(timerRemainingDurationKey) ?? focusDuration.inSeconds;
        currentDuration = Duration(seconds: remainingSeconds);
        isTimerRunning = true;
        isPaused = true;
        // 타이머는 일시정지 상태이므로 periodic timer는 시작하지 않음.
      } else {
        // 실행 중인 경우, 남은 시간을 계산
        final endTime = DateTime.fromMillisecondsSinceEpoch(timerEndTimeMillis);
        final remaining = endTime.difference(DateTime.now());
        if (remaining > Duration.zero) {
          currentDuration = remaining;
          isTimerRunning = true;
          isPaused = false;
          _startPeriodicTimer();
        } else {
          currentDuration = focusDuration;
          isTimerRunning = false;
        }
      }
      isFocusMode = prefs.getBool(timerIsFocusModeKey) ?? true;
    } else {
      currentDuration = focusDuration;
      isTimerRunning = false;
    }
    notifyListeners();
  }

  Future<void> saveDurations() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(focusDurationMinutesKey, focusDuration.inMinutes);
    await prefs.setInt(focusDurationSecondsKey, focusDuration.inSeconds % 60);
    await prefs.setInt(breakDurationMinutesKey, breakDuration.inMinutes);
    await prefs.setInt(breakDurationSecondsKey, breakDuration.inSeconds % 60);
  }

  String _getNotificationMessage(Duration duration, {required bool isFocusMode}) {
    final minutes = duration.inMinutes.toString();
    final seconds = (duration.inSeconds % 60).toString();
    String key;
    if (isFocusMode) {
      key = int.parse(seconds) > 0
          ? 'notification_template_with_seconds'
          : 'notification_template_without_seconds';
    } else {
      key = int.parse(seconds) > 0
          ? 'break_notification_template_with_seconds'
          : 'break_notification_template_without_seconds';
    }
    return int.parse(seconds) > 0
        ? key.tr(namedArgs: {'minutes': minutes, 'seconds': seconds})
        : key.tr(namedArgs: {'minutes': minutes});
  }

  // 타이머 시작 시 종료 시각을 저장하고 주기적 타이머를 시작합니다.
  Future<void> startTimer() async {
    if (isTimerRunning) return;

    final title = isFocusMode ? 'focus_title'.tr() : 'break_title'.tr();
    final message = _getNotificationMessage(currentDuration, isFocusMode: isFocusMode);
    final prefs = await SharedPreferences.getInstance();
    final whiteNoiseAsset = prefs.getString('white_noise_asset') ?? '';
    Future.microtask(() => TimerNotification.startTimer(title, message, whiteNoiseAsset: whiteNoiseAsset));

    isTimerRunning = true;
    isPaused = false;

    // 종료 시각 저장: 현재 남은 시간만큼 더한 시각
    final endTime = DateTime.now().add(currentDuration);
    await prefs.setInt(timerEndTimeKey, endTime.millisecondsSinceEpoch);
    await prefs.setBool(timerIsFocusModeKey, isFocusMode);
    await prefs.setBool(timerPausedKey, false);

    _startPeriodicTimer();
    notifyListeners();
  }

  // 주기적 타이머 실행 (startTimer와 실행 복원 시 호출)
  void _startPeriodicTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (isTimerRunning && !isPaused) {
        if (currentDuration.inSeconds > 0) {
          currentDuration -= const Duration(seconds: 1);
          final title = isFocusMode ? 'focus_title'.tr() : 'break_title'.tr();
          final message = _getNotificationMessage(currentDuration, isFocusMode: isFocusMode);
          Future.microtask(() => TimerNotification.updateTimer(title, message));

          // 업데이트된 종료 시각 저장 (앱 복원을 위해)
          final prefs = await SharedPreferences.getInstance();
          final newEndTime = DateTime.now().add(currentDuration);
          await prefs.setInt(timerEndTimeKey, newEndTime.millisecondsSinceEpoch);
        } else {
          // 타이머 완료 후 모드 전환
          isFocusMode = !isFocusMode;
          currentDuration = isFocusMode ? focusDuration : breakDuration;
          final title = isFocusMode ? 'focus_title'.tr() : 'break_title'.tr();
          final message = _getNotificationMessage(currentDuration, isFocusMode: isFocusMode);
          Future.microtask(() => TimerNotification.switchTimer(title, message));

          // 전환 후 새로운 종료 시각 저장
          final prefs = await SharedPreferences.getInstance();
          final newEndTime = DateTime.now().add(currentDuration);
          await prefs.setInt(timerEndTimeKey, newEndTime.millisecondsSinceEpoch);
          await prefs.setBool(timerIsFocusModeKey, isFocusMode);
        }
        notifyListeners();
      }
    });
  }

  void pauseTimer() async {
    if (!isTimerRunning || isPaused) return;
    isPaused = true;
    final title = 'pause_title'.tr();
    final message = _getNotificationMessage(currentDuration, isFocusMode: isFocusMode);
    Future.microtask(() => TimerNotification.pauseTimer(title, message));

    // 타이머 일시정지 상태와 남은 시간을 저장
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(timerPausedKey, true);
    await prefs.setInt(timerRemainingDurationKey, currentDuration.inSeconds);
    // 일시정지 시에는 종료 시각 업데이트 중지

    notifyListeners();
  }

  void resumeTimer() async {
    if (!isTimerRunning || !isPaused) return;
    isPaused = false;
    final title = isFocusMode ? 'focus_title'.tr() : 'break_title'.tr();
    final message = _getNotificationMessage(currentDuration, isFocusMode: isFocusMode);
    Future.microtask(() => TimerNotification.resumeTimer(title, message));

    // 재개 시 새로운 종료 시각 계산 및 저장
    final prefs = await SharedPreferences.getInstance();
    final newEndTime = DateTime.now().add(currentDuration);
    await prefs.setInt(timerEndTimeKey, newEndTime.millisecondsSinceEpoch);
    await prefs.setBool(timerPausedKey, false);
    await prefs.remove(timerRemainingDurationKey);

    // 일시정지 상태에서 재개하면 주기적 타이머 시작
    _startPeriodicTimer();
    notifyListeners();
  }

  void stopTimer() async {
    if (!isTimerRunning) return;
    Future.microtask(() => TimerNotification.endTimer());
    _timer?.cancel();
    _timer = null;
    isTimerRunning = false;
    isPaused = false;
    isFocusMode = true;
    currentDuration = focusDuration;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(timerEndTimeKey);
    await prefs.remove(timerIsFocusModeKey);
    await prefs.remove(timerPausedKey);
    await prefs.remove(timerRemainingDurationKey);
    notifyListeners();
  }
}
