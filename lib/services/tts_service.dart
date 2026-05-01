import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'ai_config_service.dart';

/// TTS 状态回调函数类型
typedef TtsStatusCallback = void Function(String status);
typedef TtsStateCallback = void Function();

/// 讯飞 TTS 服务类
/// 封装语音生成、播放控制等业务逻辑
class TtsService {
  // ==================== 单例模式 ====================
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;
  TtsService._internal();

  // ==================== 讯飞TTS配置 ====================
  // 配置从服务器获取，不再硬编码

  // ==================== 状态属性 ====================
  bool get isGenerating => _isGenerating;
  bool get isPlaying => _isPlaying;
  bool get hasAudio => _hasAudio;
  String get status => _status;
  String? get audioPath => _audioPath;

  bool _isGenerating = false;
  bool _isPlaying = false;
  bool _hasAudio = false;
  String _status = 'Enter text and tap "Generate Speech"';
  String? _audioPath;

  // ==================== 回调函数 ====================
  TtsStatusCallback? onStatusChanged;
  TtsStateCallback? onStateChanged;

  // ==================== 音频播放器 ====================
  AudioPlayer? _audioPlayer;

  /// 初始化 TTS 服务
  Future<void> initialize() async {
    _audioPlayer = AudioPlayer();
    _audioPlayer!.onPlayerComplete.listen((_) {
      _isPlaying = false;
      _updateStatus('Playback completed');
      _notifyStateChanged();
    });
  }

  /// 更新状态并触发回调
  void _updateStatus(String status) {
    _status = status;
    log('[TTS Status] $status', name: 'XfyunTTS');
    onStatusChanged?.call(status);
  }

  /// 通知状态变化
  void _notifyStateChanged() {
    onStateChanged?.call();
  }

  /// 构建讯飞TTS鉴权URL（HMAC-SHA256）
  Future<String> _buildXfyunAuthUrl() async {
    final config = await AiConfigService.getXfyunConfig();
    if (config.apiKey.isEmpty || config.apiSecret.isEmpty) {
      throw Exception('讯飞 TTS 配置未设置');
    }

    const String host = 'tts-api.xfyun.cn';
    final String date = HttpDate.format(DateTime.now().toUtc());
    const String requestLine = 'GET /v2/tts HTTP/1.1';
    final String signatureOrigin = 'host: $host\ndate: $date\n$requestLine';

    final List<int> signatureBytes = Hmac(sha256, utf8.encode(config.apiSecret))
        .convert(utf8.encode(signatureOrigin))
        .bytes;
    final String signature = base64.encode(signatureBytes);

    final String authorizationOrigin =
        'api_key="${config.apiKey}", algorithm="hmac-sha256", '
        'headers="host date request-line", signature="$signature"';
    final String authorization = base64.encode(utf8.encode(authorizationOrigin));

    final authUrl = 'wss://$host/v2/tts'
        '?authorization=${Uri.encodeComponent(authorization)}'
        '&date=${Uri.encodeComponent(date)}'
        '&host=${Uri.encodeComponent(host)}';
    
    log('[XfyunTTS] Auth URL: $authUrl', name: 'XfyunTTS');
    return authUrl;
  }

  /// 通过讯飞TTS生成语音（WebSocket流式API）
  Future<bool> _generateSpeechViaXfyun(String text) async {
    // 检查文本长度限制（8000字节）
    if (utf8.encode(text).length > 8000) {
      _isGenerating = false;
      _updateStatus('Text too long (max 8000 bytes)');
      _notifyStateChanged();
      return false;
    }

    try {
      _updateStatus('Generating speech via Xfyun...');
      _notifyStateChanged();

      final String authUrl = await _buildXfyunAuthUrl();
      final config = await AiConfigService.getXfyunConfig();
      log('[XfyunTTS] Connecting to WebSocket...', name: 'XfyunTTS');
      
      final channel = WebSocketChannel.connect(Uri.parse(authUrl));

      final String encodedText = base64.encode(utf8.encode(text));
      final Map<String, dynamic> request = {
        'common': {'app_id': config.appId},
        'business': {
          'aue': 'lame',
          'sfl': 1,
          'vcn': 'x4_yezi',
          'speed': 50,
          'volume': 50,
          'pitch': 50,
          'tte': 'UTF8',
        },
        'data': {'status': 2, 'text': encodedText},
      };

      final List<String> audioChunks = [];
      final completer = Completer<void>();
      String? errorMessage;

      channel.stream.listen(
        (message) {
          log('[XfyunTTS] Received message: $message', name: 'XfyunTTS');
          try {
            final Map<String, dynamic> response = json.decode(message);
            
            // 检查 code 字段（注意：第一帧可能只有 sid 没有 code）
            if (response['code'] != null && response['code'] != 0) {
              errorMessage = 'Xfyun error: ${response['message']} (code: ${response['code']})';
              log('[XfyunTTS] API error: $errorMessage', name: 'XfyunTTS');
              completer.complete();
              return;
            }
            
            final data = response['data'];
            if (data != null) {
              if (data['audio'] != null) {
                audioChunks.add(data['audio'] as String);
                log('[XfyunTTS] Received audio chunk #${audioChunks.length}', name: 'XfyunTTS');
              }
              if (data['status'] == 2) {
                log('[XfyunTTS] Received end signal (status=2)', name: 'XfyunTTS');
                completer.complete();
              }
            } else {
              log('[XfyunTTS] Received frame with no data (ignored)', name: 'XfyunTTS');
            }
          } catch (e) {
            errorMessage = 'Error processing Xfyun message: $e';
            log('[XfyunTTS] Parse error: $e', name: 'XfyunTTS');
            completer.complete();
          }
        },
        onError: (error) {
          errorMessage = 'Xfyun connection error: $error';
          log('[XfyunTTS] Connection error: $error', name: 'XfyunTTS');
          completer.complete();
        },
        onDone: () {
          log('[XfyunTTS] Stream closed', name: 'XfyunTTS');
          if (!completer.isCompleted) {
            completer.complete();
          }
        },
      );

      log('[XfyunTTS] Sending request...', name: 'XfyunTTS');
      channel.sink.add(json.encode(request));

      try {
        await completer.future.timeout(const Duration(seconds: 30));
        log('[XfyunTTS] Request completed', name: 'XfyunTTS');
      } finally {
        await channel.sink.close();
      }

      if (errorMessage != null) {
        _isGenerating = false;
        _updateStatus(errorMessage!);
        _notifyStateChanged();
        return false;
      }

      if (audioChunks.isEmpty) {
        _isGenerating = false;
        _updateStatus('Xfyun generation failed: no audio data');
        _notifyStateChanged();
        return false;
      }

      log('[XfyunTTS] Decoding ${audioChunks.length} audio chunks...', name: 'XfyunTTS');
      // 分别解码每个 base64 片段，然后合并字节数组
      final List<Uint8List> decodedChunks = audioChunks.map((chunk) => base64.decode(chunk)).toList();
      final int totalLength = decodedChunks.fold(0, (sum, chunk) => sum + chunk.length);
      final Uint8List audioBytes = Uint8List(totalLength);
      int offset = 0;
      for (final chunk in decodedChunks) {
        audioBytes.setRange(offset, offset + chunk.length, chunk);
        offset += chunk.length;
      }

      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final outputPath = '${tempDir.path}/tts_$timestamp.mp3';
      final file = File(outputPath);
      await file.parent.create(recursive: true);
      await file.writeAsBytes(audioBytes, flush: true);

      // 停止当前播放并清理旧文件
      if (_audioPlayer != null && _isPlaying) {
        await _audioPlayer!.stop();
        _isPlaying = false;
      }
      if (_audioPath != null) {
        final oldFile = File(_audioPath!);
        if (oldFile.existsSync()) {
          try {
            await oldFile.delete();
          } catch (_) {
            // 忽略删除失败
          }
        }
      }

      _audioPath = outputPath;
      _hasAudio = true;
      _isGenerating = false;
      _updateStatus('Speech generated! Tap "Play" to listen');
      _notifyStateChanged();
      return true;
    } catch (e) {
      log('[XfyunTTS] Exception: $e', name: 'XfyunTTS');
      _isGenerating = false;
      _updateStatus('Xfyun generation failed: $e');
      _notifyStateChanged();
      return false;
    }
  }

  /// 生成语音（使用讯飞TTS）
  Future<bool> generateSpeech(String text) async {
    final trimmedText = text.trim();
    if (trimmedText.isEmpty) {
      _updateStatus('Please enter some text');
      _notifyStateChanged();
      return false;
    }

    _isGenerating = true;
    _hasAudio = false;

    // 使用讯飞TTS
    _updateStatus('Generating speech via Xfyun...');
    _notifyStateChanged();
    if (await _generateSpeechViaXfyun(trimmedText)) {
      return true;
    }

    _isGenerating = false;
    _updateStatus('Generation failed');
    _notifyStateChanged();
    return false;
  }

  /// 播放音频
  Future<bool> playAudio() async {
    if (_audioPath == null || !_hasAudio) {
      _updateStatus('Please generate speech first');
      _notifyStateChanged();
      return false;
    }

    try {
      _isPlaying = true;
      _updateStatus('Playing...');
      _notifyStateChanged();

      await _audioPlayer!.play(DeviceFileSource(_audioPath!));
      return true;
    } catch (e) {
      _isPlaying = false;
      _updateStatus('Playback failed: $e');
      _notifyStateChanged();
      return false;
    }
  }

  /// 停止播放
  Future<void> stopAudio() async {
    if (_audioPlayer != null) {
      await _audioPlayer!.stop();
    }
    _isPlaying = false;
    _updateStatus('Stopped');
    _notifyStateChanged();
  }

  /// 释放资源
  Future<void> dispose() async {
    if (_audioPlayer != null) {
      await _audioPlayer!.dispose();
      _audioPlayer = null;
    }
  }
}
