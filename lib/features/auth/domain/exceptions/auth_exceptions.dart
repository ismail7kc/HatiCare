class PasswordMismatchException implements Exception {
  const PasswordMismatchException();
}

class AuthApiException implements Exception {
  const AuthApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() =>
      'AuthApiException(message: $message, statusCode: $statusCode)';
}
