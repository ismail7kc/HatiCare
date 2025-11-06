import 'package:flutter/material.dart';

import 'package:haticare/core/services/device_id_provider.dart';
import 'package:haticare/features/auth/domain/exceptions/auth_exceptions.dart';
import 'package:haticare/features/auth/domain/repositories/auth_repository.dart';

class LoginViewModel extends ChangeNotifier {
  LoginViewModel(this._repository);

  final AuthRepository _repository;

  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool rememberMe = false;
  bool isSubmitting = false;
  String? errorMessage;
  String? dialogMessage;
  Map<String, dynamic>? _lastResponse;
  bool _shouldNavigate = false;
  bool _shouldAutovalidate = false;

  void markNavigationHandled() {
    if (_shouldNavigate) {
      _shouldNavigate = false;
      notifyListeners();
    }
  }

  void toggleRememberMe(bool? value) {
    rememberMe = value ?? false;
    notifyListeners();
  }

  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    final emailRegex = RegExp(r'^\S+@\S+\.\S+$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    return null;
  }

  Future<void> submit() async {
    _shouldAutovalidate = true;
    notifyListeners();

    if (!formKey.currentState!.validate()) {
      return;
    }

    isSubmitting = true;
    errorMessage = null;
    dialogMessage = null;
    _lastResponse = null;
    _shouldNavigate = false;
    notifyListeners();

    try {
      final deviceId = await DeviceIdProvider().getDeviceId();
      _lastResponse = await _repository.login(
        email: emailController.text.trim(),
        password: passwordController.text,
        deviceId: deviceId,
      );
      _shouldNavigate = true;
    } on AuthApiException catch (error) {
      final message = error.message;
      dialogMessage = message.isNotEmpty
          ? message
          : 'Login failed. Please try again.';
      errorMessage = null;
      _shouldNavigate = false;
      _lastResponse = null;
    } catch (_) {
      errorMessage = 'Login failed. Please try again.';
      _shouldNavigate = false;
      _lastResponse = null;
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }

  Map<String, dynamic>? get lastResponse => _lastResponse;

  bool get shouldNavigate => _shouldNavigate;
  bool get shouldAutovalidate => _shouldAutovalidate;

  String? get roleFromResponse {
    final response = _lastResponse;
    if (response == null) return null;
    final data = response['data'];
    if (data is Map<String, dynamic>) {
      final role = data['role'] ?? data['type'];
      if (role is String) return role.toLowerCase();
    }
    final role = response['role'] ?? response['user_role'] ?? response['type'];
    return role is String ? role.toLowerCase() : null;
  }

  void clearDialogMessage() {
    if (dialogMessage != null) {
      dialogMessage = null;
      notifyListeners();
    }
  }

  void resetAutovalidate() {
    if (_shouldAutovalidate) {
      _shouldAutovalidate = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
