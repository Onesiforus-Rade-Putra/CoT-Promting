import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/achievement_model.dart';
import '../models/leaderboard_response_model.dart';
import '../models/quest_model.dart';
import '../services/dashboard_service.dart';
import '../viewmodels/dashboard_viewmodel.dart';

class DashboardRoutes {
  DashboardRoutes._();

  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String profile = '/profile';
  static const String quizList = '/quiz-list';
  static const String targetTasks = '/target-tasks';
  static const String forum = '/forum';
  static const String achievements = '/achievements';
  static const String quests = '/quests';
  static const String leaderboard = '/leaderboard';
  static const String settings = '/settings';
}

class DashboardPage extends StatelessWidget {
  static const String routeName = DashboardRoutes.dashboard;

  final DashboardService? dashboardService;

  const DashboardPage({
    super.key,
    this.dashboardService,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<DashboardViewModel>(
      create: (_) => DashboardViewModel(
        dashboardService: dashboardService ?? DashboardService(),
      )..loadDashboardData(),
      child: const _DashboardView(),
    );
  }
}

class _DashboardView extends StatefulWidget {
  const _DashboardView();

  @override
  State<_DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<_DashboardView> {
  bool _isRedirectingToLogin = false;

  Future<void> _navigateAndRefresh(
    String routeName, {
    bool refreshAfterReturn = true,
  }) async {
    await Navigator.pushNamed(context, routeName);

    if (!mounted || !refreshAfterReturn) return;

    await context.read<DashboardViewModel>().refreshDashboard();
  }

  void _handleSessionExpired(DashboardViewModel viewModel) {
    if (!viewModel.isSessionExpired || _isRedirectingToLogin) return;

    _isRedirectingToLogin = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            viewModel.errorMessage ??
                'Sesi Anda telah berakhir. Silakan login kembali.',
          ),
        ),
      );

      Navigator.pushNamedAndRemoveUntil(
        context,
        DashboardRoutes.login,
        (_) => false,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<DashboardViewModel>();

    _handleSessionExpired(viewModel);

    return Scaffold(
      backgroundColor: _AppColors.darkRed,
      bottomNavigationBar: _DashboardBottomNavigationBar(
        onItemSelected: (index) {
          switch (index) {
            case 0:
              break;
            case 1:
              _navigateAndRefresh(DashboardRoutes.forum,
                  refreshAfterReturn: false);
              break;
            case 2:
              _navigateAndRefresh(DashboardRoutes.quizList);
              break;
            case 3:
              _navigateAndRefresh(
                DashboardRoutes.leaderboard,
                refreshAfterReturn: false,
              );
              break;
            case 4:
              _navigateAndRefresh(
                DashboardRoutes.settings,
                refreshAfterReturn: false,
              );
              break;
          }
        },
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: <Color>[
              _AppColors.red,
              _AppColors.darkRed,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: viewModel.refreshDashboard,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: viewModel.isAllFailed
                  ? _FullPageError(
                      message:
                          viewModel.errorMessage ?? 'Gagal memuat dashboard.',
                      onRetry: viewModel.loadDashboardData,
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        _HeaderSection(
                          viewModel: viewModel,
                          onProfileTap: () => _navigateAndRefresh(
                            DashboardRoutes.profile,
                            refreshAfterReturn: false,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _StatisticsRow(viewModel: viewModel),
                        const SizedBox(height: 16),
                        _DailyQuestCard(
                          viewModel: viewModel,
                          onStartTap: () => _navigateAndRefresh(
                            DashboardRoutes.quizList,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _ProgressActionSection(
                          viewModel: viewModel,
                          onQuizTap: () => _navigateAndRefresh(
                            DashboardRoutes.quizList,
                          ),
                          onAddTargetTap: () => _navigateAndRefresh(
                            DashboardRoutes.targetTasks,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _FeatureGrid(
                          onAchievementTap: () => _navigateAndRefresh(
                            DashboardRoutes.achievements,
                          ),
                          onTargetTap: () => _navigateAndRefresh(
                            DashboardRoutes.targetTasks,
                          ),
                          onForumTap: () => _navigateAndRefresh(
                            DashboardRoutes.forum,
                            refreshAfterReturn: false,
                          ),
                          onLeaderboardTap: () => _navigateAndRefresh(
                            DashboardRoutes.leaderboard,
                            refreshAfterReturn: false,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _TaskSummarySection(
                          viewModel: viewModel,
                          onOpenTargetTap: () => _navigateAndRefresh(
                            DashboardRoutes.targetTasks,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _QuestSection(
                          viewModel: viewModel,
                          onOpenQuestTap: () => _navigateAndRefresh(
                            DashboardRoutes.quests,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _AchievementSection(
                          viewModel: viewModel,
                          onOpenAchievementTap: () => _navigateAndRefresh(
                            DashboardRoutes.achievements,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _LeaderboardSection(
                          viewModel: viewModel,
                          onOpenLeaderboardTap: () => _navigateAndRefresh(
                            DashboardRoutes.leaderboard,
                            refreshAfterReturn: false,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _RecentActivitySection(viewModel: viewModel),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderSection extends StatelessWidget {
  final DashboardViewModel viewModel;
  final VoidCallback onProfileTap;

  const _HeaderSection({
    required this.viewModel,
    required this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    final name = _getDisplayName(viewModel.profile);
    final level = viewModel.gamificationSummary?.currentLevel ??
        viewModel.profile?.currentLevel ??
        0;
    final xp = viewModel.gamificationSummary?.totalXpEarned ??
        viewModel.profile?.totalXp ??
        0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Halo, $name!',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Siap Belajar Hari ini?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  height: 1.15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  _HeaderBadge(text: 'Level $level'),
                  _HeaderBadge(text: '${_formatNumber(xp)} XP'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        InkWell(
          onTap: onProfileTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.white.withOpacity(0.28),
              ),
            ),
            child: const Icon(
              Icons.person_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
        ),
      ],
    );
  }
}

class _HeaderBadge extends StatelessWidget {
  final String text;

  const _HeaderBadge({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _StatisticsRow extends StatelessWidget {
  final DashboardViewModel viewModel;

  const _StatisticsRow({
    required this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    final xp = viewModel.gamificationSummary?.totalXpEarned ??
        viewModel.profile?.totalXp ??
        0;
    final ranking = viewModel.gamificationSummary?.currentRanking ?? 0;
    final streak = viewModel.gamificationSummary?.currentStreak ?? 0;

    return Row(
      children: <Widget>[
        Expanded(
          child: _StatCard(
            icon: Icons.bolt_rounded,
            label: 'Total XP',
            value: _formatNumber(xp),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            icon: Icons.emoji_events_rounded,
            label: 'Ranking',
            value: ranking <= 0 ? '-' : '#$ranking',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            icon: Icons.local_fire_department_rounded,
            label: 'Streak',
            value: '$streak hari',
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.16),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withOpacity(0.16),
        ),
      ),
      child: Column(
        children: <Widget>[
          Icon(
            icon,
            color: Colors.white,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.82),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyQuestCard extends StatelessWidget {
  final DashboardViewModel viewModel;
  final VoidCallback onStartTap;

  const _DailyQuestCard({
    required this.viewModel,
    required this.onStartTap,
  });

  @override
  Widget build(BuildContext context) {
    final completed = viewModel.gamificationSummary?.totalQuestCompleted ?? 0;
    final activeIndicatorCount = min(completed, 3);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _whiteCardDecoration(),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Quest Harian',
                  style: TextStyle(
                    color: _AppColors.textDark,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Selesaikan 3 Quest & Raih Bonus',
                  style: TextStyle(
                    color: _AppColors.textMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: List<Widget>.generate(3, (index) {
                    final isActive = index < activeIndicatorCount;

                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: CircleAvatar(
                        radius: 15,
                        backgroundColor:
                            isActive ? _AppColors.red : _AppColors.lightRed,
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: isActive ? Colors.white : _AppColors.red,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: onStartTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: _AppColors.red,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              'Mulai',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressActionSection extends StatelessWidget {
  final DashboardViewModel viewModel;
  final VoidCallback onQuizTap;
  final VoidCallback onAddTargetTap;

  const _ProgressActionSection({
    required this.viewModel,
    required this.onQuizTap,
    required this.onAddTargetTap,
  });

  @override
  Widget build(BuildContext context) {
    final completed = viewModel.gamificationSummary?.totalQuestCompleted ?? 0;
    final total = viewModel.gamificationSummary?.totalQuest ?? 0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _whiteCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Selamat Datang Kembali',
            style: TextStyle(
              color: _AppColors.textDark,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            total <= 0
                ? 'Belum ada data quest hari ini.'
                : '$completed dari $total quest diselesaikan.',
            style: const TextStyle(
              color: _AppColors.textMuted,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 9,
              value: viewModel.dailyQuestProgress,
              backgroundColor: _AppColors.lightRed,
              valueColor: const AlwaysStoppedAnimation<Color>(_AppColors.red),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Expanded(
                child: _PrimaryButton(
                  label: 'Mulai Quiz',
                  icon: Icons.quiz_rounded,
                  onTap: onQuizTap,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SecondaryButton(
                  label: 'Tambah Target',
                  icon: Icons.add_task_rounded,
                  onTap: onAddTargetTap,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeatureGrid extends StatelessWidget {
  final VoidCallback onAchievementTap;
  final VoidCallback onTargetTap;
  final VoidCallback onForumTap;
  final VoidCallback onLeaderboardTap;

  const _FeatureGrid({
    required this.onAchievementTap,
    required this.onTargetTap,
    required this.onForumTap,
    required this.onLeaderboardTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const _WhiteSectionTitle(title: 'Jelajahi Fitur'),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.15,
          children: <Widget>[
            _FeatureCard(
              icon: Icons.workspace_premium_rounded,
              title: 'Achievement',
              description: 'Lihat pencapaian belajar.',
              onTap: onAchievementTap,
            ),
            _FeatureCard(
              icon: Icons.task_alt_rounded,
              title: 'Target dan Tugas',
              description: 'Kelola target aktif.',
              onTap: onTargetTap,
            ),
            _FeatureCard(
              icon: Icons.forum_rounded,
              title: 'Forum',
              description: 'Diskusi bersama teman.',
              onTap: onForumTap,
            ),
            _FeatureCard(
              icon: Icons.leaderboard_rounded,
              title: 'Leaderboard',
              description: 'Lihat peringkat terbaik.',
              onTap: onLeaderboardTap,
            ),
          ],
        ),
      ],
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _AppColors.borderRed),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              CircleAvatar(
                radius: 20,
                backgroundColor: _AppColors.lightRed,
                child: Icon(
                  icon,
                  color: _AppColors.red,
                  size: 22,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _AppColors.textDark,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _AppColors.textMuted,
                  fontSize: 12,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TaskSummarySection extends StatelessWidget {
  final DashboardViewModel viewModel;
  final VoidCallback onOpenTargetTap;

  const _TaskSummarySection({
    required this.viewModel,
    required this.onOpenTargetTap,
  });

  @override
  Widget build(BuildContext context) {
    final summary = viewModel.taskSummary;

    return _SectionCard(
      title: 'Target dan Tugas',
      isLoading: viewModel.isLoadingTaskSummary,
      errorMessage: viewModel.taskSummaryErrorMessage,
      onRetry: () => context.read<DashboardViewModel>().loadTaskSummary(),
      child: summary == null
          ? const _EmptyState(message: 'Belum ada rangkuman tugas.')
          : Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _MiniSummaryCard(
                        label: 'Selesai',
                        value: summary.taskCompleted.toString(),
                        icon: Icons.check_circle_rounded,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _MiniSummaryCard(
                        label: 'Todo',
                        value: summary.todo.toString(),
                        icon: Icons.radio_button_unchecked_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _MiniSummaryCard(
                        label: 'On Progress',
                        value: summary.onProgress.toString(),
                        icon: Icons.timelapse_rounded,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _MiniSummaryCard(
                        label: 'High Priority',
                        value: summary.highPriority.toString(),
                        icon: Icons.priority_high_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _SecondaryButton(
                  label: 'Buka Target dan Tugas',
                  icon: Icons.arrow_forward_rounded,
                  onTap: onOpenTargetTap,
                ),
              ],
            ),
    );
  }
}

class _MiniSummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _MiniSummaryCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _AppColors.lightRed,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            icon,
            color: _AppColors.red,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  value,
                  style: const TextStyle(
                    color: _AppColors.textDark,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _AppColors.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestSection extends StatelessWidget {
  final DashboardViewModel viewModel;
  final VoidCallback onOpenQuestTap;

  const _QuestSection({
    required this.viewModel,
    required this.onOpenQuestTap,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Quest',
      isLoading: viewModel.isLoadingQuests,
      errorMessage: viewModel.questsErrorMessage,
      onRetry: () => context.read<DashboardViewModel>().loadQuests(
            frequency: viewModel.selectedQuestFrequency,
          ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              ChoiceChip(
                label: const Text('Harian'),
                selected: viewModel.selectedQuestFrequency == 'harian',
                selectedColor: _AppColors.red,
                labelStyle: TextStyle(
                  color: viewModel.selectedQuestFrequency == 'harian'
                      ? Colors.white
                      : _AppColors.textDark,
                  fontWeight: FontWeight.w700,
                ),
                onSelected: (_) => context
                    .read<DashboardViewModel>()
                    .changeQuestFrequency('harian'),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Mingguan'),
                selected: viewModel.selectedQuestFrequency == 'mingguan',
                selectedColor: _AppColors.red,
                labelStyle: TextStyle(
                  color: viewModel.selectedQuestFrequency == 'mingguan'
                      ? Colors.white
                      : _AppColors.textDark,
                  fontWeight: FontWeight.w700,
                ),
                onSelected: (_) => context
                    .read<DashboardViewModel>()
                    .changeQuestFrequency('mingguan'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (viewModel.quests.isEmpty)
            const _EmptyState(message: 'Belum ada quest.')
          else
            ...viewModel.quests.take(3).map(
                  (quest) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _QuestTile(quest: quest),
                  ),
                ),
          const SizedBox(height: 4),
          _SecondaryButton(
            label: 'Lihat Semua Quest',
            icon: Icons.arrow_forward_rounded,
            onTap: onOpenQuestTap,
          ),
        ],
      ),
    );
  }
}

class _QuestTile extends StatelessWidget {
  final QuestModel quest;

  const _QuestTile({
    required this.quest,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (quest.progressPercentage / 100).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _AppColors.softGrey,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  quest.title,
                  style: const TextStyle(
                    color: _AppColors.textDark,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
              _StatusPill(
                text: quest.isCompleted ? 'Selesai' : 'Belum',
                isCompleted: quest.isCompleted,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            quest.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _AppColors.textMuted,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              backgroundColor: _AppColors.lightRed,
              valueColor: const AlwaysStoppedAnimation<Color>(_AppColors.red),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              Text(
                '${quest.progressPercentage}%',
                style: const TextStyle(
                  color: _AppColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                '+${quest.xpReward} XP',
                style: const TextStyle(
                  color: _AppColors.red,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                quest.difficulty,
                style: const TextStyle(
                  color: _AppColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AchievementSection extends StatelessWidget {
  final DashboardViewModel viewModel;
  final VoidCallback onOpenAchievementTap;

  const _AchievementSection({
    required this.viewModel,
    required this.onOpenAchievementTap,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Achievement',
      isLoading: viewModel.isLoadingAchievements,
      errorMessage: viewModel.achievementsErrorMessage,
      onRetry: () => context.read<DashboardViewModel>().loadAchievements(),
      child: Column(
        children: <Widget>[
          if (viewModel.achievements.isEmpty)
            const _EmptyState(message: 'Belum ada achievement.')
          else
            ...viewModel.achievements.take(3).map(
                  (achievement) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _AchievementTile(achievement: achievement),
                  ),
                ),
          const SizedBox(height: 4),
          _SecondaryButton(
            label: 'Lihat Semua Achievement',
            icon: Icons.arrow_forward_rounded,
            onTap: onOpenAchievementTap,
          ),
        ],
      ),
    );
  }
}

class _AchievementTile extends StatelessWidget {
  final AchievementModel achievement;

  const _AchievementTile({
    required this.achievement,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (achievement.progressPercentage / 100).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _AppColors.softGrey,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: <Widget>[
          CircleAvatar(
            radius: 22,
            backgroundColor: achievement.isCompleted
                ? _AppColors.success.withOpacity(0.12)
                : _AppColors.lightRed,
            child: Icon(
              achievement.isCompleted
                  ? Icons.verified_rounded
                  : Icons.workspace_premium_rounded,
              color:
                  achievement.isCompleted ? _AppColors.success : _AppColors.red,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  achievement.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _AppColors.textDark,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: _AppColors.lightRed,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(_AppColors.red),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${achievement.progressPercentage}% • +${achievement.xpReward} XP',
                  style: const TextStyle(
                    color: _AppColors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LeaderboardSection extends StatelessWidget {
  final DashboardViewModel viewModel;
  final VoidCallback onOpenLeaderboardTap;

  const _LeaderboardSection({
    required this.viewModel,
    required this.onOpenLeaderboardTap,
  });

  @override
  Widget build(BuildContext context) {
    final data = viewModel.leaderboard;

    return _SectionCard(
      title: 'Leaderboard',
      isLoading: viewModel.isLoadingLeaderboard,
      errorMessage: viewModel.leaderboardErrorMessage,
      onRetry: () => context.read<DashboardViewModel>().loadLeaderboard(),
      child: data == null
          ? const _EmptyState(message: 'Belum ada data leaderboard.')
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _AppColors.lightRed,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          data.userRank <= 0
                              ? 'Peringkat Anda belum tersedia'
                              : 'Peringkat Anda #${data.userRank}',
                          style: const TextStyle(
                            color: _AppColors.textDark,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Text(
                        '${_formatNumber(data.userTotalXp)} XP',
                        style: const TextStyle(
                          color: _AppColors.red,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (data.topGlobal.isEmpty)
                  const _EmptyState(message: 'Belum ada ranking global.')
                else
                  ...data.topGlobal.take(3).map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _LeaderboardTile(item: item),
                        ),
                      ),
                const SizedBox(height: 4),
                _SecondaryButton(
                  label: 'Lihat Leaderboard',
                  icon: Icons.arrow_forward_rounded,
                  onTap: onOpenLeaderboardTap,
                ),
              ],
            ),
    );
  }
}

class _LeaderboardTile extends StatelessWidget {
  final LeaderboardItemModel item;

  const _LeaderboardTile({
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final name = item.user.fullName.trim().isNotEmpty
        ? item.user.fullName
        : item.user.username;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _AppColors.softGrey,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: <Widget>[
          CircleAvatar(
            radius: 18,
            backgroundColor: _AppColors.red,
            child: Text(
              '#${item.rank}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name.isEmpty ? 'Mahasiswa' : name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _AppColors.textDark,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(
            '${_formatNumber(item.xp)} XP',
            style: const TextStyle(
              color: _AppColors.red,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentActivitySection extends StatelessWidget {
  final DashboardViewModel viewModel;

  const _RecentActivitySection({
    required this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    final completedAchievements = viewModel.achievements
        .where((item) => item.isCompleted && item.completionDate != null)
        .toList()
      ..sort(
        (a, b) => b.completionDate!.compareTo(a.completionDate!),
      );

    return _SectionCard(
      title: 'Aktivitas Terbaru',
      isLoading: false,
      errorMessage: null,
      child: completedAchievements.isEmpty
          ? const _EmptyState(message: 'Belum ada aktivitas terbaru.')
          : Column(
              children: completedAchievements.take(3).map((achievement) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _AppColors.softGrey,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: <Widget>[
                        const CircleAvatar(
                          backgroundColor: _AppColors.lightRed,
                          child: Icon(
                            Icons.history_rounded,
                            color: _AppColors.red,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                'Menyelesaikan achievement ${achievement.title}',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: _AppColors.textDark,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatDate(achievement.completionDate!),
                                style: const TextStyle(
                                  color: _AppColors.textMuted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '+${achievement.xpReward} XP',
                          style: const TextStyle(
                            color: _AppColors.red,
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.isLoading,
    required this.errorMessage,
    required this.child,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _whiteCardDecoration(),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: const TextStyle(
              color: _AppColors.textDark,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          if (isLoading)
            const _SectionLoading()
          else if (errorMessage != null)
            _SectionError(
              message: errorMessage!,
              onRetry: onRetry,
            )
          else
            child,
        ],
      ),
    );
  }
}

class _SectionLoading extends StatelessWidget {
  const _SectionLoading();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: const LinearProgressIndicator(
            minHeight: 7,
            backgroundColor: _AppColors.lightRed,
            valueColor: AlwaysStoppedAnimation<Color>(_AppColors.red),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Memuat data...',
          style: TextStyle(
            color: _AppColors.textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _SectionError extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const _SectionError({
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Text(
          message,
          style: const TextStyle(
            color: _AppColors.textMuted,
            fontSize: 13,
          ),
        ),
        if (onRetry != null) ...<Widget>[
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: onRetry,
            style: OutlinedButton.styleFrom(
              foregroundColor: _AppColors.red,
              side: const BorderSide(color: _AppColors.red),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text('Coba Lagi'),
          ),
        ],
      ],
    );
  }
}

class _FullPageError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _FullPageError({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 120),
      padding: const EdgeInsets.all(22),
      decoration: _whiteCardDecoration(),
      child: Column(
        children: <Widget>[
          const Icon(
            Icons.error_outline_rounded,
            color: _AppColors.red,
            size: 44,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _AppColors.textDark,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          _PrimaryButton(
            label: 'Muat Ulang',
            icon: Icons.refresh_rounded,
            onTap: onRetry,
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;

  const _EmptyState({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _AppColors.softGrey,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: _AppColors.textMuted,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String text;
  final bool isCompleted;

  const _StatusPill({
    required this.text,
    required this.isCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: isCompleted
            ? _AppColors.success.withOpacity(0.12)
            : _AppColors.warning.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: isCompleted ? _AppColors.success : _AppColors.warning,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _PrimaryButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: _AppColors.red,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 13,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _SecondaryButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: _AppColors.red,
        side: const BorderSide(color: _AppColors.borderRed),
        backgroundColor: _AppColors.lightRed,
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 13,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _WhiteSectionTitle extends StatelessWidget {
  final String title;

  const _WhiteSectionTitle({
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _DashboardBottomNavigationBar extends StatelessWidget {
  final ValueChanged<int> onItemSelected;

  const _DashboardBottomNavigationBar({
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _AppColors.darkRed,
      child: SafeArea(
        top: false,
        child: Container(
          height: 68,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: <Widget>[
              _NavItem(
                icon: Icons.home_rounded,
                label: 'Home',
                isActive: true,
                onTap: () => onItemSelected(0),
              ),
              _NavItem(
                icon: Icons.forum_rounded,
                label: 'Forum',
                onTap: () => onItemSelected(1),
              ),
              _NavItem(
                icon: Icons.quiz_rounded,
                label: 'Quiz',
                onTap: () => onItemSelected(2),
              ),
              _NavItem(
                icon: Icons.leaderboard_rounded,
                label: 'Rank',
                onTap: () => onItemSelected(3),
              ),
              _NavItem(
                icon: Icons.settings_rounded,
                label: 'Settings',
                onTap: () => onItemSelected(4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color:
                isActive ? Colors.white.withOpacity(0.18) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                icon,
                color: Colors.white,
                size: 22,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: isActive ? FontWeight.w900 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppColors {
  _AppColors._();

  static const Color red = Color(0xFFE53935);
  static const Color darkRed = Color(0xFFB71C1C);
  static const Color lightRed = Color(0xFFFFEBEE);
  static const Color borderRed = Color(0xFFFFCDD2);
  static const Color textDark = Color(0xFF1F2937);
  static const Color textMuted = Color(0xFF6B7280);
  static const Color softGrey = Color(0xFFF9FAFB);
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFF59E0B);
}

BoxDecoration _whiteCardDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(24),
    boxShadow: <BoxShadow>[
      BoxShadow(
        color: Colors.black.withOpacity(0.08),
        blurRadius: 18,
        offset: const Offset(0, 8),
      ),
    ],
  );
}

String _getDisplayName(dynamic profile) {
  final fullName = profile?.fullName?.toString().trim();
  if (fullName != null && fullName.isNotEmpty) return fullName;

  final username = profile?.username?.toString().trim();
  if (username != null && username.isNotEmpty) return username;

  return 'Mahasiswa';
}

String _formatNumber(int value) {
  final text = value.toString();
  final buffer = StringBuffer();

  for (int i = 0; i < text.length; i++) {
    final positionFromEnd = text.length - i;

    buffer.write(text[i]);

    if (positionFromEnd > 1 && positionFromEnd % 3 == 1) {
      buffer.write('.');
    }
  }

  return buffer.toString();
}

String _formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  final year = date.year.toString();

  return '$day/$month/$year';
}
