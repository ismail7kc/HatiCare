import 'package:haticare/features/auth/domain/entities/signup_request.dart';

abstract class AuthRepository {
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    required String deviceId,
  });
  Future<Map<String, dynamic>> signup({required SignupRequest request});
  Future<void> sendPasswordReset({required String email});
  Future<Map<String, dynamic>> generateOtp({required String email});
  Future<Map<String, dynamic>> doctorSignupWithOtp({
    required SignupRequest request,
    required String otp,
  });
  Future<Map<String, dynamic>> pharmacySignupWithOtp({
    required SignupRequest request,
    required String otp,
  });
  Future<Map<String, dynamic>> laboratorySignupWithOtp({
    required SignupRequest request,
    required String otp,
  });
  Future<Map<String, dynamic>> forgotPassword({required String email});
  Future<Map<String, dynamic>> verifyResetPasswordOtp({
    required String email,
    required String otp,
  });
  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
    required String confirmPassword,
  });
  Future<Map<String, dynamic>> logout({
    required String deviceId,
    required String refreshToken,
  });
}
