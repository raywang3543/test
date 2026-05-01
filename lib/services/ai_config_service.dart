import 'dart:convert';
import 'package:http/http.dart' as http;
import 'server_config.dart';

/// AI 服务配置模型
class AiServiceConfig {
  final String apiKey;
  final String baseUrl;
  final String model;

  const AiServiceConfig({
    required this.apiKey,
    required this.baseUrl,
    required this.model,
  });

  factory AiServiceConfig.fromJson(Map<String, dynamic> json) {
    return AiServiceConfig(
      apiKey: json['apiKey'] as String? ?? '',
      baseUrl: json['baseUrl'] as String? ?? '',
      model: json['model'] as String? ?? '',
    );
  }
}

/// 讯飞 TTS 配置模型
class XfyunConfig {
  final String appId;
  final String apiKey;
  final String apiSecret;

  const XfyunConfig({
    required this.appId,
    required this.apiKey,
    required this.apiSecret,
  });

  factory XfyunConfig.fromJson(Map<String, dynamic> json) {
    return XfyunConfig(
      appId: json['appId'] as String? ?? '',
      apiKey: json['apiKey'] as String? ?? '',
      apiSecret: json['apiSecret'] as String? ?? '',
    );
  }
}

/// AI 配置服务 - 从服务器获取 AI 服务配置
class AiConfigService {
  static AiServiceConfig? _deepseekConfig;
  static AiServiceConfig? _kimiConfig;
  static XfyunConfig? _xfyunConfig;

  /// 获取 DeepSeek 配置
  static Future<AiServiceConfig> getDeepSeekConfig() async {
    if (_deepseekConfig != null) return _deepseekConfig!;
    await _fetchConfig();
    return _deepseekConfig ?? const AiServiceConfig(apiKey: '', baseUrl: '', model: '');
  }

  /// 获取 Kimi 配置
  static Future<AiServiceConfig> getKimiConfig() async {
    if (_kimiConfig != null) return _kimiConfig!;
    await _fetchConfig();
    return _kimiConfig ?? const AiServiceConfig(apiKey: '', baseUrl: '', model: '');
  }

  /// 获取讯飞 TTS 配置
  static Future<XfyunConfig> getXfyunConfig() async {
    if (_xfyunConfig != null) return _xfyunConfig!;
    await _fetchConfig();
    return _xfyunConfig ?? const XfyunConfig(appId: '', apiKey: '', apiSecret: '');
  }

  /// 从服务器获取配置
  static Future<void> _fetchConfig() async {
    try {
      final response = await http.get(Uri.parse('${ServerConfig.baseUrl}/config'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        _deepseekConfig = AiServiceConfig.fromJson(data['deepseek'] as Map<String, dynamic>);
        _kimiConfig = AiServiceConfig.fromJson(data['kimi'] as Map<String, dynamic>);
        _xfyunConfig = XfyunConfig.fromJson(data['xfyun'] as Map<String, dynamic>);
      } else {
        throw Exception('获取配置失败: ${response.statusCode}');
      }
    } catch (e) {
      print('[AiConfigService] 获取配置失败: $e');
      rethrow;
    }
  }

  /// 清除缓存（用于重新获取配置）
  static void clearCache() {
    _deepseekConfig = null;
    _kimiConfig = null;
    _xfyunConfig = null;
  }
}
