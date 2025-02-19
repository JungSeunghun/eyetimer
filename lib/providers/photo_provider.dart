import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../../models/photo.dart';
import '../../services/photo_service.dart';
import '../../components/memo_input_dialog.dart';

class PhotoProvider extends ChangeNotifier {
  final PhotoService _photoService = PhotoService();
  final ImagePicker _picker = ImagePicker();

  List<Photo> _todayPhotos = [];
  List<Photo> _allPhotos = [];
  Map<String, List<Photo>> _groupedPhotos = {};

  List<Photo> get todayPhotos => _todayPhotos;
  List<Photo> get allPhotos => _allPhotos;
  Map<String, List<Photo>> get groupedPhotos => _groupedPhotos;

  PhotoProvider() {
    _init();
  }

  Future<void> _init() async {
    // 초기 데이터 로딩
    await Future.wait([
      loadTodayPhotosWithCache(),
      loadAllPhotos(),
    ]);
  }

  /// 오늘 날짜의 사진을 불러오고, precacheImage까지 수행하는 메서드
  Future<void> loadTodayPhotosWithCache([BuildContext? context]) async {
    _todayPhotos = await _photoService.getTodayPhotos();
    if (context != null) {
      for (var photo in _todayPhotos) {
        await precacheImage(
          ResizeImage(
            FileImage(File(photo.filePath)),
            width: 512,
            height: 512,
          ),
          context,
        );
      }
    }
    notifyListeners();
  }

  /// 모든 사진을 불러와 날짜별로 그룹화하는 메서드
  Future<void> loadAllPhotos() async {
    _allPhotos = await _photoService.getAllPhotos();
    _groupPhotosByDate();
    notifyListeners();
  }

  /// 날짜별로 사진을 그룹화하는 내부 메서드
  void _groupPhotosByDate() {
    final Map<String, List<Photo>> grouped = {};
    for (final photo in _allPhotos) {
      final date = DateFormat('yyyy-MM-dd').format(DateTime.parse(photo.timestamp));
      grouped.putIfAbsent(date, () => []).add(photo);
    }
    // 각 날짜 그룹 내의 사진을 최신순으로 정렬
    grouped.forEach((key, value) {
      value.sort((a, b) => DateTime.parse(b.timestamp).compareTo(DateTime.parse(a.timestamp)));
    });
    _groupedPhotos = grouped;
  }

  /// 사진 추가 메서드
  Future<void> addPhoto(Photo photo) async {
    // 기존에 저장한 사진이므로 다시 저장하지 않고, 리스트에 추가만 합니다.
    _todayPhotos.insert(0, photo);
    _allPhotos.insert(0, photo);
    _groupPhotosByDate();
    notifyListeners();
  }

  /// 사진 메모 업데이트 메서드
  Future<void> updatePhotoMemo(int photoId, String updatedMemo) async {
    await _photoService.updatePhotoMemo(photoId, updatedMemo);
    await loadTodayPhotosWithCache();
    await loadAllPhotos();
  }

  /// 사진 삭제 메서드
  Future<void> deletePhoto(int photoId) async {
    await _photoService.deletePhoto(photoId);
    await loadTodayPhotosWithCache();
    await loadAllPhotos();
  }

  /// 사진 촬영 및 저장 메서드 (BuildContext가 필요함)
  Future<void> takePhoto(BuildContext context) async {
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

        // PhotoService.savePhoto가 새로 저장된 사진의 id를 반환하도록 수정되어 있다고 가정
        final int newId = await _photoService.savePhoto(newPath, timestamp, memo);

        // 새 Photo 객체 생성
        final newPhoto = Photo(
          id: newId,
          filePath: newPath,
          timestamp: timestamp,
          memo: memo,
        );

        await addPhoto(newPhoto);
      }
    } catch (e) {
      print("Error saving photo: $e");
    }
  }
}
