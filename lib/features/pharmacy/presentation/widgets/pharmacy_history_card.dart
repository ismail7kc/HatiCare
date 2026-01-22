import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../models/pharmacy_history_item.dart';

class PharmacyHistoryCard extends StatelessWidget {
  final PharmacyHistoryItem item;
  final VoidCallback onTap;

  const PharmacyHistoryCard({
    super.key,
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
              // Header with prescription ID and action
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        'RX',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Prescription #${item.prescriptionId}',
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('dd MMM yyyy, hh:mm a').format(item.createdAt),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildActionBadge(item.action),
                ],
              ),
              
              // Medications summary
              if (item.medications.isNotEmpty) ...[
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
                      ...item.medications.take(2).map((med) => Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: _getAvailabilityColor(med.availabilityStatus),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${med.name} (${med.strength})',
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontSize: 13,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '${med.availableQty}/${med.requiredQty}',
                              style: TextStyle(
                                color: _getAvailabilityColor(med.availabilityStatus),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      )),
                      if (item.medications.length > 2)
                        Text(
                          '+${item.medications.length - 2} more medications',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              
              // Score and comment
              if (item.score != null || item.comment != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (item.score != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Score: ${(item.score! * 100).toStringAsFixed(1)}%',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (item.comment != null)
                      Expanded(
                        child: Text(
                          item.comment!,
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
                    color: Colors.grey[600],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionBadge(HistoryAction action) {
    Color backgroundColor;
    Color textColor;
    String text;

    switch (action) {
      case HistoryAction.selectedFull:
        backgroundColor = const Color(0xFFE3F2FD);
        textColor = const Color(0xFF1976D2);
        text = 'Selected';
      case HistoryAction.respondedFull:
        backgroundColor = const Color(0xFFE8F5E9);
        textColor = const Color(0xFF4CA054);
        text = 'Fully Available';
      case HistoryAction.respondedPartial:
        backgroundColor = const Color(0xFFFFF1DA);
        textColor = const Color(0xFFF2B544);
        text = 'Partially Available';
      case HistoryAction.selectedPartial:
        backgroundColor = const Color(0xFFFCE4EC);
        textColor = const Color(0xFFE91E63);
        text = 'Partially Selected';
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

  Color _getAvailabilityColor(String status) {
    switch (status) {
      case 'Available':
        return const Color(0xFF4CA054);
      case 'Partially Available':
        return const Color(0xFFF2B544);
      case 'Not Available':
        return const Color(0xFFFF6B6B);
      default:
        return Colors.grey;
    }
  }
}
