class QuestionModel {
  final String id;
  final String text;
  final String optionA;
  final String optionB;
  final String optionC;
  final String optionD;
  final String difficulty;
  final String category;
  final int roundNumber;
  final int totalRounds;

  const QuestionModel({
    required this.id,
    required this.text,
    required this.optionA,
    required this.optionB,
    required this.optionC,
    required this.optionD,
    required this.difficulty,
    required this.category,
    required this.roundNumber,
    required this.totalRounds,
  });

  factory QuestionModel.fromJson(Map<String, dynamic> json) => QuestionModel(
        id: json['id'] as String,
        text: json['text'] as String,
        optionA: json['optionA'] as String,
        optionB: json['optionB'] as String,
        optionC: json['optionC'] as String,
        optionD: json['optionD'] as String,
        difficulty: json['difficulty'] as String? ?? 'Medium',
        category: json['category'] as String? ?? 'General',
        roundNumber: json['roundNumber'] as int? ?? 1,
        totalRounds: json['totalRounds'] as int? ?? 10,
      );

  /// Returns the text for a given option key ("A", "B", "C", "D")
  String getOptionText(String option) {
    return switch (option.toUpperCase()) {
      'A' => optionA,
      'B' => optionB,
      'C' => optionC,
      'D' => optionD,
      _ => '',
    };
  }
}

/// Full question including the correct answer (revealed after round ends)
class QuestionRevealModel {
  final String id;
  final String text;
  final String optionA;
  final String optionB;
  final String optionC;
  final String optionD;
  final String correctOption;
  final String difficulty;
  final String category;

  const QuestionRevealModel({
    required this.id,
    required this.text,
    required this.optionA,
    required this.optionB,
    required this.optionC,
    required this.optionD,
    required this.correctOption,
    required this.difficulty,
    required this.category,
  });

  factory QuestionRevealModel.fromJson(Map<String, dynamic> json) =>
      QuestionRevealModel(
        id: json['id'] as String,
        text: json['text'] as String,
        optionA: json['optionA'] as String,
        optionB: json['optionB'] as String,
        optionC: json['optionC'] as String,
        optionD: json['optionD'] as String,
        correctOption: json['correctOption'] as String,
        difficulty: json['difficulty'] as String? ?? 'Medium',
        category: json['category'] as String? ?? 'General',
      );

  /// Returns the text for a given option key ("A", "B", "C", "D")
  String getOptionText(String option) {
    return switch (option.toUpperCase()) {
      'A' => optionA,
      'B' => optionB,
      'C' => optionC,
      'D' => optionD,
      _ => '',
    };
  }
}
