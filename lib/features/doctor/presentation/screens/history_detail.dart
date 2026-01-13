import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:haticare/features/doctor/models/patient_visit_history.dart';

class HistoryDetail extends StatelessWidget {
  final PatientData visit;

  const HistoryDetail({super.key, required this.visit});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF9FAFB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Color(0xFFF9FAFB),
        centerTitle: true,
        title: const Text(
          'Consultation Details',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 30, left: 16, right: 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFFFF),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12.withValues(alpha: 0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: const Color(0xFFE0E7FF),
                      child: const Icon(
                        Icons.person_outline,
                        color: Color(0xFF4A69BD),
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${visit.patientName}, ${visit.patient.age}",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${visit.patient.gender}, ${visit.patient.city}",
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Expanded(
                    child: _buildInfoChip(
                      icon: 'assets/icons/calendar.svg',
                      label: 'Date',
                      value: visit.createdAt != null
                          ? "${visit.createdAt.day}/${visit.createdAt.month}/${visit.createdAt.year}"
                          : ''
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildInfoChip(
                      icon: 'assets/icons/clock.svg',
                      label: 'Duration',
                      value: visit.status,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Padding(
            //   padding: const EdgeInsets.symmetric(horizontal: 16.0),
            //   child: Column(
            //     crossAxisAlignment: CrossAxisAlignment.start,
            //     children: [
            //       const Text(
            //         'Outcome',
            //         style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            //       ),
            //       const SizedBox(height: 12),
            //       Container(
            //         width: double.infinity,
            //         padding: const EdgeInsets.symmetric(
            //           vertical: 24,
            //           horizontal: 16,
            //         ),
            //         decoration: BoxDecoration(
            //           color: const Color(0xFFF3F4F6),
            //           borderRadius: BorderRadius.circular(12),
            //         ),
            //         child: const Text(
            //           'No specific outcome recorded.',
            //           style: TextStyle(fontSize: 15, color: Colors.grey),
            //           textAlign: TextAlign.center,
            //         ),
            //       ),
            //     ],
            //   ),
            // ),

            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required String icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          SvgPicture.asset(icon, height: 24),
        ],
      ),
    );
  }
}
