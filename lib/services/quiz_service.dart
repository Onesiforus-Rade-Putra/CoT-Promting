import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../core/config/api_config.dart';
import '../core/exceptions/api_exception.dart';
import '../models/generate_certificate_response_model.dart';
import '../models/quiz_model.dart';
import '../models/quiz_question_model.dart';
import '../models/quiz_result_model.dart';
import '../models/start_quiz_response_model.dart';
import '../models/submit_quiz_request_model.dart';

class QuizService {
  QuizService({
    http.Client? client,
    FlutterSecureStorage? secureStorage,
  })  : _client = client ?? http.Client(),
        _secureStorage = secureStorage ?? const FlutterSecureStorage();

  final http.Client _client;
  final FlutterSecureStorage _secureStorage;

  Future<List<QuizModel>> getAllQuizzes() async {
    final response = await _send(
      () async => _client.get(
        _uri('/api/v1/quiz/'),
        headers: await _authorizedHeaders(),
      ),
    );

    final decoded = _decodeJson(response.body);
    if (decoded is! List) {
      throw const ApiException('Format daftar quiz tidak valid.');
    }

    return decoded
        .map(
          (item) => QuizModel.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList(growable: false);
  }

  Future<StartQuizResponseModel> startQuiz(int quizId) async {
    final response = await _send(
      () async => _client.post(
        _uri('/api/v1/quiz/$quizId/start'),
        headers: await _authorizedHeaders(),
      ),
    );

    return StartQuizResponseModel.fromJson(
      _decodeObject(response.body),
    );
  }

  Future<QuizQuestionModel> getQuizQuestion(
    int quizId,
    int questionNum,
  ) async {
    final response = await _send(
      () async => _client.get(
        _uri('/api/v1/quiz/$quizId/questions/$questionNum'),
        headers: await _authorizedHeaders(),
      ),
    );

    return QuizQuestionModel.fromJson(_decodeObject(response.body));
  }

  Future<QuizResultModel> submitQuiz(
    int quizId,
    Map<int, String> selectedAnswers,
  ) async {
    final request = SubmitQuizRequestModel.fromSelectedAnswers(
      selectedAnswers,
    );

    final response = await _send(
      () async => _client.post(
        _uri('/api/v1/quiz/$quizId/submit'),
        headers: await _authorizedHeaders(),
        body: jsonEncode(request.toJson()),
      ),
    );

    return QuizResultModel.fromJson(_decodeObject(response.body));
  }

  Future<void> exitQuizEarly(int quizId) async {
    // Endpoint sukses dapat mengembalikan body kosong/null.
    await _send(
      () async => _client.post(
        _uri('/api/v1/quiz/$quizId/exit'),
        headers: await _authorizedHeaders(),
      ),
    );
  }

  Future<GenerateCertificateResponseModel> generateCertificate(
    int quizId,
  ) async {
    final response = await _send(
      () async => _client.post(
        _uri('/api/v1/quiz/$quizId/certificate'),
        headers: await _authorizedHeaders(),
      ),
    );

    return GenerateCertificateResponseModel.fromJson(
      _decodeObject(response.body),
    );
  }

  Uri _uri(String path) => Uri.parse('${ApiConfig.baseUrl}$path');

  Future<Map<String, String>> _authorizedHeaders() async {
    final token = await _secureStorage.read(key: 'access_token');

    if (token == null || token.trim().isEmpty) {
      throw const SessionExpiredException();
    }

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<http.Response> _send(
    Future<http.Response> Function() request,
  ) async {
    try {
      final response = await request().timeout(ApiConfig.requestTimeout);
      _validateResponse(response);
      return response;
    } on SessionExpiredException {
      rethrow;
    } on ApiException {
      rethrow;
    } on SocketException {
      throw const ApiException(
        'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.',
      );
    } on TimeoutException {
      throw const ApiException(
        'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.',
      );
    } on http.ClientException {
      throw const ApiException(
        'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.',
      );
    } on FormatException {
      throw const ApiException('Format data dari server tidak valid.');
    } catch (_) {
      throw const ApiException('Terjadi kesalahan. Silakan coba lagi.');
    }
  }

  void _validateResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    if (response.statusCode == 401) {
      throw const SessionExpiredException();
    }

    if (response.statusCode == 422) {
      throw ApiException(
        _extractApiMessage(response.body) ??
            'Permintaan tidak valid. Silakan coba kembali.',
        statusCode: 422,
      );
    }

    if (response.statusCode >= 500) {
      throw ApiException(
        'Terjadi kesalahan. Silakan coba lagi.',
        statusCode: response.statusCode,
      );
    }

    throw ApiException(
      _extractApiMessage(response.body) ??
          'Permintaan gagal. Silakan coba kembali.',
      statusCode: response.statusCode,
    );
  }

  Map<String, dynamic> _decodeObject(String body) {
    final decoded = _decodeJson(body);
    if (decoded is! Map) {
      throw const FormatException('Response bukan object JSON.');
    }
    return Map<String, dynamic>.from(decoded);
  }

  dynamic _decodeJson(String body) {
    if (body.trim().isEmpty || body.trim() == 'null') return null;
    return jsonDecode(body);
  }

  String? _extractApiMessage(String body) {
    try {
      final decoded = _decodeJson(body);
      if (decoded is Map) {
        final message = decoded['message'] ?? decoded['detail'];
        if (message is String && message.trim().isNotEmpty) {
          return message;
        }
        if (message is List && message.isNotEmpty) {
          final first = message.first;
          if (first is Map && first['msg'] != null) {
            return first['msg'].toString();
          }
          return first.toString();
        }
      }
    } catch (_) {
      // Gunakan pesan fallback; jangan menampilkan body mentah.
    }
    return null;
  }

  void dispose() => _client.close();
}
