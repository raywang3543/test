import 'package:shared_preferences/shared_preferences.dart';

class ServerConfig {
  static const _key = 'server_base_url';
  static const _thinkKey = 'think_mode';
  static const defaultUrl = 'http://182.92.61.108';

  static Future<String?> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key);
  }

  static Future<void> setBaseUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    final normalized = url.trim().replaceAll(RegExp(r'/$'), '');
    await prefs.setString(_key, normalized);
  }

  static Future<bool> isConfigured() async {
    final url = await getBaseUrl();
    return url != null && url.isNotEmpty;
  }

  static Future<String> getThinkMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_thinkKey) ?? 'disabled';
  }

  static Future<void> setThinkMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_thinkKey, mode);
  }
}
