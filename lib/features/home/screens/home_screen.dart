import 'dart:io';
import 'dart:async';
import 'dart:isolate';
import 'dart:ui';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import '../../../audio_player_task.dart';
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
  // UI용 텍스트 및 상수
  final String focusModeText = '지금은 나를 위한 시간이에요.';
  final String breakModeText = '잠깐 쉬면서 하늘을 올려다볼까요.';
  final String noPhotosMessage =
      '먼 곳의 풍경을 바라보며\n사진으로 기록해보세요.';
  final String beforeStartText =
      '잠시 후 먼 곳을 바라보며 눈에 휴식을 선물하세요.';

  static const String focusTitle = '집중 시간';

  static const String focusDurationMinutesKey = 'focusDuration_minutes';
  static const String focusDurationSecondsKey = 'focusDuration_seconds';
  static const String breakDurationMinutesKey = 'breakDuration_minutes';
  static const String breakDurationSecondsKey = 'breakDuration_seconds';

  // 타이머 설정 (UI 표시용; 실제 타이머는 백그라운드에서 관리)
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

  AudioHandler? _audioHandler; // AudioHandler를 저장할 변수

  @override
  void initState() {
    super.initState();
    _loadDurations();
    _loadTodayPhotos();

    // ReceivePort 생성 및 등록
    _receivePort = ReceivePort();
    IsolateNameServer.registerPortWithName(_receivePort.sendPort, "timer_port");

    // 백그라운드 태스크에서 보내는 데이터를 수신하여 타이머 UI 업데이트
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
    _stopWhiteNoise(); // 정지 시 _audioHandler를 null로 설정하지 않음
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
        ResizeImage(FileImage(File(photo.filePath)), width: 512, height: 512),
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

        // Memo 입력 스크린으로 전환하여 메모 입력받기
        final memo = await Navigator.push<String?>(
          context,
          MaterialPageRoute(
            builder: (context) => MemoInputScreen(
              photoPath: newPath,
            ),
          ),
        );

        final photoProvider =
        Provider.of<PhotoProvider>(context, listen: false);
        final newPhoto = Photo(
            id: null, filePath: newPath, timestamp: timestamp, memo: memo);
        await _photoService.savePhoto(newPath, timestamp, memo);
        photoProvider.addPhoto(newPhoto);
        await photoProvider.loadAllPhotos();
      }
    } catch (e) {
      print("Error saving photo: $e");
    }
  }

  String _getWhiteNoiseTitle(String assetPath) {
    if (assetPath.contains('rain')) return '빗소리';
    if (assetPath.contains('ocean')) return '파도 소리';
    if (assetPath.contains('wind')) return '바람 소리';
    return '백색소음';
  }

  Future<void> _startWhiteNoise() async {
    final prefs = await SharedPreferences.getInstance();
    final assetPath = prefs.getString('white_noise_asset') ?? '';
    if (assetPath.isEmpty) {
      // 무음 선택 시 재생하지 않음
      return;
    }
    // _audioHandler가 null인 경우에만 AudioService를 초기화합니다.
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
    // 현재 _audioHandler에 설정된 MediaItem을 확인합니다.
    final currentMediaItem = _audioHandler!.mediaItem.value;
    // 만약 현재 MediaItem이 없거나, asset 경로가 다르면 새 MediaItem으로 업데이트합니다.
    if (currentMediaItem == null || currentMediaItem.id != assetPath) {
      final mediaItem = MediaItem(
        id: assetPath, // 예: "assets/sounds/rain.mp3"
        album: "White Noise",
        title: _getWhiteNoiseTitle(assetPath),
      );
      await _audioHandler!.updateMediaItem(mediaItem);
    }
    // play() 호출: 일시정지 상태라면 기존 위치에서 재생되고, 정지 후에는 처음부터 재생됩니다.
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

  String _getNotificationMessage(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return (seconds > 0)
        ? '$minutes분 $seconds초 뒤, 눈이 편안해질 수 있도록 알려드릴게요.'
        : '$minutes분 뒤, 눈이 편안해질 수 있도록 알려드릴게요.';
  }

  // Foreground Service 시작
  void _startForegroundService() async {
    if (isServiceRunning) return;
    await FlutterForegroundTask.startService(
      notificationTitle: focusTitle,
      notificationText: _getNotificationMessage(currentDuration),
      callback: startCallback,
    );
    setState(() {
      isServiceRunning = true;
      isPaused = false;
    });

    await _startWhiteNoise();
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

  // 정지: 서비스 종료
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
    );
  }
}
