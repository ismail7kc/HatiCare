import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiClient {
  final http.Client _client = http.Client();

  Future<Map<String, dynamic>> postRequest(
    String url, {
    required Map<String, dynamic> body,
    Map<String, String>? headers,
  }) async {
    final uri = Uri.parse(url);

    final response = await _client.post(
      uri,
      headers:
          headers ??
          {'Content-Type': 'application/json', 'Accept': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return _decodeJson(response.body);
    } else {
      throw Exception('Request failed: ${response.statusCode}');
    }
  }

  Map<String, dynamic> _decodeJson(String data) {
    try {
      return json.decode(data) as Map<String, dynamic>;
    } catch (_) {
      return {'status': 'success'};
    }
  }
}
