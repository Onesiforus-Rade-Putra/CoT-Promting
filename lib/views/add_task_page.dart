import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/create_task_request_model.dart';
import '../viewmodels/progress_tracking_view_model.dart';

class AddTaskPage extends StatefulWidget {
  const AddTaskPage({super.key});

  @override
  State<AddTaskPage> createState() => _AddTaskPageState();
}

class _AddTaskPageState extends State<AddTaskPage> {
  static const Color _primaryRed = Color(0xFFE21D2E);
  static const Color _darkRed = Color(0xFF9F0D1B);

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  String? _selectedCategory;
  String? _selectedPriority;
  DateTime? _deadline;
  String? _deadlineError;

  static const Map<String, String> _categories = {
    'akademik': 'Akademik',
    'pribadi': 'Pribadi',
    'organisasi': 'Organisasi',
  };

  static const Map<String, String> _priorities = {
    'tinggi': 'Tinggi',
    'sedang': 'Sedang',
    'rendah': 'Rendah',
  };

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final initial = _deadline ?? now;

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: 'Pilih tanggal deadline',
    );

    if (selectedDate == null || !mounted) return;

    final selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
      helpText: 'Pilih waktu deadline',
    );

    if (selectedTime == null || !mounted) return;

    setState(() {
      _deadline = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        selectedTime.hour,
        selectedTime.minute,
      );
      _deadlineError = null;
    });
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    final formValid = _formKey.currentState?.validate() ?? false;
    final deadlineValid = _deadline != null;

    setState(() {
      _deadlineError = deadlineValid ? null : 'Deadline wajib dipilih.';
    });

    if (!formValid || !deadlineValid) return;

    final viewModel = context.read<ProgressTrackingViewModel>();
    final request = CreateTaskRequestModel(
      title: _titleController.text,
      category: _selectedCategory!,
      priority: _selectedPriority!,
      deadline: _deadline!,
      description: _descriptionController.text,
    );

    final success = await viewModel.addTask(request);
    if (!mounted) return;

    if (viewModel.consumeSessionExpired()) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
      return;
    }

    if (success) {
      Navigator.of(context).pop(true);
      return;
    }

    _showMessage(
      viewModel.errorMessage ?? 'Tugas gagal ditambahkan.',
      isError: true,
    );
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
      backgroundColor: const Color(0xFFF7F7F8),
      appBar: AppBar(
        foregroundColor: Colors.white,
        title: const Text(
          'Tambah Tugas',
          style: TextStyle(fontWeight: FontWeight.w700),
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
      body: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x12000000),
                      blurRadius: 18,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Buat target belajar baru',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Isi informasi tugas agar aktivitas belajarmu lebih terarah.',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _titleController,
                      textInputAction: TextInputAction.next,
                      decoration: _inputDecoration(
                        label: 'Judul Tugas',
                        icon: Icons.title_rounded,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Judul tugas wajib diisi.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: _inputDecoration(
                        label: 'Kategori',
                        icon: Icons.category_outlined,
                      ),
                      items: _categories.entries
                          .map(
                            (entry) => DropdownMenuItem(
                              value: entry.key,
                              child: Text(entry.value),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: (value) {
                        setState(() => _selectedCategory = value);
                      },
                      validator: (value) => value == null
                          ? 'Kategori wajib dipilih.'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedPriority,
                      decoration: _inputDecoration(
                        label: 'Prioritas',
                        icon: Icons.flag_outlined,
                      ),
                      items: _priorities.entries
                          .map(
                            (entry) => DropdownMenuItem(
                              value: entry.key,
                              child: Text(entry.value),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: (value) {
                        setState(() => _selectedPriority = value);
                      },
                      validator: (value) => value == null
                          ? 'Prioritas wajib dipilih.'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: _pickDeadline,
                      borderRadius: BorderRadius.circular(14),
                      child: InputDecorator(
                        decoration: _inputDecoration(
                          label: 'Deadline atau Jadwal Tugas',
                          icon: Icons.event_outlined,
                        ).copyWith(errorText: _deadlineError),
                        child: Text(
                          _deadline == null
                              ? 'Pilih tanggal dan waktu'
                              : _formatDateTime(_deadline!),
                          style: TextStyle(
                            color: _deadline == null
                                ? Colors.grey.shade600
                                : Colors.black87,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      minLines: 4,
                      maxLines: 6,
                      textInputAction: TextInputAction.newline,
                      decoration: _inputDecoration(
                        label: 'Deskripsi (opsional)',
                        icon: Icons.notes_rounded,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Consumer<ProgressTrackingViewModel>(
                      builder: (context, viewModel, _) {
                        return SizedBox(
                          height: 52,
                          child: FilledButton(
                            onPressed:
                                viewModel.isCreatingTask ? null : _submit,
                            style: FilledButton.styleFrom(
                              backgroundColor: _primaryRed,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: viewModel.isCreatingTask
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Tambah',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: const Color(0xFFF8F8FA),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _primaryRed, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.red.shade400),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.red.shade700, width: 1.5),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final local = dateTime.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day/$month/${local.year} • $hour:$minute';
  }
}
