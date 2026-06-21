import 'json_parsing.dart';

class GamificationSummaryModel {
  final int totalQuest;
  final int totalQuestCompleted;
  final int currentLevel;
  final int totalXpEarned;
  final int currentRanking;
  final int currentStreak;
  final int currentLevelXp;
  final int nextLevelRequiredXpDiff;

  const GamificationSummaryModel({
    required this.totalQuest,
    required this.totalQuestCompleted,
    required this.currentLevel,
    required this.totalXpEarned,
    required this.currentRanking,
    required this.currentStreak,
    required this.currentLevelXp,
    required this.nextLevelRequiredXpDiff,
  });

  factory GamificationSummaryModel.fromJson(Map<String, dynamic> json) {
    return GamificationSummaryModel(
      totalQuest: jsonInt(json['total_quest']),
      totalQuestCompleted: jsonInt(json['total_quest_completed']),
      currentLevel: jsonInt(json['current_level']),
      totalXpEarned: jsonInt(json['total_xp_earned']),
      currentRanking: jsonInt(json['current_ranking']),
      currentStreak: jsonInt(json['current_streak']),
      currentLevelXp: jsonInt(json['current_level_xp']),
      nextLevelRequiredXpDiff: jsonInt(json['next_level_required_xp_diff']),
    );
  }
}
