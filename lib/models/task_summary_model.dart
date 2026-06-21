import 'json_parsing.dart';

class TaskSummaryModel {
  final int taskCompleted;
  final int todo;
  final int onProgress;
  final int highPriority;

  const TaskSummaryModel({
    required this.taskCompleted,
    required this.todo,
    required this.onProgress,
    required this.highPriority,
  });

  int get totalTasks => taskCompleted + todo + onProgress;

  double get completionProgress {
    if (totalTasks == 0) return 0;
    return taskCompleted / totalTasks;
  }

  factory TaskSummaryModel.fromJson(Map<String, dynamic> json) {
    return TaskSummaryModel(
      taskCompleted: jsonInt(json['task_completed']),
      todo: jsonInt(json['todo']),
      onProgress: jsonInt(json['on_progress']),
      highPriority: jsonInt(json['high_priority']),
    );
  }
}
