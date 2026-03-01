import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class UserStorage {
  static const _key = 'user_profile';
  static const _uidKey = 'user_uid';

  static String _generateUid() {
    final rand = Random();
    const hex = '0123456789abcdef';
    String s(int n) => List.generate(n, (_) => hex[rand.nextInt(16)]).join();
    return '${s(8)}-${s(4)}-4${s(3)}-${['8','9','a','b'][rand.nextInt(4)]}${s(3)}-${s(12)}';
  }

  static Future<String> getOrCreateUid() async {
    final prefs = await SharedPreferences.getInstance();
    var uid = prefs.getString(_uidKey);
    if (uid == null) {
      uid = _generateUid();
      await prefs.setString(_uidKey, uid);
    }
    return uid;
  }

  static Future<void> save(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(profile.toJson()));
  }

  static Future<UserProfile?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_key);
    if (json == null) return null;
    return UserProfile.fromJson(jsonDecode(json) as Map<String, dynamic>);
  }
}
