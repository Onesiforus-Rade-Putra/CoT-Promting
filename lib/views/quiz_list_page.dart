import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/quiz_model.dart';
import '../viewmodels/quiz_view_model.dart';
import 'quiz_play_page.dart';
import 'widgets/quiz_common_widgets.dart';

class QuizListPage extends StatefulWidget {
  const QuizListPage({super.key});

  @override
  State<QuizListPage> createState() => _QuizListPageState();
}

class _QuizListPageState extends State<QuizListPage> {
  int _selectedTab = 0;
  bool _redirectingToLogin = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadData);
  }

  Future<void> _loadData() async {
    final viewModel = context.read<QuizViewModel>();
    await viewModel.loadQuizzes();
    if (!mounted) return;
    _handleSessionExpired(viewModel);
  }

  void _handleSessionExpired(QuizViewModel viewModel) {
    if (_redirectingToLogin || !viewModel.consumeSessionExpired()) return;
    _redirectingToLogin = true;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
  }

  Future<void> _startQuiz(QuizModel quiz) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Mulai Quiz'),
        content: const Text(
          'Apakah Anda siap memulai quiz? '
          'Waktu akan berjalan setelah quiz dimulai.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Mulai'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final viewModel = context.read<QuizViewModel>();
    final success = await viewModel.startQuiz(quiz.id);
    if (!mounted) return;

    _handleSessionExpired(viewModel);
    if (!success || _redirectingToLogin) {
      _showError(viewModel.errorMessage);
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => QuizPlayPage(
          quizId: quiz.id,
          quizTitle: quiz.title,
        ),
      ),
    );

    if (mounted) {
      await context.read<QuizViewModel>().loadQuizzes();
    }
  }

  void _showError(String? message) {
    if (message == null || message.isEmpty) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: quizBackground,
      body: Consumer<QuizViewModel>(
        builder: (context, viewModel, _) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _handleSessionExpired(viewModel);
          });

          return Column(
            children: [
              _Header(viewModel: viewModel),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _loadData,
                  color: quizRed,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
                    children: [
                      _TabSelector(
                        selectedIndex: _selectedTab,
                        onChanged: (value) {
                          setState(() => _selectedTab = value);
                        },
                      ),
                      const SizedBox(height: 18),
                      if (_selectedTab == 0)
                        ..._buildQuizContent(viewModel)
                      else
                        const _QuestEmptyState(),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _buildQuizContent(QuizViewModel viewModel) {
    if (viewModel.isLoadingQuizList && viewModel.quizzes.isEmpty) {
      return const [
        SizedBox(height: 110),
        Center(child: CircularProgressIndicator(color: quizRed)),
      ];
    }

    if (viewModel.errorMessage != null && viewModel.quizzes.isEmpty) {
      return [
        _ErrorState(
          message: viewModel.errorMessage!,
          onRetry: _loadData,
        ),
      ];
    }

    if (viewModel.quizzes.isEmpty) {
      return const [
        _EmptyState(message: 'Belum ada quiz yang tersedia.'),
      ];
    }

    final recommendation = viewModel.quizzes.firstWhere(
      (quiz) => !quiz.lastAttemptSuccessfull,
      orElse: () => viewModel.quizzes.first,
    );

    return [
      _StreakCard(streak: viewModel.latestStreakCount),
      const SizedBox(height: 22),
      Text(
        'Rekomendasi Quiz',
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
      ),
      const SizedBox(height: 12),
      _RecommendedQuizCard(
        quiz: recommendation,
        isStarting:
            viewModel.isStartingQuiz &&
            viewModel.startingQuizId == recommendation.id,
        onStart: () => _startQuiz(recommendation),
      ),
      const SizedBox(height: 24),
      Text(
        'Semua Quiz',
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
      ),
      const SizedBox(height: 12),
      ...viewModel.quizzes.map(
        (quiz) => Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: _QuizCard(
            quiz: quiz,
            isStarting:
                viewModel.isStartingQuiz &&
                viewModel.startingQuizId == quiz.id,
            onStart: () => _startQuiz(quiz),
          ),
        ),
      ),
    ];
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.viewModel});

  final QuizViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return QuizGradientHeader(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.maybePop(context),
                icon: const Icon(Icons.arrow_back_rounded),
                color: Colors.white,
              ),
              const Expanded(
                child: Text(
                  'Quiz dan Quest',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.only(left: 12, right: 12, top: 4),
            child: Text(
              'Selesaikan tantangan untuk mendapatkan XP dan Sertifikat!',
              style: TextStyle(
                color: Colors.white70,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.white.withOpacity(0.22),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.track_changes_rounded,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Progress Quiz',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      '${viewModel.passedQuizCount}/${viewModel.quizzes.length} Quiz',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: viewModel.quizListProgress,
                    minHeight: 8,
                    backgroundColor: Colors.white24,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.white),
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

class _TabSelector extends StatelessWidget {
  const _TabSelector({
    required this.selectedIndex,
    required this.onChanged,
  });

  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _TabItem(
            label: 'Quiz',
            selected: selectedIndex == 0,
            onTap: () => onChanged(0),
          ),
          _TabItem(
            label: 'Quest',
            selected: selectedIndex == 1,
            onTap: () => onChanged(1),
          ),
        ],
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? quizRed : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? Colors.white : Colors.black54,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  const _StreakCard({required this.streak});

  final int streak;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF1E8), Color(0xFFFFE1D0)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.local_fire_department_rounded,
              color: Colors.deepOrange,
              size: 32,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Streak Kamu',
                  style: TextStyle(
                    color: Colors.black54,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '$streak hari',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const Text(
            'Teruskan!',
            style: TextStyle(
              color: Colors.deepOrange,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecommendedQuizCard extends StatelessWidget {
  const _RecommendedQuizCard({
    required this.quiz,
    required this.isStarting,
    required this.onStart,
  });

  final QuizModel quiz;
  final bool isStarting;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [quizRed, quizDarkRed],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: quizRed.withOpacity(0.22),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StatusPill(
            label: quiz.category,
            background: Colors.white.withOpacity(0.18),
            foreground: Colors.white,
          ),
          const SizedBox(height: 14),
          Text(
            quiz.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _WhiteMeta(
                icon: Icons.schedule_rounded,
                label: '${quiz.durationMinutes} menit',
              ),
              _WhiteMeta(
                icon: Icons.bolt_rounded,
                label: '+${quiz.xpReward} XP',
              ),
              _WhiteMeta(
                icon: Icons.signal_cellular_alt_rounded,
                label: _difficultyLabel(quiz.difficulty),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: isStarting ? null : onStart,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: quizRed,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: isStarting
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      'Mulai Quiz',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuizCard extends StatelessWidget {
  const _QuizCard({
    required this.quiz,
    required this.isStarting,
    required this.onStart,
  });

  final QuizModel quiz;
  final bool isStarting;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final passed = quiz.lastAttemptSuccessfull;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEEEEF2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  quiz.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              StatusPill(
                label: passed ? 'Lulus' : 'Belum lulus',
                background:
                    passed ? const Color(0xFFE6F7ED) : quizSoftRed,
                foreground:
                    passed ? const Color(0xFF168246) : quizRed,
                icon: passed
                    ? Icons.check_circle_rounded
                    : Icons.pending_rounded,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Kategori ${quiz.category} • Minimum skor ${quiz.minimumScore}',
            style: const TextStyle(color: Colors.black54, height: 1.4),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              StatusPill(
                label: '${quiz.durationMinutes} menit',
                background: const Color(0xFFF1F2F5),
                foreground: Colors.black87,
                icon: Icons.schedule_rounded,
              ),
              StatusPill(
                label: '+${quiz.xpReward} XP',
                background: const Color(0xFFFFF2D8),
                foreground: const Color(0xFF8B5B00),
                icon: Icons.bolt_rounded,
              ),
              StatusPill(
                label: _difficultyLabel(quiz.difficulty),
                background: quizSoftRed,
                foreground: quizRed,
              ),
              StatusPill(
                label: '${quiz.completionCount} selesai',
                background: const Color(0xFFEAF2FF),
                foreground: const Color(0xFF2459A9),
                icon: Icons.replay_rounded,
              ),
            ],
          ),
          if (passed && quiz.certificateId != null) ...[
            const SizedBox(height: 12),
            const Row(
              children: [
                Icon(
                  Icons.workspace_premium_rounded,
                  color: Color(0xFFE5A400),
                  size: 20,
                ),
                SizedBox(width: 7),
                Text(
                  'Sertifikat tersedia',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF8B6500),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: PrimaryQuizButton(
              label: passed ? 'Kerjakan Lagi' : 'Mulai Quiz',
              onPressed: onStart,
              loading: isStarting,
              icon: Icons.play_arrow_rounded,
            ),
          ),
        ],
      ),
    );
  }
}

class _WhiteMeta extends StatelessWidget {
  const _WhiteMeta({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white70, size: 18),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 70),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_rounded, size: 56, color: quizRed),
          const SizedBox(height: 14),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 80),
      child: Column(
        children: [
          const Icon(
            Icons.quiz_outlined,
            size: 58,
            color: Colors.black26,
          ),
          const SizedBox(height: 14),
          Text(message, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _QuestEmptyState extends StatelessWidget {
  const _QuestEmptyState();

  @override
  Widget build(BuildContext context) {
    return const _EmptyState(
      message:
          'Endpoint Quest belum tersedia pada dokumentasi API. '
          'Tab ini siap dihubungkan ketika service Quest tersedia.',
    );
  }
}

String _difficultyLabel(String value) {
  switch (value.toLowerCase()) {
    case 'easy':
      return 'Mudah';
    case 'medium':
      return 'Sedang';
    case 'hard':
      return 'Sulit';
    default:
      return value;
  }
}
