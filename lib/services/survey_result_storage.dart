import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/survey_model.dart';
import '../models/survey_result_model.dart';
import 'user_storage.dart';

/// 答题结果存储服务 - 将 UID 与答题信息一一对应存储在本地
class SurveyResultStorage {
  static const _key = 'survey_results';

  /// 保存新的答题结果（自动关联当前用户的 UID）
  static Future<void> saveResult({
    required Survey survey,
    required List<dynamic> answers,
    required int totalScore,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    // 获取当前用户的 UID
    final uid = await UserStorage.getOrCreateUid();
    
    // 构建答题详情列表
    final questionAnswers = <QuestionAnswer>[];
    for (int i = 0; i < survey.questions.length; i++) {
      final question = survey.questions[i];
      final answer = answers[i];
      
      final selectedOptions = <SelectedOption>[];
      int questionScore = 0;
      
      if (answer is Set<int>) {
        // 多选题
        for (final idx in answer) {
          final option = question.options[idx];
          selectedOptions.add(SelectedOption(
            content: option.content,
            score: option.score,
          ));
          questionScore += option.score;
        }
      } else if (answer is int) {
        // 单选题
        final option = question.options[answer];
        selectedOptions.add(SelectedOption(
          content: option.content,
          score: option.score,
        ));
        questionScore = option.score;
      }
      
      questionAnswers.add(QuestionAnswer(
        questionTitle: question.title,
        isMultiChoice: question.isMultiChoice,
        selectedOptions: selectedOptions,
        questionScore: questionScore,
      ));
    }
    
    // 创建新的答题结果
    final newResult = SurveyResult(
      uid: uid,
      submitTime: DateTime.now(),
      totalScore: totalScore,
      answers: questionAnswers,
    );
    
    // 读取现有的历史记录
    final existingResults = await loadAllResults();
    
    // 添加新记录到开头（最新的在前）
    existingResults.insert(0, newResult);
    
    // 保存所有记录
    final jsonList = existingResults.map((r) => r.toJson()).toList();
    await prefs.setString(_key, jsonEncode(jsonList));
  }

  /// 加载所有答题结果
  static Future<List<SurveyResult>> loadAllResults() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_key);
    if (json == null) return [];
    
    try {
      final List<dynamic> list = jsonDecode(json) as List<dynamic>;
      return list
          .map((item) => SurveyResult.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// 根据 UID 加载该用户的所有答题结果
  static Future<List<SurveyResult>> loadResultsByUid(String uid) async {
    final allResults = await loadAllResults();
    return allResults.where((r) => r.uid == uid).toList();
  }

  /// 加载当前用户的所有答题结果
  static Future<List<SurveyResult>> loadCurrentUserResults() async {
    final uid = await UserStorage.getOrCreateUid();
    return loadResultsByUid(uid);
  }

  /// 获取当前用户的最新答题结果
  static Future<SurveyResult?> loadCurrentUserLatestResult() async {
    final userResults = await loadCurrentUserResults();
    if (userResults.isEmpty) return null;
    return userResults.first; // 已按时间倒序排列
  }

  /// 清除所有答题记录
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  /// 清除当前用户的所有答题记录
  static Future<void> clearCurrentUserResults() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = await UserStorage.getOrCreateUid();
    
    final allResults = await loadAllResults();
    final filteredResults = allResults.where((r) => r.uid != uid).toList();
    
    final jsonList = filteredResults.map((r) => r.toJson()).toList();
    await prefs.setString(_key, jsonEncode(jsonList));
  }
}
