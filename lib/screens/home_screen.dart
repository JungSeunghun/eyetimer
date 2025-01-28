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
  final double sliderSizeFactor = 0.9;
  final double buttonIconSize = 72.0;

  Duration focusDuration = Duration(minutes: 20);
  Duration breakDuration = Duration(minutes: 5);
  Duration currentDuration = Duration(minutes: 20);
  bool isRunning = false;
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

  Future<void> _showNotification(String title, String body) async {
    const androidDetails = AndroidNotificationDetails(
      'timer_channel',
      'Timer Notifications',
      importance: Importance.max,
      priority: Priority.high,
    );
    const notificationDetails = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(0, title, body, notificationDetails);
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
    if (isRunning) return;

    setState(() {
      isRunning = true;
      currentDuration = focusDuration; // 타이머 초기화
      isFocusMode = true; // 집중 모드로 시작
    });

    // 시작 알림
    _showNotification(
      '집중 시간 시작',
      '다시 집중하세요! 남은 시간: ${currentDuration.inMinutes}분',
    );

    // 타이머 시작
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        if (currentDuration > const Duration(seconds: 0)) {
          currentDuration -= const Duration(seconds: 1);
        } else {
          // 모드 전환
          isFocusMode = !isFocusMode;
          currentDuration = isFocusMode ? focusDuration : breakDuration;

          // 모드 전환 시 알림
          _showNotification(
            isFocusMode ? '집중 시간 시작' : '쉬는 시간 시작',
            isFocusMode
                ? '다시 집중하세요! 남은 시간: ${currentDuration.inMinutes}분'
                : '눈을 쉬게 하세요! 남은 시간: ${currentDuration.inMinutes}분',
          );
        }
      });
    });
  }

  void pauseTimer() {
    if (!isRunning) return;

    setState(() {
      isRunning = false;
    });

    timer?.cancel();
  }

  void stopTimer() {
    setState(() {
      isRunning = false;
      currentDuration = isFocusMode ? focusDuration : breakDuration; // 현재 모드의 기본 시간으로 초기화
    });

    timer?.cancel(); // 타이머 취소
    _notificationsPlugin.cancelAll(); // 모든 알림 취소
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyMedium?.color ?? Colors.black;
    final primaryColor = theme.primaryColor;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Eye Timer',
      ),
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
                    onPlayPause: isRunning ? pauseTimer : startTimer,
                    onStop: stopTimer,
                    onTakePhoto: takePhoto,
                    primaryColor: primaryColor,
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
