import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../core/network/auth_exception.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthService _authService;
  final FlutterSecureStorage _secureStorage;

  AuthViewModel({
    required AuthService authService,
    FlutterSecureStorage? secureStorage,
  })  : _authService = authService,
        _secureStorage = secureStorage ?? const FlutterSecureStorage();

  bool _isLoading = false;
  String? _errorMessage;
  UserModel? _currentUser;
  bool _rememberMe = false;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  UserModel? get currentUser => _currentUser;
  bool get rememberMe => _rememberMe;

  void setRememberMe(bool value) {
    _rememberMe = value;
    notifyListeners();
  }

  Future<bool> login({
    required String emailOrUsername,
    required String password,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      final response = await _authService.login(
        emailOrUsername.trim(),
        password,
      );

      await _secureStorage.write(
        key: 'access_token',
        value: response.accessToken,
      );

      await _secureStorage.write(
        key: 'refresh_token',
        value: response.refreshToken,
      );

      await _secureStorage.write(
        key: 'token_type',
        value: response.tokenType,
      );

      await _secureStorage.write(
        key: 'remember_me',
        value: _rememberMe.toString(),
      );

      _currentUser = response.user;

      return true;
    } on AuthException catch (error) {
      _setError(error.message);
      return false;
    } catch (_) {
      _setError('Terjadi kesalahan. Silakan coba lagi.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<String?> getBearerToken() async {
    final tokenType = await _secureStorage.read(key: 'token_type') ?? 'Bearer';
    final accessToken = await _secureStorage.read(key: 'access_token');

    if (accessToken == null || accessToken.isEmpty) {
      return null;
    }

    return '$tokenType $accessToken';
  }

  Future<void> logout() async {
    await _secureStorage.delete(key: 'access_token');
    await _secureStorage.delete(key: 'refresh_token');
    await _secureStorage.delete(key: 'token_type');
    await _secureStorage.delete(key: 'remember_me');

    _currentUser = null;
    _errorMessage = null;
    _rememberMe = false;

    notifyListeners();
  }

  void clearError() {
    _setError(null);
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }
}
