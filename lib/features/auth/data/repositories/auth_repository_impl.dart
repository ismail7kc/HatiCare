import 'package:haticare/features/auth/data/services/auth_api_service.dart';
import 'package:haticare/features/auth/domain/entities/signup_request.dart';
import 'package:haticare/features/auth/domain/exceptions/auth_exceptions.dart';
import 'package:haticare/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._apiService);

  final AuthApiService _apiService;

  @override
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    required String deviceId,
  }) {
    return _apiService.login(
      email: email,
      password: password,
      deviceId: deviceId,
    );
  }

  @override
  Future<Map<String, dynamic>> signup({required SignupRequest request}) async {
    if (request.confirmPassword != null &&
        request.password != request.confirmPassword) {
      throw const PasswordMismatchException();
    }
    return await _apiService.signup(request: request);
  }

  @override
  Future<void> sendPasswordReset({required String email}) {
    return _apiService.sendPasswordReset(email: email);
  }

  @override
  Future<Map<String, dynamic>> generateOtp({required String email}) {
    return _apiService.generateOtp(email: email);
  }

  @override
  Future<Map<String, dynamic>> doctorSignupWithOtp({
    required SignupRequest request,
    required String otp,
  }) async {
    if (request.confirmPassword != null &&
        request.password != request.confirmPassword) {
      throw const PasswordMismatchException();
    }
    return await _apiService.doctorSignupWithOtp(request: request, otp: otp);
  }

  @override
  Future<Map<String, dynamic>> pharmacySignupWithOtp({
    required SignupRequest request,
    required String otp,
  }) async {
    if (request.confirmPassword != null &&
        request.password != request.confirmPassword) {
      throw const PasswordMismatchException();
    }
    return await _apiService.pharmacySignupWithOtp(request: request, otp: otp);
  }

  @override
  Future<Map<String, dynamic>> forgotPassword({required String email}) {
    return _apiService.forgotPassword(email: email);
  }

  @override
  Future<Map<String, dynamic>> verifyResetPasswordOtp({
    required String email,
    required String otp,
  }) {
    return _apiService.verifyResetPasswordOtp(email: email, otp: otp);
  }

  @override
  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
    required String confirmPassword,
  }) {
    return _apiService.resetPassword(
      email: email,
      otp: otp,
      newPassword: newPassword,
      confirmPassword: confirmPassword,
    );
  }

  @override
  Future<Map<String, dynamic>> logout({
    required String deviceId,
    required String refreshToken,
  }) {
    return _apiService.logout(
      deviceId: deviceId,
      refreshToken: refreshToken,
    );
  }
}
