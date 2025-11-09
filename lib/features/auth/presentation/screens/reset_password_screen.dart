import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import 'package:haticare/core/theme/app_colors.dart';
import 'package:haticare/core/widgets/app_primary_button.dart';
import 'package:haticare/core/widgets/app_text_field.dart';
import 'package:haticare/features/auth/domain/exceptions/auth_exceptions.dart';
import 'package:haticare/features/auth/domain/repositories/auth_repository.dart';
import 'package:haticare/features/auth/presentation/screens/login_screen.dart';
import 'package:haticare/features/auth/presentation/widgets/auth_top_bar.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({
    super.key,
    required this.email,
    this.title = 'Reset Password',
    this.illustrationAsset = 'assets/images/reset_password_logo.svg',
  });

  final String email;
  final String title;
  final String illustrationAsset;

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final formKey = GlobalKey<FormState>();
  final otpController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool isSubmitting = false;
  String? errorMessage;

  @override
  void dispose() {
    otpController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      isSubmitting = true;
      errorMessage = null;
    });

    try {
      final authRepository = context.read<AuthRepository>();
      final response = await authRepository.resetPassword(
        email: widget.email,
        otp: otpController.text.trim(),
        newPassword: newPasswordController.text.trim(),
        confirmPassword: confirmPasswordController.text.trim(),
      );

      if (!mounted) return;
      
      setState(() => isSubmitting = false);

      // Extract success message
      String successMessage = 'Password reset successfully';
      if (response['message'] is String) {
        successMessage = response['message'] as String;
      } else if (response['detail'] is String) {
        successMessage = response['detail'] as String;
      }

      // Show success dialog
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 28,
                ),
                SizedBox(width: 12),
                Text(
                  'Success',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            content: Text(
              successMessage,
              style: const TextStyle(
                fontSize: 16,
                height: 1.5,
              ),
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(dialogContext),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'OK',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          );
        },
      );

      if (!mounted) return;

      // Navigate to login screen
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );

      // Show success snackbar
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password reset successfully'),
            backgroundColor: Color(0xFF29A671),
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;
      
      setState(() => isSubmitting = false);

      String errorMsg = 'Password reset failed';
      if (error is AuthApiException) {
        errorMsg = error.message;
      }

      // Show error dialog
      await showDialog(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 28,
                ),
                SizedBox(width: 12),
                Text(
                  'Failed',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            content: Text(
              errorMsg,
              style: const TextStyle(
                fontSize: 16,
                height: 1.5,
              ),
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(dialogContext),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'OK',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          );
        },
      );
    }
  }

  String? _validateOtp(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter OTP';
    }
    if (value.length != 6) {
      return 'OTP must be 6 digits';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your new password';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    final validation = _validatePassword(value);
    if (validation != null) {
      return validation;
    }
    if (value != newPasswordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final viewInsets = MediaQuery.of(context).viewInsets;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: AuthTopBar(
                title: widget.title,
                onBackPressed: () => Navigator.of(context).maybePop(),
              ),
            ),
            Expanded(
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: widget.illustrationAsset.endsWith('.svg')
                            ? SvgPicture.asset(
                                widget.illustrationAsset,
                                height: 180,
                              )
                            : Image.asset(
                                widget.illustrationAsset,
                                height: 180,
                              ),
                      ),
                      Text(
                        'Reset Your Password',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Enter the OTP sent to your email and your new password.',
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'OTP*',
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF6C7278),
                        ),
                      ),
                      const SizedBox(height: 8),
                      AppTextField(
                        controller: otpController,
                        label: 'OTP*',
                        hint: 'Enter 6-digit OTP',
                        keyboardType: TextInputType.number,
                        prefixIcon: const Icon(Icons.security),
                        validator: _validateOtp,
                        maxLength: 6,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'New Password*',
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF6C7278),
                        ),
                      ),
                      const SizedBox(height: 8),
                      AppTextField(
                        controller: newPasswordController,
                        label: 'New Password*',
                        hint: 'Enter your new password',
                        obscureText: true,
                        enableObscureToggle: true,
                        validator: _validatePassword,
                        keyboardType: TextInputType.visiblePassword,
                        autofillHints: const [AutofillHints.newPassword],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Confirm New Password*',
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF6C7278),
                        ),
                      ),
                      const SizedBox(height: 8),
                      AppTextField(
                        controller: confirmPasswordController,
                        label: 'Confirm New Password*',
                        hint: 'Re-enter your password',
                        obscureText: true,
                        enableObscureToggle: true,
                        validator: _validateConfirmPassword,
                        keyboardType: TextInputType.visiblePassword,
                        autofillHints: const [AutofillHints.newPassword],
                      ),
                      if (errorMessage != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          errorMessage!,
                          style: textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      SizedBox(height: viewInsets.bottom > 0 ? 24 : 48),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: AppPrimaryButton(
                label: 'Update Password',
                onPressed: isSubmitting ? null : _handleSubmit,
                isLoading: isSubmitting,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
