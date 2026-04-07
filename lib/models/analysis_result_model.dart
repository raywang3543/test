/// Kimi 分析结果模型
class QuestionAnalysisResult {
  /// 题目序号
  final int questionIndex;
  /// 题目内容
  final String questionTitle;
  /// 匹配度百分比（0-100）
  final int matchPercentage;
  /// 本题满分
  final int fullScore;
  /// 实际得分（四舍五入）
  final int actualScore;
  /// 得分原因
  final String reason;
  /// 出题者答案描述
  final String creatorAnswer;
  /// 做题者答案描述
  final String playerAnswer;

  const QuestionAnalysisResult({
    required this.questionIndex,
    required this.questionTitle,
    required this.matchPercentage,
    required this.fullScore,
    required this.actualScore,
    required this.reason,
    required this.creatorAnswer,
    required this.playerAnswer,
  });

  Map<String, dynamic> toJson() => {
        'questionIndex': questionIndex,
        'questionTitle': questionTitle,
        'matchPercentage': matchPercentage,
        'fullScore': fullScore,
        'actualScore': actualScore,
        'reason': reason,
        'creatorAnswer': creatorAnswer,
        'playerAnswer': playerAnswer,
      };

  factory QuestionAnalysisResult.fromJson(Map<String, dynamic> json) =>
      QuestionAnalysisResult(
        questionIndex: json['questionIndex'] as int,
        questionTitle: json['questionTitle'] as String,
        matchPercentage: json['matchPercentage'] as int,
        fullScore: json['fullScore'] as int,
        actualScore: json['actualScore'] as int,
        reason: json['reason'] as String,
        creatorAnswer: json['creatorAnswer'] as String,
        playerAnswer: json['playerAnswer'] as String,
      );
}

/// 完整分析结果
class PersonalityAnalysisResult {
  /// 每道题的分析结果
  final List<QuestionAnalysisResult> questionResults;
  /// 总分
  final int totalScore;
  /// 满分
  final int fullTotalScore;
  /// 总体匹配度
  final int overallMatchPercentage;
  /// 出题者性格分析
  final String creatorAnalysis;
  /// 做题者性格分析
  final String playerAnalysis;
  /// 同性合适度分析
  final String sameGenderCompatibility;
  /// 异性合适度分析
  final String oppositeGenderCompatibility;

  const PersonalityAnalysisResult({
    required this.questionResults,
    required this.totalScore,
    required this.fullTotalScore,
    required this.overallMatchPercentage,
    required this.creatorAnalysis,
    required this.playerAnalysis,
    required this.sameGenderCompatibility,
    required this.oppositeGenderCompatibility,
  });

  Map<String, dynamic> toJson() => {
        'questionResults': questionResults.map((q) => q.toJson()).toList(),
        'totalScore': totalScore,
        'fullTotalScore': fullTotalScore,
        'overallMatchPercentage': overallMatchPercentage,
        'creatorAnalysis': creatorAnalysis,
        'playerAnalysis': playerAnalysis,
        'sameGenderCompatibility': sameGenderCompatibility,
        'oppositeGenderCompatibility': oppositeGenderCompatibility,
      };

  factory PersonalityAnalysisResult.fromJson(Map<String, dynamic> json) =>
      PersonalityAnalysisResult(
        questionResults: (json['questionResults'] as List)
            .map((q) => QuestionAnalysisResult.fromJson(q as Map<String, dynamic>))
            .toList(),
        totalScore: json['totalScore'] as int,
        fullTotalScore: json['fullTotalScore'] as int,
        overallMatchPercentage: json['overallMatchPercentage'] as int,
        creatorAnalysis: json['creatorAnalysis'] as String,
        playerAnalysis: json['playerAnalysis'] as String,
        sameGenderCompatibility: json['sameGenderCompatibility'] as String,
        oppositeGenderCompatibility: json['oppositeGenderCompatibility'] as String,
      );
}
