import '../models/vision_care.dart';
import '../repositories/vision_care_repository.dart';

class VisionCareService {
  final VisionCareRepository _repository = VisionCareRepository();

  /// 📌 시력 데이터 저장
  Future<void> saveVision(VisionCare vision) async {
    if (vision.id == null) {
      await _repository.insertVision(vision);
    } else {
      await _repository.updateVision(vision);
    }
  }

  /// 📌 시력 데이터 불러오기
  Future<List<VisionCare>> getVisionHistory() async {
    return await _repository.getAllVisions();
  }

  /// 📌 시력 데이터 삭제
  Future<void> deleteVision(int id) async {
    await _repository.deleteVision(id);
  }
}
