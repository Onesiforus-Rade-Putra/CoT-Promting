class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class SessionExpiredException extends ApiException {
  const SessionExpiredException()
      : super(
          'Sesi Anda telah berakhir. Silakan login kembali.',
          statusCode: 401,
        );
}
