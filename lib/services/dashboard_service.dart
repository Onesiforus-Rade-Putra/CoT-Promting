import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../core/config/api_config.dart';
import '../core/exceptions/dashboard_exception.dart';
import '../models/achievement_model.dart';
import '../models/gamification_summary_model.dart';
import '../models/leaderboard_response_model.dart';
import '../models/quest_model.dart';
import '../models/task_summary_model.dart';
import '../models/user_profile_model.dart';

class DashboardService {
  final http.Client _client;
  final FlutterSecureStorage _secureStorage;

  DashboardService({
    http.Client? client,
    FlutterSecureStorage? secureStorage,
  })  : _client = client ?? http.Client(),
        _secureStorage = secureStorage ?? const FlutterSecureStorage();

  Future<UserProfileModel> getMyProfile() async {
    final response = await _get('/api/v1/user/profile');
    final json = await _decodeResponseAsMap(response);

    return UserProfileModel.fromJson(json);
  }

  Future<TaskSummaryModel> getTaskSummary() async {
    final response = await _get('/api/v1/progress-tracking/summary');
    final json = await _decodeResponseAsMap(response);

    return TaskSummaryModel.fromJson(json);
  }

  Future<GamificationSummaryModel> getGamificationSummary() async {
    final response = await _get('/api/v1/gamification/summary');
    final json = await _decodeResponseAsMap(response);

    return GamificationSummaryModel.fromJson(json);
  }

  Future<List<AchievementModel>> getAchievements({
    String? achievementType,
  }) async {
    if (achievementType != null &&
        !const {'quest', 'forum', 'streak'}.contains(achievementType)) {
      throw const DashboardValidationException();
    }

    final response = await _get(
      '/api/v1/gamification/achievement',
      queryParameters: achievementType == null
          ? null
          : <String, String>{
              'achievement_type': achievementType,
            },
    );

    final list = await _decodeResponseAsList(response);

    return list
        .whereType<Map>()
        .map((item) => AchievementModel.fromJson(
              Map<String, dynamic>.from(item),
            ))
        .toList();
  }

  Future<List<QuestModel>> getQuests({
    String? frequency,
  }) async {
    if (frequency != null &&
        !const {'harian', 'mingguan'}.contains(frequency)) {
      throw const DashboardValidationException();
    }

    final response = await _get(
      '/api/v1/gamification/quests',
      queryParameters: frequency == null
          ? null
          : <String, String>{
              'frequency': frequency,
            },
    );

    final list = await _decodeResponseAsList(response);

    return list
        .whereType<Map>()
        .map((item) => QuestModel.fromJson(
              Map<String, dynamic>.from(item),
            ))
        .toList();
  }

  Future<LeaderboardResponseModel> getLeaderboard() async {
    final response = await _get('/api/v1/gamification/leaderboard');
    final json = await _decodeResponseAsMap(response);

    return LeaderboardResponseModel.fromJson(json);
  }

  Future<http.Response> _get(
    String path, {
    Map<String, String>? queryParameters,
  }) async {
    final token = await _secureStorage.read(key: ApiConfig.accessTokenKey);

    if (token == null || token.trim().isEmpty) {
      throw const DashboardUnauthorizedException();
    }

    final uri = Uri.parse('${ApiConfig.baseUrl}$path').replace(
      queryParameters: queryParameters,
    );

    try {
      final response = await _client.get(
        uri,
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(ApiConfig.requestTimeout);

      await _handleErrorStatus(response);

      return response;
    } on DashboardException {
      rethrow;
    } on SocketException {
      throw const DashboardNetworkException();
    } on TimeoutException {
      throw const DashboardNetworkException();
    } catch (_) {
      throw const DashboardServerException();
    }
  }

  Future<void> _handleErrorStatus(http.Response response) async {
    if (response.statusCode == 200) return;

    if (response.statusCode == 401) {
      await _secureStorage.delete(key: ApiConfig.accessTokenKey);
      throw const DashboardUnauthorizedException();
    }

    if (response.statusCode == 422) {
      throw const DashboardValidationException();
    }

    throw const DashboardServerException();
  }

  Future<Map<String, dynamic>> _decodeResponseAsMap(
    http.Response response,
  ) async {
    try {
      final decoded = jsonDecode(response.body);

      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }

      throw const DashboardParseException();
    } catch (_) {
      throw const DashboardParseException();
    }
  }

  Future<List<dynamic>> _decodeResponseAsList(
    http.Response response,
  ) async {
    try {
      final decoded = jsonDecode(response.body);

      if (decoded is List) {
        return decoded;
      }

      throw const DashboardParseException();
    } catch (_) {
      throw const DashboardParseException();
    }
  }
}
