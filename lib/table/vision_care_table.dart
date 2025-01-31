class VisionCareTable {
  static const String tableName = 'vision_care';
  static const String columnId = 'id';
  static const String columnDate = 'date';
  static const String columnLeftEyeVision = 'left_eye_vision';
  static const String columnRightEyeVision = 'right_eye_vision';

  static String createTableQuery = '''
    CREATE TABLE $tableName (
      $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
      $columnDate TEXT NOT NULL,
      $columnLeftEyeVision REAL NOT NULL,  -- 왼쪽 시력 (소수점 허용)
      $columnRightEyeVision REAL NOT NULL  -- 오른쪽 시력 (소수점 허용)
    )
  ''';
}
