import 'dart:convert';

import 'package:chucker_flutter/chucker_flutter.dart';
import 'package:http/http.dart' as http;

import 'package:haticare/core/config/app_config.dart';
import 'package:haticare/features/auth/data/services/auth_api_service.dart';
import 'package:haticare/features/auth/domain/entities/signup_request.dart';
import 'package:haticare/features/auth/domain/entities/user_role.dart';
import 'package:haticare/features/auth/domain/exceptions/auth_exceptions.dart';

class RemoteAuthApiService implements AuthApiService {
  RemoteAuthApiService({http.Client? client})
      : _client = client ?? ChuckerHttpClient(http.Client());

  final http.Client _client;

  @override
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    required String deviceId,
  }) async {
    final uri = Uri.parse('${AppConfig.baseUrl}/users/login/');
    final response = await _client.post(
      uri,
      headers: const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'email': email,
        'password': password,
        'device_id': deviceId,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AuthApiException(
        _extractErrorMessage(response.body) ?? 'Login failed',
        statusCode: response.statusCode,
      );
    }

    final decoded = _decodeJson(response.body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    return {'status': 'success'};
  }

  @override
  Future<Map<String, dynamic>> signup({required SignupRequest request}) async {
    final endpoint = _endpointForRole(request.role);
    final uri = Uri.parse('${AppConfig.baseUrl}/$endpoint');
    final body = jsonEncode(request.toJson());
    final response = await _client.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: body,
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AuthApiException(
        _extractErrorMessage(response.body) ?? 'Signup failed',
        statusCode: response.statusCode,
      );
    }

    final decoded = _decodeJson(response.body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    return {'status': 'success'};
  }

  @override
  Future<void> sendPasswordReset({required String email}) async {
    // TODO: Implement real password reset endpoint
    await Future<void>.delayed(const Duration(milliseconds: 500));
  }

  @override
  Future<Map<String, dynamic>> generateOtp({required String email}) async {
    final uri = Uri.parse('${AppConfig.baseUrl}/users/generate-otp/');
    final response = await _client.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({'email': email}),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AuthApiException(
        _extractErrorMessage(response.body) ?? 'Failed to generate OTP',
        statusCode: response.statusCode,
      );
    }

    final decoded = _decodeJson(response.body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    return {'status': 'success', 'message': 'OTP sent successfully'};
  }

  @override
  Future<Map<String, dynamic>> doctorSignupWithOtp({
    required SignupRequest request,
    required String otp,
  }) async {
    final uri = Uri.parse('${AppConfig.baseUrl}/users/doctor/signup/');
    final requestData = request.toJson();
    requestData['otp'] = otp;

    final multipartRequest = http.MultipartRequest('POST', uri)
      ..headers['Accept'] = 'application/json';

    final licensePath = request.licenseDocumentPath;
    requestData.forEach((key, value) {
      if (value == null) return;
      if (key == 'license_document') return;
      multipartRequest.fields[key] = value.toString();
    });

    if (licensePath != null && licensePath.isNotEmpty) {
      multipartRequest.files.add(
        await http.MultipartFile.fromPath('license_document', licensePath),
      );
    }

    final streamedResponse = await _client.send(multipartRequest);
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AuthApiException(
        _extractErrorMessage(response.body) ?? 'Doctor signup failed',
        statusCode: response.statusCode,
      );
    }

    final decoded = _decodeJson(response.body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    return {'status': 'success', 'message': 'Doctor registered successfully'};
  }

  @override
  Future<Map<String, dynamic>> pharmacySignupWithOtp({
    required SignupRequest request,
    required String otp,
  }) async {
    final uri = Uri.parse('${AppConfig.baseUrl}/users/pharmacy/signup/');
    final requestData = request.toJson();
    requestData['otp'] = otp;

    final multipartRequest = http.MultipartRequest('POST', uri)
      ..headers['Accept'] = 'application/json';

    final documentPath = request.pharmacyLicenseDocumentPath;
    requestData.forEach((key, value) {
      if (value == null) return;
      if (key == 'license_document') return;
      multipartRequest.fields[key] = value.toString();
    });

    if (documentPath != null && documentPath.isNotEmpty) {
      multipartRequest.files.add(
        await http.MultipartFile.fromPath('license_document', documentPath),
      );
    }

    final streamedResponse = await _client.send(multipartRequest);
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AuthApiException(
        _extractErrorMessage(response.body) ?? 'Pharmacy signup failed',
        statusCode: response.statusCode,
      );
    }

    final decoded = _decodeJson(response.body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    return {'status': 'success', 'message': 'Pharmacy registered successfully'};
  }

  void dispose() {
    _client.close();
  }

  String _endpointForRole(UserRole role) {
    switch (role) {
      case UserRole.doctor:
        return 'users/signup/doctor/';
      case UserRole.pharmacy:
        return 'users/signup/pharmacy/';
    }
  }

  dynamic _decodeJson(String source) {
    if (source.isEmpty) return null;
    try {
      return jsonDecode(source);
    } catch (_) {
      return null;
    }
  }

  String? _extractErrorMessage(String source) {
    final decoded = _decodeJson(source);
    if (decoded is Map<String, dynamic>) {
      if (decoded['message'] is String) return decoded['message'] as String;
      if (decoded['detail'] is String) return decoded['detail'] as String;
      if (decoded['error'] is String) return decoded['error'] as String;
    }
    return null;
  }
}
