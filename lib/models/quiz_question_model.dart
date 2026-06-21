import 'answer_option_model.dart';

class QuizQuestionModel {
  const QuizQuestionModel({
    required this.id,
    required this.currentNumber,
    required this.text,
    required this.optionA,
    required this.optionB,
    required this.optionC,
    required this.optionD,
  });

  final int id;
  final int currentNumber;
  final String text;
  final String optionA;
  final String optionB;
  final String optionC;
  final String optionD;

  factory QuizQuestionModel.fromJson(Map<String, dynamic> json) {
    return QuizQuestionModel(
      id: _toInt(json['id']),
      currentNumber: _toInt(json['current_number']),
      text: json['text']?.toString() ?? '',
      optionA: json['option_a']?.toString() ?? '',
      optionB: json['option_b']?.toString() ?? '',
      optionC: json['option_c']?.toString() ?? '',
      optionD: json['option_d']?.toString() ?? '',
    );
  }

  List<AnswerOptionModel> get options => [
        AnswerOptionModel(value: 'a', label: 'A', text: optionA),
        AnswerOptionModel(value: 'b', label: 'B', text: optionB),
        AnswerOptionModel(value: 'c', label: 'C', text: optionC),
        AnswerOptionModel(value: 'd', label: 'D', text: optionD),
      ];

  static int _toInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
