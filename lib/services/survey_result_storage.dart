import '../database/database_helper.dart';
import '../services/user_storage.dart';

/// 答题结果存储服务 - 通过服务器 API 操作
class SurveyResultStorage {
  static final _db = DatabaseHelper();

  /// 保存答题结果
  static Future<void> saveResult({
    required String creatorUid,
    required int totalScore,
  }) async {
    final answererUid = await UserStorage.getOrCreateUid();
    await _db.saveEvent(
      answererUid: answererUid,
      creatorUid: creatorUid,
      totalScore: totalScore,
    );
  }

  /// 加载当前用户的最新答题结果
  static Future<Map<String, dynamic>?> loadCurrentUserLatestResult() async {
    final uid = await UserStorage.getOrCreateUid();
    return await _db.getLatestEvent(uid);
  }

  /// 根据 UID 加载该用户的所有答题记录
  static Future<List<Map<String, dynamic>>> loadResultsByUid(String uid) async {
    return await _db.getEventsByAnswererUid(uid);
  }

  /// 加载当前用户的所有答题记录
  static Future<List<Map<String, dynamic>>> loadCurrentUserResults() async {
    final uid = await UserStorage.getOrCreateUid();
    return await _db.getEventsByAnswererUid(uid);
  }

  /// 加载所有答题记录
  static Future<List<Map<String, dynamic>>> loadAllResults() async {
    return await _db.getAllEvents();
  }

  /// 加载答了指定出题人题目的所有记录
  static Future<List<Map<String, dynamic>>> loadResultsByCreatorUid(
      String creatorUid) async {
    return await _db.getEventsByCreatorUid(creatorUid);
  }

  /// 清除所有答题记录
  static Future<void> clearAll() async {
    await _db.deleteAllEvents();
  }

  /// 清除当前用户的所有答题记录
  static Future<void> clearCurrentUserResults() async {
    final uid = await UserStorage.getOrCreateUid();
    await _db.deleteEventsByAnswererUid(uid);
  }
}
