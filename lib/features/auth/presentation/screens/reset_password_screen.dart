import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:haticare/core/theme/app_colors.dart';
import 'package:haticare/core/widgets/app_primary_button.dart';
import 'package:haticare/core/widgets/app_text_field.dart';
import 'package:haticare/features/auth/presentation/widgets/auth_top_bar.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({
    super.key,
    this.onSubmit,
    this.title = 'Reset Password',
    this.illustrationAsset = 'assets/images/reset_password_logo.svg',
  });

  final Future<void> Function(String newPassword)? onSubmit;
  final String title;
  final String illustrationAsset;

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final formKey = GlobalKey<FormState>();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool isSubmitting = false;
  String? errorMessage;

  @override
  void dispose() {
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    if (widget.onSubmit == null) {
      Navigator.of(context).maybePop();
      return;
    }

    setState(() {
      isSubmitting = true;
      errorMessage = null;
    });

    try {
      await widget.onSubmit!(newPasswordController.text.trim());
      if (!mounted) return;
      Navigator.of(context).maybePop();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        errorMessage = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() => isSubmitting = false);
      }
    }
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
                        'Enter New Password',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Enter your new password and don\'t share with anyone.',
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 24),
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
