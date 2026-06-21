class QuizResultModel {
  const QuizResultModel({
    required this.correctAnswers,
    required this.totalQuestions,
    required this.minimumScore,
    required this.passed,
    required this.pointsGained,
    required this.streakCount,
    required this.streakBonus,
    required this.certificateId,
  });

  final int correctAnswers;
  final int totalQuestions;
  final int minimumScore;
  final bool passed;
  final int pointsGained;
  final int streakCount;
  final int streakBonus;
  final String? certificateId;

  double get scorePercentage {
    if (totalQuestions <= 0) return 0;
    return (correctAnswers / totalQuestions) * 100;
  }

  factory QuizResultModel.fromJson(Map<String, dynamic> json) {
    return QuizResultModel(
      correctAnswers: _toInt(json['correct_answers']),
      totalQuestions: _toInt(json['total_questions']),
      minimumScore: _toInt(json['minimum_score']),
      passed: json['passed'] as bool? ?? false,
      pointsGained: _toInt(json['points_gained']),
      streakCount: _toInt(json['streak_count']),
      streakBonus: _toInt(json['streak_bonus']),
      certificateId: json['certificate_id']?.toString(),
    );
  }

  QuizResultModel copyWith({String? certificateId}) {
    return QuizResultModel(
      correctAnswers: correctAnswers,
      totalQuestions: totalQuestions,
      minimumScore: minimumScore,
      passed: passed,
      pointsGained: pointsGained,
      streakCount: streakCount,
      streakBonus: streakBonus,
      certificateId: certificateId ?? this.certificateId,
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
