class SurveyOption {
  final String content;
  final int score;

  const SurveyOption({required this.content, required this.score});

  Map<String, dynamic> toJson() => {'content': content, 'score': score};

  factory SurveyOption.fromJson(Map<String, dynamic> json) =>
      SurveyOption(content: json['content'] as String, score: json['score'] as int);
}

class SurveyQuestion {
  final String title;
  final List<SurveyOption> options;
  final bool isMultiChoice;
  /// 标准答案：单选为 int（选项下标），多选为 List&lt;int&gt;
  final dynamic correctAnswer;
  /// 本题总分
  final int questionScore;

  const SurveyQuestion({
    required this.title,
    required this.options,
    required this.isMultiChoice,
    this.correctAnswer,
    this.questionScore = 10,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'isMultiChoice': isMultiChoice,
        'options': options.map((o) => o.toJson()).toList(),
        'correctAnswer': correctAnswer,
        'questionScore': questionScore,
      };

  factory SurveyQuestion.fromJson(Map<String, dynamic> json) => SurveyQuestion(
        title: json['title'] as String,
        isMultiChoice: json['isMultiChoice'] as bool,
        options: (json['options'] as List)
            .map((o) => SurveyOption.fromJson(o as Map<String, dynamic>))
            .toList(),
        correctAnswer: json['correctAnswer'],
        questionScore: json['questionScore'] as int? ?? 10,
      );
}

class Survey {
  /// SQLite 自增主键
  final int? id;
  final String uid;
  final List<SurveyQuestion> questions;
  final DateTime? createdAt;
  /// 创建者的基础信息
  final String creatorBasicInfo;

  const Survey({
    this.id,
    required this.uid,
    required this.questions,
    this.createdAt,
    this.creatorBasicInfo = '',
  });

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'questions': questions.map((q) => q.toJson()).toList(),
        'createdAt': createdAt?.toIso8601String(),
        'creatorBasicInfo': creatorBasicInfo,
      };

  factory Survey.fromJson(Map<String, dynamic> json) => Survey(
        uid: json['uid'] as String? ?? '',
        questions: (json['questions'] as List)
            .map((q) => SurveyQuestion.fromJson(q as Map<String, dynamic>))
            .toList(),
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : null,
        creatorBasicInfo: json['creatorBasicInfo'] as String? ?? '',
      );
}
