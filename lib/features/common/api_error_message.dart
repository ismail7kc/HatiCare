class ApiErrorMessages {
  static const noInternet =
      "No internet connection. Please check your network.";
  static const timeout =
      "Request timed out. Please try again.";
  static const server =
      "Server error. Please try again later.";
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
}

