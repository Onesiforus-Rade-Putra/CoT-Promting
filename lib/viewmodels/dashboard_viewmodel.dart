import 'package:flutter/foundation.dart';

import '../core/exceptions/dashboard_exception.dart';
import '../models/achievement_model.dart';
import '../models/gamification_summary_model.dart';
import '../models/leaderboard_response_model.dart';
import '../models/quest_model.dart';
import '../models/task_summary_model.dart';
import '../models/user_profile_model.dart';
import '../services/dashboard_service.dart';

class DashboardViewModel extends ChangeNotifier {
  final DashboardService _dashboardService;

  DashboardViewModel({
    required DashboardService dashboardService,
  }) : _dashboardService = dashboardService;

  UserProfileModel? profile;
  TaskSummaryModel? taskSummary;
  GamificationSummaryModel? gamificationSummary;
  List<AchievementModel> achievements = <AchievementModel>[];
  List<QuestModel> quests = <QuestModel>[];
  LeaderboardResponseModel? leaderboard;

  bool isLoading = false;
  bool isLoadingProfile = false;
  bool isLoadingTaskSummary = false;
  bool isLoadingGamification = false;
  bool isLoadingAchievements = false;
  bool isLoadingQuests = false;
  bool isLoadingLeaderboard = false;

  String? errorMessage;
  String? profileErrorMessage;
  String? taskSummaryErrorMessage;
  String? gamificationErrorMessage;
  String? achievementsErrorMessage;
  String? questsErrorMessage;
  String? leaderboardErrorMessage;

  String selectedQuestFrequency = 'harian';

  bool isSessionExpired = false;

  bool get hasAnyData {
    return profile != null ||
        taskSummary != null ||
        gamificationSummary != null ||
        achievements.isNotEmpty ||
        quests.isNotEmpty ||
        leaderboard != null;
  }

  bool get isAllFailed {
    return !isLoading && !hasAnyData && errorMessage != null;
  }

  double? get levelProgress {
    final summary = gamificationSummary;
    if (summary == null) return null;

    final totalXpForCurrentLevel =
        summary.currentLevelXp + summary.nextLevelRequiredXpDiff;

    if (totalXpForCurrentLevel <= 0) return null;

    final progress = summary.currentLevelXp / totalXpForCurrentLevel;

    return progress.clamp(0.0, 1.0).toDouble();
  }

  double get dailyQuestProgress {
    final summary = gamificationSummary;
    if (summary == null || summary.totalQuest <= 0) return 0;

    final progress = summary.totalQuestCompleted / summary.totalQuest;

    return progress.clamp(0.0, 1.0).toDouble();
  }

  Future<void> loadDashboardData() async {
    isLoading = true;
    isSessionExpired = false;
    _clearErrors();
    notifyListeners();

    await Future.wait(
      <Future<void>>[
        loadProfile(),
        loadTaskSummary(),
        loadGamificationSummary(),
        loadAchievements(),
        loadQuests(frequency: selectedQuestFrequency),
        loadLeaderboard(),
      ],
      eagerError: false,
    );

    isLoading = false;

    if (!hasAnyData && errorMessage == null) {
      errorMessage = 'Gagal memuat dashboard.';
    }

    notifyListeners();
  }

  Future<void> loadProfile() async {
    isLoadingProfile = true;
    profileErrorMessage = null;
    notifyListeners();

    try {
      profile = await _dashboardService.getMyProfile();
    } catch (error) {
      _handleException(
        error,
        setSectionError: (message) => profileErrorMessage = message,
      );
    } finally {
      isLoadingProfile = false;
      notifyListeners();
    }
  }

  Future<void> loadTaskSummary() async {
    isLoadingTaskSummary = true;
    taskSummaryErrorMessage = null;
    notifyListeners();

    try {
      taskSummary = await _dashboardService.getTaskSummary();
    } catch (error) {
      _handleException(
        error,
        setSectionError: (message) => taskSummaryErrorMessage = message,
      );
    } finally {
      isLoadingTaskSummary = false;
      notifyListeners();
    }
  }

  Future<void> loadGamificationSummary() async {
    isLoadingGamification = true;
    gamificationErrorMessage = null;
    notifyListeners();

    try {
      gamificationSummary = await _dashboardService.getGamificationSummary();
    } catch (error) {
      _handleException(
        error,
        setSectionError: (message) => gamificationErrorMessage = message,
      );
    } finally {
      isLoadingGamification = false;
      notifyListeners();
    }
  }

  Future<void> loadAchievements({
    String? achievementType,
  }) async {
    isLoadingAchievements = true;
    achievementsErrorMessage = null;
    notifyListeners();

    try {
      achievements = await _dashboardService.getAchievements(
        achievementType: achievementType,
      );
    } catch (error) {
      _handleException(
        error,
        setSectionError: (message) => achievementsErrorMessage = message,
      );
    } finally {
      isLoadingAchievements = false;
      notifyListeners();
    }
  }

  Future<void> loadQuests({
    String frequency = 'harian',
  }) async {
    isLoadingQuests = true;
    questsErrorMessage = null;
    notifyListeners();

    try {
      selectedQuestFrequency = frequency;
      quests = await _dashboardService.getQuests(frequency: frequency);
    } catch (error) {
      _handleException(
        error,
        setSectionError: (message) => questsErrorMessage = message,
      );
    } finally {
      isLoadingQuests = false;
      notifyListeners();
    }
  }

  Future<void> changeQuestFrequency(String frequency) async {
    if (!const {'harian', 'mingguan'}.contains(frequency)) {
      questsErrorMessage = 'Permintaan data tidak valid.';
      notifyListeners();
      return;
    }

    selectedQuestFrequency = frequency;
    notifyListeners();

    await loadQuests(frequency: frequency);
  }

  Future<void> loadLeaderboard() async {
    isLoadingLeaderboard = true;
    leaderboardErrorMessage = null;
    notifyListeners();

    try {
      leaderboard = await _dashboardService.getLeaderboard();
    } catch (error) {
      _handleException(
        error,
        setSectionError: (message) => leaderboardErrorMessage = message,
      );
    } finally {
      isLoadingLeaderboard = false;
      notifyListeners();
    }
  }

  Future<void> refreshDashboard() async {
    await loadDashboardData();
  }

  void _clearErrors() {
    errorMessage = null;
    profileErrorMessage = null;
    taskSummaryErrorMessage = null;
    gamificationErrorMessage = null;
    achievementsErrorMessage = null;
    questsErrorMessage = null;
    leaderboardErrorMessage = null;
  }

  void _handleException(
    Object error, {
    required void Function(String message) setSectionError,
  }) {
    final message = error is DashboardException
        ? error.message
        : 'Terjadi kesalahan. Silakan coba lagi.';

    setSectionError(message);

    if (error is DashboardUnauthorizedException) {
      isSessionExpired = true;
      errorMessage = message;
      return;
    }

    errorMessage ??= message;
  }
}
