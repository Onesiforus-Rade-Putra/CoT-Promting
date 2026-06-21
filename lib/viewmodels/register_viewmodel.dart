import 'package:flutter/foundation.dart';

import '../models/register_request_model.dart';
import '../services/api_exception.dart';
import '../services/auth_service.dart';

class RegisterViewModel extends ChangeNotifier {
  final AuthService _authService;

  RegisterViewModel(this._authService);

  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  Future<bool> register(RegisterRequestModel request) async {
    _setLoading(true);
    _clearMessages();

    try {
      await _authService.register(request);

      _successMessage = 'Registrasi berhasil. Silakan login.';
      notifyListeners();

      return true;
    } on ApiException catch (error) {
      _errorMessage = error.message;
      notifyListeners();

      return false;
    } catch (_) {
      _errorMessage = 'Terjadi kesalahan. Silakan coba lagi.';
      notifyListeners();

      return false;
    } finally {
      _setLoading(false);
    }
  }

  void clearMessage() {
    _clearMessages();
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearMessages() {
    _errorMessage = null;
    _successMessage = null;
  }
}
