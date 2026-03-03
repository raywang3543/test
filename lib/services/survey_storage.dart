import 'dart:convert';
import '../database/database_helper.dart';
import '../models/survey_model.dart';
import 'user_storage.dart';

class SurveyStorage {
  static final _db = DatabaseHelper();

  /// 保存测试题（新建或覆盖）
  static Future<void> save(Survey survey) async {
    await _db.saveSurvey(
      uid: survey.uid,
      questionsJson: jsonEncode(survey.questions.map((q) => q.toJson()).toList()),
      createdAt: survey.createdAt?.toIso8601String(),
      creatorBasicInfo: survey.creatorBasicInfo,
    );
  }

  /// 加载所有测试题
  static Future<List<Survey>> loadAll() async {
    final rows = await _db.getAllSurveys();
    return rows.map(_rowToSurvey).toList();
  }

  /// 根据创建者 UID 加载测试题
  static Future<Survey?> loadByUid(String uid) async {
    final row = await _db.getSurveyByUid(uid);
    if (row == null) return null;
    return _rowToSurvey(row);
  }

  /// 加载当前用户的测试题
  static Future<Survey?> loadCurrentUserSurvey() async {
    final uid = await UserStorage.getOrCreateUid();
    return loadByUid(uid);
  }

  /// 获取所有有测试题的创建者 UID 列表
  static Future<List<String>> getAllUids() async {
    final surveys = await loadAll();
    return surveys.map((s) => s.uid).toList();
  }

  /// 检查指定 UID 是否有测试题
  static Future<bool> hasSurvey(String uid) async {
    final row = await _db.getSurveyByUid(uid);
    return row != null;
  }

  /// 删除指定 UID 的测试题
  static Future<void> deleteByUid(String uid) async {
    await _db.deleteSurveyByUid(uid);
  }

  /// 清除所有测试题
  static Future<void> clearAll() async {
    await _db.deleteAllSurveys();
  }

  /// @deprecated 仅用于兼容旧代码，始终返回 null
  static Future<Survey?> load() async => null;

  static Survey _rowToSurvey(Map<String, dynamic> row) {
    final questions = (jsonDecode(row['questionsJson'] as String) as List)
        .map((q) => SurveyQuestion.fromJson(q as Map<String, dynamic>))
        .toList();
    return Survey(
      id: row['id'] as int?,
      uid: row['uid'] as String,
      questions: questions,
      createdAt: row['createdAt'] != null
          ? DateTime.parse(row['createdAt'] as String)
          : null,
      creatorBasicInfo: row['creatorBasicInfo'] as String? ?? '',
    );
  }
}
