// lib/services/camera_service.dart
import 'dart:async';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:camera/camera.dart' as cam;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';

/// 최상위 함수: YUV420 데이터를 NV21로 변환 (별도 Isolate에서 실행)
Uint8List convertYUV420toNV21Isolate(Map<String, dynamic> data) {
  final int width = data['width'] as int;
  final int height = data['height'] as int;
  final Map<String, dynamic> plane0 = data['plane0'];
  final Map<String, dynamic> plane1 = data['plane1'];
  final Map<String, dynamic> plane2 = data['plane2'];
  final Uint8List yBytes = plane0['bytes'] as Uint8List;
  final int ySize = yBytes.length;
  final int uvWidth = width ~/ 2;
  final int uvHeight = height ~/ 2;
  final Uint8List nv21 = Uint8List(ySize + uvWidth * uvHeight * 2);
  nv21.setRange(0, ySize, yBytes);

  int uvIndex = ySize;
  final Uint8List uBytes = plane1['bytes'] as Uint8List;
  final Uint8List vBytes = plane2['bytes'] as Uint8List;
  final int uBytesPerRow = plane1['bytesPerRow'] as int;
  final int vBytesPerRow = plane2['bytesPerRow'] as int;

  for (int row = 0; row < uvHeight; row++) {
    final int vRowOffset = row * vBytesPerRow;
    final int uRowOffset = row * uBytesPerRow;
    for (int col = 0; col < uvWidth; col++) {
      final int vOffset = vRowOffset + col;
      final int uOffset = uRowOffset + col;
      if (vOffset < vBytes.length && uOffset < uBytes.length) {
        nv21[uvIndex++] = vBytes[vOffset];
        nv21[uvIndex++] = uBytes[uOffset];
      }
    }
  }
  return nv21;
}

class CameraService {
  static const double kEyeOpenThreshold = 0.25;
  static const int kBlinkCooldownMs = 100;

  cam.CameraController? _cameraController;
  bool isCameraInitialized = false;
  bool _isDetecting = false;
  late FaceDetector _faceDetector;

  DateTime _lastBlinkTime = DateTime.now();
  DateTime _lastFaceDetectionTime = DateTime.now();

  cam.CameraController? get cameraController => _cameraController;

  final void Function(List<Face> faces) onFacesDetected;

  CameraService({required this.onFacesDetected}) {
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableClassification: true,
        enableTracking: true,
        performanceMode: FaceDetectorMode.fast,
        minFaceSize: 0.3,
      ),
    );
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

  Future<void> startCameraStream() async {
    final frontCamera = await _getFrontCamera();
    if (frontCamera == null) {
      throw Exception('전면 카메라를 찾을 수 없습니다.');
    }

    _cameraController = cam.CameraController(
      frontCamera,
      cam.ResolutionPreset.high, // 낮은 해상도 사용
      enableAudio: false,
    );

    try {
      await _cameraController!.initialize();
      isCameraInitialized = true;
      await _cameraController!.startImageStream((cam.CameraImage image) {
        // 얼굴 인식 호출 주기를 제한 (예: 200ms)
        final now = DateTime.now();
        if (now.difference(_lastFaceDetectionTime).inMilliseconds < 200) return;
        _lastFaceDetectionTime = now;

        if (_isDetecting) return;
        _isDetecting = true;
        _detectFacesOnFrame(image).then((faces) {
          onFacesDetected(faces);
          _isDetecting = false;
        }).catchError((error) {
          debugPrint('얼굴 인식 오류: $error');
          _isDetecting = false;
        });
      });
    } catch (e) {
      throw Exception('카메라 초기화 오류: $e');
    }
  }

  Future<List<Face>> _detectFacesOnFrame(cam.CameraImage image) async {
    // 이미지의 width, height를 지역 변수에 저장하여 여러 번 접근하지 않도록 함.
    final int width = image.width;
    final int height = image.height;
    final platform = defaultTargetPlatform;
    late Uint8List bytes;
    late InputImageFormat imageFormat;

    // 헬퍼 함수: YUV 데이터 구성을 위한 Map 생성 (중복 코드 제거)
    Map<String, dynamic> buildYuvData() {
      return {
        'width': width,
        'height': height,
        'plane0': {
          'bytes': image.planes[0].bytes,
          'bytesPerRow': image.planes[0].bytesPerRow,
        },
        'plane1': {
          'bytes': image.planes[1].bytes,
          'bytesPerRow': image.planes[1].bytesPerRow,
        },
        'plane2': {
          'bytes': image.planes[2].bytes,
          'bytesPerRow': image.planes[2].bytesPerRow,
        },
      };
    }

    if (platform == TargetPlatform.android) {
      final int rawFormat = image.format.raw;
      if (rawFormat == 35) {
        final Map<String, dynamic> yuvData = buildYuvData();
        bytes = await compute(convertYUV420toNV21Isolate, yuvData);
        imageFormat = InputImageFormat.nv21;
      } else if (rawFormat == 17) {
        final WriteBuffer allBytes = WriteBuffer();
        for (final plane in image.planes) {
          allBytes.putUint8List(plane.bytes);
        }
        bytes = allBytes.done().buffer.asUint8List();
        imageFormat = InputImageFormat.nv21;
      } else {
        final Map<String, dynamic> yuvData = buildYuvData();
        bytes = await compute(convertYUV420toNV21Isolate, yuvData);
        imageFormat = InputImageFormat.nv21;
      }
    } else if (platform == TargetPlatform.iOS) {
      final WriteBuffer allBytes = WriteBuffer();
      for (final plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      bytes = allBytes.done().buffer.asUint8List();
      imageFormat = InputImageFormat.bgra8888;
    } else {
      final Map<String, dynamic> yuvData = buildYuvData();
      bytes = await compute(convertYUV420toNV21Isolate, yuvData);
      imageFormat = InputImageFormat.nv21;
    }

    final imageSize = Size(width.toDouble(), height.toDouble());
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

  /// 얼굴 인식 후 깜빡임 체크 (UI나 게임에 전달)
  void checkBlinking(List<Face> faces, void Function() onBlink) {
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
      onBlink();
    }
  }

  void dispose() {
    _cameraController?.dispose();
    _faceDetector.close();
  }
}
