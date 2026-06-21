class QuizModel {
  const QuizModel({
    required this.id,
    required this.title,
    required this.category,
    required this.durationMinutes,
    required this.minimumScore,
    required this.xpReward,
    required this.difficulty,
    required this.lastAttemptSuccessfull,
    required this.certificateId,
    required this.completionCount,
  });

  final int id;
  final String title;
  final String category;
  final int durationMinutes;
  final int minimumScore;
  final int xpReward;
  final String difficulty;
  final bool lastAttemptSuccessfull;
  final String? certificateId;
  final int completionCount;

  factory QuizModel.fromJson(Map<String, dynamic> json) {
    return QuizModel(
      id: _toInt(json['id']),
      title: json['title']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      durationMinutes: _toInt(json['duration_minutes']),
      minimumScore: _toInt(json['minimum_score']),
      xpReward: _toInt(json['xp_reward']),
      difficulty: json['difficulty']?.toString() ?? 'easy',
      // Nama JSON harus tetap sama dengan dokumentasi API.
      lastAttemptSuccessfull:
          json['last_attempt_successfull'] as bool? ?? false,
      certificateId: json['certificate_id']?.toString(),
      completionCount: _toInt(json['completion_count']),
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
