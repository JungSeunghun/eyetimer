class VisionCare {
  final int? id; // 자동 증가 (nullable)
  final String date; // YYYY-MM-DD 형식
  final double leftEyeVision; // 왼쪽 시력 (소수점 허용)
  final double rightEyeVision; // 오른쪽 시력 (소수점 허용)

  VisionCare({
    this.id,
    required this.date,
    required this.leftEyeVision,
    required this.rightEyeVision,
  });

  /// 📌 Map -> VisionCare (DB에서 불러오기)
  factory VisionCare.fromMap(Map<String, dynamic> map) {
    return VisionCare(
      id: map['id'],
      date: map['date'],
      leftEyeVision: map['left_eye_vision'],
      rightEyeVision: map['right_eye_vision'],
    );
  }

  /// 📌 VisionCare -> Map (DB에 저장할 때)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'left_eye_vision': leftEyeVision,
      'right_eye_vision': rightEyeVision,
    };
  }
}
