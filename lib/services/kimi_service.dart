import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/survey_model.dart';

/// Kimi API 服务 - 用于性格分析
/// API 文档: https://platform.moonshot.cn/docs/api/chat
class KimiService {
  // Kimi API 配置
  // 注意：实际使用时应该将 API Key 存储在安全的地方，如环境变量或密钥管理服务
  static const String _apiKey = 'sk-LatXCAEc7kwefpWTrOdM8IiYk0C97Axeykgcj4Rh0TQ5KeEN';
  static const String _baseUrl = 'https://api.moonshot.cn/v1';
  static const String _model = 'moonshot-v1-8k';

  /// 分析用户答题结果，返回性格分析（包含出题者和做题者对比）
  static Future<String> analyzePersonality({
    required Survey survey,
    required List<dynamic> answers,
    required int totalScore,
  }) async {
    // 如果没有配置 API Key，返回提示信息
    if (_apiKey.isEmpty) {
      return '⚠️ 请先配置 Kimi API Key\n\n'
          '请在 lib/services/kimi_service.dart 文件中设置 _apiKey。\n'
          '获取 API Key: https://platform.moonshot.cn/';
    }

    try {
      // 构建提示词
      final prompt = _buildAnalysisPrompt(survey, answers, totalScore);

      final response = await http.post(
        Uri.parse('$_baseUrl/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': _model,
          'messages': [
            {
              'role': 'system',
              'content': '你是一位专业的心理分析师和情感顾问，擅长通过答题分析用户的性格特点，'
                  '并判断两个人是否适合交往。你会分别分析出题者（标准答案设置者）和做题者的性格特点，'
                  '然后给出两者性格差异分析，以及是否适合交往的建议。',
            },
            {
              'role': 'user',
              'content': prompt,
            },
          ],
          'temperature': 0.7,
          'max_tokens': 2000,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final content = data['choices']?[0]?['message']?['content'] as String?;
        if (content != null && content.isNotEmpty) {
          return content;
        }
        return '分析结果为空，请稍后重试。';
      } else if (response.statusCode == 401) {
        return '⚠️ API Key 无效\n\n请检查 kimiservice.dart 中的 _apiKey 是否正确。';
      } else if (response.statusCode == 429) {
        return '⚠️ 请求过于频繁\n\n请稍后再试。';
      } else {
        return '⚠️ 分析失败 (${response.statusCode})\n\n${response.body}';
      }
    } catch (e) {
      return '⚠️ 网络错误\n\n请检查网络连接后重试。\n错误信息: $e';
    }
  }

  /// 构建分析提示词
  static String _buildAnalysisPrompt(
    Survey survey,
    List<dynamic> answers,
    int totalScore,
  ) {
    final buffer = StringBuffer();
    
    buffer.writeln('请根据以下答题情况进行性格分析和匹配度评估：');
    buffer.writeln();
    buffer.writeln('===========================');
    buffer.writeln('【做题者答题情况】');
    buffer.writeln('===========================');
    buffer.writeln('总分: $totalScore 分');
    buffer.writeln('题目总数: ${survey.questions.length} 题');
    buffer.writeln();
    buffer.writeln('【每题答题详情】:');
    buffer.writeln();

    for (int i = 0; i < survey.questions.length; i++) {
      final question = survey.questions[i];
      final answer = answers[i];

      buffer.writeln('第 ${i + 1} 题: ${question.title}');
      
      // 出题者标准答案
      buffer.write('出题者答案: ');
      final correctAnswer = question.correctAnswer;
      if (correctAnswer == null) {
        buffer.writeln('未设置');
      } else if (question.isMultiChoice) {
        final correctList = correctAnswer is List ? correctAnswer : [correctAnswer];
        final correctTexts = <String>[];
        for (final idx in correctList) {
          final index = idx as int;
          if (index >= 0 && index < question.options.length) {
            correctTexts.add('${String.fromCharCode(65 + index)}. ${question.options[index].content}');
          }
        }
        buffer.writeln(correctTexts.isEmpty ? '无' : correctTexts.join('、'));
      } else {
        if (correctAnswer is int && correctAnswer >= 0 && correctAnswer < question.options.length) {
          buffer.writeln('${String.fromCharCode(65 + correctAnswer)}. ${question.options[correctAnswer].content}');
        } else {
          buffer.writeln('无效');
        }
      }

      // 做题者答案
      buffer.write('做题者答案: ');
      if (answer is Set<int>) {
        if (answer.isEmpty) {
          buffer.writeln('未作答');
        } else {
          final selectedTexts = <String>[];
          for (final idx in answer.toList()..sort()) {
            if (idx >= 0 && idx < question.options.length) {
              selectedTexts.add('${String.fromCharCode(65 + idx)}. ${question.options[idx].content} (${question.options[idx].score}分)');
            }
          }
          buffer.writeln(selectedTexts.join('、'));
        }
      } else if (answer is int) {
        if (answer >= 0 && answer < question.options.length) {
          buffer.writeln('${String.fromCharCode(65 + answer)}. ${question.options[answer].content} (${question.options[answer].score}分)');
        } else {
          buffer.writeln('无效');
        }
      } else {
        buffer.writeln('未作答');
      }
      buffer.writeln();
    }

    buffer.writeln('===========================');
    buffer.writeln('请按以下结构输出分析报告：');
    buffer.writeln('===========================');
    buffer.writeln();
    buffer.writeln('1. 【出题者性格分析】');
    buffer.writeln('   - 根据出题者设置的标准答案，分析其性格特点、价值观、情感需求等');
    buffer.writeln();
    buffer.writeln('2. 【做题者性格分析】');
    buffer.writeln('   - 根据做题者的答题情况，分析其性格特点、情感倾向、行为模式等');
    buffer.writeln();
    buffer.writeln('3. 【性格差异分析】');
    buffer.writeln('   - 分析两者在价值观、情感表达、生活方式等方面的异同');
    buffer.writeln('   - 指出可能的冲突点和互补点');
    buffer.writeln();
    buffer.writeln('4. 【同性交往建议】');
    buffer.writeln('   - 如果两人是同性朋友/闺蜜/兄弟，是否适合深交？');
    buffer.writeln('   - 友谊发展的潜力和建议');
    buffer.writeln('   - 适合一起进行的活动类型');
    buffer.writeln();
    buffer.writeln('5. 【异性交往建议】');
    buffer.writeln('   - 如果两人是异性，是否适合发展为恋爱关系？');
    buffer.writeln('   - 匹配度评分（1-10分）及理由');
    buffer.writeln('   - 恋爱关系中的优势和挑战');
    buffer.writeln('   - 相处建议');
    buffer.writeln();
    buffer.writeln('6. 【总结】');
    buffer.writeln('   - 总体评价和建议');
    buffer.writeln();
    buffer.writeln('请用中文回答，语气友好专业，分析要有洞察力且具体。');

    return buffer.toString();
  }
}
