import '../services/api_client.dart';

export 'database_helper_stub.dart'
    if (dart.library.html) 'database_helper_web.dart'
    if (dart.library.io) 'database_helper_io.dart';

/// 数据库帮助类 - 通过 HTTP 调用服务器端 SQLite
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  final _client = ApiClient();

  // ==================== userInfo ====================

  Future<void> saveUserInfo({
    required String uid,
    required String basicInfo,
    required String detailedInfo,
    int? passingScore,
  }) =>
      _client.saveUserInfo(
        uid: uid,
        basicInfo: basicInfo,
        detailedInfo: detailedInfo,
        passingScore: passingScore,
      );

  Future<Map<String, dynamic>?> getUserInfo(String uid) =>
      _client.getUserInfo(uid);

  Future<List<Map<String, dynamic>>> getAllUserInfo() =>
      _client.getAllUserInfo();

  // ==================== survey ====================

  Future<int> saveSurvey({
    required String uid,
    required String questionsJson,
    String? createdAt,
    String creatorBasicInfo = '',
  }) =>
      _client.saveSurvey(
        uid: uid,
        questionsJson: questionsJson,
        createdAt: createdAt,
        creatorBasicInfo: creatorBasicInfo,
      );

  Future<Map<String, dynamic>?> getSurveyByUid(String uid) =>
      _client.getSurveyByUid(uid);

  Future<List<Map<String, dynamic>>> getAllSurveys() =>
      _client.getAllSurveys();

  Future<void> deleteSurveyByUid(String uid) =>
      _client.deleteSurveyByUid(uid);

  Future<void> deleteAllSurveys() => _client.deleteAllSurveys();

  // ==================== event ====================

  Future<void> saveEvent({
    required String answererUid,
    required String creatorUid,
    required int totalScore,
    DateTime? submitTime,
  }) =>
      _client.saveEvent(
        answererUid: answererUid,
        creatorUid: creatorUid,
        totalScore: totalScore,
        submitTime: submitTime,
      );

  Future<List<Map<String, dynamic>>> getEventsByAnswererUid(String uid) =>
      _client.getEventsByAnswererUid(uid);

  Future<List<Map<String, dynamic>>> getEventsByCreatorUid(String uid) =>
      _client.getEventsByCreatorUid(uid);

  Future<List<Map<String, dynamic>>> getEventsByAnswererAndCreatorUid(
          String answererUid, String creatorUid) =>
      _client.getEventsByAnswererAndCreatorUid(answererUid, creatorUid);

  Future<Map<String, dynamic>?> getLatestEvent(String answererUid) =>
      _client.getLatestEvent(answererUid);

  Future<List<Map<String, dynamic>>> getAllEvents() => _client.getAllEvents();

  Future<void> deleteEventsByCreatorUid(String creatorUid) =>
      _client.deleteEventsByCreatorUid(creatorUid);

  Future<void> deleteEventsByAnswererUid(String answererUid) =>
      _client.deleteEventsByAnswererUid(answererUid);

  Future<void> deleteAllEvents() => _client.deleteAllEvents();

  /// 兼容旧代码：数据已在服务器，无需迁移
  Future<bool> needsMigration() async => false;
}
