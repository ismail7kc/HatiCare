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
  bool speakerOn = false;

  @override
  void initState() {
    super.initState();
    _startCallOnce();
  }

  void _startCallOnce() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final micGranted = await requestMicPermission();
      if (!micGranted) {
        if (!mounted) return;
        GlobalAlert.show("Please turn on microphone permission");
        return;
      }

      final vm = context.read<AudioCallVM>();

      final prefs = await SharedPreferences.getInstance();
      final accessToken =
          SaveLoginResponse.loginData?['access_token'] ??
          prefs.getString('access_token') ??
          '';

      vm.startCall(visitId: widget.visitId, authToken: accessToken);
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AudioCallVM>();

    return WillPopScope(
      onWillPop: () async {
        await vm.endCall();
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
              await vm.endCall();
              Navigator.pop(context);
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

                Text(
                  vm.isConnected ? vm.duration : vm.callStatus,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),

                /// ───────── ACTION BUTTONS ─────────
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

                /// ───────── CALL CONTROLS ─────────
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

                /// ───────── END CALL ─────────
                const Spacer(),

                GestureDetector(
                  onTap: () async {
                    await vm.endCall();
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AppointmentDetailScreen(
                          appointment: widget.appointments,
                          visitId: widget.visitId,
                        ),
                      ),
                    );
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
