import 'dart:async';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FlappyBirdScreen extends StatefulWidget {
  const FlappyBirdScreen({Key? key}) : super(key: key);

  @override
  State<FlappyBirdScreen> createState() => _FlappyBirdScreenState();
}

class _FlappyBirdScreenState extends State<FlappyBirdScreen>
    with SingleTickerProviderStateMixin {
  // ==================================
  //             상수 정의
  // ==================================

  // 문자열 상수
  static const String kAppBarTitle = 'Blink to Flap - FlappyBird';
  static const String kNoFrontCameraMsg = '전면 카메라를 찾을 수 없습니다.';
  static const String kFaceDetectionErrorMsg = '얼굴 인식 오류';
  static const String kCameraInitErrorMsg = '카메라 초기화 오류';
  static const String kScoreLabel = 'Score';
  static const String kGameOverLabel = 'Game Over!';
  static const String kInstructionMsg = '눈을 깜빡여 새를 조종하세요!';
  static const String kStartButtonLabel = '게임 시작';

  // 숫자 상수
  static const double kJumpForce = -4;
  static const double kGravity = 0.2;
  static const double kBarrierGap = 0.4;
  static const double kBarrierWidth = 0.2;
  static const double kBarrierSpeed = 0.03;
  static const double kBirdXCenter = 0.3;
  static const double kBarrierInitialX = 1.5;
  static const double kMaxRandomXOffset = 0.2;
  static const double kMaxRandomTopHeight = 0.2;
  static const double kBirdSize = 50; // 새의 너비·높이
  static const double kBirdRotationMultiplier = 0.03;
  static const double kBirdVelocityMultiplier = 0.02;
  static const double kCeilingFloorHeight = 30;
  static const double kBirdHitboxHalfSize = 25;
  static const int kCountdownStart = 3;
  static const int kFrameRateMs = 24;

  // 눈 깜빡임 관련
  static const double kEyeOpenThreshold = 0.2;     // 눈이 감겼다고 볼 임계값
  static const int kBlinkCooldownMs = 100;         // 깜빡임 쿨타임(밀리초)

  // 색상 상수
  static const Color kCeilingFloorColor = Colors.brown;
  static const Color kBarrierColor = Colors.green;
  static const Color kBirdColor = Colors.yellow;

  // ==================================
  //       카메라 / MLKit 관련 변수
  // ==================================
  CameraController? _cameraController;
  late FaceDetector _faceDetector;

  bool _isDetecting = false;
  bool _isCameraInitialized = false;

  // ==================================
  //         게임 관련 변수
  // ==================================
  bool _gameStarted = false;
  bool _isGameOver = false;
  bool _hasPassedPipe = false;

  double _birdY = 0;
  double _birdVelocity = 0.0;

  double _barrierX = kBarrierInitialX;
  double _barrierTopHeight = 0.3;

  int _score = 0;

  DateTime _lastBlinkTime = DateTime.now();

  bool _isStartingCountdown = false;
  int _countdown = kCountdownStart;
  Timer? _countdownTimer;

  final math.Random _random = math.Random();

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
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _faceDetector.close();
    _countdownTimer?.cancel();
    super.dispose();
  }

  // ==================================
  //          플래피 버드 로직
  // ==================================
  void _startGame() {
    setState(() {
      _gameStarted = true;
      _isGameOver = false;
      _score = 0;
      _birdY = 0;
      _birdVelocity = 0.0;
      _barrierX = kBarrierInitialX + _random.nextDouble() * kMaxRandomXOffset;
      _barrierTopHeight = _random.nextDouble() * kMaxRandomTopHeight;
      _hasPassedPipe = false;
    });

    final size = MediaQuery.of(context).size;
    const frameRate = Duration(milliseconds: kFrameRateMs);

    Timer.periodic(frameRate, (timer) {
      if (_isGameOver) {
        timer.cancel();
        return;
      }

      // 중력 적용
      _birdVelocity += kGravity;
      _birdY += _birdVelocity * kBirdVelocityMultiplier;

      setState(() {
        _barrierX -= kBarrierSpeed;

        // 새가 파이프를 지나쳤는지 검사 -> 점수 증가
        final pipeRight = _barrierX * size.width + (size.width * kBarrierWidth);
        final birdRight = (size.width * kBirdXCenter) + kBirdSize;

        if (!_hasPassedPipe && birdRight > pipeRight) {
          _score++;
          _hasPassedPipe = true;
        }

        // 파이프가 화면 밖으로 벗어나면 재생성
        if (_barrierX < -1.8) {
          _barrierX = kBarrierInitialX + _random.nextDouble() * kMaxRandomXOffset;
          _barrierTopHeight = _random.nextDouble() * kMaxRandomTopHeight;
          _hasPassedPipe = false;
        }
      });

      // 천장/바닥 충돌 판정
      final birdCenterY = size.height * 0.5 + _birdY * 100;
      final birdTop = birdCenterY - kBirdHitboxHalfSize;
      final birdBottom = birdCenterY + kBirdHitboxHalfSize;

      // (30은 천장/바닥 높이, birdHitboxHalfSize는 새 반지름)
      if (birdTop < kCeilingFloorHeight ||
          birdBottom > size.height - kCeilingFloorHeight - kBirdHitboxHalfSize) {
        _endGame(timer);
      }

      // 파이프 충돌 판정
      final pipeLeft = _barrierX * size.width;
      final pipeRight = pipeLeft + (size.width * kBarrierWidth);

      final birdLeft = (size.width * kBirdXCenter);
      final birdR = birdLeft + kBirdSize;

      // X축으로 겹치는지
      final isXOverlap = (birdR > pipeLeft) && (birdLeft < pipeRight);
      if (isXOverlap) {
        final topPipeBottom = size.height * _barrierTopHeight;
        final gapHeight = size.height * kBarrierGap;
        final bottomPipeTop = topPipeBottom + gapHeight;

        if (birdTop < topPipeBottom || birdBottom > bottomPipeTop) {
          _endGame(timer);
        }
      }
    });
  }

  void _endGame(Timer timer) {
    timer.cancel();
    setState(() {
      _isGameOver = true;
      _gameStarted = false;
      _isStartingCountdown = false;
      _countdown = kCountdownStart;
      _birdY = 0;
      _birdVelocity = 0;
      _barrierX = kBarrierInitialX;
    });
  }

  void _handleBlinkToJump() {
    if (!_gameStarted || _isGameOver) return;
    setState(() {
      _birdVelocity = kJumpForce;
    });
  }

  // ==================================
  //        카메라/ML Kit 로직
  // ==================================
  Future<CameraDescription?> _getFrontCamera() async {
    final cameras = await availableCameras();
    for (var camera in cameras) {
      if (camera.lensDirection == CameraLensDirection.front) {
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

    _cameraController = CameraController(
      frontCamera,
      ResolutionPreset.ultraHigh,
      enableAudio: false,
    );

    try {
      await _cameraController!.initialize();
      if (!mounted) return;

      setState(() => _isCameraInitialized = true);

      // 카메라 스트림 처리
      await _cameraController!.startImageStream((CameraImage image) {
        if (_isDetecting) return;
        _isDetecting = true;

        _detectFacesOnFrame(image).then((faces) {
          setState(() {});
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

  Future<List<Face>> _detectFacesOnFrame(CameraImage image) async {
    final rawFormat = image.format.raw;
    final platform = defaultTargetPlatform;

    late Uint8List bytes;
    late InputImageFormat imageFormat;

    if (platform == TargetPlatform.android) {
      if (rawFormat == 35) {
        bytes = _yuv420toNV21(image);
        imageFormat = InputImageFormat.nv21;
      } else if (rawFormat == 17) {
        final WriteBuffer allBytes = WriteBuffer();
        for (Plane plane in image.planes) {
          allBytes.putUint8List(plane.bytes);
        }
        bytes = allBytes.done().buffer.asUint8List();
        imageFormat = InputImageFormat.nv21;
      } else {
        bytes = _yuv420toNV21(image);
        imageFormat = InputImageFormat.nv21;
      }
    } else if (platform == TargetPlatform.iOS) {
      final WriteBuffer allBytes = WriteBuffer();
      for (Plane plane in image.planes) {
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

    final faces = await _faceDetector.processImage(inputImage);
    _checkBlinking(faces);
    return faces;
  }

  void _checkBlinking(List<Face> faces) {
    if (faces.isEmpty) {
      return;
    }
    final face = faces.first;
    final leftProb = face.leftEyeOpenProbability ?? 1.0;
    final rightProb = face.rightEyeOpenProbability ?? 1.0;

    // 시간 차이 계산
    final now = DateTime.now();
    final timeDiff = now.difference(_lastBlinkTime).inMilliseconds;

    // 두 눈 모두 임계값 이하 & 쿨다운 이후라면 점프 처리
    if (leftProb < kEyeOpenThreshold &&
        rightProb < kEyeOpenThreshold &&
        timeDiff > kBlinkCooldownMs) {
      _lastBlinkTime = now;
      _handleBlinkToJump();
    }

    setState(() {});
  }

  Uint8List _yuv420toNV21(CameraImage image) {
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

    if (!_gameStarted && !_isStartingCountdown) {
      setState(() => _isStartingCountdown = true);

      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() => _countdown--);

        if (_countdown == 0) {
          timer.cancel();
          _startGame();
        }
      });
    }
  }

  // ==================================
  //            빌드 메서드
  // ==================================
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final birdCenterY = size.height * 0.5 + _birdY * 100;
    final birdTop = birdCenterY - kBirdHitboxHalfSize;

    return Scaffold(
      appBar: AppBar(
        title: const Text(kAppBarTitle),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // 카메라 프리뷰
          Positioned.fill(
            child: _isCameraInitialized && _cameraController != null
                ? Transform(
              alignment: Alignment.center,
              transform: Matrix4.rotationY(math.pi),
              child: RotatedBox(
                quarterTurns: 3,
                child: CameraPreview(_cameraController!),
              ),
            )
                : const Center(child: Text('')),
          ),

          // 천장
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: kCeilingFloorHeight,
            child: Container(color: kCeilingFloorColor),
          ),

          // 바닥
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: kCeilingFloorHeight,
            child: Container(color: kCeilingFloorColor),
          ),

          // 파이프
          AnimatedPositioned(
            duration: const Duration(milliseconds: kFrameRateMs),
            left: _barrierX * size.width,
            child: Column(
              children: [
                // 상단 파이프
                Container(
                  width: size.width * kBarrierWidth,
                  height: size.height * _barrierTopHeight,
                  color: kBarrierColor,
                ),
                // 빈 공간
                Container(
                  width: size.width * kBarrierWidth,
                  height: size.height * kBarrierGap,
                  color: Colors.transparent,
                ),
                // 하단 파이프
                Container(
                  width: size.width * kBarrierWidth,
                  height: size.height *
                      (1 - _barrierTopHeight - kBarrierGap),
                  color: kBarrierColor,
                ),
              ],
            ),
          ),

          // 새 아이콘
          AnimatedPositioned(
            duration: const Duration(milliseconds: kFrameRateMs),
            left: size.width * kBirdXCenter,
            top: birdTop,
            child: Transform.rotate(
              angle: _birdVelocity * kBirdRotationMultiplier,
              child: Container(
                width: kBirdSize,
                height: kBirdSize,
                color: kBirdColor,
              ),
            ),
          ),

          // 스코어
          Positioned(
            top: 20,
            right: 20,
            child: Text(
              '$kScoreLabel: $_score',
              style: const TextStyle(fontSize: 24, color: Colors.white),
            ),
          ),

          // 게임 안내 텍스트
          if (!_gameStarted)
            Center(
              child: Text(
                _isGameOver
                    ? '$kGameOverLabel\n$kScoreLabel: $_score\n\n'
                    : kInstructionMsg,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),

          // 카운트다운 표시
          if (!_gameStarted && _isStartingCountdown)
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
          if (!_gameStarted && !_isStartingCountdown)
            Positioned(
              bottom: 50,
              left: size.width * 0.3,
              right: size.width * 0.3,
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
        ],
      ),
    );
  }
}
