// my_foreground_task_handler.dart
import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class MyForegroundTaskHandler extends TaskHandler {
  Duration currentDuration = Duration();
  Duration focusDuration = const Duration(minutes: 20);
  Duration breakDuration = const Duration(minutes: 5);
  bool isFocusMode = true;
  bool isPaused = false;

  // Locale code obtained from the system locale.
  late String localeCode;

  // Translation map loaded from assets
  Map<String, dynamic> _translationMap = {};

  /// Loads the translation JSON file from assets based on the system locale.
  Future<void> _loadTranslations() async {
    try {
      final jsonString = await rootBundle.loadString('assets/translations/$localeCode.json');
      _translationMap = json.decode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      // Fallback: use an empty map if loading fails.
      _translationMap = {};
    }
  }

  /// A simple translation helper function.
  /// It replaces named arguments in the form {key} with their corresponding values.
  String tr(String key, {Map<String, String>? namedArgs}) {
    var value = _translationMap[key]?.toString() ?? key;
    if (namedArgs != null) {
      namedArgs.forEach((k, v) {
        value = value.replaceAll('{$k}', v);
      });
    }
    return value;
  }

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    // Load timer settings (you can still use SharedPreferences for other settings if needed)
    // For this example, we use the default values.
    focusDuration = const Duration(minutes: 20);
    breakDuration = const Duration(minutes: 5);
    currentDuration = focusDuration;

    // Get the system's current locale language code.
    // PlatformDispatcher.instance.locale returns the current system locale.
    localeCode = PlatformDispatcher.instance.locale.languageCode;

    await _loadTranslations();
    await _playSoundNotification();
    _updateNotification();
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    if (!isPaused) {
      if (currentDuration > Duration(seconds: 0)) {
        currentDuration -= Duration(seconds: 1);
      } else {
        _playSoundNotification();
        isFocusMode = !isFocusMode;
        currentDuration = isFocusMode ? focusDuration : breakDuration;
      }
      _updateNotification();

      // Send remaining time (in seconds) to UI via IsolateNameServer.
      final sendPort = IsolateNameServer.lookupPortByName("timer_port");
      sendPort?.send(currentDuration.inSeconds);
    }
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    // Optional cleanup if needed.
  }

  @override
  void onReceiveData(Object data) {
    if (data is String) {
      switch (data) {
        case 'pause':
          isPaused = true;
          _updateNotification(
            title: tr('pause_title'),
            body: tr('pause_body'),
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

  /// Updates the foreground notification using FlutterForegroundTask's update function.
  Future<void> _updateNotification({String? title, String? body}) async {
    final notificationTitle = title ?? (isFocusMode ? tr('focus_time') : tr('break_time'));
    final minutes = currentDuration.inMinutes.toString();
    final seconds = (currentDuration.inSeconds % 60).toString();
    String notificationText;
    if (int.parse(seconds) > 0) {
      notificationText = tr('notification_template_with_seconds',
          namedArgs: {'minutes': minutes, 'seconds': seconds});
    } else {
      notificationText = tr('notification_template_without_seconds',
          namedArgs: {'minutes': minutes});
    }

    FlutterForegroundTask.updateService(
      notificationTitle: notificationTitle,
      notificationText: notificationText,
    );
  }

  /// Plays a sound notification when the mode switches using flutter_local_notifications.
  Future<void> _playSoundNotification() async {
    final localNotifications = FlutterLocalNotificationsPlugin();
    const androidSettings = AndroidInitializationSettings('mipmap/launcher_icon');
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

    const androidDetails = AndroidNotificationDetails(
      'mode_switch_channel',
      'Mode Switch Notifications',
      channelDescription: 'Notification played when mode switches',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      autoCancel: true,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final title = isFocusMode ? tr('focus_time') : tr('break_time');
    final message = isFocusMode ? tr('focus_started') : tr('break_started');

    await localNotifications.show(
      1,
      title,
      message,
      notificationDetails,
    );

    Future.delayed(const Duration(seconds: 1), () async {
      await localNotifications.cancel(1);
    });
  }
}
