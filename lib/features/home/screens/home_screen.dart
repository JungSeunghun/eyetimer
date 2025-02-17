import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:audio_service/audio_service.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as path;

import '../../../audio_player_task.dart';
import '../../../timer_notification.dart'; // 네이티브 호출용 클래스
import '../components/control_buttons.dart';
import '../components/duration_picker_dialog.dart';
import '../../../components/memo_input_dialog.dart';
import '../components/photo_slider.dart';
import '../components/status_text.dart';
import '../components/timer_display.dart';
import '../../../models/photo.dart';
import '../../../providers/photo_provider.dart';
import '../../../services/photo_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();

  // SharedPreferences 키
  static const String focusDurationMinutesKey = 'focusDuration_minutes';
  static const String focusDurationSecondsKey = 'focusDuration_seconds';
  static const String breakDurationMinutesKey = 'breakDuration_minutes';
  static const String breakDurationSecondsKey = 'breakDuration_seconds';

  // 기본 타이머 값
  Duration focusDuration = const Duration(minutes: 20);
  Duration breakDuration = const Duration(minutes: 5);
  Duration currentDuration = const Duration(minutes: 20);

  // 타이머 실행 상태
  bool isTimerRunning = false;
  bool isPaused = false;
  bool isFocusMode = true; // 집중모드 여부 (true: 집중, false: 휴식)

  // 타이머 periodic 인스턴스를 저장할 변수
  Timer? _timer;

  // 번역 키 getters (기존)
  String get focus_title => 'focus_title'.tr();
  String get break_title => 'break_title'.tr();
  String get focusModeText => 'focus_mode_text'.tr();
  String get breakModeText => 'break_mode_text'.tr();

  // 번역 키 getters for title
  String get pauseTitle => 'pause_title'.tr();          // 예: "일시정지"
  String get resumeTitle => 'resume_title'.tr();        // 예: "재개"

  // 사진 관련 변수들
  final PhotoService _photoService = PhotoService();
  final ImagePicker _picker = ImagePicker();
  List<Photo> todayPhotos = [];
  final PageController _pageController = PageController(viewportFraction: 1.0);

  StreamSubscription<dynamic>? _taskDataSubscription;
  late ReceivePort _receivePort;

  // MyAudioHandler 인스턴스 추가 (화이트노이즈 제어용)
  late final MyAudioHandler _audioHandler;

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

    // Provider를 통해 미리 생성된 AudioHandler를 가져옵니다.
    _audioHandler = Provider.of<MyAudioHandler>(context, listen: false);

    // 화면이 완전히 렌더링된 후에 스크롤을 맨 아래로 이동
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _taskDataSubscription?.cancel();
    IsolateNameServer.removePortNameMapping("timer_port");
    _stopTimerNotification();
    _stopWhiteNoise();
    super.dispose();
  }

  Future<void> _playWhiteNoise() async {
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
          localizedTitle = baseName; // 해당하는 localization 키가 없으면 기본 파일명을 사용
          break;
      }

      final mediaItem = MediaItem(
        id: asset,
        album: 'White Noise',
        title: localizedTitle, // localization 적용된 타이틀 사용
      );
      await _audioHandler.updateMediaItem(mediaItem);
      await _audioHandler.play();
    }
  }


  Future<void> _pauseWhiteNoise() async {
    final prefs = await SharedPreferences.getInstance();
    final asset = prefs.getString('white_noise_asset') ?? '';
    if (asset.isNotEmpty) {
      await _audioHandler.pause();
    }
  }

  Future<void> _resumeWhiteNoise() async {
    final prefs = await SharedPreferences.getInstance();
    final asset = prefs.getString('white_noise_asset') ?? '';
    if (asset.isNotEmpty) {
      await _audioHandler.play();
    }
  }

  Future<void> _stopWhiteNoise() async {
    final prefs = await SharedPreferences.getInstance();
    final asset = prefs.getString('white_noise_asset') ?? '';
    if (asset.isNotEmpty) {
      await _audioHandler.stop();
    }
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

        // MemoInputScreen을 열어 memo 값을 받음
        final memo = await Navigator.push<String?>(
          context,
          MaterialPageRoute(
            builder: (context) => MemoInputScreen(photoPath: newPath),
          ),
        );

        final photoProvider = Provider.of<PhotoProvider>(context, listen: false);

        // PhotoService.savePhoto가 새로 저장된 사진의 id를 반환하도록 수정합니다.
        final int newId = await _photoService.savePhoto(newPath, timestamp, memo);

        // newId를 받아 Photo 객체를 생성합니다.
        final newPhoto = Photo(
          id: newId,  // null이 아니라 새로 생성된 id 할당
          filePath: newPath,
          timestamp: timestamp,
          memo: memo,
        );

        photoProvider.addPhoto(newPhoto);
        await photoProvider.loadAllPhotos();
      }
    } catch (e) {
      print("Error saving photo: $e");
    }
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
        ? key.tr(namedArgs: {
      'minutes': minutes,
      'seconds': seconds,
    })
        : key.tr(namedArgs: {
      'minutes': minutes,
    });
  }

  void _startTimerNotification() async {
    if (isTimerRunning) return;
    String title = isFocusMode ? focus_title : break_title;
    String message = _getNotificationMessage(currentDuration, isFocusMode: isFocusMode);
    TimerNotification.startTimer(title, message);
    setState(() {
      isTimerRunning = true;
      isPaused = false;
    });
  }

  /// 타이머 알림 업데이트 (매초 호출, title 및 메시지 포함)
  void _updateTimerNotification() async {
    if (!isTimerRunning || isPaused) return;
    String title = isFocusMode ? focus_title : break_title;
    String message = _getNotificationMessage(
        currentDuration,
        isFocusMode: isFocusMode
    );
    TimerNotification.updateTimer(title, message);
  }

  /// 타이머 알림 종료
  void _stopTimerNotification() async {
    if (!isTimerRunning) return;
    TimerNotification.endTimer();
    setState(() {
      isFocusMode = true;
      isTimerRunning = false;
      isPaused = false;
      currentDuration = focusDuration;
    });
    _timer?.cancel();
    _timer = null;
    _stopWhiteNoise();
  }

  /// 타이머 일시정지 (플랫폼 네이티브 호출, title 및 메시지 포함)
  void _pauseTimer() async {
    if (!isTimerRunning || isPaused) return;
    setState(() {
      isPaused = true;
    });
    String title = pauseTitle;
    String message = _getNotificationMessage(
        currentDuration,
        isFocusMode: isFocusMode
    );
    TimerNotification.pauseTimer(title, message);
    _pauseWhiteNoise();
  }

  /// 타이머 재개 (플랫폼 네이티브 호출, title 및 메시지 포함)
  void _resumeTimer() async {
    if (!isTimerRunning || !isPaused) return;
    setState(() {
      isPaused = false;
    });
    String title = resumeTitle;
    String message = 'timer_resumed'.tr();
    TimerNotification.resumeTimer(title, message);
    _resumeWhiteNoise();
  }

  /// Flutter에서 타이머 실행: 매초 업데이트하며, 집중/휴식 모드를 반복합니다.
  void _startTimer() {
    _startTimerNotification();
    _playWhiteNoise(); //
    // 타이머가 이미 실행 중이면 새 타이머를 생성하지 않음
    if (_timer != null) return;
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (isTimerRunning && !isPaused) {
        if (currentDuration.inSeconds > 0) {
          setState(() {
            currentDuration -= Duration(seconds: 1);
          });
          _updateTimerNotification();
        } else {
          // 현재 모드의 시간이 끝났으므로 모드를 전환합니다.
          setState(() {
            isFocusMode = !isFocusMode;
            // 새로운 모드에 따라 타이머 시간을 재설정합니다.
            currentDuration = isFocusMode ? focusDuration : breakDuration;
          });
          // 전환된 모드의 제목과 메시지를 생성하여 네이티브에 업데이트 명령을 전달합니다.
          String title = isFocusMode ? focus_title : break_title;
          String message = _getNotificationMessage(
              isFocusMode ? focusDuration : breakDuration,
              isFocusMode: isFocusMode
          );
          TimerNotification.switchTimer(title, message);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyMedium?.color ?? Colors.black;
    final photoProvider = Provider.of<PhotoProvider>(context);

    return Scaffold(
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // PhotoSlider와 TimerDisplay를 Stack으로 겹쳐서 배치
            Stack(
              children: [
                PhotoSlider(
                  todayPhotos: photoProvider.todayPhotos,
                  pageController: _pageController,
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
                // Positioned.fill으로 전체 영역을 채우고 Center로 TimerDisplay를 중앙에 배치
                Positioned.fill(
                  child: Center(
                    child: TimerDisplay(
                      currentDuration: currentDuration,
                      focusDuration: focusDuration,
                      breakDuration: breakDuration,
                      isFocusMode: isFocusMode, // 집중 모드 여부에 따라 maxDuration이 자동 선택됨
                    )
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32.0),
            StatusText(
              isRunning: isTimerRunning,
              isFocusMode: isFocusMode,
              focusModeText: focusModeText,
              breakModeText: breakModeText,
              beforeStartText: 'before_start_text'.tr(),
              textColor: textColor,
            ),
            const SizedBox(height: 32.0),
            ControlButtons(
              isRunning: isTimerRunning,
              isPaused: isPaused,
              onPlay: () {
                if (isTimerRunning && isPaused) {
                  _resumeTimer();
                } else {
                  _startTimer();
                }
              },
              onPause: _pauseTimer,
              onStop: _stopTimerNotification,
              onTakePhoto: takePhoto,
            ),
            // 컨트롤 버튼 아래에 설정 버튼 추가
            const SizedBox(height: 24.0),
            TextButton(
              child: Text(
                "timer_setting".tr(),
                style: TextStyle(
                  color: textColor.withValues(alpha: 0.7),
                ),
              ),
              onPressed: () => showDialog(
                context: context,
                builder: (context) => DurationPickerDialog(
                  focusDuration: focusDuration,
                  breakDuration: breakDuration,
                  onSave: (newFocusDuration, newBreakDuration) {
                    setState(() {
                      focusDuration = newFocusDuration;
                      breakDuration = newBreakDuration;
                      currentDuration = focusDuration;
                      isFocusMode = true; // 집중 모드로 재설정
                    });
                    _saveDurations();
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      // bottomNavigationBar: SizedBox(
      //   height: AdSize.banner.height.toDouble(),
      //   child: const GoogleBannerAdWidget(),
      // ),
    );
  }
}
