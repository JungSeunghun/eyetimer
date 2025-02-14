import 'dart:async';
import 'dart:typed_data';
import 'package:camera/camera.dart' as cam;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';

/// YUV420 데이터를 NV21로 변환 (별도 Isolate에서 실행)
Uint8List convertYUV420toNV21Isolate(Map<String, dynamic> data) {
  final int width = data['width'] as int;
  final int height = data['height'] as int;
  final Uint8List yBytes = (data['plane0']['bytes'] as Uint8List);
  final int ySize = yBytes.length;
  final int uvWidth = width ~/ 2;
  final int uvHeight = height ~/ 2;
  final Uint8List nv21 = Uint8List(ySize + uvWidth * uvHeight * 2);
  nv21.setRange(0, ySize, yBytes);

  int uvIndex = ySize;
  final Uint8List uBytes = (data['plane1']['bytes'] as Uint8List);
  final Uint8List vBytes = (data['plane2']['bytes'] as Uint8List);
  final int uBytesPerRow = data['plane1']['bytesPerRow'] as int;
  final int vBytesPerRow = data['plane2']['bytesPerRow'] as int;

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
  static const double kEyeOpenThreshold = 0.1;
  static const int kBlinkCooldownMs = 150;

  cam.CameraController? _cameraController;
  bool isCameraInitialized = false;
  bool _isDetecting = false;
  late final FaceDetector _faceDetector;

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

  Future<cam.CameraDescription> _getFrontCamera() async {
    final cameras = await cam.availableCameras();
    return cameras.firstWhere(
          (camera) => camera.lensDirection == cam.CameraLensDirection.front,
      orElse: () => throw Exception('전면 카메라를 찾을 수 없습니다.'),
    );
  }

  Future<void> startCameraStream() async {
    final frontCamera = await _getFrontCamera();
    _cameraController = cam.CameraController(
      frontCamera,
      cam.ResolutionPreset.high,
      enableAudio: false,
    );

    try {
      await _cameraController!.initialize();
      isCameraInitialized = true;
      await _cameraController!.startImageStream((cam.CameraImage image) {
        final now = DateTime.now();

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

  /// 공통적으로 YUV 데이터를 구성하는 헬퍼 함수
  Map<String, dynamic> _buildYuvData(cam.CameraImage image) {
    return {
      'width': image.width,
      'height': image.height,
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

  Future<List<Face>> _detectFacesOnFrame(cam.CameraImage image) async {
    final int width = image.width;
    final int height = image.height;
    final platform = defaultTargetPlatform;
    late Uint8List bytes;
    late InputImageFormat imageFormat;

    // iOS나 기타 플랫폼에서는 WriteBuffer를 활용
    Uint8List _concatenatePlanes(List<cam.Plane> planes) {
      final WriteBuffer allBytes = WriteBuffer();
      for (final plane in planes) {
        allBytes.putUint8List(plane.bytes);
      }
      return allBytes.done().buffer.asUint8List();
    }

    if (platform == TargetPlatform.android) {
      final int rawFormat = image.format.raw;
      // 안드로이드의 경우 rawFormat 35와 그 외의 경우를 구분
      if (rawFormat == 35 || rawFormat != 17) {
        final Map<String, dynamic> yuvData = _buildYuvData(image);
        bytes = await compute(convertYUV420toNV21Isolate, yuvData);
        imageFormat = InputImageFormat.nv21;
      } else if (rawFormat == 17) {
        bytes = _concatenatePlanes(image.planes);
        imageFormat = InputImageFormat.nv21;
      }
    } else if (platform == TargetPlatform.iOS) {
      bytes = _concatenatePlanes(image.planes);
      imageFormat = InputImageFormat.bgra8888;
    } else {
      final Map<String, dynamic> yuvData = _buildYuvData(image);
      bytes = await compute(convertYUV420toNV21Isolate, yuvData);
      imageFormat = InputImageFormat.nv21;
    }

    final imageSize = Size(width.toDouble(), height.toDouble());
    // _cameraController가 null이 아닐 때만 rotation을 가져옴
    final rotation = _cameraController != null
        ? _rotationIntToImageRotation(_cameraController!.description.sensorOrientation)
        : InputImageRotation.rotation0deg;

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

  void checkBlinking(List<Face> faces, void Function() onBlinkLeft, void Function() onBlinkRight) {
    if (faces.isEmpty) return;
    final face = faces.first;
    final leftProb = face.leftEyeOpenProbability ?? 1.0;
    final rightProb = face.rightEyeOpenProbability ?? 1.0;
    final now = DateTime.now();

    // 왼쪽 눈만 깜빡인 경우
    if (leftProb < kEyeOpenThreshold) {
      onBlinkLeft();
    }
    // 오른쪽 눈만 깜빡인 경우
    else if (rightProb < kEyeOpenThreshold) {
      onBlinkRight();
    }
  }

  void dispose() {
    _cameraController?.dispose();
    _faceDetector.close();
  }
}
