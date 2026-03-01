import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/survey_model.dart';

class SurveyStorage {
  static const _key = 'saved_survey';

  static Future<void> save(Survey survey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(survey.toJson()));
  }

  static Future<Survey?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_key);
    if (json == null) return null;
    return Survey.fromJson(jsonDecode(json) as Map<String, dynamic>);
  }
}
