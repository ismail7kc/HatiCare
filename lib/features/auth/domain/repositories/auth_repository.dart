import 'package:haticare/features/auth/domain/entities/signup_request.dart';

abstract class AuthRepository {
  Future<void> login({required String email, required String password});
  Future<Map<String, dynamic>> signup({required SignupRequest request});
  Future<void> sendPasswordReset({required String email});
}
