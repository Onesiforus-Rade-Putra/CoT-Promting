class SubmitQuizRequestModel {
  const SubmitQuizRequestModel({required this.answers});

  final Map<String, String> answers;

  factory SubmitQuizRequestModel.fromSelectedAnswers(
    Map<int, String> selectedAnswers,
  ) {
    final converted = <String, String>{};

    for (final entry in selectedAnswers.entries) {
      final answer = entry.value.toLowerCase();
      if (!const {'a', 'b', 'c', 'd'}.contains(answer)) {
        throw ArgumentError('Pilihan jawaban harus berupa a, b, c, atau d.');
      }
      converted[entry.key.toString()] = answer;
    }

    return SubmitQuizRequestModel(answers: converted);
  }

  Map<String, dynamic> toJson() => {'answers': answers};
}
