import 'user_model.dart';

class LoginResponseModel {
  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final UserModel user;

  const LoginResponseModel({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.user,
  });

  factory LoginResponseModel.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'];

    if (userJson is! Map<String, dynamic>) {
      throw const FormatException('Invalid user response format');
    }

    return LoginResponseModel(
      accessToken: json['access_token'] as String? ?? '',
      refreshToken: json['refresh_token'] as String? ?? '',
      tokenType: json['token_type'] as String? ?? 'Bearer',
      user: UserModel.fromJson(userJson),
    );
  }
}
