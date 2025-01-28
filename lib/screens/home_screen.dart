import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _loadTodayPhotos();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
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
    });

    timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (currentDuration > Duration.zero) {
          currentDuration -= Duration(seconds: 1);
        } else {
          if (isFocusMode) {
            currentDuration = breakDuration;
          } else {
            currentDuration = focusDuration;
          }
          isFocusMode = !isFocusMode;
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
      currentDuration = isFocusMode ? focusDuration : breakDuration;
    });

    timer?.cancel();
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
