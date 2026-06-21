import 'json_parsing.dart';

class LeaderboardResponseModel {
  final int userRank;
  final int userTotalXp;
  final List<LeaderboardItemModel> topGlobal;
  final List<LeaderboardItemModel> topFriends;

  const LeaderboardResponseModel({
    required this.userRank,
    required this.userTotalXp,
    required this.topGlobal,
    required this.topFriends,
  });

  factory LeaderboardResponseModel.fromJson(Map<String, dynamic> json) {
    return LeaderboardResponseModel(
      userRank: jsonInt(json['user_rank']),
      userTotalXp: jsonInt(json['user_total_xp']),
      topGlobal: jsonList(
        json['top_global'],
        LeaderboardItemModel.fromJson,
      ),
      topFriends: jsonList(
        json['top_friends'],
        LeaderboardItemModel.fromJson,
      ),
    );
  }
}

class LeaderboardItemModel {
  final PublicUserModel user;
  final int xp;
  final int rank;
  final int level;

  const LeaderboardItemModel({
    required this.user,
    required this.xp,
    required this.rank,
    required this.level,
  });

  factory LeaderboardItemModel.fromJson(Map<String, dynamic> json) {
    return LeaderboardItemModel(
      user: PublicUserModel.fromJson(
        Map<String, dynamic>.from(json['user'] ?? <String, dynamic>{}),
      ),
      xp: jsonInt(json['xp']),
      rank: jsonInt(json['rank']),
      level: jsonInt(json['level']),
    );
  }
}

class PublicUserModel {
  final String id;
  final String username;
  final String fullName;

  const PublicUserModel({
    required this.id,
    required this.username,
    required this.fullName,
  });

  factory PublicUserModel.fromJson(Map<String, dynamic> json) {
    return PublicUserModel(
      id: jsonString(json['id']),
      username: jsonString(json['username']),
      fullName: jsonString(json['full_name']),
    );
  }
}
