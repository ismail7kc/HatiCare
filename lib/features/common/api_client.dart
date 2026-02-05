import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:haticare/features/common/api_error_message.dart';
import 'package:http/http.dart' as http;
import 'package:haticare/features/common/shared_prefs_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  final http.Client _client = http.Client();

  Future<Map<String, dynamic>> postRequest(
    String url, {
    required Map<String, dynamic> body,
    Map<String, String>? headers,
  }) async {
    try {
      final uri = Uri.parse(url);

      final response = await _safeRequest(() {
        return _client.post(
          uri,
          headers:
              headers ??
              {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
              },
          body: jsonEncode(body),
        );
      });

      return _handleResponse(response);
    } on ApiException catch (e) {
      return {"success": false, "message": e.message, "data": {}};
    }
  }

  Future<Map<String, dynamic>> getRequest(
    String url, {
    Map<String, String>? headers,
  }) async {
    try {
      final uri = Uri.parse(url);

      final response = await _safeRequest(() {
        return _client.get(
          uri,
          headers:
              headers ??
              {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
              },
        );
      });

      return _handleResponse(response);
    } on ApiException catch (e) {
      return {"success": false, "message": e.message, "data": {}};
    }
  }

  Future<Map<String, dynamic>> uploadProfileImage(
    String url,
    File imageFile,
  ) async {
    try {
      final uri = Uri.parse(url);
      final request = http.MultipartRequest('PATCH', uri);

      // Get access token from SharedPreferences as fallback
      final prefs = await SharedPreferences.getInstance();
      final accessToken =
          SaveLoginResponse.loginData?['access_token'] ??
          prefs.getString('access_token') ??
          '';
      request.headers['Authorization'] = 'Bearer $accessToken';
      request.headers['Accept'] = 'application/json';

      request.files.add(
        await http.MultipartFile.fromPath('profile_picture', imageFile.path),
      );

      final streamedResponse = await _safeRequest(() async {
        final stream = await request.send();
        return http.Response.fromStream(stream);
      });

      debugPrint('✅ PATCH URL: $uri');
      debugPrint('✅ Status Code: ${streamedResponse.statusCode}');
      debugPrint('✅ Response Body: ${streamedResponse.body}');

      return _handleResponse(streamedResponse);
    } catch (e) {
      debugPrint('Upload Exception: $e');
      return {"success": false, "message": e.toString()};
    }
  }

  Future<Map<String, dynamic>> getSingleDoctor(String url) async {
    final uri = Uri.parse(url);

    final prefs = await SharedPreferences.getInstance();
    final accessToken =
        SaveLoginResponse.loginData?['access_token'] ??
        prefs.getString('access_token') ??
        '';

    final response = await _safeRequest(() {
      return http.get(uri, headers: {'Authorization': 'Bearer $accessToken'});
    });

    debugPrint('✅ PATCH URL: $uri');
    debugPrint('✅ Status Code: ${response.statusCode}');
    debugPrint('✅ Response Body: ${response.body}');

    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> updateDocRequest(
    String url, {
    required Map<String, dynamic> body,
  }) async {
    try {
      final uri = Uri.parse(url);
      final request = http.MultipartRequest('PATCH', uri);

      final prefs = await SharedPreferences.getInstance();
      final accessToken =
          SaveLoginResponse.loginData?['access_token'] ??
          prefs.getString('access_token') ??
          '';

      request.headers.addAll({
        'Authorization': 'Bearer $accessToken',
        'Accept': 'application/json',
        'Content-Type': 'multipart/form-data',
      });

      for (var entry in body.entries) {
        final key = entry.key;
        final value = entry.value;

        if (value is File) {
          request.files.add(
            await http.MultipartFile.fromPath(
              key,
              value.path,
              filename: value.path.split('/').last,
            ),
          );
        } else if (value != null) {
          request.fields[key] = value.toString();
        }
      }
      final response = await _safeRequest(() async {
        final streamed = await request.send();
        return http.Response.fromStream(streamed);
      });

      debugPrint('PATCH $url');
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Response Body: ${response.body}');

      return _handleResponse(response);
    } catch (e) {
      debugPrint("ERROR in updateDocRequest: $e");
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getPatientQueue(String url) async {
    try {
      final uri = Uri.parse(url);

      final prefs = await SharedPreferences.getInstance();
      final accessToken =
          SaveLoginResponse.loginData?['access_token'] ??
          prefs.getString('access_token') ??
          '';

      final response = await _safeRequest(() {
        return _client.get(
          uri,
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Accept': 'application/json',
          },
        );
      });

      debugPrint('GET PatientQueue URL: $uri');
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Response Body: ${response.body}');

      return _handleResponse(response);
    } catch (e) {
      debugPrint('getPatientQueue Exception: $e');
      return {'success': false, 'message': e.toString(), 'data': {}};
    }
  }

  Future<Map<String, dynamic>> acceptPatientResponse(String url) async {
    try {
      final uri = Uri.parse(url);

      final prefs = await SharedPreferences.getInstance();
      final accessToken =
          SaveLoginResponse.loginData?['access_token'] ??
          prefs.getString('access_token') ??
          '';

      final response = await _safeRequest(() {
        return _client.post(
          uri,
          headers: {'Authorization': 'Bearer $accessToken'},
        );
      });

      debugPrint('Patient Accecpt Response URL: $uri');
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Response Body: ${response.body}');

      return _handleResponse(response);
    } catch (error) {
      debugPrint('Patient Accept: $error');
      return {'success': false, 'message': error.toString(), 'data': {}};
    }
  }

  Future<Map<String, dynamic>> createPrescription(
    String url, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final uri = Uri.parse(url);

      final prefs = await SharedPreferences.getInstance();
      final accessToken =
          SaveLoginResponse.loginData?['access_token'] ??
          prefs.getString('access_token') ??
          '';

      final response = await _safeRequest(() {
        return _client.post(
          uri,
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json',
          },
          body: body != null ? jsonEncode(body) : null,
        );
      });
      debugPrint('Create Presecription Response URL: $uri');
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Response Body: ${response.body}');

      return _handleResponse(response);
    } catch (error) {
      debugPrint('Patient Prescription: $error');
      return {'success': false, 'message': error.toString(), 'data': {}};
    }
  }

  Future<Map<String, dynamic>> getLabTestFromServer(String url) async {
    try {
      final uri = Uri.parse(url);
      final response = await _safeRequest(() {
        return _client.get(uri);
      });

      debugPrint('Server Success Response is $response');

      return _handleResponse(response);
    } catch (error) {
      debugPrint('Getting Errir while Laboratory Test');
      return {'success': false, 'message': error.toString(), 'data': {}};
    }
  }

  Future<Map<String, dynamic>> fetchPatientVisitHistory(String url) async {
    try {
      final uri = Uri.parse(url);
      final pref = await SharedPreferences.getInstance();

      final accessToken =
          SaveLoginResponse.loginData?['access_token'] ??
          pref.getString('access_token') ??
          '';

      final response = await _safeRequest(() {
        return _client.get(
          uri,
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json',
          },
        );
      });

      debugPrint('Fetch Visit Patient Api : $uri');
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Response Body: ${response.body}');

      return _handlePatientVisitHistoryResponse(response);
    } catch (error) {
      debugPrint('Patient Prescription: $error');
      return {'success': false, 'message': error.toString(), 'data': {}};
    }
  }

  Future<Map<String, dynamic>> doctorVisitComplete(
    String uri,
    Map<String, dynamic>? body,
  ) async {
    try {
      final parsedUri = Uri.parse(uri);

      final prefs = await SharedPreferences.getInstance();
      final accessToken =
          SaveLoginResponse.loginData?['access_token'] ??
          prefs.getString('access_token') ??
          '';

      final response = await _safeRequest(() {
        return _client.patch(
          parsedUri,
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json',
          },
          body: body != null ? jsonEncode(body) : null,
        );
      });

      debugPrint('POST URL: $parsedUri');
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Response Body: ${response.body}');

      return _handleResponse(response);
    } catch (error) {
      debugPrint('doctorVisitComplete Error: $error');
      return {
        'success': false,
        'message': 'Something went wrong: $error',
        'data': {},
      };
    }
  }

  Future<http.Response> _safeRequest(
    Future<http.Response> Function() request,
  ) async {
    try {
      return await request().timeout(const Duration(minutes: 1));
    } on SocketException {
      // GlobalAlert.show(ApiErrorMessages.noInternet);
      throw ApiException(ApiErrorMessages.noInternet);
    } on TimeoutException {
      // GlobalAlert.show(ApiErrorMessages.timeout);
      throw ApiException(ApiErrorMessages.timeout);
    } catch (_) {
      // GlobalAlert.show(ApiErrorMessages.timeout);
      throw ApiException(ApiErrorMessages.timeout);
    }
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      return {
        "success":
            decoded['success'] ??
            (response.statusCode >= 200 && response.statusCode < 300),
        "code": response.statusCode,
        "message": decoded['message'] ?? '',
        "data": decoded['data'] ?? {},
        "raw": response.body,
      };
    } catch (e) {
      // debugPrint("Error decoding response: $e");
      return {
        "success": false,
        "code": response.statusCode,
        "message": "Invalid JSON",
        "raw": response.body,
        "data": {},
      };
    }
  }

  Map<String, dynamic> _handlePatientVisitHistoryResponse(
    http.Response response,
  ) {
    try {
      final decoded = jsonDecode(response.body);
      return Map<String, dynamic>.from(decoded);
    } catch (e) {
      debugPrint("Error decoding PatientVisitHistory response: $e");
      return {};
    }
  }
}
