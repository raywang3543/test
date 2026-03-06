import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/database_helper.dart';
import '../models/user_model.dart';

/// 数据迁移服务 - 将 SharedPreferences 数据迁移到 SQLite
class DataMigration {
  static bool _hasMigrated = false;

  /// 执行数据迁移
  /// 将 SharedPreferences 中的旧数据迁移到 SQLite，然后清理旧数据
  static Future<void> migrateIfNeeded() async {
    if (_hasMigrated) return;

    final prefs = await SharedPreferences.getInstance();
    final db = DatabaseHelper();

    // 检查是否需要迁移
    final oldUid = prefs.getString('user_uid');
    final oldProfileJson = prefs.getString('user_profile');
    final oldSurveyResults = prefs.getString('survey_results');
    final oldSavedSurveys = prefs.getString('saved_surveys');

    // 如果没有旧数据，直接标记为已迁移
    if (oldUid == null && oldProfileJson == null && oldSurveyResults == null && oldSavedSurveys == null) {
      _hasMigrated = true;
      return;
    }

    // 迁移 UID：旧 UID 已由 UserStorage 从 SharedPreferences 读取，无需额外处理

    // 迁移用户资料
    if (oldProfileJson != null) {
      try {
        final oldUid = prefs.getString('user_uid');
        if (oldUid != null) {
          final json = jsonDecode(oldProfileJson) as Map<String, dynamic>;
          final profile = UserProfile(
            basicInfo: json['basicInfo'] as String? ?? '',
            detailedInfo: json['detailedInfo'] as String? ?? '',
            passingScore: json['passingScore'] as int?,
          );

          // 保存到 userInfo 表
          await db.saveUserInfo(
            uid: oldUid,
            basicInfo: profile.basicInfo,
            detailedInfo: profile.detailedInfo,
            passingScore: profile.passingScore,
          );
        }
      } catch (e) {
        // 解析失败，忽略
      }
    }

    // 迁移测试题到 survey 表
    if (oldSavedSurveys != null) {
      try {
        final List<dynamic> surveys = jsonDecode(oldSavedSurveys) as List<dynamic>;
        for (final item in surveys) {
          final s = item as Map<String, dynamic>;
          final uid = s['uid'] as String?;
          if (uid == null) continue;
          await db.saveSurvey(
            uid: uid,
            questionsJson: jsonEncode(s['questions'] ?? []),
            createdAt: s['createdAt'] as String?,
            creatorBasicInfo: s['creatorBasicInfo'] as String? ?? '',
          );
        }
      } catch (e) {
        // 解析失败，忽略
      }
    }

    // 迁移答题结果到 event 表
    if (oldSurveyResults != null) {
      try {
        final List<dynamic> results = jsonDecode(oldSurveyResults) as List<dynamic>;
        for (final item in results) {
          final result = item as Map<String, dynamic>;
          final uid = result['uid'] as String?;
          final totalScore = result['totalScore'] as int?;
          final submitTimeStr = result['submitTime'] as String?;

          if (uid != null && totalScore != null) {
            await db.saveEvent(
              answererUid: uid,
              creatorUid: uid, // 旧数据没有出题人信息，使用答题人 UID
              totalScore: totalScore,
              submitTime: submitTimeStr != null
                  ? DateTime.parse(submitTimeStr)
                  : DateTime.now(),
            );
          }
        }
      } catch (e) {
        // 解析失败，忽略
      }
    }

    _hasMigrated = true;
  }

  /// 清理 SharedPreferences 中的旧数据
  static Future<void> clearOldData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_uid');
    await prefs.remove('user_profile');
    await prefs.remove('survey_results');
    await prefs.remove('saved_surveys');
  }

  /// 完整的迁移流程：迁移数据并清理旧数据
  static Future<void> performMigration() async {
    await migrateIfNeeded();
    await clearOldData();
  }
}
