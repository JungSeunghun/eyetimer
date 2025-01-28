import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();

  DatabaseHelper._internal();

  static const String _databaseName = 'photos.db';
  static const int _databaseVersion = 2; // 데이터베이스 버전을 2로 변경

  static const String photoTable = 'photos';
  static const String columnId = 'id';
  static const String columnFilePath = 'file_path';
  static const String columnTimestamp = 'timestamp';
  static const String columnMemo = 'memo';

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $photoTable (
        $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnFilePath TEXT NOT NULL,
        $columnTimestamp TEXT NOT NULL,
        $columnMemo TEXT
      )
    ''');
  }

  // 데이터베이스 버전이 변경되었을 때 실행되는 메서드
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // memo 컬럼 추가
      await db.execute('ALTER TABLE $photoTable ADD COLUMN $columnMemo TEXT');
    }
  }
}
