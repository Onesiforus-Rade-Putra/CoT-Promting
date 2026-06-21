import 'quiz_question_model.dart';

class StartQuizResponseModel {
  const StartQuizResponseModel({
    required this.attemptId,
    required this.text,
    required this.totalQuestions,
    required this.endDateTime,
    required this.firstQuestion,
  });

  final int attemptId;
  final String text;
  final int totalQuestions;
  final DateTime endDateTime;
  final QuizQuestionModel firstQuestion;

  factory StartQuizResponseModel.fromJson(Map<String, dynamic> json) {
    final endDateTimeValue = json['end_date_time']?.toString();
    final parsedEndDateTime = DateTime.tryParse(endDateTimeValue ?? '');

    if (parsedEndDateTime == null) {
      throw const FormatException('Format end_date_time tidak valid.');
    }

    return StartQuizResponseModel(
      attemptId: _toInt(json['attempt_id']),
      text: json['text']?.toString() ?? '',
      totalQuestions: _toInt(json['total_questions']),
      endDateTime: parsedEndDateTime,
      firstQuestion: QuizQuestionModel.fromJson(
        Map<String, dynamic>.from(json['first_question'] as Map),
      ),
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
