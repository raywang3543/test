import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/database_helper.dart';
import '../models/user_model.dart';

/// 用户存储服务
/// UID 在本地 SharedPreferences 中生成并持久化，不依赖服务器
class UserStorage {
  static final _db = DatabaseHelper();
  static const _uidKey = 'user_uid';

  /// 生成 UUID v4 格式的 UID
  static String _generateUid() {
    final rand = Random.secure();
    const hex = '0123456789abcdef';
    String s(int n) => List.generate(n, (_) => hex[rand.nextInt(16)]).join();
    final variant = ['8', '9', 'a', 'b'][rand.nextInt(4)];
    return '${s(8)}-${s(4)}-4${s(3)}-$variant${s(3)}-${s(12)}';
  }

  /// 获取或创建 UID（本地 SharedPreferences）
  static Future<String> getOrCreateUid() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_uidKey);
    if (existing != null && existing.isNotEmpty) return existing;

    final uid = _generateUid();
    await prefs.setString(_uidKey, uid);
    return uid;
  }

  /// 获取当前 UID（如果不存在返回 null）
  static Future<String?> getCurrentUid() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString(_uidKey);
    return (uid != null && uid.isNotEmpty) ? uid : null;
  }

  /// 保存用户信息到服务器
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
