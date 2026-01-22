import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:haticare/core/theme/app_colors.dart';
import 'package:intl/intl.dart';

enum ItemType {
  prescription,
  labTest,
}

class PrescriptionListItem extends StatelessWidget {
  final Map<String, dynamic> data;
  final ItemType itemType;
  final VoidCallback? onTap;
  final String? customTitle;

  const PrescriptionListItem({
    super.key,
    required this.data,
    this.itemType = ItemType.prescription,
    this.onTap,
    this.customTitle,
  });

  @override
  Widget build(BuildContext context) {
    // Extract common data
    final patientName = data['patient_name']?.toString() ?? 'Unknown Patient';
    final doctorName = data['doctor_name']?.toString() ?? 'Dr. Unknown';
    final createdAt = data['created_at']?.toString() ?? '';
    
    // Parse date
    DateTime issuedDate = DateTime.now();
    if (createdAt.isNotEmpty) {
      issuedDate = DateTime.tryParse(createdAt) ?? issuedDate;
    }
    
    // Format date and time
    final formattedDate = DateFormat('dd-MM-yyyy').format(issuedDate);
    final formattedTime = DateFormat('h:mm a').format(issuedDate);
    
    // Get item-specific data
    String itemSummary = '';
    String displayTitle = customTitle ?? 
        (itemType == ItemType.prescription ? 'New Prescription' : 'Lab Tests');
    
    if (itemType == ItemType.prescription) {
      // Get medications for prescription
      if (data['medications'] is List) {
        itemSummary = (data['medications'] as List)
            .map((med) => med is Map<String, dynamic>
                ? med['name']?.toString() ?? 'Unknown Medication'
                : med.toString())
            .where((name) => name.isNotEmpty)
            .join(', ');
      }
    } else {
      // Get lab tests for laboratory
      if (data['lab_tests'] is List) {
        itemSummary = (data['lab_tests'] as List)
            .map((test) => test is Map<String, dynamic>
                ? test['name']?.toString() ?? 'Unknown Test'
                : test.toString())
            .where((name) => name.isNotEmpty)
            .join(', ');
      }
    }
    
    // Get patient info
    String patientInfo = patientName;
    if (itemType == ItemType.prescription) {
      final patientAge = data['patient_age']?.toString();
      if (patientAge != null && patientAge.isNotEmpty) {
        patientInfo = '$patientName, $patientAge';
      }
    }
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
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
                    width: 28,
                    height: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ShaderMask(
                      shaderCallback: (bounds) =>
                          AppColors.primaryGradient.createShader(bounds),
                      child: Text(
                        displayTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        formattedDate,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        formattedTime,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 18),
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
                        'Patient',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        patientInfo,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (itemSummary.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  itemSummary,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.primary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  SvgPicture.asset(
                    'assets/icons/doctor_icon.svg',
                    width: 22,
                    height: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Doctor',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          doctorName,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SvgPicture.asset(
                    'assets/icons/arrow_forward_line_icon.svg',
                    width: 26,
                    height: 26,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
