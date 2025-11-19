import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:haticare/features/doctor/models/appointment_model.dart';
import 'package:haticare/features/doctor/presentation/screens/appointment_detail.dart';

import '../../../../core/theme/app_colors.dart';

class AudioCallScreen extends StatelessWidget {
  final AppointmentModel appointments;

  const AudioCallScreen({super.key, required this.appointments});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Audio Call',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        centerTitle: false,
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        width: double.infinity,
        height: double.infinity,
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
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

              // Name
              const Text(
                "Alex Johnson",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),

              // Call Duration
              const Text(
                "22:55 min",
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),

              const Spacer(flex: 2),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
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
                padding: const EdgeInsets.symmetric(horizontal: 40.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _BottomButton(
                      icon: Icons.volume_up_rounded,
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                    _BottomButton(
                      icon: Icons.videocam_rounded,
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                    _BottomButton(
                      icon: Icons.mic_none_rounded,
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AppointmentDetail(appointment: appointments),
                    ),
                  );
                },
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFE53935),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: const Icon(
                    Icons.call_end,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),

              const Spacer(),
            ],
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

  const _BottomButton({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 26,
      backgroundColor: color,
      child: Icon(icon, color: Colors.white, size: 24),
    );
  }
}
