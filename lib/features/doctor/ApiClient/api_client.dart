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

  Future<Map<String, dynamic>> getRequest(
    String url, {
    Map<String, String>? headers,
  }) async {
    final uri = Uri.parse(url);

    final response = await _client.get(
      uri,
      headers:
          headers ??
          {'Content-Type': 'application/json', 'Accept': 'application/json'},
    );

    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> updateDocRequest(
    String url, {
    required Map<String, dynamic> body,
    Map<String, String>? headers,
  }) async {
    final uri = Uri.parse(url);
    final response = await _client.put(
      uri,
      headers:
          headers ??
          {'Content-Type': 'application/json', 'Accept': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return _decodeJson(response.body);
    } else {
      throw Exception(
        'Update failed: ${response.statusCode}\n${response.body}',
      );
    }
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return _decodeJson(response.body);
    } else {
      throw Exception(
        'Request failed: ${response.statusCode}\n${response.body}',
      );
    }
  }

  Map<String, dynamic> _decodeJson(String data) {
    final decoded = json.decode(data);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is List) return {'data': decoded};
    return {};
  }

  // Map<String, dynamic> _decodeJson(String data) {
  //   try {
  //     return json.decode(data) as Map<String, dynamic>;
  //   } catch (_) {
  //     return {'status': 'success'};
  //   }
  // }
}
