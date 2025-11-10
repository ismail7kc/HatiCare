import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:haticare/core/theme/app_colors.dart';
import 'package:haticare/core/widgets/app_primary_button.dart';
import 'package:haticare/core/widgets/app_text_field.dart';
import 'package:haticare/features/auth/domain/repositories/auth_repository.dart';
import 'package:haticare/features/auth/presentation/screens/reset_password_screen.dart';
import 'package:haticare/features/auth/presentation/viewmodels/forgot_password_view_model.dart';
import 'package:haticare/features/auth/presentation/widgets/auth_top_bar.dart';

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key, this.prefilledEmail});

  final String? prefilledEmail;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ForgotPasswordViewModel>(
      create: (context) => ForgotPasswordViewModel(
        context.read<AuthRepository>(),
        initialEmail: prefilledEmail,
      ),
      child: const _ForgotPasswordView(),
    );
  }
}

class _ForgotPasswordView extends StatelessWidget {
  const _ForgotPasswordView();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ForgotPasswordViewModel>();
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    // Show success dialog and navigate to reset password screen
    if (viewModel.shouldNavigateToOtp) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (context.mounted) {
          viewModel.markNavigationHandled();
          
          // Show success dialog
          final shouldNavigate = await showDialog<bool>(
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
                      'OTP Sent',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                content: Text(
                  viewModel.successMessage ?? 'OTP has been sent to your email',
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
                actions: [
                  ElevatedButton(
                    onPressed: () => Navigator.pop(dialogContext, true),
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
                      'Continue',
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

          if (shouldNavigate == true && context.mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ResetPasswordScreen(
                  email: viewModel.emailController.text.trim(),
                ),
              ),
            );
          }
        }
      });
    }

    // Show error dialog
    if (viewModel.errorMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (context.mounted) {
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
                  viewModel.errorMessage!,
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
          viewModel.clearError();
        }
      });
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: AuthTopBar(
                title: 'Forgot Password',
                onBackPressed: () => Navigator.of(context).maybePop(),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Form(
                  key: viewModel.formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                        Center(
                          child: SvgPicture.asset(
                            'assets/images/forgot_password_logo.svg',
                            height: 200,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Forgot password?',
                          style: textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Don’t worry. Please enter your email details which we may use to reset your password.',
                          style: textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Email',
                          style: textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF6C7278),
                          ),
                        ),
                        const SizedBox(height: 8),
                        AppTextField(
                          controller: viewModel.emailController,
                          label: 'Email',
                          hint: 'Enter Your Email Here',
                          keyboardType: TextInputType.emailAddress,
                          prefixIcon: const Icon(Icons.email_outlined),
                          autofillHints: const [AutofillHints.email],
                          validator: viewModel.validateEmail,
                        ),
                        if (viewModel.errorMessage != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            viewModel.errorMessage!,
                            style: textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        if (viewModel.successMessage != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.check_circle, color: AppColors.primary),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    viewModel.successMessage!,
                                    style: textTheme.bodySmall?.copyWith(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                      const SizedBox(height: 24),
                      AppPrimaryButton(
                        label: 'Continue',
                        onPressed: viewModel.isSubmitting ? null : viewModel.submit,
                        isLoading: viewModel.isSubmitting,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
