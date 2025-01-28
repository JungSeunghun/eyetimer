import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../components/control_buttons.dart';
import '../components/custom_app_bar.dart';
import '../components/custom_bottom_navigation_bar.dart';
import '../components/memo_input_dialog.dart';
import '../components/photo_slider.dart';
import '../components/status_text.dart';
import '../components/timer_display.dart';
import '../models/photo.dart';
import '../services/photo_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final String focusModeText = '지금은 나를 위한 시간이에요.';
  final String breakModeText = '잠깐 쉬면서 하늘을 올려다볼까요.';
  final String noPhotosMessage = '눈이 행복해지는 순간을 담아보세요.\n작은 풍경도 큰 위로가 될 수 있어요.';
  final String beforeStartText =
      '20-20-20 법칙은 20분 집중 후\n20초 동안 먼 곳을 바라보며\n눈의 피로를 줄이는 방법이에요.';

  static const String focusTitle = '집중 시간';
  static const String breakTitle = '쉬는 시간';

  final double sliderSizeFactor = 0.9;
  final double buttonIconSize = 72.0;

  Duration focusDuration = Duration(minutes: 20);
  Duration breakDuration = Duration(minutes: 5);
  Duration currentDuration = Duration(minutes: 20);
  bool isRunning = false;
  bool isPaused = false;
  bool isFocusMode = true;
  Timer? timer;

  final PhotoService _photoService = PhotoService();
  final ImagePicker _picker = ImagePicker();
  List<Photo> todayPhotos = [];
  final PageController _pageController = PageController(
      viewportFraction: 1.0
  );

  late FlutterLocalNotificationsPlugin _notificationsPlugin;

  @override
  void initState() {
    super.initState();
    _loadTodayPhotos();
    _initializeNotifications(); // 알림 초기화
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  void _initializeNotifications() {
    _notificationsPlugin = FlutterLocalNotificationsPlugin();

    // iOS 및 macOS 초기화 설정
    const darwinInitialization = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // Android 초기화 설정
    const androidInitialization = AndroidInitializationSettings('@mipmap/ic_launcher');

    // 전체 초기화 설정
    const initializationSettings = InitializationSettings(
      android: androidInitialization,
      iOS: darwinInitialization, // DarwinInitializationSettings 사용
    );

    _notificationsPlugin.initialize(initializationSettings);
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

        final memo = await showMemoInputDialog(
            context,
            photoPath: photo.path,
        );

        await _photoService.savePhoto(newPath, timestamp, memo);
        _loadTodayPhotos();
      }
    } catch (e) {
      print("Error saving photo: $e");
    }
  }

  void startTimer() {
    if (isRunning && !isPaused) return;

    setState(() {
      isRunning = true;
      isPaused = false;
    });

    // 타이머 시작 알림 (소리 있음)
    _showNotification(
      title: focusTitle,
      body: _getNotificationMessage(isFocusMode, currentDuration),
      silent: false, // 소리 있음
    );

    // 타이머 시작
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        if (currentDuration > const Duration(seconds: 0)) {
          currentDuration -= const Duration(seconds: 1);

          // 타이머 진행 중 알림 업데이트 (무음)
          _showNotification(
            title: isFocusMode ? focusTitle : breakTitle,
            body: _getNotificationMessage(isFocusMode, currentDuration),
            silent: true, // 무음 알림
          );
        } else {
          // 모드 전환
          isFocusMode = !isFocusMode;
          currentDuration = isFocusMode ? focusDuration : breakDuration;

          // 모드 전환 알림 (소리 있음)
          _showNotification(
            title: isFocusMode ? focusTitle : breakTitle,
            body: _getNotificationMessage(isFocusMode, currentDuration),
            silent: false, // 소리 있음
          );
        }
      });
    });
  }

  // 알림 메시지 생성 함수
  String _getNotificationMessage(bool isFocusMode, Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;

    if (isFocusMode) {
      return seconds > 0
          ? '$minutes분 $seconds초 뒤, 눈이 편안해질 수 있도록 알려드릴게요.'
          : '$minutes분 뒤, 눈이 편안해질 수 있도록 알려드릴게요.';
    } else {
      return seconds > 0
          ? '$minutes분 $seconds초 동안 창밖을 바라보며 마음과 눈에 휴식을 선물하세요.'
          : '$minutes분 동안 창밖을 바라보며 마음과 눈에 휴식을 선물하세요.';
    }
  }

  void pauseTimer() {
    if (!isRunning) return;

    setState(() {
      isPaused = true;
    });

    timer?.cancel();
  }

  void stopTimer() {
    setState(() {
      isRunning = false;
      isPaused = false;
      isFocusMode = true;
      currentDuration = focusDuration; // 초기화
    });

    timer?.cancel();
    _notificationsPlugin.cancelAll();
  }

  Future<void> _showNotification({
    required String title,
    required String body,
    bool silent = false, // 기본값은 무음 알림
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'timer_channel',
      'Timer Notifications',
      importance: Importance.max,
      priority: Priority.high,
      ongoing: true, // 알림 고정
      showWhen: false, // 시간 표시 제거
      silent: silent, // 소리 설정
    );

    // iOS 알림 설정
    final iOSDetails = DarwinNotificationDetails(
      presentAlert: true, // 알림 표시
      presentBadge: true, // 배지 업데이트
      presentSound: !silent, // 소리 설정
    );

    // 공통 알림 설정
    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iOSDetails,
    );
    
    await _notificationsPlugin.show(
      0, // 알림 ID 고정
      title,
      body,
      notificationDetails,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyMedium?.color ?? Colors.black;
    final primaryColor = theme.primaryColor;

    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              PhotoSlider(
                todayPhotos: todayPhotos,
                pageController: _pageController,
                noPhotosMessage: noPhotosMessage,
                textColor: textColor,
                onEditMemo: (Photo photo, String updatedMemo) async {
                  // 메모 수정 로직
                  await _photoService.updatePhotoMemo(photo.id!, updatedMemo);
                  _loadTodayPhotos();
                },
                onDeletePhoto: (Photo photo) async {
                  // 사진 삭제 로직
                  await _photoService.deletePhoto(photo.id!);
                  _loadTodayPhotos();
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
                    isRunning: isRunning,
                    isPaused: isPaused,
                    onPlay: startTimer,
                    onPause: pauseTimer,
                    onStop: stopTimer,
                    onTakePhoto: takePhoto,
                    primaryColor: theme.primaryColor,
                    textColor: textColor,
                    buttonIconSize: buttonIconSize,
                  ),
                  StatusText(
                    isRunning: isRunning,
                    isFocusMode: isFocusMode,
                    focusModeText: focusModeText,
                    breakModeText: breakModeText,
                    beforeStartText: beforeStartText,
                    textColor: textColor,
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
