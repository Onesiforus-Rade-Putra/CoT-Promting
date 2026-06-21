import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/task_model.dart';
import '../models/task_progress.dart';
import '../models/task_summary_model.dart';
import '../viewmodels/progress_tracking_view_model.dart';
import 'add_task_page.dart';

class TargetTaskPage extends StatefulWidget {
  const TargetTaskPage({super.key});

  @override
  State<TargetTaskPage> createState() => _TargetTaskPageState();
}

class _TargetTaskPageState extends State<TargetTaskPage> {
  static const Color _primaryRed = Color(0xFFE21D2E);
  static const Color _darkRed = Color(0xFF9F0D1B);

  ProgressTrackingViewModel? _viewModel;
  bool _initialized = false;
  bool _isNavigatingToLogin = false;

  static const Map<String?, String> _categoryFilters = {
    null: 'Semua',
    'akademik': 'Akademik',
    'pribadi': 'Pribadi',
    'organisasi': 'Organisasi',
  };

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final nextViewModel = context.read<ProgressTrackingViewModel>();
    if (!identical(_viewModel, nextViewModel)) {
      _viewModel?.removeListener(_handleViewModelState);
      _viewModel = nextViewModel;
      _viewModel?.addListener(_handleViewModelState);
    }

    if (!_initialized) {
      _initialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _viewModel?.initialize();
      });
    }
  }

  @override
  void dispose() {
    _viewModel?.removeListener(_handleViewModelState);
    super.dispose();
  }

  void _handleViewModelState() {
    final viewModel = _viewModel;
    if (!mounted || viewModel == null || _isNavigatingToLogin) return;

    if (viewModel.consumeSessionExpired()) {
      _isNavigatingToLogin = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
      });
    }
  }

  Future<void> _openAddTask() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const AddTaskPage()),
    );

    if (!mounted || created != true) return;
    _showMessage('Tugas berhasil ditambahkan.');
  }

  Future<void> _changeFilter(String? category) async {
    final viewModel = context.read<ProgressTrackingViewModel>();
    await viewModel.changeCategoryFilter(category);

    if (!mounted || viewModel.isSessionExpired) return;
    if (viewModel.errorMessage != null) {
      _showMessage(viewModel.errorMessage!, isError: true);
    }
  }

  Future<void> _refresh() async {
    final viewModel = context.read<ProgressTrackingViewModel>();
    await viewModel.refreshData();

    if (!mounted || viewModel.isSessionExpired) return;
    if (viewModel.errorMessage != null) {
      _showMessage(viewModel.errorMessage!, isError: true);
    }
  }

  Future<void> _toggleTask(TaskModel task, bool isCompleted) async {
    final progress = isCompleted ? TaskProgress.completed : TaskProgress.todo;
    await _updateProgress(task, progress);
  }

  Future<void> _openProgressEditor(TaskModel task) async {
    final selectedProgress = await showModalBottomSheet<TaskProgress>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ubah progress tugas',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                task.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 12),
              ...TaskProgress.values.map(
                (progress) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(_progressIcon(progress), color: _primaryRed),
                  title: Text(progress.label),
                  trailing: task.isCompleted &&
                          progress == TaskProgress.completed
                      ? const Icon(Icons.check_circle, color: _primaryRed)
                      : null,
                  onTap: () => Navigator.of(sheetContext).pop(progress),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Nilai progress bersifat konfigurasi sementara dan harus '
                'disamakan dengan nilai yang diterima backend.',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        );
      },
    );

    if (selectedProgress == null || !mounted) return;
    await _updateProgress(task, selectedProgress);
  }

  Future<void> _updateProgress(
    TaskModel task,
    TaskProgress progress,
  ) async {
    final viewModel = context.read<ProgressTrackingViewModel>();
    final success = await viewModel.changeTaskProgress(
      task.id,
      progress.apiValue,
    );

    if (!mounted || viewModel.isSessionExpired) return;

    if (success) {
      _showMessage('Progress tugas berhasil diperbarui.');
    } else {
      _showMessage(
        viewModel.errorMessage ?? 'Progress tugas gagal diperbarui.',
        isError: true,
      );
    }
  }

  Future<void> _confirmDelete(TaskModel task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Hapus tugas?'),
          content: const Text(
            'Apakah Anda yakin ingin menghapus tugas ini?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Batal'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: _primaryRed),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Ya, Hapus'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    final viewModel = context.read<ProgressTrackingViewModel>();
    final success = await viewModel.removeTask(task.id);

    if (!mounted || viewModel.isSessionExpired) return;

    if (success) {
      _showMessage('Tugas berhasil dihapus.');
    } else {
      _showMessage(
        viewModel.errorMessage ?? 'Tugas gagal dihapus.',
        isError: true,
      );
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red.shade700 : null,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Target dan Tugas',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [_primaryRed, _darkRed],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddTask,
        backgroundColor: _primaryRed,
        foregroundColor: Colors.white,
        tooltip: 'Tambah tugas',
        child: const Icon(Icons.add_rounded),
      ),
      body: Consumer<ProgressTrackingViewModel>(
        builder: (context, viewModel, _) {
          return RefreshIndicator(
            onRefresh: _refresh,
            color: _primaryRed,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              children: [
                _ProgressHeader(
                  summary: viewModel.summary,
                  isLoading: viewModel.isLoadingSummary,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SummarySection(
                        summary: viewModel.summary,
                        isLoading: viewModel.isLoadingSummary,
                      ),
                      const SizedBox(height: 26),
                      const Text(
                        'Filter Kategori',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _categoryFilters.entries.map((entry) {
                            final selected =
                                viewModel.selectedCategory == entry.key;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                selected: selected,
                                label: Text(entry.value),
                                onSelected: viewModel.isLoadingTasks
                                    ? null
                                    : (_) => _changeFilter(entry.key),
                                selectedColor: _primaryRed.withOpacity(0.12),
                                side: BorderSide(
                                  color: selected
                                      ? _primaryRed
                                      : Colors.grey.shade300,
                                ),
                                labelStyle: TextStyle(
                                  color: selected
                                      ? _primaryRed
                                      : Colors.grey.shade700,
                                  fontWeight: selected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                                showCheckmark: false,
                              ),
                            );
                          }).toList(growable: false),
                        ),
                      ),
                      const SizedBox(height: 26),
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Daftar Tugas',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          if (viewModel.isLoadingTasks &&
                              viewModel.tasks.isNotEmpty)
                            const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: _primaryRed,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _buildTaskContent(viewModel),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTaskContent(ProgressTrackingViewModel viewModel) {
    if (viewModel.isLoadingTasks && viewModel.tasks.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 56),
        child: Center(
          child: CircularProgressIndicator(color: _primaryRed),
        ),
      );
    }

    if (viewModel.tasks.isEmpty && viewModel.errorMessage != null) {
      return _ErrorState(
        message: viewModel.errorMessage!,
        onRetry: _refresh,
      );
    }

    if (viewModel.tasks.isEmpty) {
      return _EmptyState(onAdd: _openAddTask);
    }

    return Column(
      children: viewModel.tasks
          .map(
            (task) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _TaskCard(
                task: task,
                isUpdating: viewModel.isTaskUpdating(task.id),
                isDeleting: viewModel.isTaskDeleting(task.id),
                onChanged: (value) => _toggleTask(task, value),
                onEdit: () => _openProgressEditor(task),
                onDelete: () => _confirmDelete(task),
              ),
            ),
          )
          .toList(growable: false),
    );
  }

  static IconData _progressIcon(TaskProgress progress) {
    switch (progress) {
      case TaskProgress.todo:
        return Icons.radio_button_unchecked_rounded;
      case TaskProgress.onProgress:
        return Icons.timelapse_rounded;
      case TaskProgress.completed:
        return Icons.check_circle_outline_rounded;
    }
  }
}

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({required this.summary, required this.isLoading});

  final TaskSummaryModel? summary;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final completed = summary?.taskCompleted ?? 0;
    final total = summary?.totalTasks ?? 0;
    final progress = summary?.completionProgress ?? 0;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _TargetTaskPageState._primaryRed,
            _TargetTaskPageState._darkRed,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 26),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withOpacity(0.18)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Progress Belajarmu',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$completed dari $total tugas selesai',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                minHeight: 10,
                value: isLoading && summary == null ? null : progress,
                backgroundColor: Colors.white.withOpacity(0.25),
                valueColor: const AlwaysStoppedAnimation(Colors.white),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _motivation(progress, total),
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _motivation(double progress, int total) {
    if (total == 0) return 'Tambahkan target pertamamu dan mulai berkembang!';
    if (progress >= 1) return 'Hebat! Semua tugas sudah kamu selesaikan.';
    if (progress >= 0.75) return 'Sedikit lagi, pertahankan ritmemu!';
    if (progress >= 0.4) return 'Progress yang bagus. Terus lanjutkan!';
    return 'Mulai dari satu tugas kecil hari ini.';
  }
}

class _SummarySection extends StatelessWidget {
  const _SummarySection({required this.summary, required this.isLoading});

  final TaskSummaryModel? summary;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final items = [
      _SummaryItem(
        title: 'Tugas Selesai',
        value: summary?.taskCompleted ?? 0,
        icon: Icons.task_alt_rounded,
        color: Colors.green,
      ),
      _SummaryItem(
        title: 'Belum Dikerjakan',
        value: summary?.todo ?? 0,
        icon: Icons.pending_actions_rounded,
        color: Colors.orange,
      ),
      _SummaryItem(
        title: 'Sedang Berjalan',
        value: summary?.onProgress ?? 0,
        icon: Icons.timelapse_rounded,
        color: Colors.blue,
      ),
      _SummaryItem(
        title: 'Prioritas Tinggi',
        value: summary?.highPriority ?? 0,
        icon: Icons.priority_high_rounded,
        color: _TargetTaskPageState._primaryRed,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ringkasan Tugas',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 14),
        if (isLoading && summary == null)
          const LinearProgressIndicator(
            color: _TargetTaskPageState._primaryRed,
          ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.45,
          ),
          itemBuilder: (context, index) {
            final item = items[index];
            return Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0B000000),
                    blurRadius: 12,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: item.color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(item.icon, color: item.color, size: 21),
                  ),
                  Text(
                    '${item.value}',
                    style: const TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _SummaryItem {
  const _SummaryItem({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final int value;
  final IconData icon;
  final Color color;
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.task,
    required this.isUpdating,
    required this.isDeleting,
    required this.onChanged,
    required this.onEdit,
    required this.onDelete,
  });

  final TaskModel task;
  final bool isUpdating;
  final bool isDeleting;
  final ValueChanged<bool> onChanged;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  bool get _isBusy => isUpdating || isDeleting;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: isDeleting ? 0.55 : 1,
      duration: const Duration(milliseconds: 180),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0B000000),
              blurRadius: 14,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 42,
              height: 42,
              child: isUpdating
                  ? const Padding(
                      padding: EdgeInsets.all(10),
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: _TargetTaskPageState._primaryRed,
                      ),
                    )
                  : Checkbox(
                      value: task.isCompleted,
                      activeColor: _TargetTaskPageState._primaryRed,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                      onChanged: _isBusy
                          ? null
                          : (value) => onChanged(value ?? false),
                    ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          task.title,
                          style: TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w800,
                            decoration: task.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                            color: task.isCompleted
                                ? Colors.grey.shade500
                                : Colors.black87,
                          ),
                        ),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        tooltip: 'Ubah progress',
                        onPressed: _isBusy ? null : onEdit,
                        icon: const Icon(Icons.edit_outlined, size: 21),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        tooltip: 'Hapus tugas',
                        onPressed: _isBusy ? null : onDelete,
                        icon: Icon(
                          Icons.delete_outline_rounded,
                          size: 21,
                          color: Colors.red.shade600,
                        ),
                      ),
                    ],
                  ),
                  if (task.description != null) ...[
                    const SizedBox(height: 5),
                    Text(
                      task.description!,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        height: 1.35,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _InfoBadge(
                        icon: Icons.category_outlined,
                        label: _capitalize(task.category),
                        foregroundColor: Colors.indigo.shade700,
                        backgroundColor: Colors.indigo.withOpacity(0.08),
                      ),
                      _InfoBadge(
                        icon: Icons.event_outlined,
                        label: _formatDateTime(task.deadline),
                        foregroundColor: Colors.grey.shade700,
                        backgroundColor: Colors.grey.withOpacity(0.10),
                      ),
                      _InfoBadge(
                        icon: Icons.flag_outlined,
                        label: 'Prioritas ${_capitalize(task.priority)}',
                        foregroundColor: _priorityColor(task.priority),
                        backgroundColor:
                            _priorityColor(task.priority).withOpacity(0.10),
                      ),
                      _InfoBadge(
                        icon: task.isCompleted
                            ? Icons.check_circle_outline
                            : Icons.pending_outlined,
                        label: task.isCompleted ? 'Selesai' : 'Belum selesai',
                        foregroundColor: task.isCompleted
                            ? Colors.green.shade700
                            : Colors.orange.shade800,
                        backgroundColor: (task.isCompleted
                                ? Colors.green
                                : Colors.orange)
                            .withOpacity(0.10),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Color _priorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'tinggi':
        return Colors.red.shade700;
      case 'sedang':
        return Colors.orange.shade800;
      case 'rendah':
        return Colors.green.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  static String _capitalize(String value) {
    if (value.isEmpty) return '-';
    return '${value[0].toUpperCase()}${value.substring(1)}';
  }

  static String _formatDateTime(DateTime value) {
    final local = value.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day/$month/${local.year} $hour:$minute';
  }
}

class _InfoBadge extends StatelessWidget {
  const _InfoBadge({
    required this.icon,
    required this.label,
    required this.foregroundColor,
    required this.backgroundColor,
  });

  final IconData icon;
  final String label;
  final Color foregroundColor;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: foregroundColor),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: foregroundColor,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 46),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9FA),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: _TargetTaskPageState._primaryRed.withOpacity(0.10),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.assignment_add,
              size: 34,
              color: _TargetTaskPageState._primaryRed,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Belum ada tugas. Tambahkan target pertamamu.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Tambah Tugas'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _TargetTaskPageState._primaryRed,
              side: const BorderSide(
                color: _TargetTaskPageState._primaryRed,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red.withOpacity(0.20)),
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline_rounded, color: Colors.red.shade700),
          const SizedBox(height: 10),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 14),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }
}
