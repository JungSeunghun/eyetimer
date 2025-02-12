import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/photo.dart';
import '../table/photo_table.dart';

class PhotoRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  /// 📌 사진 삽입
  Future<int> insertPhoto(Photo photo) async {
    final db = await _databaseHelper.database;
    return await db.insert(
      PhotoTable.tableName,
      photo.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 📌 모든 사진 가져오기
  Future<List<Photo>> getAllPhotos() async {
    final db = await _databaseHelper.database;
    final result = await db.query(PhotoTable.tableName);
    return result.map((json) => Photo.fromMap(json)).toList();
  }

  /// 📌 오늘 찍은 사진 가져오기
  Future<List<Photo>> getTodayPhotos() async {
    final db = await _databaseHelper.database;
    final todayDate = DateTime.now().toIso8601String().split('T')[0]; // YYYY-MM-DD 형식 변환 최적화

    final result = await db.query(
      PhotoTable.tableName,
      where: '${PhotoTable.columnTimestamp} LIKE ?',
      whereArgs: ['$todayDate%'],
      orderBy: '${PhotoTable.columnTimestamp} DESC',
    );

    return result.map(Photo.fromMap).toList();
  }

  /// 📌 특정 ID로 사진 가져오기
  Future<Photo?> getPhotoById(int id) async {
    final db = await _databaseHelper.database;
    final result = await db.query(
      PhotoTable.tableName,
      where: '${PhotoTable.columnId} = ?',
      whereArgs: [id],
    );

    return result.isNotEmpty ? Photo.fromMap(result.first) : null;
  }

  /// 📌 사진 메모 업데이트
  Future<void> updatePhotoMemo(int id, String memo) async {
    final db = await _databaseHelper.database;
    await db.update(
      PhotoTable.tableName,
      {PhotoTable.columnMemo: memo},
      where: '${PhotoTable.columnId} = ?',
      whereArgs: [id],
    );
  }

  /// 📌 사진 삭제
  Future<void> deletePhoto(int id) async {
    final db = await _databaseHelper.database;
    await db.delete(
      PhotoTable.tableName,
      where: '${PhotoTable.columnId} = ?',
      whereArgs: [id],
    );
  }
}
