import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:haticare/features/common/shared_prefs_helper.dart';
import 'package:haticare/features/doctor/presentation/viewModel/dummy_call_vm.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/theme/app_colors.dart';

class DummyCallScreen extends StatefulWidget {
  const DummyCallScreen({super.key});

  @override
  State<DummyCallScreen> createState() => _DummyCallScreenState();
}

class _DummyCallScreenState extends State<DummyCallScreen> {
  final _numberController = TextEditingController();
  final _visitIdController = TextEditingController();
  final _tokenController = TextEditingController();

  @override
  void dispose() {
    _numberController.dispose();
    _visitIdController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  Future<bool> _requestMic() async {
    final status = await Permission.microphone.request();
    return status == PermissionStatus.granted;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _startCall() async {
    final vm = context.read<DummyCallVM>();

    final number = _numberController.text.trim();
    if (number.isEmpty) {
      _showError('Please enter a phone number');
      return;
    }

    final micGranted = await _requestMic();
    if (!micGranted) {
      _showError('Microphone permission is required to start call');
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final accessToken =
        SaveLoginResponse.loginData?['access_token'] ??
        prefs.getString('access_token') ??
        '';

    final visitId = int.tryParse(_visitIdController.text.trim()) ?? 0;
    final pastedToken = _tokenController.text.trim();

    await vm.startCall(
      number: number,
      visitId: visitId,
      token: pastedToken.isEmpty ? null : pastedToken,
      authToken: accessToken,
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DummyCallVM>();

    return PopScope(
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          await vm.endCall();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          elevation: 0,
          title: const Text(
            'Dummy Call Tester',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
          ),
        ),
        body: SafeArea(
          child: vm.isConnected || vm.isCalling
              ? _buildCallView(vm)
              : _buildInputView(vm),
        ),
      ),
    );
  }

  Widget _buildInputView(DummyCallVM vm) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Enter a number to call (testing only)',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _numberController,
            keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: _decoration('Phone number'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _visitIdController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: _decoration('Visit ID (optional, for fetching token)'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _tokenController,
            maxLines: 3,
            decoration: _decoration(
              'Twilio token (optional, overrides visit ID)',
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: vm.isCalling ? null : _startCall,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryDark,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Call',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            vm.callStatus,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }

  InputDecoration _decoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppColors.textSecondary),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE2E2EA)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE2E2EA)),
      ),
    );
  }

  Widget _buildCallView(DummyCallVM vm) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
      width: double.infinity,
      height: double.infinity,
      child: Column(
        children: [
          const Spacer(flex: 2),
          const CircleAvatar(
            radius: 60,
            backgroundColor: Color(0xFF1F3B7F),
            child: Icon(
              Icons.person_outline,
              size: 80,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            vm.dialedNumber,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            vm.isConnected ? vm.duration : vm.callStatus,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 72),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _RoundButton(
                  icon: vm.speakerOn
                      ? Icons.volume_up_rounded
                      : Icons.volume_off_rounded,
                  color: vm.speakerOn
                      ? Colors.white
                      : Colors.white.withOpacity(0.4),
                  onTap: vm.toggleSpeaker,
                ),
                _RoundButton(
                  icon: vm.micMuted
                      ? Icons.mic_off_rounded
                      : Icons.mic_none_rounded,
                  color: vm.micMuted
                      ? Colors.white
                      : Colors.white.withOpacity(0.4),
                  onTap: vm.toggleMute,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () async {
              await vm.endCall();
              if (!mounted) return;
              Navigator.pop(context);
            },
            child: const CircleAvatar(
              radius: 30,
              backgroundColor: Color(0xFFE53935),
              child: Icon(Icons.call_end, color: Colors.white, size: 28),
            ),
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _RoundButton({
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: CircleAvatar(
        radius: 26,
        backgroundColor: Colors.white.withOpacity(0.2),
        child: Icon(icon, color: color, size: 24),
      ),
    );
  }
}