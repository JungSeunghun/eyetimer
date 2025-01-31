import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../table/photo_table.dart';
import '../table/vision_care_table.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();

  DatabaseHelper._internal();

  static const String _databaseName = 'photos.db';
  static const int _databaseVersion = 3; // DB 버전 유지

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
    await db.execute(PhotoTable.createTableQuery);
    await db.execute(VisionCareTable.createTableQuery);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE ${PhotoTable.tableName} ADD COLUMN ${PhotoTable.columnMemo} TEXT');
    }
    if (oldVersion < 3) {
      await db.execute(VisionCareTable.createTableQuery);
    }
  }
}
