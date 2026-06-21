class RegisterRequestModel {
  final String email;
  final String username;
  final String password;
  final String phoneNumber;
  final String? nim;
  final String fullName;
  final DateTime? birthDate;

  const RegisterRequestModel({
    required this.email,
    required this.username,
    required this.password,
    required this.phoneNumber,
    required this.fullName,
    this.nim,
    this.birthDate,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'email': email.trim(),
      'username': username.trim(),
      'password': password,
      'phone_number': phoneNumber.trim(),
      'full_name': fullName.trim(),
    };

    final String? cleanedNim = nim?.trim();

    if (cleanedNim != null && cleanedNim.isNotEmpty) {
      data['nim'] = cleanedNim;
    }

    if (birthDate != null) {
      data['birth_date'] = _formatDateForApi(birthDate!);
    }

    return data;
  }

  String _formatDateForApi(DateTime date) {
    final String year = date.year.toString().padLeft(4, '0');
    final String month = date.month.toString().padLeft(2, '0');
    final String day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }
}
