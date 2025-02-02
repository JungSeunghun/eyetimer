// lib/screens/blink_rabbit_screen.dart
import 'dart:async';
import 'dart:math' as math;
import 'package:camera/camera.dart' as cam;
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../game/blink_rabbit_game.dart';
import '../services/camera_service.dart';

class BlinkRabbitScreen extends StatefulWidget {
  const BlinkRabbitScreen({Key? key}) : super(key: key);

  @override
  State<BlinkRabbitScreen> createState() => _BlinkRabbitScreenState();
}

class _BlinkRabbitScreenState extends State<BlinkRabbitScreen> {
  // 상수들
  static const String kAppBarTitle = '깜빡깜빡';
  static const String kScoreLabel = 'Score';
  static const String kGameOverLabel = 'Game Over!';
  static const String kInstructionMsg = '눈을 깜빡여 조종하세요!';
  static const String kStartButtonLabel = '게임 시작';
  static const String kRetryButtonLabel = '다시하기';

  late BlinkRabbitGame _game;
  late CameraService _cameraService;

  bool _isStartingCountdown = false;
  int _countdown = 3;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _game = BlinkRabbitGame()
      ..onScoreChanged = () {
        setState(() {});
      }
      ..onGameOver = () {
        setState(() {});
      };

    _cameraService = CameraService(
      onFacesDetected: (faces) {
        // 깜빡임 체크 후 게임에 전달
        _cameraService.checkBlinking(faces, _game.onBlink);
      },
    );

    // 카메라 스트림 시작
    _cameraService.startCameraStream().catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    });
  }

  @override
  void dispose() {
    _cameraService.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _handleStartButton() async {
    if (!_game.isGameStarted && !_isStartingCountdown) {
      setState(() => _isStartingCountdown = true);
      _countdown = 3;
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() => _countdown--);
        if (_countdown == 0) {
          timer.cancel();
          _game.startGame();
          setState(() => _isStartingCountdown = false);
        }
      });
    }
  }

  void _handleRetryButton() {
    setState(() {
      _game.startGame();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(kAppBarTitle),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // 카메라 프리뷰 (카메라 서비스에 의해 초기화된 컨트롤러 사용)
          // Positioned.fill(
          //   child: _cameraService.isCameraInitialized && _cameraService.cameraController != null
          //       ? Transform(
          //     alignment: Alignment.center,
          //     transform: Matrix4.rotationY(math.pi),
          //     child: cam.CameraPreview(_cameraService.cameraController!),
          //   )
          //       : const Center(child: Text('')),
          // ),
          // Flame Game 위젯
          Positioned.fill(
            child: GameWidget(game: _game),
          ),
          // 점수 오버레이
          Positioned(
            top: 20,
            right: 20,
            child: Text(
              '$kScoreLabel: ${_game.score}',
              style: const TextStyle(fontSize: 24, color: Colors.white),
            ),
          ),
          // 안내 및 게임 오버 메시지
          // 안내 및 게임 오버 메시지 (중앙보다 위쪽에 배치)
          if (!_game.isGameStarted)
            Align(
              alignment: const Alignment(0, -0.3),
              child: Text(
                _game.isGameOver
                    ? '$kGameOverLabel\n$kScoreLabel: ${_game.score}'
                    : kInstructionMsg,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),

          // 카운트다운 표시
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
          // 게임 시작 버튼
          if (!_game.isGameStarted && !_isStartingCountdown && !_game.isGameOver)
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
                    color: Colors.white.withOpacity(0.1),
                  ),
                  child: const Center(
                    child: Text(
                      kStartButtonLabel,
                      style: TextStyle(fontSize: 20, color: Colors.white),
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
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 2),
                    borderRadius: BorderRadius.circular(30),
                    color: Colors.white.withOpacity(0.1),
                  ),
                  child: const Center(
                    child: Text(
                      kRetryButtonLabel,
                      style: TextStyle(fontSize: 20, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
