import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:pinput/pinput.dart';

import 'package:haticare/core/theme/app_colors.dart';
import 'package:haticare/core/widgets/app_primary_button.dart';
import 'package:haticare/features/auth/presentation/screens/login_screen.dart';

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({
    super.key,
    required this.email,
    required this.apiUrl,
    this.title = 'OTP Verification',
    this.successMessage = 'OTP verified successfully!',
    this.isForReset = true,
    this.resendApiUrl,
    this.userId,
  });

  final String email;
  final Uri apiUrl;
  final String title;
  final String successMessage;
  final bool isForReset;
  final Uri? resendApiUrl;
  final int? userId;

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  static const int _resendDelaySeconds = 300;

  final pinController = TextEditingController();
  final focusNode = FocusNode();

  bool isLoading = false;
  bool canResend = false;
  int _remainingSeconds = _resendDelaySeconds;
  Timer? _timer;

  late final PinTheme defaultPinTheme = PinTheme(
    width: 56,
    height: 60,
    textStyle: const TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    ),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE0E3EA)),
      color: Colors.white,
      boxShadow: const [
        BoxShadow(
          color: Color(0x11000000),
          blurRadius: 10,
          offset: Offset(0, 4),
        ),
      ],
    ),
  );

  @override
  void initState() {
    super.initState();
    if (widget.resendApiUrl != null) {
      _startResendTimer();
      if (!widget.isForReset) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _resendOtp(force: true));
      }
    }
  }

  @override
  void dispose() {
    pinController.dispose();
    focusNode.dispose();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> verifyOtp() async {
    if (pinController.text.length != 4) {
      _showSnackBar('Please enter a 4-digit OTP');
      return;
    }

    setState(() => isLoading = true);

    try {
      final response = await http.post(
        widget.apiUrl,
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': widget.email,
          'otp': pinController.text,
        }),
      );

      setState(() => isLoading = false);

      if (!mounted) return;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        await _showSuccessDialog();
      } else {
        final message = _readErrorMessage(response.body) ?? 'OTP verification failed';
        _showSnackBar(message);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => isLoading = false);
      _showSnackBar('Network error: $error');
    }
  }

  Future<void> _showSuccessDialog() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Success'),
        content: Text(widget.successMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );

    if (!mounted) return;

    if (widget.isForReset) {
      // TODO: Navigate to reset password screen when implemented
      Navigator.pop(context);
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      );

      await Future<void>.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;

      showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Account Activated'),
          content: const Text('Your account has been successfully activated!'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _resendOtp({bool force = false}) async {
    if ((!canResend && !force) || widget.resendApiUrl == null) {
      return;
    }

    setState(() => canResend = false);

    try {
      final payload = <String, dynamic>{'email': widget.email};
      if (widget.userId != null) {
        payload['user_id'] = widget.userId;
      }

      final response = await http.post(
        widget.resendApiUrl!,
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      final ok = response.statusCode >= 200 && response.statusCode < 300;
      final message = _readErrorMessage(response.body) ??
          (ok ? 'OTP resent successfully' : 'Failed to resend OTP');

      if (!mounted) return;

      _showSnackBar(
        message,
        backgroundColor: ok ? const Color(0xFF29A671) : Colors.redAccent,
      );

      if (ok) {
        _startResendTimer();
      } else {
        setState(() => canResend = true);
      }
    } catch (error) {
      if (!mounted) return;
      _showSnackBar('Network error: $error');
      setState(() => canResend = true);
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

  String? _readErrorMessage(String body) {
    if (body.isEmpty) return null;
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final value = decoded['message'] ?? decoded['detail'] ?? decoded['error'];
        if (value is String && value.isNotEmpty) {
          return value;
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  void _showSnackBar(String message, {Color backgroundColor = AppColors.primary}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: backgroundColor),
    );
  }

  String _formatRemaining() {
    final minutes = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        centerTitle: true,
        title: Text(
          widget.title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 40,
            bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SvgPicture.asset(
                'assets/images/forgot_password_logo.svg',
                height: 160,
              ),
              const SizedBox(height: 32),
              Text(
                'Enter OTP',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please enter the 4-digit OTP sent to ${widget.email}.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 32),
              Pinput(
                length: 4,
                controller: pinController,
                focusNode: focusNode,
                defaultPinTheme: defaultPinTheme,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
                autofocus: true,
              ),
              const SizedBox(height: 32),
              AppPrimaryButton(
                label: 'Verify OTP',
                onPressed: isLoading ? null : verifyOtp,
                isLoading: isLoading,
              ),
              const SizedBox(height: 16),
              if (widget.resendApiUrl != null) _ResendRow(
                canResend: canResend,
                onPressed: () => _resendOtp(),
                formattedTime: _formatRemaining(),
              ),
            ],
          ),
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          canResend
              ? 'You can resend the OTP now.'
              : 'Resend available in $formattedTime',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        const SizedBox(width: 8),
        TextButton(
          onPressed: canResend ? onPressed : null,
          child: const Text('Resend OTP'),
        ),
      ],
    );
  }
}
