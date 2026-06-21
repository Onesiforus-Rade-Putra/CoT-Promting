import 'package:flutter/foundation.dart';

import '../models/create_task_request_model.dart';
import '../models/task_model.dart';
import '../models/task_summary_model.dart';
import '../services/api_exception.dart';
import '../services/progress_tracking_service.dart';

class ProgressTrackingViewModel extends ChangeNotifier {
  ProgressTrackingViewModel(this._service);

  final ProgressTrackingService _service;

  TaskSummaryModel? _summary;
  List<TaskModel> _tasks = const [];
  bool _isLoadingSummary = false;
  bool _isLoadingTasks = false;
  bool _isCreatingTask = false;
  final Set<int> _updatingTaskIds = <int>{};
  final Set<int> _deletingTaskIds = <int>{};
  String? _errorMessage;
  String? _selectedCategory;
  bool _isSessionExpired = false;
  int _tasksRequestGeneration = 0;

  TaskSummaryModel? get summary => _summary;
  List<TaskModel> get tasks => List.unmodifiable(_tasks);
  bool get isLoadingSummary => _isLoadingSummary;
  bool get isLoadingTasks => _isLoadingTasks;
  bool get isCreatingTask => _isCreatingTask;
  bool get isUpdatingTask => _updatingTaskIds.isNotEmpty;
  bool get isDeletingTask => _deletingTaskIds.isNotEmpty;
  String? get errorMessage => _errorMessage;
  String? get selectedCategory => _selectedCategory;
  bool get isSessionExpired => _isSessionExpired;

  bool isTaskUpdating(int taskId) => _updatingTaskIds.contains(taskId);
  bool isTaskDeleting(int taskId) => _deletingTaskIds.contains(taskId);
  bool isTaskBusy(int taskId) =>
      isTaskUpdating(taskId) || isTaskDeleting(taskId);

  Future<void> initialize() async {
    _clearError();
    await Future.wait([
      _fetchSummary(),
      _fetchTasks(category: _selectedCategory),
    ]);
  }

  Future<void> loadSummary() async {
    _clearError();
    await _fetchSummary();
  }

  Future<void> loadTasks({String? category}) async {
    _selectedCategory = category;
    _clearError();
    notifyListeners();
    await _fetchTasks(category: category);
  }

  Future<void> changeCategoryFilter(String? category) async {
    if (_selectedCategory == category && !_isLoadingTasks) return;
    await loadTasks(category: category);
  }

  Future<bool> addTask(CreateTaskRequestModel request) async {
    if (_isCreatingTask) return false;

    _isCreatingTask = true;
    _clearError();
    notifyListeners();

    try {
      await _service.createTask(request);
      await _refreshAfterMutation();
      return true;
    } catch (error) {
      _handleError(error);
      return false;
    } finally {
      _isCreatingTask = false;
      notifyListeners();
    }
  }

  Future<bool> changeTaskProgress(int taskId, String progress) async {
    if (_updatingTaskIds.contains(taskId) ||
        _deletingTaskIds.contains(taskId)) {
      return false;
    }

    _updatingTaskIds.add(taskId);
    _clearError();
    notifyListeners();

    try {
      await _service.updateTaskProgress(taskId, progress);
      await _refreshAfterMutation();
      return true;
    } catch (error) {
      _handleError(error);
      return false;
    } finally {
      _updatingTaskIds.remove(taskId);
      notifyListeners();
    }
  }

  Future<bool> removeTask(int taskId) async {
    if (_deletingTaskIds.contains(taskId) ||
        _updatingTaskIds.contains(taskId)) {
      return false;
    }

    _deletingTaskIds.add(taskId);
    _clearError();
    notifyListeners();

    try {
      await _service.deleteTask(taskId);
      await _refreshAfterMutation();
      return true;
    } catch (error) {
      _handleError(error);
      return false;
    } finally {
      _deletingTaskIds.remove(taskId);
      notifyListeners();
    }
  }

  Future<void> refreshData() async {
    _clearError();
    await Future.wait([
      _fetchSummary(),
      _fetchTasks(category: _selectedCategory),
    ]);
  }

  bool consumeSessionExpired() {
    if (!_isSessionExpired) return false;
    _isSessionExpired = false;
    return true;
  }

  Future<void> _refreshAfterMutation() async {
    await Future.wait([
      _fetchSummary(),
      _fetchTasks(category: _selectedCategory),
    ]);
  }

  Future<void> _fetchSummary() async {
    _isLoadingSummary = true;
    notifyListeners();

    try {
      _summary = await _service.getTaskSummary();
    } catch (error) {
      _handleError(error);
    } finally {
      _isLoadingSummary = false;
      notifyListeners();
    }
  }

  Future<void> _fetchTasks({String? category}) async {
    final requestGeneration = ++_tasksRequestGeneration;
    _isLoadingTasks = true;
    notifyListeners();

    try {
      final result = await _service.getTasks(category: category);
      if (requestGeneration == _tasksRequestGeneration) {
        _tasks = result;
      }
    } catch (error) {
      if (requestGeneration == _tasksRequestGeneration) {
        _handleError(error);
      }
    } finally {
      if (requestGeneration == _tasksRequestGeneration) {
        _isLoadingTasks = false;
        notifyListeners();
      }
    }
  }

  void _handleError(Object error) {
    if (error is UnauthorizedException) {
      _isSessionExpired = true;
      _errorMessage = error.message;
      notifyListeners();
      return;
    }

    if (error is ApiException) {
      _errorMessage = error.message;
    } else {
      _errorMessage = 'Terjadi kesalahan. Silakan coba lagi.';
    }
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }
}
