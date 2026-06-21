class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class UnauthorizedException extends ApiException {
  const UnauthorizedException()
      : super(
          'Sesi Anda telah berakhir. Silakan login kembali.',
          statusCode: 401,
        );
}

class ValidationApiException extends ApiException {
  const ValidationApiException(String message)
      : super(message, statusCode: 422);
}

class NetworkApiException extends ApiException {
  const NetworkApiException()
      : super(
          'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.',
        );
}

class ServerApiException extends ApiException {
  const ServerApiException()
      : super(
          'Terjadi kesalahan. Silakan coba lagi.',
        );
}
