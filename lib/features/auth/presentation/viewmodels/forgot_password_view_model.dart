import 'package:flutter/material.dart';

import 'package:haticare/features/auth/domain/exceptions/auth_exceptions.dart';
import 'package:haticare/features/auth/domain/repositories/auth_repository.dart';

class ForgotPasswordViewModel extends ChangeNotifier {
  ForgotPasswordViewModel(this._repository, {String? initialEmail})
      : emailController = TextEditingController(text: initialEmail) {
    _setupEmailListener();
  }

  final AuthRepository _repository;

  final formKey = GlobalKey<FormState>();
  final TextEditingController emailController;

  bool isSubmitting = false;
  String? errorMessage;
  String? successMessage;
  bool _shouldNavigateToOtp = false;
  bool _showValidation = false;

  void _setupEmailListener() {
    emailController.addListener(_onEmailChanged);
  }

  void _onEmailChanged() {
    // If error is showing and user types a valid email, clear the error
    if (errorMessage != null) {
      final validationError = validateEmail(emailController.text);
      if (validationError == null) {
        errorMessage = null;
        notifyListeners();
      }
    }
  }

  bool get shouldNavigateToOtp => _shouldNavigateToOtp;

  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^\S+@\S+\.\S+$');
    if (!emailRegex.hasMatch(value)) {
      return 'Enter a valid email';
    }
    return null;
  }

  Future<void> submit() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    isSubmitting = true;
    errorMessage = null;
    successMessage = null;
    _shouldNavigateToOtp = false;
    notifyListeners();

    try {
      final response = await _repository.forgotPassword(
        email: emailController.text.trim(),
      );
      
      successMessage = _extractMessage(response) ?? 'OTP sent to your email';
      _shouldNavigateToOtp = true;
    } catch (error) {
      if (error is AuthApiException) {
        errorMessage = error.message;
      } else {
        errorMessage = 'Something went wrong. Please try again.';
      }
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }

  void markNavigationHandled() {
    _shouldNavigateToOtp = false;
    notifyListeners();
  }

  void clearError() {
    if (errorMessage != null) {
      errorMessage = null;
      notifyListeners();
    }
  }

  String? _extractMessage(Map<String, dynamic> response) {
    if (response['message'] is String) return response['message'] as String;
    if (response['detail'] is String) return response['detail'] as String;
    return null;
  }

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }
}
