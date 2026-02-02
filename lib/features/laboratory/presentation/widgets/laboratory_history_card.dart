import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import '../../../../core/theme/app_colors.dart';

class LaboratoryHistoryCard extends StatelessWidget {
  final Map<String, dynamic> prescription;
  final VoidCallback onTap;

  const LaboratoryHistoryCard({
    super.key,
    required this.prescription,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final prescriptionId = prescription['prescription_id']?.toString() ?? '';
    final patientName = prescription['patient_name']?.toString() ?? 'Unknown Patient';
    final labTests = prescription['lab_tests'] as List<dynamic>? ?? [];
    final notes = prescription['notes']?.toString() ?? '';
    final rexCode = prescription['rex_code']?.toString() ?? '';

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
              // Header with RX code and status
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
                        Icons.science_outlined,
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
                        if (rexCode.isNotEmpty)
                          Text(
                            'RX: $rexCode',
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          )
                        else
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
                  _buildStatusBadge(),
                ],
              ),

              // Lab tests summary
              if (labTests.isNotEmpty) ...[
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
                        'Lab Tests:',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      ...labTests.take(2).map((test) {
                        final testName = test['name']?.toString() ?? 'Unknown Test';
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
                                  testName,
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
                      if (labTests.length > 2)
                        Text(
                          '+${labTests.length - 2} more tests',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ),
                ),
              ],

              // Notes
              if (notes.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.note_outlined,
                      size: 14,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        notes,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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

  Widget _buildStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(25),
      ),
      child: const Text(
        'Completed',
        style: TextStyle(
          color: Color(0xFF4CA054),
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
