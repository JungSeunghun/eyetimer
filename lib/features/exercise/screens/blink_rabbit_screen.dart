// lib/screens/blink_rabbit_screen.dart
import 'dart:async';
import 'dart:io';
import 'package:flame/game.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
// import 'package:google_mobile_ads/google_mobile_ads.dart'; // 전면 광고 관련 import 주석처리
import '../game/blink_rabbit_game.dart';
import '../services/camera_service.dart';
import 'package:flutter/foundation.dart'; // for kDebugMode
import 'package:flutter/widgets.dart'; // PopScope is defined here

/*
// 플랫폼과 디버그 모드 여부에 따라 전면광고 단위 ID를 반환하는 함수
String getInterstitialAdUnitId() {
  if (Platform.isAndroid) {
    return kDebugMode
        ? 'ca-app-pub-3940256099942544/1033173712' // Android 테스트용 전면 광고 ID
        : 'ca-app-pub-3357808033770699/3706161937';
  } else if (Platform.isIOS) {
    return kDebugMode
        ? 'ca-app-pub-3940256099942544/4411468910' // iOS 테스트용 전면 광고 ID
        : 'YOUR_IOS_PRODUCTION_INTERSTITIAL_AD_UNIT_ID';
  }
  return '';
}
*/

class BlinkRabbitScreen extends StatefulWidget {
  const BlinkRabbitScreen({Key? key}) : super(key: key);

  @override
  State<BlinkRabbitScreen> createState() => _BlinkRabbitScreenState();
}

class _BlinkRabbitScreenState extends State<BlinkRabbitScreen> {
  // 번역 키 (translation keys)
  static const String kAppBarTitleKey = "blink_rabbit_appbar_title";
  static const String kScoreLabelKey = "score_label";
  static const String kGameOverLabelKey = "game_over_label";
  static const String kInstructionMsgKey = "instruction_msg";
  static const String kStartButtonLabelKey = "start_button_label";
  static const String kRetryButtonLabelKey = "retry_button_label";

  static const String kFaceRecognizingMsgKey = "face_recognizing_msg";
  static const String kFaceRecognizedMsgKey = "face_recognized_msg";
  static const String kFaceNotDetectedMsgKey = "face_not_detected_msg";

  late BlinkRabbitGame _game;
  late CameraService _cameraService;

  bool _isStartingCountdown = false;
  int _countdown = 3;
  Timer? _countdownTimer;

  // 얼굴 인식 관련 상태 변수
  bool _faceDetected = false;
  String _startMessage = "";

  /*
  // 전면광고 관련 필드
  InterstitialAd? _interstitialAd;
  bool _isInterstitialAdLoaded = false;
  bool _isAdShowing = false; // 광고 표시 중인지를 나타내는 플래그
  */

  @override
  void initState() {
    super.initState();

    // 게임 객체 생성 및 콜백 설정
    _game = BlinkRabbitGame()
      ..onScoreChanged = () {
        if (!mounted) return;
        setState(() {});
      }
      ..onGameOver = () {
        if (!mounted) return;
        setState(() {});
      };

    // 초기화 시점에 전면광고 로드
    // _loadInterstitialAd();

    // 얼굴 인식 관련 카메라 서비스 설정
    _cameraService = CameraService(
      onFacesDetected: (faces) {
        if (!mounted) return;
        if (faces.isNotEmpty) {
          if (!_faceDetected) {
            setState(() {
              _faceDetected = true;
            });
          }
        } else {
          setState(() {
            _faceDetected = false;
          });
        }
        // 깜빡임 체크 후 게임에 전달
        _cameraService.checkBlinking(faces, _game.onBlink);
      },
    );

    // 카메라 스트림 시작
    _cameraService.startCameraStream().catchError((error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    });
  }

  /*
  // 전면광고 로드 함수 (initState 및 게임 오버 시 호출)
  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: getInterstitialAdUnitId(),
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          if (!mounted) return;
          setState(() {
            _interstitialAd = ad;
            _isInterstitialAdLoaded = true;
          });
        },
        onAdFailedToLoad: (error) {
          if (!mounted) return;
          setState(() {
            _interstitialAd = null;
            _isInterstitialAdLoaded = false;
          });
          debugPrint('InterstitialAd failed to load: $error');
        },
      ),
    );
  }
  */

  @override
  void dispose() {
    _cameraService.dispose();
    _countdownTimer?.cancel();
    // _interstitialAd?.dispose();
    super.dispose();
  }

  Future<void> _handleStartButton() async {
    if (_game.isGameStarted || _isStartingCountdown) return;
    if (!mounted) return;

    // 시작 버튼 클릭 시 "얼굴을 인식 중입니다." 메시지 표시
    setState(() {
      _startMessage = kFaceRecognizingMsgKey.tr();
    });

    // 최대 5초 동안 얼굴 인식을 기다림 (100ms 간격 확인)
    bool detected = false;
    for (int i = 0; i < 50; i++) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (!mounted) return;
      if (_faceDetected) {
        detected = true;
        break;
      }
    }

    if (!mounted) return;
    if (detected) {
      // 얼굴 인식 완료 메시지 표시
      setState(() {
        _startMessage = kFaceRecognizedMsgKey.tr();
      });
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      setState(() {
        _startMessage = "";
        _isStartingCountdown = true;
        _countdown = 3;
      });
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        setState(() => _countdown--);
        if (_countdown == 0) {
          timer.cancel();
          _game.startGame();
          if (mounted) {
            setState(() => _isStartingCountdown = false);
          }
        }
      });
    } else {
      // 얼굴이 인식되지 않으면 메시지 지우고 오류 스낵바 표시
      setState(() {
        _startMessage = "";
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(kFaceNotDetectedMsgKey.tr())),
        );
      }
    }
  }

  void _handleRetryButton() {
    if (!mounted) return;
    setState(() {
      _game.startGame();
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool popResult, dynamic result) {
        Future.microtask(() async {
          FlameAudio.bgm.stop();
          FlameAudio.bgm.dispose();
          /*
          // 전면광고 관련 부분 주석처리
          if (_isAdShowing) return;
          if (_isInterstitialAdLoaded && _interstitialAd != null) {
            _isAdShowing = true;
            _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
              onAdDismissedFullScreenContent: (ad) {
                ad.dispose();
                _isAdShowing = false;
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop(); // 이전 라우트가 있으면 pop하여 돌아감
                }
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                ad.dispose();
                _isAdShowing = false;
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop(); // 실패해도 이전 라우트로 돌아감
                }
              },
            );
            _interstitialAd!.show();
          } else {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop(); // 광고가 없으면 바로 pop
            }
          }
          */
          // 광고 관련 부분 주석처리 후 기본 pop 동작
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        });
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(kAppBarTitleKey.tr()),
          centerTitle: true,
        ),
        body: Stack(
          children: [
            // Flame Game 위젯
            Positioned.fill(
              child: GameWidget(game: _game),
            ),
            // 점수 오버레이
            Positioned(
              top: 8,
              right: 20,
              child: Text(
                '${kScoreLabelKey.tr()}: ${_game.score.toInt()}',
                style: const TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
            // 안내, 게임 오버, 얼굴 인식 메시지 (중앙보다 위쪽에 배치)
            if (!_game.isGameStarted && !_isStartingCountdown)
              Align(
                alignment: const Alignment(0, -0.3),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.black45,
                  child: Text(
                    _game.isGameOver
                        ? '${kGameOverLabelKey.tr()}\n${kScoreLabelKey.tr()}: ${_game.score.toInt()}'
                        : '${kInstructionMsgKey.tr()}${_startMessage.isNotEmpty ? "\n\n$_startMessage" : ""}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
            // 카운트다운 표시 (게임 시작 전)
            if (!_game.isGameStarted && _isStartingCountdown)
              Center(
                child: Text(
                  '$_countdown',
                  style: const TextStyle(
                    fontSize: 80,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        blurRadius: 10,
                        color: Colors.black,
                        offset: Offset(2, 2),
                      )
                    ],
                  ),
                ),
              ),
            // 게임 시작 버튼 (게임이 시작되지 않고, 카운트다운 중이 아닐 때)
            if (!_game.isGameStarted &&
                !_isStartingCountdown &&
                !_game.isGameOver)
              Positioned(
                bottom: 50,
                left: MediaQuery.of(context).size.width * 0.3,
                right: MediaQuery.of(context).size.width * 0.3,
                child: GestureDetector(
                  onTap: _handleStartButton,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 2),
                      borderRadius: BorderRadius.circular(30),
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                    child: Center(
                      child: Text(
                        kStartButtonLabelKey.tr(),
                        style: const TextStyle(fontSize: 20, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
            // 다시하기 버튼 (게임 오버 시)
            if (_game.isGameOver)
              Positioned(
                bottom: 50,
                left: MediaQuery.of(context).size.width * 0.3,
                right: MediaQuery.of(context).size.width * 0.3,
                child: GestureDetector(
                  onTap: _handleRetryButton,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 2),
                      borderRadius: BorderRadius.circular(30),
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                    child: Center(
                      child: Text(
                        kRetryButtonLabelKey.tr(),
                        style: const TextStyle(fontSize: 20, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
