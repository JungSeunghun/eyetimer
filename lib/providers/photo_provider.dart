import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/photo.dart';
import '../../services/photo_service.dart';

class PhotoProvider extends ChangeNotifier {
  final PhotoService _photoService = PhotoService();
  List<Photo> _todayPhotos = [];
  List<Photo> _allPhotos = [];
  Map<String, List<Photo>> _groupedPhotos = {};

  List<Photo> get todayPhotos => _todayPhotos;
  List<Photo> get allPhotos => _allPhotos;
  Map<String, List<Photo>> get groupedPhotos => _groupedPhotos;

  PhotoProvider() {
    loadTodayPhotos();
    loadAllPhotos();
  }

  /// 오늘 날짜의 사진을 불러오는 메서드
  Future<void> loadTodayPhotos() async {
    _todayPhotos = await _photoService.getTodayPhotos();
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
    _todayPhotos.insert(0, photo);
    _allPhotos.insert(0, photo);
    _groupPhotosByDate();
    await loadAllPhotos();
    notifyListeners();
  }

  /// 사진 메모 업데이트 메서드
  Future<void> updatePhotoMemo(int photoId, String updatedMemo) async {
    await _photoService.updatePhotoMemo(photoId, updatedMemo);
    await loadTodayPhotos();
    await loadAllPhotos();
  }

  /// 사진 삭제 메서드
  Future<void> deletePhoto(int photoId) async {
    await _photoService.deletePhoto(photoId);
    await loadTodayPhotos();
    await loadAllPhotos();
  }
}
