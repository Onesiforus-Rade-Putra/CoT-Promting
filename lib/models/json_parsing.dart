String jsonString(dynamic value, {String fallback = ''}) {
  if (value == null) return fallback;
  return value.toString();
}

String? jsonNullableString(dynamic value) {
  if (value == null) return null;

  final text = value.toString().trim();
  if (text.isEmpty) return null;

  return text;
}

int jsonInt(dynamic value, {int fallback = 0}) {
  if (value == null) return fallback;
  if (value is int) return value;
  if (value is num) return value.toInt();

  return int.tryParse(value.toString()) ?? fallback;
}

bool jsonBool(dynamic value, {bool fallback = false}) {
  if (value == null) return fallback;
  if (value is bool) return value;
  if (value is num) return value != 0;

  final text = value.toString().toLowerCase();
  if (text == 'true') return true;
  if (text == 'false') return false;

  return fallback;
}

DateTime? jsonDate(dynamic value) {
  if (value == null) return null;

  final text = value.toString().trim();
  if (text.isEmpty) return null;

  return DateTime.tryParse(text);
}

List<T> jsonList<T>(
  dynamic value,
  T Function(Map<String, dynamic> json) mapper,
) {
  if (value is! List) return <T>[];

  return value
      .whereType<Map>()
      .map((item) => mapper(Map<String, dynamic>.from(item)))
      .toList();
}
