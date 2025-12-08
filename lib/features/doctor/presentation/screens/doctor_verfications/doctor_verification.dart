import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:haticare/core/theme/app_colors.dart';
import 'package:haticare/features/doctor/presentation/screens/doctor_home_screen.dart';
import 'package:haticare/features/doctor/presentation/screens/doctor_verfications/identify_document.dart';
import 'package:haticare/features/doctor/presentation/screens/doctor_verfications/take_selfi.dart';

class DoctorVerificationScreen extends StatefulWidget {
  const DoctorVerificationScreen({super.key});

  @override
  DoctorVerificationScreenState createState() =>
      DoctorVerificationScreenState();
}

class DoctorVerificationScreenState extends State<DoctorVerificationScreen> {
  bool idCardChecked = false;
  bool selfieChecked = false;
  bool licenseChecked = false;

  bool get isAllChecked => idCardChecked && selfieChecked && licenseChecked;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 30,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Center(
                      child: SvgPicture.asset(
                        'assets/images/verification_illustration.svg',
                        height: 180,
                      ),
                    ),
                    const SizedBox(height: 30),
                    const Text(
                      'Verifying your identity',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Please submit the following documents to verify your identity',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 30),

                    GestureDetector(
                      onTap: idCardChecked
                          ? null
                          : () async {
                              final completed = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const IdentifyDocumentScreen(isValidID: true),
                                ),
                              );

                              if (completed == true) {
                                setState(() => idCardChecked = true);
                              }
                            },
                      child: _VerificationOption(
                        icon: 'assets/icons/id_card.svg',
                        title: 'Take a picture of a valid ID',
                        subtitle:
                            'To check if your personal informations are correct.',
                        isChecked: idCardChecked,
                      ),
                    ),

                    const SizedBox(height: 15),

                    GestureDetector(
                      onTap: selfieChecked
                          ? null
                          : () async {
                              final completed = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const TakeSelfieScreen(),
                                ),
                              );

                              if (completed == true) {
                                setState(() => selfieChecked = true);
                              }
                            },
                      child: _VerificationOption(
                        icon: 'assets/icons/selfie.svg',
                        title: 'Take a selfie',
                        subtitle:
                            'To match your face to your Passport or ID photo.',
                        isChecked: selfieChecked,
                      ),
                    ),

                    const SizedBox(height: 15),

                    GestureDetector(
                      onTap: licenseChecked
                          ? null
                          : () async {
                              final completed = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const IdentifyDocumentScreen(isValidID: false),
                                ),
                              );

                              if (completed == true) {
                                setState(() => licenseChecked = true);
                              }
                            },
                      child: _VerificationOption(
                        icon: 'assets/icons/id_card.svg',
                        title: 'Take a picture of Nursing License',
                        subtitle:
                            'To check if you have a valid nursing license.',
                        isChecked: licenseChecked,
                      ),
                    ),

                    const SizedBox(height: 25),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.asset(
                          'assets/icons/lock_icon.svg',
                          height: 16,
                          width: 16,
                          colorFilter: const ColorFilter.mode(
                            Colors.black87,
                            BlendMode.srcIn,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Your information will be encrypted and secured.',
                          style: TextStyle(fontSize: 13, color: Colors.black54),
                        ),
                      ],
                    ),
                    SizedBox(height: 40),
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Opacity(
                        opacity: isAllChecked ? 1.0 : 0.4,
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: isAllChecked
                                ? AppColors.primaryGradient
                                : LinearGradient(
                                    colors: [Colors.grey, Colors.grey],
                                  ),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: isAllChecked
                                ? () {
                                    // if (isAllChecked) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => DoctorHomeScreen(),
                                        ),
                                      );
                                    // }
                                  }
                                : null,
                            child: const Text(
                              'Continue',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VerificationOption extends StatelessWidget {
  final String icon;
  final String title;
  final String subtitle;
  final bool isChecked;

  const _VerificationOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.isChecked = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Transform.translate(
            offset: const Offset(0, -2),
            child: SvgPicture.asset(icon, height: 30, width: 30),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          if (isChecked)
            Transform.translate(
              offset: const Offset(4, 16),
              child: SvgPicture.asset(
                'assets/icons/check_mark.svg',
                height: 22,
                width: 22,
              ),
            ),
        ],
      ),
    );
  }
}
