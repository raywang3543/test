import 'dart:convert';
import 'package:http/http.dart' as http;
import 'server_config.dart';

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  Future<String> _base() async {
    final url = await ServerConfig.getBaseUrl();
    if (url == null || url.isEmpty) throw ApiException('服务器地址未配置');
    return url;
  }

  Future<dynamic> _get(String path) async {
    final res = await http.get(Uri.parse('${await _base()}$path'));
    if (res.statusCode == 404) return null;
    _assertOk(res);
    return jsonDecode(res.body);
  }

  Future<dynamic> _post(String path, [Map<String, dynamic>? body]) async {
    final res = await http.post(
      Uri.parse('${await _base()}$path'),
      headers: {'Content-Type': 'application/json'},
      body: body != null ? jsonEncode(body) : null,
    );
    _assertOk(res);
    return jsonDecode(res.body);
  }

  Future<dynamic> _put(String path, Map<String, dynamic> body) async {
    final res = await http.put(
      Uri.parse('${await _base()}$path'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    _assertOk(res);
    return jsonDecode(res.body);
  }

  Future<void> _delete(String path) async {
    final res = await http.delete(Uri.parse('${await _base()}$path'));
    _assertOk(res);
  }

  void _assertOk(http.Response res) {
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw ApiException('服务器错误 ${res.statusCode}: ${res.body}');
    }
  }

  // ==================== userInfo ====================

  Future<void> saveUserInfo({
    required String uid,
    required String basicInfo,
    required String detailedInfo,
    int? passingScore,
  }) async {
    await _put('/users/$uid', {
      'uid': uid,
      'basicInfo': basicInfo,
      'detailedInfo': detailedInfo,
      'passingScore': passingScore,
    });
  }

  Future<Map<String, dynamic>?> getUserInfo(String uid) async {
    final data = await _get('/users/$uid');
    return data as Map<String, dynamic>?;
  }

  Future<List<Map<String, dynamic>>> getAllUserInfo() async {
    final data = await _get('/users') as List;
    return data.cast<Map<String, dynamic>>();
  }

  // ==================== survey ====================

  Future<int> saveSurvey({
    required String uid,
    required String questionsJson,
    String? createdAt,
    String creatorBasicInfo = '',
  }) async {
    final data = await _post('/surveys', {
      'uid': uid,
      'questionsJson': questionsJson,
      'createdAt': createdAt,
      'creatorBasicInfo': creatorBasicInfo,
    });
    return data['id'] as int;
  }

  Future<Map<String, dynamic>?> getSurveyByUid(String uid) async {
    final data = await _get('/surveys/$uid');
    return data as Map<String, dynamic>?;
  }

  Future<List<Map<String, dynamic>>> getAllSurveys() async {
    final data = await _get('/surveys') as List;
    return data.cast<Map<String, dynamic>>();
  }

  Future<void> deleteSurveyByUid(String uid) async {
    await _delete('/surveys/$uid');
  }

  Future<void> deleteAllSurveys() async {
    await _delete('/surveys');
  }

  // ==================== event ====================

  Future<void> saveEvent({
    required String answererUid,
    required String creatorUid,
    required int totalScore,
    DateTime? submitTime,
  }) async {
    await _post('/events', {
      'answererUid': answererUid,
      'creatorUid': creatorUid,
      'totalScore': totalScore,
      'submitTime': (submitTime ?? DateTime.now()).toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getEventsByAnswererUid(String uid) async {
    final data = await _get('/events/answerer/$uid') as List;
    return data.cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> getEventsByCreatorUid(String uid) async {
    final data = await _get('/events/creator/$uid') as List;
    return data.cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> getEventsByAnswererAndCreatorUid(
      String answererUid, String creatorUid) async {
    final data =
        await _get('/events/answerer/$answererUid/creator/$creatorUid') as List;
    return data.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>?> getLatestEvent(String answererUid) async {
    final data = await _get('/events/answerer/$answererUid/latest');
    return data as Map<String, dynamic>?;
  }

  Future<List<Map<String, dynamic>>> getAllEvents() async {
    final data = await _get('/events') as List;
    return data.cast<Map<String, dynamic>>();
  }

  Future<void> deleteEventsByCreatorUid(String creatorUid) async {
    await _delete('/events/creator/$creatorUid');
  }

  Future<void> deleteEventsByAnswererUid(String answererUid) async {
    await _delete('/events/answerer/$answererUid');
  }

  Future<void> deleteAllEvents() async {
    await _delete('/events');
  }
}
