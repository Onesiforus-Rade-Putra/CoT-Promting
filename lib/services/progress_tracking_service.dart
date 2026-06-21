import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../models/create_task_request_model.dart';
import '../models/task_model.dart';
import '../models/task_summary_model.dart';
import 'api_exception.dart';

class ProgressTrackingService {
  ProgressTrackingService({
    required String baseUrl,
    FlutterSecureStorage? secureStorage,
    http.Client? httpClient,
  })  : _baseUrl = baseUrl.replaceFirst(RegExp(r'/$'), ''),
        _secureStorage = secureStorage ?? const FlutterSecureStorage(),
        _httpClient = httpClient ?? http.Client();

  final String _baseUrl;
  final FlutterSecureStorage _secureStorage;
  final http.Client _httpClient;

  static const String _tokenKey = 'access_token';
  static const Duration _requestTimeout = Duration(seconds: 20);

  Future<TaskSummaryModel> getTaskSummary() async {
    final response = await _send(
      () async => _httpClient.get(
        _buildUri('/api/v1/progress-tracking/summary'),
        headers: await _authorizedHeaders(),
      ),
    );

    _ensureSuccess(response, allowedStatusCodes: const {200});

    final data = _decodeJsonObject(response.body);
    return TaskSummaryModel.fromJson(data);
  }

  Future<List<TaskModel>> getTasks({String? category}) async {
    final queryParameters = <String, String>{
      if (category != null && category.isNotEmpty) 'category': category,
    };

    final response = await _send(
      () async => _httpClient.get(
        _buildUri(
          '/api/v1/progress-tracking/tasks',
          queryParameters: queryParameters,
        ),
        headers: await _authorizedHeaders(),
      ),
    );

    _ensureSuccess(response, allowedStatusCodes: const {200});

    final decoded = _decodeJson(response.body);
    if (decoded is! List<dynamic>) {
      throw const ApiException('Format daftar tugas dari server tidak valid.');
    }

    return decoded
        .map(
          (item) => TaskModel.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList(growable: false);
  }

  Future<TaskModel> createTask(CreateTaskRequestModel request) async {
    final response = await _send(
      () async => _httpClient.post(
        _buildUri('/api/v1/progress-tracking/tasks'),
        headers: await _authorizedHeaders(),
        body: jsonEncode(request.toJson()),
      ),
    );

    _ensureSuccess(response, allowedStatusCodes: const {201});

    final data = _decodeJsonObject(response.body);
    return TaskModel.fromJson(data);
  }

  Future<void> updateTaskProgress(int taskId, String progress) async {
    final encodedProgress = Uri.encodeComponent(progress);
    final response = await _send(
      () async => _httpClient.post(
        _buildUri(
          '/api/v1/progress-tracking/tasks/$taskId/'
          'update_progress/$encodedProgress',
        ),
        headers: await _authorizedHeaders(),
      ),
    );

    // Endpoint ini dapat mengembalikan body kosong/null, sehingga tidak di-decode.
    _ensureSuccess(response, allowedStatusCodes: const {200});
  }

  Future<void> deleteTask(int taskId) async {
    final response = await _send(
      () async => _httpClient.delete(
        _buildUri('/api/v1/progress-tracking/tasks/$taskId'),
        headers: await _authorizedHeaders(),
      ),
    );

    // Endpoint ini dapat mengembalikan body kosong/null, sehingga tidak di-decode.
    _ensureSuccess(response, allowedStatusCodes: const {200});
  }

  Future<Map<String, String>> _authorizedHeaders() async {
    final token = await _secureStorage.read(key: _tokenKey);

    if (token == null || token.trim().isEmpty) {
      throw const UnauthorizedException();
    }

    return <String, String>{
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Uri _buildUri(
    String path, {
    Map<String, String>? queryParameters,
  }) {
    final uri = Uri.parse('$_baseUrl$path');
    if (queryParameters == null || queryParameters.isEmpty) return uri;
    return uri.replace(queryParameters: queryParameters);
  }

  Future<http.Response> _send(
    Future<http.Response> Function() request,
  ) async {
    try {
      return await request().timeout(_requestTimeout);
    } on UnauthorizedException {
      rethrow;
    } on SocketException {
      throw const NetworkApiException();
    } on http.ClientException {
      throw const NetworkApiException();
    } on TimeoutException {
      throw const NetworkApiException();
    } on FormatException catch (error) {
      throw ApiException(error.message);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ServerApiException();
    }
  }

  void _ensureSuccess(
    http.Response response, {
    required Set<int> allowedStatusCodes,
  }) {
    if (allowedStatusCodes.contains(response.statusCode)) return;

    if (response.statusCode == 401) {
      throw const UnauthorizedException();
    }

    if (response.statusCode == 422) {
      throw ValidationApiException(
        _extractErrorMessage(
          response.body,
          fallback: 'Data tugas tidak valid. Periksa kembali input Anda.',
        ),
      );
    }

    if (response.statusCode >= 500) {
      throw const ServerApiException();
    }

    throw ApiException(
      _extractErrorMessage(
        response.body,
        fallback: 'Permintaan tidak dapat diproses. Silakan coba lagi.',
      ),
      statusCode: response.statusCode,
    );
  }

  dynamic _decodeJson(String body) {
    if (body.trim().isEmpty || body.trim() == 'null') {
      throw const ApiException('Respons server kosong atau tidak valid.');
    }

    try {
      return jsonDecode(body);
    } on FormatException {
      throw const ApiException('Format respons server tidak valid.');
    }
  }

  Map<String, dynamic> _decodeJsonObject(String body) {
    final decoded = _decodeJson(body);
    if (decoded is! Map) {
      throw const ApiException('Format respons server tidak valid.');
    }
    return Map<String, dynamic>.from(decoded);
  }

  String _extractErrorMessage(
    String body, {
    required String fallback,
  }) {
    if (body.trim().isEmpty || body.trim() == 'null') return fallback;

    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) {
        final map = Map<String, dynamic>.from(decoded);

        for (final key in const ['message', 'detail', 'error']) {
          final value = map[key];
          if (value is String && value.trim().isNotEmpty) {
            return value.trim();
          }
        }

        final errors = map['errors'];
        if (errors is List && errors.isNotEmpty) {
          return errors.map((item) => item.toString()).join('\n');
        }
        if (errors is Map && errors.isNotEmpty) {
          return errors.values
              .expand((value) => value is List ? value : [value])
              .map((item) => item.toString())
              .join('\n');
        }
      }
    } catch (_) {
      // Gunakan fallback jika body bukan JSON.
    }

    return fallback;
  }

  void dispose() {
    _httpClient.close();
  }
}
