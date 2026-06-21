class DashboardException implements Exception {
  final String message;

  const DashboardException(this.message);

  @override
  String toString() => message;
}

class DashboardUnauthorizedException extends DashboardException {
  const DashboardUnauthorizedException()
      : super('Sesi Anda telah berakhir. Silakan login kembali.');
}

class DashboardValidationException extends DashboardException {
  const DashboardValidationException() : super('Permintaan data tidak valid.');
}

class DashboardNetworkException extends DashboardException {
  const DashboardNetworkException()
      : super(
            'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.');
}

class DashboardServerException extends DashboardException {
  const DashboardServerException()
      : super('Terjadi kesalahan pada server. Silakan coba lagi nanti.');
}

class DashboardParseException extends DashboardException {
  const DashboardParseException()
      : super('Format data dari server tidak valid.');
}
