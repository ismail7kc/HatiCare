import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pinput/pinput.dart';
import 'package:provider/provider.dart';

import 'package:haticare/core/theme/app_colors.dart';
import 'package:haticare/core/widgets/app_primary_button.dart';
import 'package:haticare/features/auth/domain/entities/signup_request.dart';
import 'package:haticare/features/auth/domain/entities/user_role.dart';
import 'package:haticare/features/auth/domain/exceptions/auth_exceptions.dart';
import 'package:haticare/features/auth/domain/repositories/auth_repository.dart';
import 'package:haticare/features/auth/presentation/screens/login_screen.dart';
import 'package:haticare/features/auth/presentation/widgets/auth_top_bar.dart';

class UnifiedOtpVerificationScreen extends StatefulWidget {
  const UnifiedOtpVerificationScreen({
    super.key,
    required this.email,
    required this.signupRequest,
  });

  final String email;
  final SignupRequest signupRequest;

  @override
  State<UnifiedOtpVerificationScreen> createState() =>
      _UnifiedOtpVerificationScreenState();
}

class _UnifiedOtpVerificationScreenState
    extends State<UnifiedOtpVerificationScreen> {
  static const int _resendDelaySeconds = 300;

  final pinController = TextEditingController();
  final focusNode = FocusNode();

  bool isLoading = false;
  bool canResend = false;
  int _remainingSeconds = _resendDelaySeconds;
  Timer? _timer;

  late final PinTheme defaultPinTheme = PinTheme(
    width: 64,
    height: 64,
    textStyle: const TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    ),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(32),
      border: Border.all(color: const Color(0xFFE2E5EE)),
      color: Colors.white,
    ),
  );

  bool get isDoctor => widget.signupRequest.role == UserRole.doctor;
  bool get isPharmacy => widget.signupRequest.role == UserRole.pharmacy;
  bool get isLaboratory => widget.signupRequest.role == UserRole.laboratory;

  String get roleTitle {
    if (isDoctor) return 'Doctor';
    if (isPharmacy) return 'Pharmacy';
    return 'Laboratory';
  }

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  @override
  void dispose() {
    pinController.dispose();
    focusNode.dispose();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> verifyOtpAndSignup() async {
    if (pinController.text.length != 6) {
      _showSnackBar('Please enter a 6-digit OTP', isError: true);
      return;
    }

    setState(() => isLoading = true);

    try {
      final repository = context.read<AuthRepository>();
      

      Map<String, dynamic> response;
      if (isDoctor) {
        response = await repository.doctorSignupWithOtp(
          request: widget.signupRequest,
          otp: pinController.text,
        );
      } else if (isPharmacy) {
        response = await repository.pharmacySignupWithOtp(
          request: widget.signupRequest,
          otp: pinController.text,
        );
      } else {
        // Laboratory
        response = await repository.laboratorySignupWithOtp(
          request: widget.signupRequest,
          otp: pinController.text,
        );
      }

      if (!mounted) return;

      setState(() => isLoading = false);

      final successMessage =
          _successMessageFromResponse(response) ?? 'Account registered successfully.';

      final dialogConfirmed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          final textTheme = Theme.of(dialogContext).textTheme;
          return AlertDialog(
            title: Text(
              isDoctor ? 'Doctor Registration Successful' : 'Pharmacy Registration Successful',
              style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            content: Text(successMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );

      if (dialogConfirmed != true || !mounted) {
        return;
      }

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => isLoading = false);

      String message = 'OTP verification failed';
      if (error is AuthApiException) {
        message = error.message;
      }
      
      // Show error dialog
      await showDialog(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 28,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Verification Failed',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            content: Text(
              message,
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

  Future<void> _resendOtp() async {
    if (!canResend) return;

    setState(() => canResend = false);

    try {
      final repository = context.read<AuthRepository>();
      await repository.generateOtp(email: widget.email);

      if (!mounted) return;

      _showSnackBar('OTP resent successfully', isError: false);
      _startResendTimer();
    } catch (error) {
      if (!mounted) return;
      setState(() => canResend = true);

      String message = 'Failed to resend OTP';
      if (error is AuthApiException) {
        message = error.message;
      }
      _showSnackBar(message, isError: true);
    }
  }

  void _startResendTimer() {
    _timer?.cancel();
    setState(() {
      canResend = false;
      _remainingSeconds = _resendDelaySeconds;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_remainingSeconds <= 1) {
        timer.cancel();
        setState(() {
          canResend = true;
          _remainingSeconds = 0;
        });
      } else {
        setState(() => _remainingSeconds--);
      }
    });
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : const Color(0xFF29A671),
      ),
    );
  }

  String? _successMessageFromResponse(Map<String, dynamic> response) {
    if (response['message'] is String) {
      return response['message'] as String;
    }
    if (response['detail'] is String) {
      return response['detail'] as String;
    }
    if (response['status'] is String) {
      return response['status'] as String;
    }
    return null;
  }

  String _formatRemaining() {
    final minutes = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: AuthTopBar(
                title: '$roleTitle OTP Verification',
                onBackPressed: () => Navigator.of(context).maybePop(),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Verification code',
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Please enter the OTP sent to ${widget.email}',
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Pinput(
                      length: 6,
                      controller: pinController,
                      focusNode: focusNode,
                      defaultPinTheme: defaultPinTheme,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(6),
                      ],
                      autofocus: true,
                      separatorBuilder: (index) => const SizedBox(width: 12),
                    ),
                    const SizedBox(height: 28),
                    _ResendRow(
                      canResend: canResend,
                      onPressed: _resendOtp,
                      formattedTime: _formatRemaining(),
                    ),
                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: AppPrimaryButton(
                label: 'Continue',
                onPressed: isLoading ? null : verifyOtpAndSignup,
                isLoading: isLoading,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResendRow extends StatelessWidget {
  const _ResendRow({
    required this.canResend,
    required this.onPressed,
    required this.formattedTime,
  });

  final bool canResend;
  final VoidCallback onPressed;
  final String formattedTime;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        Text(
          "Didn't receive any code?",
          style: textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        TextButton(
          onPressed: canResend ? onPressed : null,
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            foregroundColor: const Color(0xFF0E7CC0),
          ),
          child: Text(
            canResend ? 'Resend code' : 'Resend code in $formattedTime',
            style: textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
