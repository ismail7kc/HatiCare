import 'package:chucker_flutter/chucker_flutter.dart';
import 'package:http/http.dart' as http;

/// Create an HTTP client with Chucker interceptor for debugging
http.Client createChuckerHttpClient() {
  return ChuckerHttpClient(http.Client());
}
