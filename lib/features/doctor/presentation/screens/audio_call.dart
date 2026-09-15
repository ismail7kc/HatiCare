import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:haticare/features/common/global_alert.dart';
import 'package:haticare/features/common/shared_prefs_helper.dart';
import 'package:haticare/features/doctor/models/appointment_model.dart';
import 'package:haticare/features/doctor/presentation/screens/appointment_detail.dart';
import 'package:haticare/features/doctor/presentation/viewModel/audio_callVM.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/theme/app_colors.dart';

Future<bool> requestMicPermission() async {
  final status = await Permission.microphone.request();
  return status == PermissionStatus.granted;
}

class AudioCallScreen extends StatefulWidget {
  final AppointmentModel appointments;
  final int visitId;

  const AudioCallScreen({
    super.key,
    required this.appointments,
    required this.visitId,
  });

  @override
  State<AudioCallScreen> createState() => _AudioCallScreenState();
}

class _AudioCallScreenState extends State<AudioCallScreen> {
  late final AudioCallVM _vm;

  /// Set as soon as this screen starts leaving, so the call events that arrive
  /// while closing don't trigger a second navigation.
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _vm = context.read<AudioCallVM>();
    _vm.addListener(_onCallStateChanged);
    _startCallOnce();
  }

  @override
  void dispose() {
    _vm.removeListener(_onCallStateChanged);
    super.dispose();
  }

  void _startCallOnce() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final micGranted = await requestMicPermission();
      if (!mounted) return;

      if (!micGranted) {
        GlobalAlert.show(
          "Please turn on microphone permission to start the call",
          title: 'Microphone permission',
          onOk: _leaveCall,
        );
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final accessToken =
          SaveLoginResponse.loginData?['access_token'] ??
          prefs.getString('access_token') ??
          '';

      if (!mounted) return;

      _vm.startCall(visitId: widget.visitId, authToken: accessToken);
    });
  }

  /// Reacts to call failures and to the patient hanging up.
  void _onCallStateChanged() {
    if (!mounted || _closing) return;

    if (_vm.callFailed) {
      _closing = true;
      GlobalAlert.show(
        _vm.errorMessage ?? 'The call could not be completed.',
        title: 'Call Failed',
        onOk: _leaveCall,
      );
      return;
    }

    if (_vm.callEnded) {
      _closing = true;

      final message = _vm.errorMessage;
      if (message != null && message.isNotEmpty) {
        GlobalAlert.show(message, title: 'Call Ended', onOk: _leaveCall);
      } else {
        _leaveCall();
      }
    }
  }

  void _leaveCall() {
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  /// Hangs up, then returns to the appointment the call was started from.
  Future<void> _endCallAndOpenAppointment() async {
    if (_closing) return;
    _closing = true;

    await _vm.endCall();

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => AppointmentDetailScreen(
          appointment: widget.appointments,
          visitId: widget.visitId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AudioCallVM>();

    return WillPopScope(
      onWillPop: () async {
        if (!_closing) {
          _closing = true;
          await vm.endCall();
        }
        return true;
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            onPressed: () async {
              if (_closing) return;
              _closing = true;

              final navigator = Navigator.of(context);
              await vm.endCall();
              navigator.pop();
            },
          ),
          title: const Text(
            'Audio Call',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
        body: Container(
          decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
          width: double.infinity,
          height: double.infinity,
          child: SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 2),

                Transform.translate(
                  offset: const Offset(0, -16),
                  child: const CircleAvatar(
                    radius: 60,
                    backgroundColor: Color(0xFF1F3B7F),
                    child: Icon(
                      Icons.person_outline,
                      size: 80,
                      color: Colors.white,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                Text(
                  widget.appointments.patientName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 8),

                if (vm.isConnected)
                  Text(
                    vm.duration,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  )
                else
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (vm.isCalling) ...[
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                      Text(
                        vm.callStatus,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),

                const Spacer(),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: const [
                      _ActionButton(
                        icon: 'assets/icons/issue-Rx.svg',
                        label: "Issue Rx",
                      ),
                      _ActionButton(
                        icon: 'assets/icons/referral.svg',
                        label: "Referral",
                      ),
                      _ActionButton(
                        icon: 'assets/icons/hospitalize.svg',
                        label: "Hospitalize",
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 48),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _BottomButton(
                        icon: Icons.volume_up_rounded,
                        color: vm.speakerOn
                            ? Colors.white
                            : Colors.white.withOpacity(0.4),
                        onTap: vm.toggleSpeaker,
                      ),

                      _BottomButton(
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

                const Spacer(),

                GestureDetector(
                  onTap: _endCallAndOpenAppointment,
                  child: const CircleAvatar(
                    radius: 30,
                    backgroundColor: Color(0xFFE53935),
                    child: Icon(Icons.call_end, color: Colors.white, size: 28),
                  ),
                ),

                const Spacer(flex: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String icon;
  final String label;

  const _ActionButton({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SvgPicture.asset(icon, height: 28),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

class _BottomButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _BottomButton({required this.icon, required this.color, this.onTap});

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
