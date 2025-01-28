import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/photo.dart';

class PhotoRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  // 사진 삽입
  Future<void> insertPhoto(Photo photo) async {
    final db = await _databaseHelper.database;
    await db.insert(
      DatabaseHelper.photoTable,
      photo.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Photo>> getAllPhotos() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> result = await db.query('photos');
    final List<Photo> resultList = result.map((json) {
      return Photo.fromMap(json);
    }).toList();
    return resultList;
  }


  // 오늘 찍은 사진 가져오기
  Future<List<Photo>> getTodayPhotos() async {
    final db = await _databaseHelper.database;
    final todayDate = DateTime.now().toIso8601String().substring(0, 10); // YYYY-MM-DD

    final result = await db.query(
      DatabaseHelper.photoTable,
      where: '${DatabaseHelper.columnTimestamp} LIKE ?',
      whereArgs: ['$todayDate%'],
      orderBy: '${DatabaseHelper.columnTimestamp} DESC',
    );

    return result.map((map) => Photo.fromMap(map)).toList();
  }

  // 특정 ID로 사진 가져오기
  Future<Photo?> getPhotoById(int id) async {
    final db = await _databaseHelper.database;
    final result = await db.query(
      DatabaseHelper.photoTable,
      where: '${DatabaseHelper.columnId} = ?',
      whereArgs: [id],
    );

    if (result.isNotEmpty) {
      return Photo.fromMap(result.first);
    }
    return null;
  }

  Future<void> updatePhotoMemo(int id, String memo) async {
    final db = await _databaseHelper.database;
    await db.update(
      DatabaseHelper.photoTable,
      {DatabaseHelper.columnMemo: memo},
      where: '${DatabaseHelper.columnId} = ?',
      whereArgs: [id],
    );
  }

  Future<void> deletePhoto(int id) async {
    final db = await _databaseHelper.database;
    await db.delete(
      DatabaseHelper.photoTable,
      where: '${DatabaseHelper.columnId} = ?',
      whereArgs: [id],
    );
  }

}
