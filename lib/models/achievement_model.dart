import 'json_parsing.dart';

class AchievementModel {
  final String title;
  final String description;
  final String type;
  final int xpReward;
  final String difficulty;
  final int progressPercentage;
  final bool isCompleted;
  final DateTime? completionDate;

  const AchievementModel({
    required this.title,
    required this.description,
    required this.type,
    required this.xpReward,
    required this.difficulty,
    required this.progressPercentage,
    required this.isCompleted,
    this.completionDate,
  });

  factory AchievementModel.fromJson(Map<String, dynamic> json) {
    return AchievementModel(
      title: jsonString(json['title']),
      description: jsonString(json['description']),
      type: jsonString(json['type']),
      xpReward: jsonInt(json['xp_reward']),
      difficulty: jsonString(json['difficulty']),
      progressPercentage: jsonInt(json['progress_percentage']),
      isCompleted: jsonBool(json['is_completed']),
      completionDate: jsonDate(json['completion_date']),
    );
  }
}
