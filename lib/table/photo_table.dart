class PhotoTable {
  static const String tableName = 'photos';
  static const String columnId = 'id';
  static const String columnFilePath = 'file_path';
  static const String columnTimestamp = 'timestamp';
  static const String columnMemo = 'memo';

  static String createTableQuery = '''
    CREATE TABLE $tableName (
      $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
      $columnFilePath TEXT NOT NULL,
      $columnTimestamp TEXT NOT NULL,
      $columnMemo TEXT
    )
  ''';
}
