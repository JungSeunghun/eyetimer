// timer_provider.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as path;
import '../../../timer_notification.dart';
import '../audio_player_task.dart';

// TimerProvider는 타이머, 화이트노이즈, 알림 업데이트 관련 상태와 로직을 관리합니다.
class TimerProvider extends ChangeNotifier {
  // SharedPreferences 키
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

  // 외부 의존성: 화이트노이즈 제어를 위한 AudioHandler
  MyAudioHandler? audioHandler;

  // 생성자 또는 setter를 통해 audioHandler를 설정할 수 있음
  void setAudioHandler(MyAudioHandler handler) {
    audioHandler = handler;
  }

  // 생성자에서 loadDurations 호출
  TimerProvider() {
    loadDurations();
  }

  // SharedPreferences에서 지속시간을 불러오는 메서드
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

  // 지속시간을 SharedPreferences에 저장하는 메서드
  Future<void> saveDurations() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(focusDurationMinutesKey, focusDuration.inMinutes);
    await prefs.setInt(focusDurationSecondsKey, focusDuration.inSeconds % 60);
    await prefs.setInt(breakDurationMinutesKey, breakDuration.inMinutes);
    await prefs.setInt(breakDurationSecondsKey, breakDuration.inSeconds % 60);
  }

  // 알림 메시지 생성 (easy_localization 적용)
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

  // 화이트노이즈 재생
  Future<void> playWhiteNoise() async {
    if (audioHandler == null) return;
    final prefs = await SharedPreferences.getInstance();
    final asset = prefs.getString('white_noise_asset') ?? '';
    if (asset.isNotEmpty) {
      final fileName = path.basename(asset);
      final baseName = path.basenameWithoutExtension(fileName).toLowerCase();
      String localizedTitle;
      switch (baseName) {
        case 'rain':
          localizedTitle = 'white_noise_rain'.tr();
          break;
        case 'ocean':
          localizedTitle = 'white_noise_ocean'.tr();
          break;
        case 'wind':
          localizedTitle = 'white_noise_wind'.tr();
          break;
        default:
          localizedTitle = baseName;
          break;
      }
      final mediaItem = MediaItem(
        id: asset,
        album: 'White Noise',
        title: localizedTitle,
      );
      await audioHandler!.updateMediaItem(mediaItem);
      await audioHandler!.play();
    }
  }

  Future<void> pauseWhiteNoise() async {
    if (audioHandler == null) return;
    final prefs = await SharedPreferences.getInstance();
    final asset = prefs.getString('white_noise_asset') ?? '';
    if (asset.isNotEmpty) {
      await audioHandler!.pause();
    }
  }

  Future<void> resumeWhiteNoise() async {
    if (audioHandler == null) return;
    final prefs = await SharedPreferences.getInstance();
    final asset = prefs.getString('white_noise_asset') ?? '';
    if (asset.isNotEmpty) {
      await audioHandler!.play();
    }
  }

  Future<void> stopWhiteNoise() async {
    if (audioHandler == null) return;
    final prefs = await SharedPreferences.getInstance();
    final asset = prefs.getString('white_noise_asset') ?? '';
    if (asset.isNotEmpty) {
      await audioHandler!.stop();
    }
  }

  // 타이머 시작 (알림 및 화이트노이즈 재생 포함)
  void startTimer() {
    if (isTimerRunning) return;
    // 타이머 알림 시작
    final title = isFocusMode ? 'focus_title'.tr() : 'break_title'.tr();
    final message = _getNotificationMessage(currentDuration, isFocusMode: isFocusMode);
    // 알림 시작은 별도 Future에서 처리
    Future.microtask(() => TimerNotification.startTimer(title, message));
    // 화이트노이즈 재생
    playWhiteNoise();
    isTimerRunning = true;
    isPaused = false;
    notifyListeners();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (isTimerRunning && !isPaused) {
        if (currentDuration.inSeconds > 0) {
          currentDuration -= const Duration(seconds: 1);
          _updateTimerNotification();
        } else {
          // 모드 전환
          isFocusMode = !isFocusMode;
          currentDuration = isFocusMode ? focusDuration : breakDuration;
          final title = isFocusMode ? 'focus_title'.tr() : 'break_title'.tr();
          final message = _getNotificationMessage(currentDuration, isFocusMode: isFocusMode);
          TimerNotification.switchTimer(title, message);
        }
        notifyListeners();
      }
    });
  }

  void _updateTimerNotification() {
    if (!isTimerRunning || isPaused) return;
    final title = isFocusMode ? 'focus_title'.tr() : 'break_title'.tr();
    final message = _getNotificationMessage(currentDuration, isFocusMode: isFocusMode);
    Future.microtask(() => TimerNotification.updateTimer(title, message));
  }

  void pauseTimer() {
    if (!isTimerRunning || isPaused) return;
    isPaused = true;
    final title = 'pause_title'.tr();
    final message = _getNotificationMessage(currentDuration, isFocusMode: isFocusMode);
    Future.microtask(() => TimerNotification.pauseTimer(title, message));
    pauseWhiteNoise();
    notifyListeners();
  }

  void resumeTimer() {
    if (!isTimerRunning || !isPaused) return;
    isPaused = false;
    final title = 'resume_title'.tr();
    final message = 'timer_resumed'.tr();
    Future.microtask(() => TimerNotification.resumeTimer(title, message));
    resumeWhiteNoise();
    notifyListeners();
  }

  void stopTimer() {
    if (!isTimerRunning) return;
    Future.microtask(() => TimerNotification.endTimer());
    _timer?.cancel();
    _timer = null;
    stopWhiteNoise();
    isTimerRunning = false;
    isPaused = false;
    isFocusMode = true;
    currentDuration = focusDuration;
    notifyListeners();
  }
}
