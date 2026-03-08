import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/analysis_result_model.dart';
import '../models/survey_model.dart';

/// Kimi API 服务 - 用于性格分析
/// API 文档: https://platform.moonshot.cn/docs/api/chat
class KimiService {
  // Kimi API 配置
  static const String _apiKey = 'sk-LatXCAEc7kwefpWTrOdM8IiYk0C97Axeykgcj4Rh0TQ5KeEN';
  static const String _baseUrl = 'https://api.moonshot.cn/v1';
  static const String _model = 'moonshot-v1-8k';

  /// 分析用户答题结果，返回详细的匹配分析
  static Future<PersonalityAnalysisResult> analyzePersonalityDetailed({
    required Survey survey,
    required List<dynamic> answers,
  }) async {
    // 如果没有配置 API Key，返回模拟数据
    if (_apiKey.isEmpty) {
      return _generateMockResult(survey, answers);
    }

    try {
      // 构建提示词
      final prompt = _buildAnalysisPrompt(survey, answers);

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
              'content': '你是一位专业的心理分析师和情感顾问。你的任务是分析出题者和做题者的答题情况，'
                  '分别给出两人的性格分析，然后评估他们作为朋友的匹配度和作为伴侣的匹配度。'
                  '请以严格的 JSON 格式返回结果，不要包含任何其他文字。',
            },
            {
              'role': 'user',
              'content': prompt,
            },
          ],
          'temperature': 0.5,
          'max_tokens': 4000,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final content = data['choices']?[0]?['message']?['content'] as String?;
        if (content != null && content.isNotEmpty) {
          return _parseAnalysisResult(content, survey, answers);
        }
        return _generateMockResult(survey, answers);
      } else if (response.statusCode == 401) {
        return _generateMockResult(survey, answers, error: 'API Key 无效');
      } else if (response.statusCode == 429) {
        return _generateMockResult(survey, answers, error: '请求过于频繁');
      } else {
        return _generateMockResult(survey, answers, error: '请求失败: ${response.statusCode}');
      }
    } catch (e) {
      return _generateMockResult(survey, answers, error: '网络错误: $e');
    }
  }

  /// 构建分析提示词
  static String _buildAnalysisPrompt(Survey survey, List<dynamic> answers) {
    final buffer = StringBuffer();
    
    buffer.writeln('请分析以下答题情况，并严格按照 JSON 格式返回结果。');
    buffer.writeln();
    buffer.writeln('答题详情:');
    buffer.writeln();

    for (int i = 0; i < survey.questions.length; i++) {
      final question = survey.questions[i];
      final answer = answers[i];

      buffer.writeln('第 ${i + 1} 题: ${question.title}');
      buffer.writeln('本题满分: ${question.questionScore} 分');
      
      // 出题者答案
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
              selectedTexts.add('${String.fromCharCode(65 + idx)}. ${question.options[idx].content}');
            }
          }
          buffer.writeln(selectedTexts.join('、'));
        }
      } else if (answer is int) {
        if (answer >= 0 && answer < question.options.length) {
          buffer.writeln('${String.fromCharCode(65 + answer)}. ${question.options[answer].content}');
        } else {
          buffer.writeln('无效');
        }
      } else {
        buffer.writeln('未作答');
      }
      buffer.writeln();
    }

    buffer.writeln();
    buffer.writeln('请返回以下格式的 JSON（不要包含 markdown 代码块标记）:');
    buffer.writeln('''
{
  "questionResults": [
    {
      "questionIndex": 0,
      "questionTitle": "题目内容",
      "matchPercentage": 85,
      "reason": "答案高度相似，表明双方在该问题上观点一致...",
      "creatorAnswer": "A. 选项内容",
      "playerAnswer": "A. 选项内容"
    }
  ],
  "overallMatchPercentage": 75,
  "creatorAnalysis": "出题者是一个外向开朗、注重情感表达的人...",
  "playerAnalysis": "做题者性格内敛沉稳，善于思考...",
  "sameGenderCompatibility": "作为朋友，两人性格互补...适合成为...",
  "oppositeGenderCompatibility": "作为伴侣，两人的匹配度为...恋爱关系中..."
}
''');
    buffer.writeln();
    buffer.writeln('分析要求:');
    buffer.writeln('1. creatorAnalysis: 根据出题者设置的答案，分析其性格特点（150字左右）');
    buffer.writeln('2. playerAnalysis: 根据做题者的答案，分析其性格特点（150字左右）');
    buffer.writeln('3. sameGenderCompatibility: 分析两人作为朋友的匹配度，包括友谊发展潜力和建议（150字左右）');
    buffer.writeln('4. oppositeGenderCompatibility: 分析两人作为伴侣的匹配度，包括匹配度评分、恋爱关系中的优势和挑战、相处建议（200字左右）');
    buffer.writeln('5. matchPercentage: 根据答案相似程度给出 0-100 的整数');

    return buffer.toString();
  }

  /// 判断做题者答案是否与出题者答案完全一致
  static bool _answersMatch(SurveyQuestion question, dynamic answer) {
    final correctAnswer = question.correctAnswer;
    if (correctAnswer == null) return false;
    if (!question.isMultiChoice) {
      return answer == correctAnswer;
    } else {
      final correctSet = (correctAnswer is List)
          ? Set<int>.from(correctAnswer.cast<int>())
          : <int>{if (correctAnswer is int) correctAnswer};
      final answerSet = answer is Set<int> ? answer : <int>{};
      return answerSet.length == correctSet.length &&
          answerSet.containsAll(correctSet);
    }
  }

  /// 解析分析结果
  static PersonalityAnalysisResult _parseAnalysisResult(
    String content,
    Survey survey,
    List<dynamic> answers,
  ) {
    try {
      // 尝试提取 JSON
      String jsonStr = content;
      // 移除可能的 markdown 代码块
      if (content.contains('```json')) {
        jsonStr = content.split('```json')[1].split('```')[0].trim();
      } else if (content.contains('```')) {
        jsonStr = content.split('```')[1].split('```')[0].trim();
      }

      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      final rawResults = data['questionResults'] as List;
      final questionResults = <QuestionAnalysisResult>[];
      for (int i = 0; i < rawResults.length; i++) {
        final q = rawResults[i] as Map<String, dynamic>;
        final question = i < survey.questions.length ? survey.questions[i] : null;
        final answer = i < answers.length ? answers[i] : null;
        // 答案完全一致时强制 100%，否则使用 AI 给出的值
        final matched = question != null && answer != null && _answersMatch(question, answer);
        final matchPercentage = matched ? 100 : (q['matchPercentage'] as int);
        final fullScore = question?.questionScore ?? 0;
        final actualScore = (fullScore * matchPercentage / 100).round();
        questionResults.add(QuestionAnalysisResult(
          questionIndex: q['questionIndex'] as int,
          questionTitle: q['questionTitle'] as String,
          matchPercentage: matchPercentage,
          fullScore: fullScore,
          actualScore: actualScore,
          reason: matched ? '与出题者答案完全一致' : (q['reason'] as String? ?? ''),
          creatorAnswer: q['creatorAnswer'] as String? ?? '',
          playerAnswer: q['playerAnswer'] as String? ?? '',
        ));
      }

      final totalScore = questionResults.fold<int>(0, (sum, q) => sum + q.actualScore);
      final fullTotalScore = questionResults.fold<int>(0, (sum, q) => sum + q.fullScore);
      
      return PersonalityAnalysisResult(
        questionResults: questionResults,
        totalScore: totalScore,
        fullTotalScore: fullTotalScore,
        overallMatchPercentage: data['overallMatchPercentage'] as int,
        creatorAnalysis: data['creatorAnalysis'] as String? ?? '未提供分析',
        playerAnalysis: data['playerAnalysis'] as String? ?? '未提供分析',
        sameGenderCompatibility: data['sameGenderCompatibility'] as String? ?? '未提供分析',
        oppositeGenderCompatibility: data['oppositeGenderCompatibility'] as String? ?? '未提供分析',
      );
    } catch (e) {
      // 解析失败返回模拟数据
      return _generateMockResult(survey, answers, error: '解析失败: $e');
    }
  }

  /// 生成模拟结果（用于 API 不可用时）
  static PersonalityAnalysisResult _generateMockResult(
    Survey survey,
    List<dynamic> answers, {
    String? error,
  }) {
    final questionResults = <QuestionAnalysisResult>[];
    var totalScore = 0;
    var fullTotalScore = 0;
    
    for (int i = 0; i < survey.questions.length; i++) {
      final question = survey.questions[i];
      final answer = answers[i];
      final fullScore = question.questionScore;
      
      // 计算匹配度：完全一致给 100%，有答案给 70%，无答案给 0%
      int matchPercentage;
      if (answer == null || (answer is Set && answer.isEmpty)) {
        matchPercentage = 0;
      } else if (_answersMatch(question, answer)) {
        matchPercentage = 100;
      } else {
        matchPercentage = 70;
      }
      
      final actualScore = (fullScore * matchPercentage / 100).round();
      totalScore += actualScore;
      fullTotalScore += fullScore;
      
      // 构建答案描述
      String creatorAnswerStr = '未设置';
      if (question.correctAnswer != null) {
        if (!question.isMultiChoice) {
          final idx = question.correctAnswer as int;
          creatorAnswerStr = idx < question.options.length 
              ? '${String.fromCharCode(65 + idx)}. ${question.options[idx].content}'
              : '无效';
        } else {
          final list = question.correctAnswer is List 
              ? question.correctAnswer as List
              : [question.correctAnswer];
          creatorAnswerStr = list.map((idx) {
            final i = idx as int;
            return i < question.options.length 
                ? '${String.fromCharCode(65 + i)}. ${question.options[i].content}'
                : '';
          }).join('、');
        }
      }
      
      String playerAnswerStr = '未作答';
      if (answer is int) {
        playerAnswerStr = answer < question.options.length
            ? '${String.fromCharCode(65 + answer)}. ${question.options[answer].content}'
            : '无效';
      } else if (answer is Set && answer.isNotEmpty) {
        playerAnswerStr = answer.map((idx) {
          final index = idx as int;
          return index < question.options.length
              ? '${String.fromCharCode(65 + index)}. ${question.options[index].content}'
              : '';
        }).join('、');
      }
      
      questionResults.add(QuestionAnalysisResult(
        questionIndex: i,
        questionTitle: question.title,
        matchPercentage: matchPercentage,
        fullScore: fullScore,
        actualScore: actualScore,
        reason: error != null 
            ? '分析服务暂时不可用，使用默认评分'
            : '匹配度$matchPercentage%，双方答案${matchPercentage >= 100 ? "完全一致" : "较为接近"}',
        creatorAnswer: creatorAnswerStr,
        playerAnswer: playerAnswerStr,
      ));
    }
    
    final overallMatchPercentage = fullTotalScore > 0
        ? (totalScore / fullTotalScore * 100).round()
        : 0;
    
    if (error != null) {
      return PersonalityAnalysisResult(
        questionResults: questionResults,
        totalScore: totalScore,
        fullTotalScore: fullTotalScore,
        overallMatchPercentage: overallMatchPercentage,
        creatorAnalysis: '⚠️ $error\n\n已使用默认评分规则计算得分。',
        playerAnalysis: '请检查网络连接或 API 配置。',
        sameGenderCompatibility: '无法分析合适度。',
        oppositeGenderCompatibility: '无法分析合适度。',
      );
    }
    
    return PersonalityAnalysisResult(
      questionResults: questionResults,
      totalScore: totalScore,
      fullTotalScore: fullTotalScore,
      overallMatchPercentage: overallMatchPercentage,
      creatorAnalysis: '出题者是一个注重情感表达、有自己独特见解的人。从答案选择来看，TA对生活有自己的态度和追求。',
      playerAnalysis: '做题者性格较为随和，能够理解和尊重他人的观点，同时也保持着自己的独立思考。',
      sameGenderCompatibility: '作为朋友，两人性格互补，能够相互理解和包容。出题者的主见与做题者的随和形成良好的平衡，适合成为深交的朋友。建议多进行深入的交流，分享彼此的生活经历。',
      oppositeGenderCompatibility: '作为伴侣，两人的匹配度为 $overallMatchPercentage%。出题者的独立个性与做题者的包容性格能够形成良好的互补。恋爱关系中，双方需要多沟通，尊重彼此的差异。建议一起参与双方都感兴趣的活动，增进感情。',
    );
  }
}
