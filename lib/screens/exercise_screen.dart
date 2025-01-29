import 'dart:math' as math;
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
// ML Kit Face Detection
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';

class ExerciseScreen extends StatefulWidget {
  const ExerciseScreen({Key? key}) : super(key: key);

  @override
  State<ExerciseScreen> createState() => _ExerciseScreenState();
}

class _ExerciseScreenState extends State<ExerciseScreen> {
  CameraController? _cameraController;
  late FaceDetector _faceDetector;

  bool _isDetecting = false;

  bool _faceFound = false;    // 얼굴이 존재하는지
  bool _isBlinking = false;   // 눈이 깜빡임(두 눈 모두 감김) 상태인지
  bool _isCameraInitialized = false;

  @override
  void initState() {
    super.initState();
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableClassification: true,   // 꼭 true 이어야 eyeOpenProbability 사용 가능
        enableTracking: true,
      ),
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _faceDetector.close();
    super.dispose();
  }

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
        const SnackBar(content: Text('전면 카메라를 찾을 수 없습니다.')),
      );
      return;
    }

    // 해상도를 높여야(예: high) 눈 인식 확률이 올라감
    _cameraController = CameraController(
      frontCamera,
      ResolutionPreset.high,
      enableAudio: false,
    );

    try {
      await _cameraController!.initialize();
      if (!mounted) return;

      setState(() {
        _isCameraInitialized = true;
        _faceFound = false;
        _isBlinking = false;
      });

      // 카메라 이미지 스트림 처리
      await _cameraController!.startImageStream((CameraImage image) {
        if (_isDetecting) return;
        _isDetecting = true;

        _detectFacesOnFrame(image).then((faces) {
          // 얼굴 유무
          setState(() {
            _faceFound = faces.isNotEmpty;
          });
          _isDetecting = false;
        }).catchError((error) {
          debugPrint('얼굴 인식 오류: $error');
          _isDetecting = false;
        });
      });
    } catch (e) {
      debugPrint('카메라 초기화 오류: $e');
    }
  }

  /// 얼굴 인식 + 눈 깜빡임 감지
  Future<List<Face>> _detectFacesOnFrame(CameraImage image) async {
    final rawFormat = image.format.raw;
    final platform = defaultTargetPlatform;

    late Uint8List bytes;
    late InputImageFormat imageFormat;

    // 안드로이드 vs iOS 분기
    if (platform == TargetPlatform.android) {
      if (rawFormat == 35) {
        // YUV_420_888 => NV21 변환
        bytes = _yuv420toNV21(image);
        imageFormat = InputImageFormat.nv21;
      } else if (rawFormat == 17) {
        // 이미 NV21
        final WriteBuffer allBytes = WriteBuffer();
        for (Plane plane in image.planes) {
          allBytes.putUint8List(plane.bytes);
        }
        bytes = allBytes.done().buffer.asUint8List();
        imageFormat = InputImageFormat.nv21;
      } else {
        // 그 외 포맷도 일단 YUV->NV21
        bytes = _yuv420toNV21(image);
        imageFormat = InputImageFormat.nv21;
      }
    } else if (platform == TargetPlatform.iOS) {
      // iOS BGRA8888 가정
      final WriteBuffer allBytes = WriteBuffer();
      for (Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      bytes = allBytes.done().buffer.asUint8List();
      imageFormat = InputImageFormat.bgra8888;
    } else {
      // 기타 플랫폼 → 기본적으로 NV21 처리
      bytes = _yuv420toNV21(image);
      imageFormat = InputImageFormat.nv21;
    }

    final imageSize = Size(
      image.width.toDouble(),
      image.height.toDouble(),
    );
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

    // 실제로 얼굴 인식
    final faces = await _faceDetector.processImage(inputImage);

    // [추가] 눈 깜빡임(= 두 눈 확률이 모두 낮을 때) 감지
    _checkBlinking(faces);

    return faces;
  }

  /// 눈 깜빡임 여부 체크
  void _checkBlinking(List<Face> faces) {
    if (faces.isEmpty) {
      // 얼굴 자체가 없으므로 깜빡임 false
      setState(() => _isBlinking = false);
      return;
    }

    // 일단 첫 번째 얼굴만 확인 (필요 시 여러 얼굴도 순회 가능)
    final face = faces.first;

    // eyeOpenProbability는 enableClassification=true여야만 값이 제공됨
    final leftProb = face.leftEyeOpenProbability;
    final rightProb = face.rightEyeOpenProbability;

    // 값이 null이면 지원 안 되는 경우도 있음
    if (leftProb != null && rightProb != null) {
      // 두 눈 모두 충분히 낮으면 '깜빡임'으로 판별 (임계값 0.3 예시)
      final bool isBlinkNow = (leftProb < 0.3 && rightProb < 0.3);
      setState(() {
        _isBlinking = isBlinkNow;
      });
    } else {
      // 값이 없으면 깜빡임 판단 불가
      setState(() => _isBlinking = false);
    }
  }

  /// YUV_420_888 -> NV21 변환 (안드로이드용)
  Uint8List _yuv420toNV21(CameraImage image) {
    final yPlane = image.planes[0];
    final uPlane = image.planes[1];
    final vPlane = image.planes[2];

    final int ySize = yPlane.bytes.length;
    final int uvWidth = image.width ~/ 2;
    final int uvHeight = image.height ~/ 2;

    final Uint8List nv21 = Uint8List(ySize + uvWidth * uvHeight * 2);

    // 1) Y plane 복사
    nv21.setRange(0, ySize, yPlane.bytes);

    // 2) U/V plane 인터리브
    int uvIndex = ySize;
    for (int row = 0; row < uvHeight; row++) {
      final int vRowOffset = row * vPlane.bytesPerRow;
      final int uRowOffset = row * uPlane.bytesPerRow;

      for (int col = 0; col < uvWidth; col++) {
        final int vOffset = vRowOffset + col;
        final int uOffset = uRowOffset + col;

        if (vOffset < vPlane.bytes.length && uOffset < uPlane.bytes.length) {
          // 순서 바꿔가며 테스트 가능
          nv21[uvIndex++] = vPlane.bytes[vOffset];
          nv21[uvIndex++] = uPlane.bytes[uOffset];
        }
      }
    }

    return nv21;
  }

  /// 센서 방향 → ML Kit 회전값 변환
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

  @override
  Widget build(BuildContext context) {
    // UI에서 깜빡임 상태 / 얼굴 인식 여부 표시
    String statusText;
    if (_isBlinking) {
      statusText = '깜빡임';
    } else {
      statusText = _faceFound ? '인식이 완료됐습니다.' : '인식 중입니다.';
    }

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: _isCameraInitialized && _cameraController != null
                ? Transform(
              alignment: Alignment.center,
              transform: Matrix4.rotationY(math.pi),
              child: RotatedBox(
                quarterTurns: 3,
                child: CameraPreview(_cameraController!),
              ),
            )
                : const Center(
              child: Text(
                '카메라가 준비되지 않았습니다.',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              statusText,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            onPressed: _startCamera,
            child: const Text('시작'),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
