import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:haticare/core/theme/app_colors.dart';
import 'package:haticare/core/widgets/app_primary_button.dart';
import 'package:haticare/core/widgets/app_text_field.dart';
import 'package:haticare/features/auth/domain/repositories/auth_repository.dart';
import 'package:haticare/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:haticare/features/auth/presentation/screens/signup_screen.dart';
import 'package:haticare/features/auth/presentation/viewmodels/login_view_model.dart';
import 'package:haticare/features/pharmacy/presentation/screens/pharmacy_home_screen.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';
import 'package:haticare/features/doctor/presentation/screens/doctor_home_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<LoginViewModel>(
      create: (context) => LoginViewModel(context.read<AuthRepository>()),
      child: const _LoginView(),
    );
  }
}

class _LoginView extends StatelessWidget {
  const _LoginView();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<LoginViewModel>();
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    if (viewModel.shouldNavigate) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;

        final role = viewModel.roleFromResponse;
        if (role == 'doctor') {
          PersistentNavBarNavigator.pushNewScreen(
            context,
            screen: DoctorHomeScreen(),
            withNavBar: false,
            pageTransitionAnimation: PageTransitionAnimation.cupertino,
          );
        } else if (role == 'pharmacy') {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const PharmacyHomeScreen()),
            (route) => false,
          );
        } else {
          PersistentNavBarNavigator.pushNewScreen(
            context,
            screen: DoctorHomeScreen(),
            withNavBar: false,
            pageTransitionAnimation: PageTransitionAnimation.cupertino,
          );
        }

        viewModel.markNavigationHandled();
      });
    }

    if (viewModel.dialogMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          showDialog<void>(
            context: context,
            barrierDismissible: false,
            builder: (dialogContext) {
              return AlertDialog(
                title: const Text('Account Deactivated'),
                content: Text(viewModel.dialogMessage!),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                      viewModel.clearDialogMessage();
                    },
                    child: const Text('OK'),
                  ),
                ],
              );
            },
          );
        }
      });
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Align(
            alignment: Alignment.topCenter,
            child: Form(
              key: viewModel.formKey,
              autovalidateMode: AutovalidateMode.disabled,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 24),
                    Text(
                      'Login to Your Account',
                      style: textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Please provide your login credentials to continue',
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
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
                    const SizedBox(height: 6),
                    AppTextField(
                      controller: viewModel.emailController,
                      keyboardType: TextInputType.emailAddress,
                      label: 'Email',
                      hint: 'Enter Your Email',
                      prefixIcon: const Icon(Icons.email_outlined),
                      validator: viewModel.validateEmail,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Password',
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF6C7278),
                      ),
                    ),
                    const SizedBox(height: 6),
                    AppTextField(
                      controller: viewModel.passwordController,
                      label: 'Password',
                      hint: 'Enter Your Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      obscureText: true,
                      enableObscureToggle: true,
                      validator: viewModel.validatePassword,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        SizedBox(
                          height: 24,
                          width: 24,
                          child: Checkbox(
                            value: viewModel.rememberMe,
                            onChanged: viewModel.isSubmitting
                                ? null
                                : viewModel.toggleRememberMe,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text('Remember me'),
                        const Spacer(),
                        TextButton(
                          onPressed: viewModel.isSubmitting
                              ? null
                              : () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const ForgotPasswordScreen(),
                                    ),
                                  );
                                },
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            padding: EdgeInsets.zero,
                          ),
                          child: const Text('Forgot Password ?'),
                        ),
                      ],
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
                    const SizedBox(height: 24),
                    AppPrimaryButton(
                      label: 'Log In',
                      onPressed: viewModel.isSubmitting
                          ? null
                          : viewModel.submit,
                      isLoading: viewModel.isSubmitting,
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Text.rich(
                        TextSpan(
                          text: "Don't have an account? ",
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          children: [
                            TextSpan(
                              text: 'Create an account',
                              style: TextStyle(
                                color: viewModel.isSubmitting
                                    ? Colors.grey
                                    : AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const SignupScreen(),
                                    ),
                                  );
                                },
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
