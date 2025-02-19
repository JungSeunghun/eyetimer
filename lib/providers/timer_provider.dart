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
    currentDuration = focusDuration;
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

  // 타이머 시작 (화이트노이즈 관련 호출 제거)
  Future<void> startTimer() async {
    if (isTimerRunning) return;

    final title = isFocusMode ? 'focus_title'.tr() : 'break_title'.tr();
    final message = _getNotificationMessage(currentDuration, isFocusMode: isFocusMode);
    final prefs = await SharedPreferences.getInstance();
    final whiteNoiseAsset = prefs.getString('white_noise_asset') ?? '';
    Future.microtask(() => TimerNotification.startTimer(title, message, whiteNoiseAsset: whiteNoiseAsset));
    isTimerRunning = true;
    isPaused = false;
    notifyListeners();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (isTimerRunning && !isPaused) {
        if (currentDuration.inSeconds > 0) {
          currentDuration -= const Duration(seconds: 1);
          final title = isFocusMode ? 'focus_title'.tr() : 'break_title'.tr();
          final message = _getNotificationMessage(currentDuration, isFocusMode: isFocusMode);
          Future.microtask(() => TimerNotification.updateTimer(title, message));
        } else {
          isFocusMode = !isFocusMode;
          currentDuration = isFocusMode ? focusDuration : breakDuration;
          final title = isFocusMode ? 'focus_title'.tr() : 'break_title'.tr();
          final message = _getNotificationMessage(currentDuration, isFocusMode: isFocusMode);
          Future.microtask(() => TimerNotification.switchTimer(title, message));
        }
        notifyListeners();
      }
    });
  }

  void pauseTimer() {
    if (!isTimerRunning || isPaused) return;
    isPaused = true;
    final title = 'pause_title'.tr();
    final message = _getNotificationMessage(currentDuration, isFocusMode: isFocusMode);
    Future.microtask(() => TimerNotification.pauseTimer(title, message));
    notifyListeners();
  }

  void resumeTimer() {
    if (!isTimerRunning || !isPaused) return;
    isPaused = false;
    final title = isFocusMode ? 'focus_title'.tr() : 'break_title'.tr();
    final message = _getNotificationMessage(currentDuration, isFocusMode: isFocusMode);
    Future.microtask(() => TimerNotification.resumeTimer(title, message));
    notifyListeners();
  }

  void stopTimer() {
    if (!isTimerRunning) return;
    Future.microtask(() => TimerNotification.endTimer());
    _timer?.cancel();
    _timer = null;
    isTimerRunning = false;
    isPaused = false;
    isFocusMode = true;
    currentDuration = focusDuration;
    notifyListeners();
  }
}
