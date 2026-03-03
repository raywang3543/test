import 'dart:async';
import 'dart:math';
import 'package:sqflite/sqflite.dart';

// 根据平台导入不同的实现
export 'database_helper_stub.dart'
    if (dart.library.html) 'database_helper_web.dart'
    if (dart.library.io) 'database_helper_io.dart';
import 'database_helper_stub.dart'
    if (dart.library.html) 'database_helper_web.dart'
    if (dart.library.io) 'database_helper_io.dart';

/// SQLite 数据库帮助类
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal() {
    // 初始化平台特定的设置
    initDatabasePlatform();
  }

  static Database? _database;

  // 表名
  static const String _userInfoTable = 'userInfo';
  static const String _eventTable = 'event';
  static const String _currentUserTable = 'currentUser';
  static const String _surveyTable = 'survey';

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// 初始化数据库
  Future<Database> _initDatabase() async {
    return await openDatabaseForPlatform(
      'emotion_test.db',
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// 创建表（全新安装）
  Future<void> _onCreate(Database db, int version) async {
    // userInfo 表：存储用户信息
    await db.execute('''
      CREATE TABLE $_userInfoTable (
        uid TEXT PRIMARY KEY,
        basicInfo TEXT NOT NULL DEFAULT '',
        detailedInfo TEXT NOT NULL DEFAULT '',
        passingScore INTEGER,
        surveyId INTEGER
      )
    ''');

    // survey 表：存储测试题
    await db.execute('''
      CREATE TABLE $_surveyTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uid TEXT NOT NULL UNIQUE,
        questionsJson TEXT NOT NULL,
        createdAt TEXT,
        creatorBasicInfo TEXT NOT NULL DEFAULT ''
      )
    ''');

    // event 表：存储答题事件
    await db.execute('''
      CREATE TABLE $_eventTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        answererUid TEXT NOT NULL,
        creatorUid TEXT NOT NULL,
        totalScore INTEGER NOT NULL,
        submitTime TEXT NOT NULL
      )
    ''');

    // currentUser 表：存储当前用户 UID
    await db.execute('''
      CREATE TABLE $_currentUserTable (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        uid TEXT NOT NULL
      )
    ''');
  }

  /// 数据库升级
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // 新增 survey 表
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $_surveyTable (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          uid TEXT NOT NULL UNIQUE,
          questionsJson TEXT NOT NULL,
          createdAt TEXT,
          creatorBasicInfo TEXT NOT NULL DEFAULT ''
        )
      ''');
      // userInfo 新增 surveyId 字段
      await db.execute('ALTER TABLE $_userInfoTable ADD COLUMN surveyId INTEGER');
    }
  }

  // ==================== userInfo 表操作 ====================

  /// 保存或更新用户信息
  Future<void> saveUserInfo({
    required String uid,
    required String basicInfo,
    required String detailedInfo,
    int? passingScore,
  }) async {
    final db = await database;
    await db.insert(
      _userInfoTable,
      {
        'uid': uid,
        'basicInfo': basicInfo,
        'detailedInfo': detailedInfo,
        'passingScore': passingScore,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 根据 UID 查询用户信息
  Future<Map<String, dynamic>?> getUserInfo(String uid) async {
    final db = await database;
    final results = await db.query(
      _userInfoTable,
      where: 'uid = ?',
      whereArgs: [uid],
    );
    if (results.isEmpty) return null;
    return results.first;
  }

  /// 获取所有用户信息
  Future<List<Map<String, dynamic>>> getAllUserInfo() async {
    final db = await database;
    return await db.query(_userInfoTable);
  }

  // ==================== event 表操作 ====================

  /// 保存答题事件
  /// 若已存在相同 answererUid + creatorUid 的记录，则只更新 totalScore 和 submitTime
  Future<void> saveEvent({
    required String answererUid,
    required String creatorUid,
    required int totalScore,
    DateTime? submitTime,
  }) async {
    final db = await database;
    final submitTimeStr = (submitTime ?? DateTime.now()).toIso8601String();
    final existing = await db.query(
      _eventTable,
      where: 'answererUid = ? AND creatorUid = ?',
      whereArgs: [answererUid, creatorUid],
      limit: 1,
    );
    if (existing.isNotEmpty) {
      await db.update(
        _eventTable,
        {'totalScore': totalScore, 'submitTime': submitTimeStr},
        where: 'answererUid = ? AND creatorUid = ?',
        whereArgs: [answererUid, creatorUid],
      );
    } else {
      await db.insert(_eventTable, {
        'answererUid': answererUid,
        'creatorUid': creatorUid,
        'totalScore': totalScore,
        'submitTime': submitTimeStr,
      });
    }
  }

  /// 根据答题人 UID 查询所有答题记录
  Future<List<Map<String, dynamic>>> getEventsByAnswererUid(
      String answererUid) async {
    final db = await database;
    return await db.query(
      _eventTable,
      where: 'answererUid = ?',
      whereArgs: [answererUid],
      orderBy: 'submitTime DESC',
    );
  }

  /// 根据出题人 UID 查询所有答题记录
  Future<List<Map<String, dynamic>>> getEventsByCreatorUid(
      String creatorUid) async {
    final db = await database;
    return await db.query(
      _eventTable,
      where: 'creatorUid = ?',
      whereArgs: [creatorUid],
      orderBy: 'submitTime DESC',
    );
  }

  /// 根据答题人 UID 和出题人 UID 查询答题记录
  Future<List<Map<String, dynamic>>> getEventsByAnswererAndCreatorUid(
      String answererUid, String creatorUid) async {
    final db = await database;
    return await db.query(
      _eventTable,
      where: 'answererUid = ? AND creatorUid = ?',
      whereArgs: [answererUid, creatorUid],
      orderBy: 'submitTime DESC',
    );
  }

  /// 删除指定出题人 UID 的所有答题记录
  Future<void> deleteEventsByCreatorUid(String creatorUid) async {
    final db = await database;
    await db.delete(_eventTable, where: 'creatorUid = ?', whereArgs: [creatorUid]);
  }

  /// 删除指定答题人 UID 的所有答题记录
  Future<void> deleteEventsByAnswererUid(String answererUid) async {
    final db = await database;
    await db.delete(_eventTable, where: 'answererUid = ?', whereArgs: [answererUid]);
  }

  /// 获取所有答题事件
  Future<List<Map<String, dynamic>>> getAllEvents() async {
    final db = await database;
    return await db.query(
      _eventTable,
      orderBy: 'submitTime DESC',
    );
  }

  /// 获取最新的答题记录
  Future<Map<String, dynamic>?> getLatestEvent(String answererUid) async {
    final db = await database;
    final results = await db.query(
      _eventTable,
      where: 'answererUid = ?',
      whereArgs: [answererUid],
      orderBy: 'submitTime DESC',
      limit: 1,
    );
    if (results.isEmpty) return null;
    return results.first;
  }

  // ==================== currentUser 表操作 ====================

  /// 生成 UID
  static String generateUid() {
    final rand = Random();
    const hex = '0123456789abcdef';
    String s(int n) => List.generate(n, (_) => hex[rand.nextInt(16)]).join();
    return '${s(8)}-${s(4)}-4${s(3)}-${['8', '9', 'a', 'b'][rand.nextInt(4)]}${s(3)}-${s(12)}';
  }

  /// 获取或创建当前用户 UID
  Future<String> getOrCreateUid() async {
    final db = await database;
    final results = await db.query(_currentUserTable);

    if (results.isNotEmpty) {
      return results.first['uid'] as String;
    }

    // 创建新的 UID
    final uid = generateUid();
    await db.insert(
      _currentUserTable,
      {'id': 1, 'uid': uid},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // 同时在 userInfo 表中创建默认记录
    await saveUserInfo(
      uid: uid,
      basicInfo: '',
      detailedInfo: '',
      passingScore: null,
    );

    return uid;
  }

  /// 获取当前用户 UID（如果不存在返回 null）
  Future<String?> getCurrentUid() async {
    final db = await database;
    final results = await db.query(_currentUserTable);
    if (results.isEmpty) return null;
    return results.first['uid'] as String;
  }

  /// 设置当前用户 UID
  Future<void> setCurrentUid(String uid) async {
    final db = await database;
    await db.insert(
      _currentUserTable,
      {'id': 1, 'uid': uid},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ==================== 迁移辅助方法 ====================

  /// 检查是否需要从 SharedPreferences 迁移数据
  Future<bool> needsMigration() async {
    final db = await database;
    final results = await db.query(_currentUserTable);
    return results.isEmpty;
  }

  // ==================== survey 表操作 ====================

  /// 保存或更新测试题，并将 surveyId 写入 userInfo
  Future<int> saveSurvey({
    required String uid,
    required String questionsJson,
    String? createdAt,
    String creatorBasicInfo = '',
  }) async {
    final db = await database;
    final existing = await db.query(_surveyTable, where: 'uid = ?', whereArgs: [uid]);
    int id;
    if (existing.isNotEmpty) {
      id = existing.first['id'] as int;
      await db.update(
        _surveyTable,
        {'questionsJson': questionsJson, 'creatorBasicInfo': creatorBasicInfo},
        where: 'uid = ?',
        whereArgs: [uid],
      );
    } else {
      id = await db.insert(_surveyTable, {
        'uid': uid,
        'questionsJson': questionsJson,
        'createdAt': createdAt,
        'creatorBasicInfo': creatorBasicInfo,
      });
    }
    await db.update(
      _userInfoTable,
      {'surveyId': id},
      where: 'uid = ?',
      whereArgs: [uid],
    );
    return id;
  }

  /// 根据创建者 UID 查询测试题
  Future<Map<String, dynamic>?> getSurveyByUid(String uid) async {
    final db = await database;
    final results = await db.query(_surveyTable, where: 'uid = ?', whereArgs: [uid]);
    if (results.isEmpty) return null;
    return results.first;
  }

  /// 查询所有测试题
  Future<List<Map<String, dynamic>>> getAllSurveys() async {
    final db = await database;
    return await db.query(_surveyTable, orderBy: 'createdAt DESC');
  }

  /// 删除指定创建者 UID 的测试题，并清除 userInfo 中的 surveyId
  Future<void> deleteSurveyByUid(String uid) async {
    final db = await database;
    await db.delete(_surveyTable, where: 'uid = ?', whereArgs: [uid]);
    await db.update(_userInfoTable, {'surveyId': null}, where: 'uid = ?', whereArgs: [uid]);
  }

  /// 删除所有测试题并清除所有 userInfo 中的 surveyId
  Future<void> deleteAllSurveys() async {
    final db = await database;
    await db.delete(_surveyTable);
    await db.update(_userInfoTable, {'surveyId': null});
  }

  /// 关闭数据库
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
