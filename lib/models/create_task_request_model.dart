class CreateTaskRequestModel {
  const CreateTaskRequestModel({
    required this.title,
    required this.category,
    required this.priority,
    required this.deadline,
    this.description,
  });

  final String title;
  final String category;
  final String priority;
  final DateTime deadline;
  final String? description;

  Map<String, dynamic> toJson() {
    final trimmedDescription = description?.trim();

    return <String, dynamic>{
      'title': title.trim(),
      'category': category,
      'priority': priority,
      'deadline': deadline.toUtc().toIso8601String(),
      if (trimmedDescription != null && trimmedDescription.isNotEmpty)
        'description': trimmedDescription,
    };
  }
}
