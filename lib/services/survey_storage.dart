import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/survey_model.dart';
import 'user_storage.dart';

class SurveyStorage {
  static const _key = 'saved_surveys'; // 改为复数，存储多个测试题

  /// 保存测试题（自动关联当前用户的 UID）
  static Future<void> save(Survey survey) async {
    final prefs = await SharedPreferences.getInstance();
    
    // 读取现有的所有测试题
    final allSurveys = await loadAll();
    
    // 查找是否已有该 UID 的测试题，有则替换，无则添加
    final index = allSurveys.indexWhere((s) => s.uid == survey.uid);
    if (index >= 0) {
      allSurveys[index] = survey;
    } else {
      allSurveys.add(survey);
    }
    
    // 保存所有测试题
    final jsonList = allSurveys.map((s) => s.toJson()).toList();
    await prefs.setString(_key, jsonEncode(jsonList));
  }

  /// 加载所有测试题
  static Future<List<Survey>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_key);
    if (json == null) return [];
    
    try {
      final List<dynamic> list = jsonDecode(json) as List<dynamic>;
      return list
          .map((item) => Survey.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// 根据 UID 加载对应的测试题
  static Future<Survey?> loadByUid(String uid) async {
    final allSurveys = await loadAll();
    try {
      return allSurveys.firstWhere((s) => s.uid == uid);
    } catch (e) {
      return null;
    }
  }

  /// 加载当前用户的测试题
  static Future<Survey?> loadCurrentUserSurvey() async {
    final uid = await UserStorage.getOrCreateUid();
    return loadByUid(uid);
  }

  /// 获取所有有测试题的 UID 列表
  static Future<List<String>> getAllUids() async {
    final allSurveys = await loadAll();
    return allSurveys.map((s) => s.uid).toList();
  }

  /// 检查指定 UID 是否有测试题
  static Future<bool> hasSurvey(String uid) async {
    final survey = await loadByUid(uid);
    return survey != null;
  }

  /// 删除指定 UID 的测试题
  static Future<void> deleteByUid(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final allSurveys = await loadAll();
    allSurveys.removeWhere((s) => s.uid == uid);
    
    final jsonList = allSurveys.map((s) => s.toJson()).toList();
    await prefs.setString(_key, jsonEncode(jsonList));
  }

  /// 清除所有测试题
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  // ========== 兼容旧版本的方法 ==========
  
  /// @deprecated 仅用于兼容旧代码，始终返回 null
  static Future<Survey?> load() async {
    return null;
  }
}
