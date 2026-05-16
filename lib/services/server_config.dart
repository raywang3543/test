import 'package:shared_preferences/shared_preferences.dart';

class ServerConfig {
  static const _thinkKey = 'think_mode';
  static const baseUrl = 'http://127.0.0.1:8000';

  static Future<String> getThinkMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_thinkKey) ?? 'disabled';
  }

  static Future<void> setThinkMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_thinkKey, mode);
  }
}
