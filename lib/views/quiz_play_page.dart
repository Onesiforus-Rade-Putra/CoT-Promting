import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/answer_option_model.dart';
import '../models/quiz_question_model.dart';
import '../models/quiz_result_model.dart';
import '../viewmodels/quiz_view_model.dart';
import 'quiz_result_page.dart';
import 'widgets/quiz_common_widgets.dart';

class QuizPlayPage extends StatefulWidget {
  const QuizPlayPage({
    super.key,
    required this.quizId,
    required this.quizTitle,
  });

  final int quizId;
  final String quizTitle;

  @override
  State<QuizPlayPage> createState() => _QuizPlayPageState();
}

class _QuizPlayPageState extends State<QuizPlayPage> {
  QuizViewModel? _viewModel;
  bool _navigatingToResult = false;
  bool _redirectingToLogin = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newViewModel = context.read<QuizViewModel>();
    if (_viewModel != newViewModel) {
      _viewModel?.removeListener(_onViewModelChanged);
      _viewModel = newViewModel;
      _viewModel!.addListener(_onViewModelChanged);
    }
  }

  @override
  void dispose() {
    _viewModel?.removeListener(_onViewModelChanged);
    super.dispose();
  }

  void _onViewModelChanged() {
    if (!mounted) return;
    final viewModel = _viewModel!;

    if (!_redirectingToLogin && viewModel.consumeSessionExpired()) {
      _redirectingToLogin = true;
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
      return;
    }

    final result = viewModel.quizResult;
    if (result != null && !_navigatingToResult) {
      _navigatingToResult = true;
      final capturedResult = result;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        viewModel.clearActiveQuiz();
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => QuizResultPage(
              quizId: widget.quizId,
              quizTitle: widget.quizTitle,
              result: capturedResult,
            ),
          ),
        );
      });
    }
  }

  Future<bool> _requestExit() async {
    final currentViewModel = context.read<QuizViewModel>();
    if (currentViewModel.isSubmittingQuiz) {
      _showMessage('Jawaban sedang dikirim. Mohon tunggu sampai selesai.');
      return false;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Keluar dari Quiz?'),
        content: const Text(
          'Apakah Anda yakin ingin keluar? '
          'Jawaban quiz yang belum dikirim dapat hilang.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: quizRed),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return false;

    final viewModel = context.read<QuizViewModel>();
    final success = await viewModel.exitQuiz(widget.quizId);
    if (!mounted) return false;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quiz dibatalkan.')),
      );
      Navigator.of(context).pop();
    } else if (viewModel.errorMessage != null) {
      _showMessage(viewModel.errorMessage!);
    }

    return false;
  }

  Future<void> _goToQuestion(int number) async {
    await context.read<QuizViewModel>().loadQuestion(
          widget.quizId,
          number,
        );
  }

  Future<void> _confirmSubmit() async {
    final viewModel = context.read<QuizViewModel>();
    final unanswered = viewModel.totalQuestions - viewModel.answeredCount;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          unanswered > 0 ? 'Masih ada soal kosong' : 'Selesaikan Quiz',
        ),
        content: Text(
          unanswered > 0
              ? 'Ada $unanswered soal belum dijawab. '
                  'Kirim jawaban quiz sekarang?'
              : 'Kirim jawaban quiz sekarang?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Periksa Lagi'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Ya, Kirim'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    final success = await viewModel.submitQuiz(widget.quizId);
    if (!success && mounted && viewModel.errorMessage != null) {
      _showMessage(viewModel.errorMessage!);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _requestExit,
      child: Scaffold(
        backgroundColor: quizBackground,
        body: Consumer<QuizViewModel>(
          builder: (context, viewModel, _) {
            final question = viewModel.currentQuestion;

            return SafeArea(
              child: Column(
                children: [
                  _PlayHeader(
                    title: widget.quizTitle,
                    currentNumber: viewModel.currentQuestionNumber,
                    totalQuestions: viewModel.totalQuestions,
                    remainingTime: viewModel.remainingTime,
                    progress: viewModel.questionProgress,
                    onBack: _requestExit,
                  ),
                  Expanded(
                    child: Stack(
                      children: [
                        SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                          child: Column(
                            children: [
                              if (viewModel.timeExpired)
                                const _InfoBanner(
                                  icon: Icons.timer_off_rounded,
                                  message:
                                      'Waktu pengerjaan telah habis. '
                                      'Jawaban sedang dikirim otomatis.',
                                ),
                              if (viewModel.errorMessage != null)
                                _QuestionErrorBanner(
                                  message: viewModel.errorMessage!,
                                  onRetry: () {
                                    if (viewModel.timeExpired) {
                                      viewModel.submitQuiz(widget.quizId);
                                      return;
                                    }
                                    _goToQuestion(
                                      viewModel.failedQuestionNumber ??
                                          viewModel.currentQuestionNumber,
                                    );
                                  },
                                ),
                              if (question != null)
                                _QuestionCard(
                                  question: question,
                                  selectedAnswer:
                                      viewModel.getSelectedAnswer(question.id),
                                  enabled: viewModel.canSelectAnswer,
                                  onSelected: (answer) {
                                    viewModel.selectAnswer(
                                      question.id,
                                      answer,
                                    );
                                  },
                                )
                              else if (!viewModel.isLoadingQuestion)
                                const _InfoBanner(
                                  icon: Icons.info_outline_rounded,
                                  message: 'Soal tidak tersedia.',
                                ),
                            ],
                          ),
                        ),
                        if (viewModel.isLoadingQuestion)
                          const Positioned.fill(
                            child: ColoredBox(
                              color: Color(0x66FFFFFF),
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: quizRed,
                                ),
                              ),
                            ),
                          ),
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: _BottomNavigation(
                            canGoPrevious:
                                viewModel.currentQuestionNumber > 1 &&
                                !viewModel.isLoadingQuestion &&
                                !viewModel.isSubmittingQuiz,
                            isLastQuestion: viewModel.isLastQuestion,
                            loading: viewModel.isSubmittingQuiz,
                            timeExpired: viewModel.timeExpired,
                            onPrevious: () => _goToQuestion(
                              viewModel.currentQuestionNumber - 1,
                            ),
                            onNext: () => _goToQuestion(
                              viewModel.currentQuestionNumber + 1,
                            ),
                            onSubmit: _confirmSubmit,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PlayHeader extends StatelessWidget {
  const _PlayHeader({
    required this.title,
    required this.currentNumber,
    required this.totalQuestions,
    required this.remainingTime,
    required this.progress,
    required this.onBack,
  });

  final String title;
  final int currentNumber;
  final int totalQuestions;
  final Duration remainingTime;
  final double progress;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final minutes = remainingTime.inMinutes.remainder(60);
    final seconds = remainingTime.inSeconds.remainder(60);
    final hours = remainingTime.inHours;
    final timerText = hours > 0
        ? '${hours.toString().padLeft(2, '0')}:'
            '${minutes.toString().padLeft(2, '0')}:'
            '${seconds.toString().padLeft(2, '0')}'
        : '${minutes.toString().padLeft(2, '0')}:'
            '${seconds.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 20, 18),
      color: Colors.white,
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Soal',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: quizSoftRed,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.timer_outlined,
                      color: quizRed,
                      size: 19,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      timerText,
                      style: const TextStyle(
                        color: quizRed,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Text(
                'Soal $currentNumber dari $totalQuestions',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              Text(
                '$currentNumber/$totalQuestions',
                style: const TextStyle(
                  color: quizRed,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              backgroundColor: quizSoftRed,
              valueColor: const AlwaysStoppedAnimation<Color>(quizRed),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    required this.question,
    required this.selectedAnswer,
    required this.enabled,
    required this.onSelected,
  });

  final QuizQuestionModel question;
  final String? selectedAnswer;
  final bool enabled;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: quizRed.withOpacity(0.35)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 16,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pilih Jawaban',
            style: TextStyle(
              color: quizRed,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            question.text,
            style: const TextStyle(
              fontSize: 20,
              height: 1.45,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 22),
          ...question.options.map(
            (option) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _AnswerOption(
                option: option,
                selected: selectedAnswer == option.value,
                enabled: enabled,
                onTap: () => onSelected(option.value),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnswerOption extends StatelessWidget {
  const _AnswerOption({
    required this.option,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final AnswerOptionModel option;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? quizSoftRed : Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? quizRed : const Color(0xFFE2E2E7),
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? quizRed : const Color(0xFFF4F4F6),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  option.label,
                  style: TextStyle(
                    color: selected ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Text(
                  option.text,
                  style: TextStyle(
                    height: 1.35,
                    fontWeight:
                        selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
              if (selected)
                const Icon(Icons.check_circle_rounded, color: quizRed),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomNavigation extends StatelessWidget {
  const _BottomNavigation({
    required this.canGoPrevious,
    required this.isLastQuestion,
    required this.loading,
    required this.timeExpired,
    required this.onPrevious,
    required this.onNext,
    required this.onSubmit,
  });

  final bool canGoPrevious;
  final bool isLastQuestion;
  final bool loading;
  final bool timeExpired;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x16000000),
            blurRadius: 16,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: canGoPrevious ? onPrevious : null,
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('Sebelumnya'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: PrimaryQuizButton(
                label: isLastQuestion ? 'Selesai' : 'Selanjutnya',
                loading: loading,
                icon: isLastQuestion
                    ? Icons.check_rounded
                    : Icons.arrow_forward_rounded,
                onPressed: timeExpired
                    ? null
                    : isLastQuestion
                        ? onSubmit
                        : onNext,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({
    required this.icon,
    required this.message,
  });

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4DA),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF8B6200)),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}

class _QuestionErrorBanner extends StatelessWidget {
  const _QuestionErrorBanner({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: quizSoftRed,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: quizRed),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
          TextButton(
            onPressed: onRetry,
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }
}
