import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:pinput/pinput.dart';
import 'package:haticare/core/theme/app_colors.dart';
import 'package:haticare/core/widgets/app_primary_button.dart';
import 'package:haticare/features/auth/presentation/screens/login_screen.dart';
import 'package:haticare/features/auth/presentation/widgets/auth_top_bar.dart';

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
    final textTheme = Theme.of(context).textTheme;

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
                      'Please enter the OTP sent to the email associated with this account for verification',
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.5,
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
                      separatorBuilder: (index) => const SizedBox(width: 16),
                    ),
                    const SizedBox(height: 28),
                    if (widget.resendApiUrl != null)
                      _ResendRow(
                        canResend: canResend,
                        onPressed: () => _resendOtp(),
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
                onPressed: isLoading ? null : verifyOtp,
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
