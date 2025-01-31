import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/vision_care.dart';
import '../table/vision_care_table.dart';

class VisionCareRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  /// 📌 시력 데이터 삽입
  Future<void> insertVision(VisionCare vision) async {
    final db = await _databaseHelper.database;
    await db.insert(
      VisionCareTable.tableName,
      vision.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 📌 모든 시력 데이터 가져오기
  Future<List<VisionCare>> getAllVisions() async {
    final db = await _databaseHelper.database;
    final result = await db.query(VisionCareTable.tableName);
    return result.map((json) => VisionCare.fromMap(json)).toList();
  }

  /// 📌 특정 ID의 시력 데이터 가져오기
  Future<VisionCare?> getVisionById(int id) async {
    final db = await _databaseHelper.database;
    final result = await db.query(
      VisionCareTable.tableName,
      where: '${VisionCareTable.columnId} = ?',
      whereArgs: [id],
    );

    return result.isNotEmpty ? VisionCare.fromMap(result.first) : null;
  }

  /// 📌 시력 데이터 업데이트
  Future<void> updateVision(VisionCare vision) async {
    final db = await _databaseHelper.database;
    await db.update(
      VisionCareTable.tableName,
      vision.toMap(),
      where: '${VisionCareTable.columnId} = ?',
      whereArgs: [vision.id],
    );
  }

  /// 📌 시력 데이터 삭제
  Future<void> deleteVision(int id) async {
    final db = await _databaseHelper.database;
    await db.delete(
      VisionCareTable.tableName,
      where: '${VisionCareTable.columnId} = ?',
      whereArgs: [id],
    );
  }
}
