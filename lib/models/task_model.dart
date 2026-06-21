class TaskModel {
  const TaskModel({
    required this.id,
    required this.title,
    required this.category,
    required this.priority,
    required this.deadline,
    required this.isCompleted,
    this.description,
  });

  final int id;
  final String title;
  final String category;
  final String priority;
  final DateTime deadline;
  final String? description;
  final bool isCompleted;

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    final rawDeadline = json['deadline']?.toString();
    final parsedDeadline = DateTime.tryParse(rawDeadline ?? '');

    if (parsedDeadline == null) {
      throw const FormatException('Format deadline tugas tidak valid.');
    }

    return TaskModel(
      id: _readInt(json['id']),
      title: json['title']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      priority: json['priority']?.toString() ?? '',
      deadline: parsedDeadline,
      description: _readNullableString(json['description']),
      isCompleted: json['is_completed'] == true,
    );
  }

  static int _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String? _readNullableString(dynamic value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }
}
