import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/quiz_result_model.dart';
import '../viewmodels/quiz_view_model.dart';
import 'quiz_play_page.dart';
import 'widgets/quiz_common_widgets.dart';

class QuizResultPage extends StatefulWidget {
  const QuizResultPage({
    super.key,
    required this.quizId,
    required this.quizTitle,
    required this.result,
  });

  final int quizId;
  final String quizTitle;
  final QuizResultModel result;

  @override
  State<QuizResultPage> createState() => _QuizResultPageState();
}

class _QuizResultPageState extends State<QuizResultPage> {
  late String? _certificateId;
  bool _redirectingToLogin = false;

  @override
  void initState() {
    super.initState();
    _certificateId = widget.result.certificateId;
  }

  Future<void> _generateCertificate() async {
    final viewModel = context.read<QuizViewModel>();
    final certificateId = await viewModel.generateCertificate(widget.quizId);
    if (!mounted) return;

    if (viewModel.consumeSessionExpired()) {
      _redirectingToLogin = true;
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
      return;
    }

    if (certificateId == null) {
      _showMessage(
        viewModel.errorMessage ?? 'Sertifikat gagal dibuat.',
      );
      return;
    }

    setState(() => _certificateId = certificateId);
    _showMessage('Sertifikat berhasil dibuat.');
  }

  Future<void> _retryQuiz() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Coba Lagi'),
        content: const Text(
          'Waktu quiz baru akan dimulai setelah Anda menekan Mulai.',
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
    final success = await viewModel.startQuiz(widget.quizId);
    if (!mounted) return;

    if (viewModel.consumeSessionExpired()) {
      _redirectingToLogin = true;
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
      return;
    }

    if (!success || _redirectingToLogin) {
      _showMessage(viewModel.errorMessage ?? 'Quiz gagal dimulai.');
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => QuizPlayPage(
          quizId: widget.quizId,
          quizTitle: widget.quizTitle,
        ),
      ),
    );
  }

  void _backToQuizList() {
    Navigator.of(context).pop();
  }

  Future<void> _showCertificateId() async {
    final id = _certificateId;
    if (id == null) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sertifikat Tersedia'),
        content: SelectableText(
          'Certificate ID:\n$id\n\n'
          'API saat ini belum memberikan URL atau file PDF.',
        ),
        actions: [
          TextButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: id));
              if (dialogContext.mounted) Navigator.pop(dialogContext);
              _showMessage('ID sertifikat disalin.');
            },
            icon: const Icon(Icons.copy_rounded),
            label: const Text('Salin ID'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.result;

    return Scaffold(
      backgroundColor: quizBackground,
      body: Consumer<QuizViewModel>(
        builder: (context, viewModel, _) {
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(26),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x14000000),
                          blurRadius: 24,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 92,
                          height: 92,
                          decoration: BoxDecoration(
                            color: result.passed
                                ? const Color(0xFFFFF2C7)
                                : quizSoftRed,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            result.passed
                                ? Icons.emoji_events_rounded
                                : Icons.replay_rounded,
                            size: 52,
                            color: result.passed
                                ? const Color(0xFFE2A500)
                                : quizRed,
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Quiz Selesai!',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          result.passed
                              ? 'Selamat, Anda lulus!'
                              : 'Anda belum lulus. Coba lagi.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: result.passed
                                ? const Color(0xFF168246)
                                : quizRed,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${result.correctAnswers} dari '
                          '${result.totalQuestions} jawaban benar',
                          style: const TextStyle(color: Colors.black54),
                        ),
                        const SizedBox(height: 24),
                        _ScorePanel(result: result),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Expanded(
                              child: _RewardCard(
                                icon: Icons.bolt_rounded,
                                label: 'Poin',
                                value: '+${result.pointsGained}',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _RewardCard(
                                icon: Icons.local_fire_department_rounded,
                                label: 'Streak',
                                value: '${result.streakCount} hari',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _RewardCard(
                          icon: Icons.auto_awesome_rounded,
                          label: 'Bonus Streak',
                          value: '+${result.streakBonus}',
                          fullWidth: true,
                        ),
                        const SizedBox(height: 24),
                        if (result.passed && _certificateId == null)
                          SizedBox(
                            width: double.infinity,
                            child: PrimaryQuizButton(
                              label: 'Generate Sertifikat',
                              icon: Icons.workspace_premium_rounded,
                              loading: viewModel.isGeneratingCertificate,
                              onPressed: _generateCertificate,
                            ),
                          ),
                        if (result.passed && _certificateId != null)
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _showCertificateId,
                              icon:
                                  const Icon(Icons.workspace_premium_rounded),
                              label: const Text('Sertifikat Tersedia'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: quizRed,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                side: const BorderSide(color: quizRed),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),
                        if (result.passed) const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: viewModel.isStartingQuiz
                                ? null
                                : _retryQuiz,
                            icon: viewModel.isStartingQuiz
                                ? const SizedBox.square(
                                    dimension: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.replay_rounded),
                            label: const Text('Coba Lagi'),
                            style: OutlinedButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: TextButton.icon(
                            onPressed: _backToQuizList,
                            icon: const Icon(Icons.arrow_back_rounded),
                            label: const Text('Kembali ke Quest'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ScorePanel extends StatelessWidget {
  const _ScorePanel({required this.result});

  final QuizResultModel result;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: quizSoftRed,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Text(
            '${result.scorePercentage.toStringAsFixed(0)}%',
            style: const TextStyle(
              color: quizRed,
              fontSize: 38,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Text(
            'Skor Tampilan',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Minimum score: ${result.minimumScore}',
            style: const TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

class _RewardCard extends StatelessWidget {
  const _RewardCard({
    required this.icon,
    required this.label,
    required this.value,
    this.fullWidth = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7FA),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Row(
        mainAxisAlignment:
            fullWidth ? MainAxisAlignment.start : MainAxisAlignment.center,
        children: [
          Icon(icon, color: quizRed),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: fullWidth
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.center,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 12,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
