enum TaskProgress {
  todo,
  onProgress,
  completed,
}

extension TaskProgressX on TaskProgress {
  String get apiValue {
    switch (this) {
      case TaskProgress.todo:
        return 'todo';
      case TaskProgress.onProgress:
        return 'on_progress';
      case TaskProgress.completed:
        return 'completed';
    }
  }

  String get label {
    switch (this) {
      case TaskProgress.todo:
        return 'Belum Dikerjakan';
      case TaskProgress.onProgress:
        return 'Sedang Berjalan';
      case TaskProgress.completed:
        return 'Selesai';
    }
  }
}
