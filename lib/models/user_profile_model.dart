import 'json_parsing.dart';

class UserProfileModel {
  final String id;
  final String email;
  final String? username;
  final String? fullName;
  final String? description;
  final String? phoneNumber;
  final String? nim;
  final DateTime? birthDate;
  final bool? notifications;
  final bool? shareLeaderboardStats;
  final int? totalXp;
  final int? currentLevel;

  const UserProfileModel({
    required this.id,
    required this.email,
    this.username,
    this.fullName,
    this.description,
    this.phoneNumber,
    this.nim,
    this.birthDate,
    this.notifications,
    this.shareLeaderboardStats,
    this.totalXp,
    this.currentLevel,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      id: jsonString(json['id']),
      email: jsonString(json['email']),
      username: jsonNullableString(json['username']),
      fullName: jsonNullableString(json['full_name']),
      description: jsonNullableString(json['description']),
      phoneNumber: jsonNullableString(json['phone_number']),
      nim: jsonNullableString(json['nim']),
      birthDate: jsonDate(json['birth_date']),
      notifications: jsonBool(json['notifications']),
      shareLeaderboardStats: jsonBool(json['share_leaderboard_stats']),
      totalXp: jsonInt(json['total_xp']),
      currentLevel: jsonInt(json['current_level']),
    );
  }
}
