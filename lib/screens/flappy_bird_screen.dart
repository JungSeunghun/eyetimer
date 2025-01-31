import 'dart:async';
import 'dart:typed_data';
import 'dart:math' as math;

import 'package:camera/camera.dart' as cam;
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
// ML Kit
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';

class FlappyBirdGame extends FlameGame {
  static const double kJumpForce = -4;
  static const double kGravity = 0.2;
  static const double kBarrierGap = 0.4;
  static const double kBarrierWidth = 0.2;
  static const double kBarrierSpeed = 0.03;
  static const double kBirdXCenter = 0.3;
  static const double kBarrierInitialX = 1.5;
  static const double kMaxRandomXOffset = 0.2;
  static const double kMaxRandomTopHeight = 0.2;
  static const double kBirdSize = 50;
  static const double kBirdRotationMultiplier = 0.03;
  static const double kBirdVelocityMultiplier = 0.02;
  static const double kCeilingFloorHeight = 30;
  static const double kBirdHitboxHalfSize = 25;

  final math.Random _random = math.Random();

  late double screenW;
  late double screenH;

  bool isGameStarted = false;
  bool isGameOver = false;
  bool hasPassedPipe = false;

  double birdY = 0;
  double birdVelocity = 0;

  double barrierX = kBarrierInitialX;
  double barrierTopHeight = 0.3;

  int score = 0;

  FlappyBirdGame();

  // Add callbacks
  VoidCallback? onScoreChanged;
  VoidCallback? onGameOver;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
  }

  @override
  void onGameResize(Vector2 canvasSize) {
    super.onGameResize(canvasSize);
    screenW = canvasSize.x;
    screenH = canvasSize.y;
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (screenW <= 0 || screenH <= 0) return;
    if (!isGameStarted || isGameOver) return;

    // 중력
    birdVelocity += kGravity;
    birdY += birdVelocity * kBirdVelocityMultiplier;

    // 파이프 이동
    barrierX -= kBarrierSpeed;

    // 점수 증가(파이프를 지나칠 때)
    final pipeRight = barrierX * screenW + (screenW * kBarrierWidth);
    final birdRight = (screenW * kBirdXCenter) + kBirdSize;
    if (!hasPassedPipe && birdRight > pipeRight) {
      score++;
      hasPassedPipe = true;
      onScoreChanged?.call(); // Notify UI
    }

    // 파이프가 화면 밖으로 벗어나면 재생성
    if (barrierX < -1.8) {
      barrierX = kBarrierInitialX + _random.nextDouble() * kMaxRandomXOffset;
      barrierTopHeight = _random.nextDouble() * kMaxRandomTopHeight;
      hasPassedPipe = false;
    }

    // 천장/바닥 충돌
    final birdCenterY = screenH * 0.5 + birdY * 100;
    final birdTop = birdCenterY - kBirdHitboxHalfSize;
    final birdBottom = birdCenterY + kBirdHitboxHalfSize;

    if (birdTop < kCeilingFloorHeight ||
        birdBottom > screenH - kCeilingFloorHeight - kBirdHitboxHalfSize) {
      endGame();
      return;
    }

    // 파이프 충돌
    final pipeLeft = barrierX * screenW;
    final pipeR = pipeLeft + (screenW * kBarrierWidth);
    final birdLeft = (screenW * kBirdXCenter);
    final birdR = birdLeft + kBirdSize;

    final isXOverlap = (birdR > pipeLeft) && (birdLeft < pipeR);
    if (isXOverlap) {
      final topPipeBottom = screenH * barrierTopHeight;
      final gapHeight = screenH * kBarrierGap;
      final bottomPipeTop = topPipeBottom + gapHeight;

      if (birdTop < topPipeBottom || birdBottom > bottomPipeTop) {
        endGame();
      }
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    if (screenW == 0 || screenH == 0) return;

    // 천장
    final ceilingRect = Rect.fromLTWH(0, 0, screenW, kCeilingFloorHeight);
    canvas.drawRect(ceilingRect, Paint()..color = Colors.brown);

    // 바닥
    final floorRect = Rect.fromLTWH(
      0,
      screenH - kCeilingFloorHeight,
      screenW,
      kCeilingFloorHeight,
    );
    canvas.drawRect(floorRect, Paint()..color = Colors.brown);

    // 파이프
    final topPipeRect = Rect.fromLTWH(
      barrierX * screenW,
      0,
      screenW * kBarrierWidth,
      screenH * barrierTopHeight,
    );
    final bottomPipeRect = Rect.fromLTWH(
      barrierX * screenW,
      screenH * barrierTopHeight + screenH * kBarrierGap,
      screenW * kBarrierWidth,
      screenH * (1 - barrierTopHeight - kBarrierGap),
    );
    canvas.drawRect(topPipeRect, Paint()..color = Colors.green);
    canvas.drawRect(bottomPipeRect, Paint()..color = Colors.green);

    // 새 그리기
    final birdCenterY = screenH * 0.5 + birdY * 100;
    final birdTop = birdCenterY - kBirdSize / 2;

    final angle = birdVelocity * kBirdRotationMultiplier;
    canvas.save();
    canvas.translate(screenW * kBirdXCenter + kBirdSize / 2, birdTop + kBirdSize / 2);
    canvas.rotate(angle);
    canvas.translate(-(screenW * kBirdXCenter + kBirdSize / 2), -(birdTop + kBirdSize / 2));

    final birdRect = Rect.fromLTWH(
      screenW * kBirdXCenter,
      birdTop,
      kBirdSize,
      kBirdSize,
    );
    canvas.drawRect(birdRect, Paint()..color = Colors.yellow);
    canvas.restore();
  }

  void startGame() {
    isGameStarted = true;
    isGameOver = false;
    score = 0;
    birdY = 0;
    birdVelocity = 0;
    barrierX = kBarrierInitialX + _random.nextDouble() * kMaxRandomXOffset;
    barrierTopHeight = _random.nextDouble() * kMaxRandomTopHeight;
    hasPassedPipe = false;
  }

  void endGame() {
    isGameOver = true;
    isGameStarted = false;
    onGameOver?.call(); // Notify UI
  }

  void onBlink() {
    if (!isGameStarted || isGameOver) return;
    birdVelocity = kJumpForce;
  }
}

class FlappyBirdScreen extends StatefulWidget {
  const FlappyBirdScreen({Key? key}) : super(key: key);

  @override
  State<FlappyBirdScreen> createState() => _FlappyBirdScreenState();
}

class _FlappyBirdScreenState extends State<FlappyBirdScreen> {
  static const String kAppBarTitle = 'Blink to Flap - FlappyBird';
  static const String kNoFrontCameraMsg = '전면 카메라를 찾을 수 없습니다.';
  static const String kFaceDetectionErrorMsg = '얼굴 인식 오류';
  static const String kCameraInitErrorMsg = '카메라 초기화 오류';
  static const String kScoreLabel = 'Score';
  static const String kGameOverLabel = 'Game Over!';
  static const String kInstructionMsg = '눈을 깜빡여 새를 조종하세요!';
  static const String kStartButtonLabel = '게임 시작';
  static const String kRetryButtonLabel = '다시하기';

  static const double kEyeOpenThreshold = 0.2;
  static const int kBlinkCooldownMs = 100;

  cam.CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isDetecting = false;
  late FaceDetector _faceDetector;

  bool _isStartingCountdown = false;
  int _countdown = 3;
  Timer? _countdownTimer;

  DateTime _lastBlinkTime = DateTime.now();

  late FlappyBirdGame _game;

  @override
  void initState() {
    super.initState();
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableClassification: true,
        enableTracking: true,
        performanceMode: FaceDetectorMode.accurate,
        minFaceSize: 0.3,
      ),
    );
    _game = FlappyBirdGame()
      ..onScoreChanged = () {
        setState(() {}); // Rebuild UI when score changes
      }
      ..onGameOver = () {
        setState(() {}); // Rebuild UI when game ends
      };
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _faceDetector.close();
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<cam.CameraDescription?> _getFrontCamera() async {
    final cameras = await cam.availableCameras();
    for (var camera in cameras) {
      if (camera.lensDirection == cam.CameraLensDirection.front) {
        return camera;
      }
    }
    return null;
  }

  Future<void> _startCamera() async {
    final frontCamera = await _getFrontCamera();
    if (frontCamera == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(kNoFrontCameraMsg)),
      );
      return;
    }

    _cameraController = cam.CameraController(
      frontCamera,
      cam.ResolutionPreset.ultraHigh,
      enableAudio: false,
    );

    try {
      await _cameraController!.initialize();
      if (!mounted) return;

      setState(() => _isCameraInitialized = true);

      await _cameraController!.startImageStream((cam.CameraImage image) {
        if (_isDetecting) return;
        _isDetecting = true;

        _detectFacesOnFrame(image).then((faces) {
          _checkBlinking(faces);
          _isDetecting = false;
        }).catchError((error) {
          debugPrint('$kFaceDetectionErrorMsg: $error');
          _isDetecting = false;
        });
      });
    } catch (e) {
      debugPrint('$kCameraInitErrorMsg: $e');
    }
  }

  Future<List<Face>> _detectFacesOnFrame(cam.CameraImage image) async {
    final rawFormat = image.format.raw;
    final platform = defaultTargetPlatform;

    late Uint8List bytes;
    late InputImageFormat imageFormat;

    if (platform == TargetPlatform.android) {
      // NV21로 변환
      if (rawFormat == 35) {
        bytes = _yuv420toNV21(image);
        imageFormat = InputImageFormat.nv21;
      } else if (rawFormat == 17) {
        final WriteBuffer allBytes = WriteBuffer();
        for (cam.Plane plane in image.planes) {
          allBytes.putUint8List(plane.bytes);
        }
        bytes = allBytes.done().buffer.asUint8List();
        imageFormat = InputImageFormat.nv21;
      } else {
        bytes = _yuv420toNV21(image);
        imageFormat = InputImageFormat.nv21;
      }
    } else if (platform == TargetPlatform.iOS) {
      // iOS -> BGRA8888
      final WriteBuffer allBytes = WriteBuffer();
      for (cam.Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      bytes = allBytes.done().buffer.asUint8List();
      imageFormat = InputImageFormat.bgra8888;
    } else {
      bytes = _yuv420toNV21(image);
      imageFormat = InputImageFormat.nv21;
    }

    final imageSize = Size(image.width.toDouble(), image.height.toDouble());
    final rotation = _rotationIntToImageRotation(
      _cameraController!.description.sensorOrientation,
    );

    final inputImage = InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: imageSize,
        rotation: rotation,
        format: imageFormat,
        bytesPerRow: image.planes[0].bytesPerRow,
      ),
    );

    return await _faceDetector.processImage(inputImage);
  }

  void _checkBlinking(List<Face> faces) {
    if (faces.isEmpty) return;
    final face = faces.first;
    final leftProb = face.leftEyeOpenProbability ?? 1.0;
    final rightProb = face.rightEyeOpenProbability ?? 1.0;

    final now = DateTime.now();
    final timeDiff = now.difference(_lastBlinkTime).inMilliseconds;

    if (leftProb < kEyeOpenThreshold &&
        rightProb < kEyeOpenThreshold &&
        timeDiff > kBlinkCooldownMs) {
      _lastBlinkTime = now;
      _game.onBlink();
    }
  }

  Uint8List _yuv420toNV21(cam.CameraImage image) {
    final yPlane = image.planes[0];
    final uPlane = image.planes[1];
    final vPlane = image.planes[2];

    final int ySize = yPlane.bytes.length;
    final int uvWidth = image.width ~/ 2;
    final int uvHeight = image.height ~/ 2;

    final Uint8List nv21 = Uint8List(ySize + uvWidth * uvHeight * 2);
    nv21.setRange(0, ySize, yPlane.bytes);

    int uvIndex = ySize;
    for (int row = 0; row < uvHeight; row++) {
      final int vRowOffset = row * vPlane.bytesPerRow;
      final int uRowOffset = row * uPlane.bytesPerRow;

      for (int col = 0; col < uvWidth; col++) {
        final int vOffset = vRowOffset + col;
        final int uOffset = uRowOffset + col;
        if (vOffset < vPlane.bytes.length && uOffset < uPlane.bytes.length) {
          nv21[uvIndex++] = vPlane.bytes[vOffset];
          nv21[uvIndex++] = uPlane.bytes[uOffset];
        }
      }
    }
    return nv21;
  }

  InputImageRotation _rotationIntToImageRotation(int rotation) {
    switch (rotation) {
      case 90:
        return InputImageRotation.rotation90deg;
      case 180:
        return InputImageRotation.rotation180deg;
      case 270:
        return InputImageRotation.rotation270deg;
      default:
        return InputImageRotation.rotation0deg;
    }
  }

  Future<void> _handleStartButton() async {
    if (!_isCameraInitialized) {
      await _startCamera();
    }
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

  /// "다시하기" 버튼 누를 때 즉시 새 게임 시작
  void _handleRetryButton() {
    // 카메라가 아직 안 켜져 있으면 켜고,
    // 이미 켜져 있으면 바로 startGame() 실행
    if (!_isCameraInitialized) {
      _startCamera().then((_) {
        setState(() {
          _game.startGame();
        });
      });
    } else {
      setState(() {
        _game.startGame();
      });
    }
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
          // 1) 카메라 프리뷰
          Positioned.fill(
            child: _isCameraInitialized && _cameraController != null
                ? Transform(
              alignment: Alignment.center,
              transform: Matrix4.rotationY(math.pi),
              child: RotatedBox(
                quarterTurns: 3,
                child: cam.CameraPreview(_cameraController!),
              ),
            )
                : const Center(child: Text('')),
          ),

          // 2) Flame Game
          Positioned.fill(
            child: GameWidget(
              game: _game,
            ),
          ),

          // 3) UI 오버레이
          // 점수
          Positioned(
            top: 20,
            right: 20,
            child: Text(
              '$kScoreLabel: ${_game.score}',
              style: const TextStyle(fontSize: 24, color: Colors.white),
            ),
          ),

          // 안내 문구 / 게임 오버 문구
          if (!_game.isGameStarted)
            Center(
              child: Text(
                _game.isGameOver
                    ? '$kGameOverLabel\n$kScoreLabel: ${_game.score}\n\n'
                    : kInstructionMsg,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),

          // 카운트다운
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

          // "게임 시작" 버튼 (게임이 오버가 아닐 때, 아직 시작 전이면 표시)
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

          // "다시하기" 버튼 (게임 오버일 때만 표시)
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
