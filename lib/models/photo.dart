class Photo {
  final int? id;
  final String filePath;
  final String timestamp;
  final String? memo; // 메모 필드 추가 (nullable)

  Photo({this.id, required this.filePath, required this.timestamp, this.memo});

  // 데이터베이스에서 가져온 데이터를 객체로 변환
  factory Photo.fromMap(Map<String, dynamic> map) {
    return Photo(
      id: map['id'],
      filePath: map['file_path'],
      timestamp: map['timestamp'],
      memo: map['memo'], // 메모 필드 추가
    );
  }

  // 객체를 데이터베이스에 삽입할 수 있도록 맵으로 변환
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'file_path': filePath,
      'timestamp': timestamp,
      'memo': memo, // 메모 필드 추가
    };
  }

  factory Photo.fromJson(Map<String, dynamic> json) {
    return Photo(
      id: json['id'] as int?,
      filePath: json['filePath'] as String,
      timestamp: json['timestamp'] as String,
      memo: json['memo'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'filePath': filePath,
      'timestamp': timestamp,
      'memo': memo,
    };
  }
}
