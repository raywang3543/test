/// 用户答题结果模型，将 UID 与答题信息一一对应存储
class SurveyResult {
  final String uid;
  final DateTime submitTime;
  final int totalScore;
  final List<QuestionAnswer> answers;

  const SurveyResult({
    required this.uid,
    required this.submitTime,
    required this.totalScore,
    required this.answers,
  });

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'submitTime': submitTime.toIso8601String(),
        'totalScore': totalScore,
        'answers': answers.map((a) => a.toJson()).toList(),
      };

  factory SurveyResult.fromJson(Map<String, dynamic> json) => SurveyResult(
        uid: json['uid'] as String,
        submitTime: DateTime.parse(json['submitTime'] as String),
        totalScore: json['totalScore'] as int,
        answers: (json['answers'] as List)
            .map((a) => QuestionAnswer.fromJson(a as Map<String, dynamic>))
            .toList(),
      );
}

/// 单题答题记录
class QuestionAnswer {
  final String questionTitle;
  final bool isMultiChoice;
  final List<SelectedOption> selectedOptions;
  final int questionScore;

  const QuestionAnswer({
    required this.questionTitle,
    required this.isMultiChoice,
    required this.selectedOptions,
    required this.questionScore,
  });

  Map<String, dynamic> toJson() => {
        'questionTitle': questionTitle,
        'isMultiChoice': isMultiChoice,
        'selectedOptions': selectedOptions.map((o) => o.toJson()).toList(),
        'questionScore': questionScore,
      };

  factory QuestionAnswer.fromJson(Map<String, dynamic> json) => QuestionAnswer(
        questionTitle: json['questionTitle'] as String,
        isMultiChoice: json['isMultiChoice'] as bool,
        selectedOptions: (json['selectedOptions'] as List)
            .map((o) => SelectedOption.fromJson(o as Map<String, dynamic>))
            .toList(),
        questionScore: json['questionScore'] as int,
      );
}

/// 选中的选项记录
class SelectedOption {
  final String content;
  final int score;

  const SelectedOption({
    required this.content,
    required this.score,
  });

  Map<String, dynamic> toJson() => {
        'content': content,
        'score': score,
      };

  factory SelectedOption.fromJson(Map<String, dynamic> json) => SelectedOption(
        content: json['content'] as String,
        score: json['score'] as int,
      );
}
