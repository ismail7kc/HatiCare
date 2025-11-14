import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:haticare/core/theme/app_colors.dart';
import 'package:haticare/features/doctor/presentation/screens/audio_call.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';
import 'package:haticare/features/doctor/models/appointment_model.dart';
import 'package:haticare/features/doctor/presentation/dialogs/dialog_helpers.dart';

class AppointmentDetail extends StatelessWidget {
  final AppointmentModel appointment;
  final bool isCameFromAccept;

  const AppointmentDetail({
    super.key,
    required this.appointment,
    this.isCameFromAccept = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          'Appointment Details',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (isCameFromAccept) ...[
              const Text(
                "Incoming Request",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              const Text(
                "You have 19 seconds to respond",
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 25),
            ],

            if (isCameFromAccept) ...[
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 90,
                    height: 90,
                    child: CircularProgressIndicator(
                      value: appointment.progressValue,
                      strokeWidth: 6,
                      backgroundColor: Colors.grey.shade200,
                      color: const Color(0xFF34C759),
                    ),
                  ),
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.blue.shade50,
                    child: SvgPicture.asset(
                      'assets/icons/user-square.svg',
                      height: 36,
                      color: Colors.blueAccent,
                    ),
                  ),
                ],
              ),
            ] else ...[
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.blue.shade50,
                child: SvgPicture.asset(
                  'assets/icons/person_Img.svg',
                  height: 100,
                  width: 100,
                ),
              ),
            ],

            const SizedBox(height: 18),
            Text(
              appointment.patientName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            Text(
              "${appointment.patientAge} years old, Male",
              style: const TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 30),

            // Reason for Visit
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SvgPicture.asset('assets/icons/sticky-note.svg', height: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Reason for Visit",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          appointment.reasonForVisit,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Reported Symptoms
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      SvgPicture.asset('assets/icons/sticky-note.svg', height: 24),
                      const SizedBox(width: 10),
                      const Text(
                        "Reported Symptoms",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: appointment.symptoms.map((symptom) {
                      return Chip(
                        label: Text(
                          symptom,
                          style: const TextStyle(
                            color: Color(0xFF8B0000),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        backgroundColor: const Color(0xFFFFE5E5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            if (!isCameFromAccept) ...[
              Container(
                height: 108,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SvgPicture.asset(
                      'assets/icons//sticky-note.svg',
                      height: 22,
                      color: Colors.black,
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: TextField(
                          maxLines: null,
                          textAlignVertical: TextAlignVertical.top,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Notes',
                            hintStyle: TextStyle(
                              color: Colors.black,
                              fontSize: 14,
                            ),
                            contentPadding: EdgeInsets.only(top: -30),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildActionButton(context, 'assets/icons/video_2.svg', "Issue RX"),
                  _buildActionButton(context, 'assets/icons/video_1.svg', "Referral"),
                  _buildActionButton(context,'assets/icons/video_3.svg',"Hospitalize",
                  ),
                ],
              ),
            ],

            const SizedBox(height: 40),

            if (isCameFromAccept) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        backgroundColor: const Color(0xFFF1F3F6),
                        foregroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text("Decline"),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          // PersistentNavBarNavigator.pushNewScreen(
                          //   context,
                          //   screen: AudioCallScreen(appointments: appointment),
                          //   withNavBar: false,
                          //   pageTransitionAnimation:
                          //       PageTransitionAnimation.cupertino,
                          // );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          "Accept",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String iconPath,
    String label,
  ) {
    return Column(
      children: [
        GestureDetector(
          onTap: () => DialogHelper.showDialogForLabel(context, label),
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
            child: Center(
              child: SvgPicture.asset(iconPath, width: 80, height: 64),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.black)),
      ],
    );
  }
}
