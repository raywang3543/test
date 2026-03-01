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

  const SurveyQuestion({
    required this.title,
    required this.options,
    required this.isMultiChoice,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'isMultiChoice': isMultiChoice,
        'options': options.map((o) => o.toJson()).toList(),
      };

  factory SurveyQuestion.fromJson(Map<String, dynamic> json) => SurveyQuestion(
        title: json['title'] as String,
        isMultiChoice: json['isMultiChoice'] as bool,
        options: (json['options'] as List)
            .map((o) => SurveyOption.fromJson(o as Map<String, dynamic>))
            .toList(),
      );
}

class Survey {
  final List<SurveyQuestion> questions;

  const Survey({required this.questions});

  Map<String, dynamic> toJson() => {
        'questions': questions.map((q) => q.toJson()).toList(),
      };

  factory Survey.fromJson(Map<String, dynamic> json) => Survey(
        questions: (json['questions'] as List)
            .map((q) => SurveyQuestion.fromJson(q as Map<String, dynamic>))
            .toList(),
      );
}
