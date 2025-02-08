import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:audio_service/audio_service.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../audio_player_task.dart';
import '../../../components/google_banner_ad_widget.dart';
import '../components/control_buttons.dart';
import '../components/duration_picker_dialog.dart';
import '../../../components/memo_input_dialog.dart';
import '../components/photo_slider.dart';
import '../components/status_text.dart';
import '../components/timer_display.dart';
import '../../../models/photo.dart';
import '../../../providers/photo_provider.dart';
import '../../../services/photo_service.dart';
import '../../../my_foreground_task_handler.dart';

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(MyForegroundTaskHandler());
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // SharedPreferences 키
  static const String focusDurationMinutesKey = 'focusDuration_minutes';
  static const String focusDurationSecondsKey = 'focusDuration_seconds';
  static const String breakDurationMinutesKey = 'breakDuration_minutes';
  static const String breakDurationSecondsKey = 'breakDuration_seconds';

  // 기본 타이머 값
  Duration focusDuration = const Duration(minutes: 20);
  Duration breakDuration = const Duration(minutes: 5);
  Duration currentDuration = const Duration(minutes: 20);

  // Foreground Service 상태
  bool isServiceRunning = false;
  bool isPaused = false;

  // 사진 관련 변수들
  final PhotoService _photoService = PhotoService();
  final ImagePicker _picker = ImagePicker();
  List<Photo> todayPhotos = [];
  final PageController _pageController = PageController(viewportFraction: 1.0);

  late FlutterLocalNotificationsPlugin _notificationsPlugin;
  StreamSubscription<dynamic>? _taskDataSubscription;
  late ReceivePort _receivePort;

  AudioHandler? _audioHandler;

  @override
  void initState() {
    super.initState();
    _loadDurations();
    _loadTodayPhotos();

    _receivePort = ReceivePort();
    IsolateNameServer.registerPortWithName(_receivePort.sendPort, "timer_port");

    _taskDataSubscription = _receivePort.listen((data) {
      if (data is int) {
        setState(() {
          currentDuration = Duration(seconds: data);
        });
      }
    });
  }

  @override
  void dispose() {
    _taskDataSubscription?.cancel();
    IsolateNameServer.removePortNameMapping("timer_port");
    FlutterForegroundTask.stopService();
    _stopWhiteNoise();
    super.dispose();
  }

  Future<void> _loadDurations() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      final focusMinutes = prefs.getInt(focusDurationMinutesKey) ?? 20;
      final focusSeconds = prefs.getInt(focusDurationSecondsKey) ?? 0;
      focusDuration = Duration(minutes: focusMinutes, seconds: focusSeconds);

      final breakMinutes = prefs.getInt(breakDurationMinutesKey) ?? 5;
      final breakSeconds = prefs.getInt(breakDurationSecondsKey) ?? 0;
      breakDuration = Duration(minutes: breakMinutes, seconds: breakSeconds);

      currentDuration = focusDuration;
    });
  }

  Future<void> _saveDurations() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(focusDurationMinutesKey, focusDuration.inMinutes);
    await prefs.setInt(focusDurationSecondsKey, focusDuration.inSeconds % 60);
    await prefs.setInt(breakDurationMinutesKey, breakDuration.inMinutes);
    await prefs.setInt(breakDurationSecondsKey, breakDuration.inSeconds % 60);
  }

  Future<void> _loadTodayPhotos() async {
    final photos = await _photoService.getTodayPhotos();
    setState(() {
      todayPhotos = photos;
    });
    for (var photo in todayPhotos) {
      precacheImage(
        ResizeImage(
          FileImage(File(photo.filePath)),
          width: 512,
          height: 512,
        ),
        context,
      );
    }
  }

  Future<void> takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
      if (photo != null) {
        final timestamp = DateTime.now().toIso8601String();
        final fileName = timestamp.replaceAll(RegExp(r'[:\.]'), '-');
        final appDir = await getApplicationDocumentsDirectory();
        final eyeTimerDir = Directory('${appDir.path}/image');
        if (!await eyeTimerDir.exists()) {
          await eyeTimerDir.create(recursive: true);
        }
        final newPath = '${eyeTimerDir.path}/$fileName.jpg';
        final File tempFile = File(photo.path);
        await tempFile.copy(newPath);

        final memo = await Navigator.push<String?>(
          context,
          MaterialPageRoute(
            builder: (context) => MemoInputScreen(photoPath: newPath),
          ),
        );

        final photoProvider = Provider.of<PhotoProvider>(context, listen: false);
        final newPhoto = Photo(
          id: null,
          filePath: newPath,
          timestamp: timestamp,
          memo: memo,
        );
        await _photoService.savePhoto(newPath, timestamp, memo);
        photoProvider.addPhoto(newPhoto);
        await photoProvider.loadAllPhotos();
      }
    } catch (e) {
      print("Error saving photo: $e");
    }
  }

  // 백색소음 제목도 번역 키를 사용하도록 변경 (BuildContext 전달)
  String _getWhiteNoiseTitle(BuildContext context, String assetPath) {
    if (assetPath.contains('rain')) return 'white_noise_rain'.tr();
    if (assetPath.contains('ocean')) return 'white_noise_ocean'.tr();
    if (assetPath.contains('wind')) return 'white_noise_wind'.tr();
    return 'white_noise_default'.tr();
  }

  Future<void> _startWhiteNoise(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final assetPath = prefs.getString('white_noise_asset') ?? '';
    if (assetPath.isEmpty) {
      return;
    }
    if (_audioHandler == null) {
      _audioHandler = await AudioService.init(
        builder: () => MyAudioHandler(),
        config: AudioServiceConfig(
          androidNotificationChannelId: 'white_noise_channel',
          androidNotificationChannelName: '백색소음 재생',
          androidNotificationChannelDescription: '백색소음 재생 서비스',
          notificationColor: const Color(0xFF2196f3),
          androidNotificationIcon: 'mipmap/launcher_icon',
        ),
      );
    }
    final currentMediaItem = _audioHandler!.mediaItem.value;
    if (currentMediaItem == null || currentMediaItem.id != assetPath) {
      final mediaItem = MediaItem(
        id: assetPath,
        album: "White Noise",
        title: _getWhiteNoiseTitle(context, assetPath),
      );
      await _audioHandler!.updateMediaItem(mediaItem);
    }
    await _audioHandler!.play();
  }

  Future<void> _pauseWhiteNoise() async {
    if (_audioHandler != null &&
        _audioHandler!.playbackState.value.processingState != AudioProcessingState.idle) {
      await _audioHandler!.pause();
    }
  }

  Future<void> _resumeWhiteNoise() async {
    if (_audioHandler != null &&
        _audioHandler!.playbackState.value.processingState != AudioProcessingState.idle) {
      await _audioHandler!.play();
    }
  }

  Future<void> _stopWhiteNoise() async {
    if (_audioHandler != null &&
        _audioHandler!.playbackState.value.processingState != AudioProcessingState.idle) {
      await _audioHandler!.stop();
    }
  }

  // _getNotificationMessage 함수는 번역 키를 이용하여 메시지를 반환합니다.
  String _getNotificationMessage(Duration duration) {
    final minutes = duration.inMinutes.toString();
    final seconds = (duration.inSeconds % 60).toString();
    if (int.parse(seconds) > 0) {
      return 'notification_template_with_seconds'.tr(namedArgs: {
        'minutes': minutes,
        'seconds' : seconds
      });
    } else {
      return 'notification_template_without_seconds'.tr(namedArgs: {
        'minutes': minutes,
      });
    }
  }

  void _startForegroundService() async {
    if (isServiceRunning) return;
    await FlutterForegroundTask.startService(
      notificationTitle: 'focus_title'.tr(),
      notificationText: _getNotificationMessage(currentDuration),
      callback: startCallback,
    );
    setState(() {
      isServiceRunning = true;
      isPaused = false;
    });
    await _startWhiteNoise(context);
  }

  void _pauseForegroundService() {
    if (!isServiceRunning || isPaused) return;
    FlutterForegroundTask.sendDataToTask('pause');
    setState(() {
      isPaused = true;
    });
    _pauseWhiteNoise();
  }

  void _resumeForegroundService() {
    if (!isServiceRunning || !isPaused) return;
    FlutterForegroundTask.sendDataToTask('resume');
    setState(() {
      isPaused = false;
    });
    _resumeWhiteNoise();
  }

  void _stopForegroundService() async {
    if (!isServiceRunning) return;
    await FlutterForegroundTask.stopService();
    setState(() {
      isServiceRunning = false;
      isPaused = false;
      currentDuration = focusDuration;
    });
    await _stopWhiteNoise();
  }

  void _showDurationPickerDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => DurationPickerDialog(
        focusDuration: focusDuration,
        breakDuration: breakDuration,
        onSave: (newFocusDuration, newBreakDuration) {
          setState(() {
            focusDuration = newFocusDuration;
            breakDuration = newBreakDuration;
            currentDuration = focusDuration;
          });
          _saveDurations();
        },
      ),
    );
  }

  // 번역 키를 사용하는 getter들
  String get focusModeText => 'focus_mode_text'.tr();
  String get breakModeText => 'break_mode_text'.tr();
  String get noPhotosMessage => 'no_photos_message'.tr();
  String get beforeStartText => 'before_start_text'.tr();
  String get focusTitle => 'focus_title'.tr();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyMedium?.color ?? Colors.black;
    final photoProvider = Provider.of<PhotoProvider>(context);

    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              PhotoSlider(
                todayPhotos: photoProvider.todayPhotos,
                pageController: _pageController,
                noPhotosMessage: noPhotosMessage,
                textColor: textColor,
                onEditMemo: (Photo photo, String updatedMemo) {
                  photoProvider.updatePhotoMemo(photo.id!, updatedMemo);
                  photoProvider.loadTodayPhotos();
                },
                onDeletePhoto: (Photo photo) {
                  photoProvider.deletePhoto(photo.id!);
                  photoProvider.loadTodayPhotos();
                },
              ),
              const SizedBox(height: 24.0),
              TimerDisplay(
                currentDuration: currentDuration,
                textColor: textColor,
                onSettingsPressed: () => _showDurationPickerDialog(context),
              ),
              const SizedBox(height: 16.0),
              StatusText(
                isRunning: isServiceRunning,
                isFocusMode: true,
                focusModeText: focusModeText,
                breakModeText: breakModeText,
                beforeStartText: beforeStartText,
                textColor: textColor,
              ),
              const SizedBox(height: 32.0),
              ControlButtons(
                isRunning: isServiceRunning,
                isPaused: isPaused,
                onPlay: () {
                  if (isServiceRunning && isPaused) {
                    _resumeForegroundService();
                  } else {
                    _startForegroundService();
                  }
                },
                onPause: _pauseForegroundService,
                onStop: _stopForegroundService,
                onTakePhoto: takePhoto,
              ),
            ],
          ),
        ),
      ),
      // 하단에 애드몹 배너광고를 고정된 높이로 추가하여 콘텐츠를 가리지 않도록 함.
      bottomNavigationBar: SizedBox(
        height: AdSize.banner.height.toDouble(),
        child: const GoogleBannerAdWidget(),
      ),
    );
  }
}
