class AnswerOptionModel {
  const AnswerOptionModel({
    required this.value,
    required this.label,
    required this.text,
  });

  /// Nilai yang dikirim ke API: a, b, c, atau d.
  final String value;
  final String label;
  final String text;
}
