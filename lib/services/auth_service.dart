import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../core/config/api_config.dart';
import '../core/network/auth_exception.dart';
import '../models/login_response_model.dart';
import '../models/register_request_model.dart';
import 'api_exception.dart';

class AuthService {
  final http.Client _client;

  AuthService({
    http.Client? client,
  }) : _client = client ?? http.Client();

  Future<LoginResponseModel> login(
    String emailOrUsername,
    String password,
  ) async {
    final Uri url = Uri.parse('${ApiConfig.baseUrl}/api/v1/auth/login');

    try {
      final response = await _client
          .post(
            url,
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'email_or_username': emailOrUsername,
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 20));

      return _handleLoginResponse(response);
    } on SocketException {
      throw AuthException(
        'Terjadi kesalahan. Silakan coba lagi.',
      );
    } on TimeoutException {
      throw AuthException(
        'Terjadi kesalahan. Silakan coba lagi.',
      );
    } on AuthException {
      rethrow;
    } catch (_) {
      throw AuthException(
        'Terjadi kesalahan. Silakan coba lagi.',
      );
    }
  }

  LoginResponseModel _handleLoginResponse(http.Response response) {
    switch (response.statusCode) {
      case 200:
        try {
          final decodedBody = jsonDecode(response.body);

          if (decodedBody is! Map<String, dynamic>) {
            throw const FormatException('Invalid login response format');
          }

          final loginResponse = LoginResponseModel.fromJson(decodedBody);

          if (loginResponse.accessToken.isEmpty ||
              loginResponse.refreshToken.isEmpty) {
            throw const FormatException('Token tidak ditemukan');
          }

          return loginResponse;
        } catch (_) {
          throw AuthException(
            'Terjadi kesalahan. Silakan coba lagi.',
            statusCode: response.statusCode,
          );
        }

      case 401:
        throw AuthException(
          'Email/username atau password salah.',
          statusCode: response.statusCode,
        );

      case 422:
        throw AuthException(
          _parseValidationMessage(response.body),
          statusCode: response.statusCode,
        );

      default:
        throw AuthException(
          'Terjadi kesalahan. Silakan coba lagi.',
          statusCode: response.statusCode,
        );
    }
  }

  String _parseValidationMessage(String responseBody) {
    try {
      final decodedBody = jsonDecode(responseBody);

      if (decodedBody is Map<String, dynamic>) {
        final message = decodedBody['message'];

        if (message is String && message.isNotEmpty) {
          return message;
        }

        final detail = decodedBody['detail'];

        if (detail is String && detail.isNotEmpty) {
          return detail;
        }

        if (detail is List && detail.isNotEmpty) {
          return 'Input wajib diisi atau data tidak valid.';
        }

        final errors = decodedBody['errors'];

        if (errors is Map && errors.isNotEmpty) {
          return 'Input wajib diisi atau data tidak valid.';
        }
      }

      return 'Input wajib diisi atau data tidak valid.';
    } catch (_) {
      return 'Input wajib diisi atau data tidak valid.';
    }
  }

  Future<void> register(RegisterRequestModel request) async {
    final Uri uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/auth/register');

    try {
      final http.Response response = await _client
          .post(
            uri,
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(request.toJson()),
          )
          .timeout(ApiConfig.requestTimeout);

      if (response.statusCode == 200) {
        return;
      }

      if (response.statusCode == 422) {
        final String message = _extractValidationErrorMessage(response.body);

        throw ApiException(
          message,
          statusCode: response.statusCode,
        );
      }

      throw ApiException(
        'Terjadi kesalahan. Silakan coba lagi.',
        statusCode: response.statusCode,
      );
    } on TimeoutException {
      throw const ApiException('Terjadi kesalahan. Silakan coba lagi.');
    } on SocketException {
      throw const ApiException('Terjadi kesalahan. Silakan coba lagi.');
    } on FormatException {
      throw const ApiException('Terjadi kesalahan. Silakan coba lagi.');
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException('Terjadi kesalahan. Silakan coba lagi.');
    }
  }

  String _extractValidationErrorMessage(String responseBody) {
    const String fallbackMessage =
        'Data registrasi tidak valid. Silakan periksa kembali.';

    if (responseBody.trim().isEmpty) {
      return fallbackMessage;
    }

    try {
      final dynamic decoded = jsonDecode(responseBody);
      final List<String> messages = [];

      if (decoded is Map<String, dynamic>) {
        _collectMessageFromMap(decoded, messages);
      } else if (decoded is List) {
        _collectMessageFromList(decoded, messages);
      }

      if (messages.isEmpty) {
        return fallbackMessage;
      }

      return messages.join('\n');
    } catch (_) {
      return fallbackMessage;
    }
  }

  void _collectMessageFromMap(
    Map<String, dynamic> data,
    List<String> messages,
  ) {
    final dynamic message = data['message'];
    final dynamic error = data['error'];
    final dynamic detail = data['detail'];
    final dynamic errors = data['errors'];

    if (message is String && message.trim().isNotEmpty) {
      messages.add(message.trim());
    }

    if (error is String && error.trim().isNotEmpty) {
      messages.add(error.trim());
    }

    if (detail is String && detail.trim().isNotEmpty) {
      messages.add(detail.trim());
    } else if (detail is List) {
      _collectMessageFromList(detail, messages);
    } else if (detail is Map<String, dynamic>) {
      _collectMessageFromMap(detail, messages);
    }

    if (errors is Map<String, dynamic>) {
      for (final dynamic value in errors.values) {
        if (value is String && value.trim().isNotEmpty) {
          messages.add(value.trim());
        } else if (value is List) {
          for (final dynamic item in value) {
            if (item is String && item.trim().isNotEmpty) {
              messages.add(item.trim());
            } else if (item is Map<String, dynamic>) {
              _collectMessageFromMap(item, messages);
            }
          }
        }
      }
    }
  }

  void _collectMessageFromList(
    List<dynamic> data,
    List<String> messages,
  ) {
    for (final dynamic item in data) {
      if (item is String && item.trim().isNotEmpty) {
        messages.add(item.trim());
      } else if (item is Map<String, dynamic>) {
        final dynamic msg = item['msg'];
        final dynamic message = item['message'];
        final dynamic detail = item['detail'];

        if (msg is String && msg.trim().isNotEmpty) {
          messages.add(msg.trim());
        } else if (message is String && message.trim().isNotEmpty) {
          messages.add(message.trim());
        } else if (detail is String && detail.trim().isNotEmpty) {
          messages.add(detail.trim());
        } else {
          _collectMessageFromMap(item, messages);
        }
      }
    }
  }

  void dispose() {
    _client.close();
  }
}
