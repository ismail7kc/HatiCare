import 'dart:async';

import 'auth_api_service.dart';
import 'package:haticare/features/auth/domain/entities/signup_request.dart';

class MockAuthApiService implements AuthApiService {
  @override
  Future<void> login({required String email, required String password}) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
  }

  @override
  Future<Map<String, dynamic>> signup({required SignupRequest request}) async {
    await Future<void>.delayed(const Duration(milliseconds: 800));
    return {'status': 'success'};
  }

  @override
  Future<void> sendPasswordReset({required String email}) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
  }

  @override
  Future<Map<String, dynamic>> generateOtp({required String email}) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    return {'status': 'success', 'message': 'OTP sent successfully'};
  }

  @override
  Future<Map<String, dynamic>> doctorSignupWithOtp({
    required SignupRequest request,
    required String otp,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 800));
    return {'status': 'success', 'message': 'Doctor registered successfully'};
  }

  @override
  Future<Map<String, dynamic>> pharmacySignupWithOtp({
    required SignupRequest request,
    required String otp,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 800));
    return {'status': 'success', 'message': 'Pharmacy registered successfully'};
  }

  void dispose() {}
}
