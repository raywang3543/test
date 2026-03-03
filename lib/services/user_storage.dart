import '../database/database_helper.dart';
import '../models/user_model.dart';

/// 用户存储服务 - 使用 SQLite
class UserStorage {
  static final _db = DatabaseHelper();

  /// 获取或创建 UID
  /// 当 currentUser 表中不存在 uid 时，为用户创建 uid 并保存
  static Future<String> getOrCreateUid() async {
    return await _db.getOrCreateUid();
  }

  /// 获取当前用户 UID（如果不存在返回 null）
  static Future<String?> getCurrentUid() async {
    return await _db.getCurrentUid();
  }

  /// 保存用户信息到 userInfo 表
  static Future<void> save(UserProfile profile) async {
    final uid = await getOrCreateUid();
    await _db.saveUserInfo(
      uid: uid,
      basicInfo: profile.basicInfo,
      detailedInfo: profile.detailedInfo,
      passingScore: profile.passingScore,
    );
  }

  /// 加载当前用户信息
  static Future<UserProfile?> load() async {
    final uid = await getCurrentUid();
    if (uid == null) return null;

    final data = await _db.getUserInfo(uid);
    if (data == null) return null;

    return UserProfile(
      basicInfo: data['basicInfo'] as String? ?? '',
      detailedInfo: data['detailedInfo'] as String? ?? '',
      passingScore: data['passingScore'] as int?,
    );
  }

  /// 加载所有用户信息
  static Future<List<Map<String, dynamic>>> loadAll() async {
    return await _db.getAllUserInfo();
  }

  /// 根据 UID 加载用户信息
  static Future<UserProfile?> loadByUid(String uid) async {
    final data = await _db.getUserInfo(uid);
    if (data == null) return null;

    return UserProfile(
      basicInfo: data['basicInfo'] as String? ?? '',
      detailedInfo: data['detailedInfo'] as String? ?? '',
      passingScore: data['passingScore'] as int?,
    );
  }
}
