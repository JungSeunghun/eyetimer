import '../models/photo.dart';
import '../repositories/photo_repository.dart';

class PhotoService {
  final PhotoRepository _photoRepository = PhotoRepository();

  // 사진 저장 (메모 포함)
  Future<int> savePhoto(String filePath, String timestamp, String? memo) async {
    final photo = Photo(filePath: filePath, timestamp: timestamp, memo: memo);
    final int newId = await _photoRepository.insertPhoto(photo);
    return newId;
  }

  Future<List<Photo>> getAllPhotos() async {
    return await _photoRepository.getAllPhotos();
  }

  // 오늘 찍은 사진 가져오기
  Future<List<Photo>> getTodayPhotos() async {
    return await _photoRepository.getTodayPhotos();
  }

  /// Update the memo for a specific photo
  Future<void> updatePhotoMemo(int id, String memo) async {
    await _photoRepository.updatePhotoMemo(id, memo);
  }

  /// Delete a specific photo from the database
  Future<void> deletePhoto(int id) async {
    await _photoRepository.deletePhoto(id);
  }

}
