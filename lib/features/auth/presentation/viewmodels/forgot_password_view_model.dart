import 'package:flutter/material.dart';

import 'package:haticare/features/auth/domain/repositories/auth_repository.dart';

class ForgotPasswordViewModel extends ChangeNotifier {
  ForgotPasswordViewModel(this._repository, {String? initialEmail})
      : emailController = TextEditingController(text: initialEmail);

  final AuthRepository _repository;

  final formKey = GlobalKey<FormState>();
  final TextEditingController emailController;

  bool isSubmitting = false;
  String? errorMessage;
  String? successMessage;

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
    notifyListeners();

    try {
      await _repository.sendPasswordReset(
        email: emailController.text.trim(),
      );
      successMessage =
          'If the email exists, a reset link has been sent to your inbox.';
    } catch (_) {
      errorMessage = 'Something went wrong. Please try again.';
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }
}
