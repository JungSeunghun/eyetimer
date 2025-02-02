// lib/services/camera_service.dart
import 'dart:async';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:camera/camera.dart' as cam;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';

class CameraService {
  static const double kEyeOpenThreshold = 0.2;
  static const int kBlinkCooldownMs = 100;

  cam.CameraController? _cameraController;
  bool isCameraInitialized = false;
  bool _isDetecting = false;
  late FaceDetector _faceDetector;

  DateTime _lastBlinkTime = DateTime.now();

  cam.CameraController? get cameraController => _cameraController;

  final void Function(List<Face> faces) onFacesDetected;

  CameraService({required this.onFacesDetected}) {
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableClassification: true,
        enableTracking: true,
        performanceMode: FaceDetectorMode.accurate,
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
      cam.ResolutionPreset.ultraHigh,
      enableAudio: false,
    );

    try {
      await _cameraController!.initialize();
      isCameraInitialized = true;
      await _cameraController!.startImageStream((cam.CameraImage image) {
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
    final rotation = _rotationIntToImageRotation(_cameraController!.description.sensorOrientation);

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

  /// 변환 함수: YUV420 -> NV21
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
