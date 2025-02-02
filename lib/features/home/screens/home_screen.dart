import 'dart:io';
import 'dart:async';
import 'dart:isolate';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

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

// 백그라운드 엔트리 포인트 (최상위에 정의)
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
      '20분 집중 후 먼 곳을 바라보며 눈의 피로를 줄여보세요.';

  static const String focusTitle = '집중 시간';

  final double sliderSizeFactor = 0.9;
  final double buttonIconSize = 72.0;

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
        final memo = await showMemoInputDialog(context, photoPath: photo.path);
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
  }

// 일시정지: 백그라운드 태스크에 'pause' 메시지 전송
  void _pauseForegroundService() {
    if (!isServiceRunning || isPaused) return;
    FlutterForegroundTask.sendDataToTask('pause');
    setState(() {
      isPaused = true;
    });
  }

// 재개: 백그라운드 태스크에 'resume' 메시지 전송
  void _resumeForegroundService() {
    if (!isServiceRunning || !isPaused) return;
    FlutterForegroundTask.sendDataToTask('resume');
    setState(() {
      isPaused = false;
    });
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
  }

  String _getNotificationMessage(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return (seconds > 0)
        ? '$minutes분 $seconds초 뒤, 눈이 편안해질 수 있도록 알려드릴게요.'
        : '$minutes분 뒤, 눈이 편안해질 수 있도록 알려드릴게요.';
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
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  TimerDisplay(
                    currentDuration: currentDuration,
                    textColor: textColor,
                  ),
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
                    primaryColor: theme.primaryColor,
                    textColor: textColor,
                    buttonIconSize: buttonIconSize,
                  ),
                  StatusText(
                    isRunning: isServiceRunning,
                    isFocusMode: true,
                    focusModeText: focusModeText,
                    breakModeText: breakModeText,
                    beforeStartText: beforeStartText,
                    textColor: textColor,
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: IconButton(
                      icon: Icon(Icons.settings, color: textColor),
                      onPressed: () => _showDurationPickerDialog(context),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
