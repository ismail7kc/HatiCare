import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import '../../../../core/theme/app_colors.dart';

class PharmacyHistoryCard extends StatelessWidget {
  final Map<String, dynamic> prescription;
  final VoidCallback onTap;

  const PharmacyHistoryCard({
    super.key,
    required this.prescription,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final prescriptionId = prescription['prescription_id']?.toString() ?? '';
    final patientName = prescription['patient_name']?.toString() ?? 'Unknown Patient';
    final medications = prescription['medications'] as List<dynamic>? ?? [];
    final pharmacyStatus = prescription['pharmacy_status']?.toString() ?? '';
    final doctor = prescription['doctor']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with prescription ID and status
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.local_pharmacy_outlined,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Prescription #$prescriptionId',
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          patientName,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(pharmacyStatus),
                ],
              ),

              // Medications summary
              if (medications.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Medications:',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      ...medications.take(2).map((med) {
                        final medName = med['name']?.toString() ?? 'Unknown';
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  medName,
                                  style: const TextStyle(
                                    color: Colors.black87,
                                    fontSize: 13,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      if (medications.length > 2)
                        Text(
                          '+${medications.length - 2} more medications',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ),
                ),
              ],

              // Doctor name
              if (doctor.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 14,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      doctor.startsWith('Dr.') ? doctor : 'Dr. $doctor',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],

              // Arrow indicator
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SvgPicture.asset(
                    'assets/icons/arrow_forward_line_icon.svg',
                    width: 20,
                    height: 20,
                    colorFilter: ColorFilter.mode(
                      Colors.grey[600]!,
                      BlendMode.srcIn,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color backgroundColor;
    Color textColor;
    String text;

    switch (status.toLowerCase()) {
      case 'completed':
        backgroundColor = const Color(0xFFE8F5E9);
        textColor = const Color(0xFF4CA054);
        text = 'Completed';
      case 'assigned':
        backgroundColor = const Color(0xFFE3F2FD);
        textColor = const Color(0xFF1976D2);
        text = 'Assigned';
      case 'open':
        backgroundColor = const Color(0xFFFFF1DA);
        textColor = const Color(0xFFF2B544);
        text = 'Open';
      default:
        backgroundColor = Colors.grey[200]!;
        textColor = Colors.grey[700]!;
        text = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
