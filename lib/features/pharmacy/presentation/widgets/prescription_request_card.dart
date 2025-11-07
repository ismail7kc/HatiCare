import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:haticare/core/theme/app_colors.dart';
import 'package:haticare/features/pharmacy/domain/entities/prescription_request.dart';
import 'package:intl/intl.dart';

class PrescriptionRequestCard extends StatelessWidget {
  final PrescriptionRequest request;
  final VoidCallback onTap;

  const PrescriptionRequestCard({
    super.key,
    required this.request,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2,vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SvgPicture.asset(
                    'assets/icons/new_prescription_icon.svg',
                    width: 30,
                    height: 30,
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: ShaderMask(
                      shaderCallback: (bounds) =>
                          AppColors.primaryGradient.createShader(bounds),
                      child: const Text(
                        'New Prescription',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),

                  Text(
                    DateFormat('dd-MM-yyyy  h:mm a').format(request.dateIssued),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ],
              ),


              const SizedBox(height: 20),

              /// 🔹 Patient Row
              Row(
                children: [
                  SvgPicture.asset(
                    'assets/icons/patient_icon.svg',
                    width: 22,
                    height: 22,
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Patient",
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        "${request.patientName}, ${request.patientAge}",
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  )
                ],
              ),

              const SizedBox(height: 16),

              /// 🔹 Doctor Row
              Row(
                children: [
                  SvgPicture.asset(
                    'assets/icons/doctor_icon.svg',
                    width: 22,
                    height: 22,
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Doctor",
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        request.doctorName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),

                  /// Right arrow
                  SvgPicture.asset(
                    'assets/icons/arrow_forward_line_icon.svg',
                    width: 28,
                    height: 28,
                    colorFilter: const ColorFilter.mode(
                      Colors.black,
                      BlendMode.srcIn,
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
