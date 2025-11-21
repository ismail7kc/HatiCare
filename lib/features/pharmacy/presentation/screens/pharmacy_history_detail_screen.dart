import 'package:flutter/material.dart';
import 'package:haticare/core/theme/app_colors.dart';
import 'package:haticare/features/pharmacy/domain/entities/prescription_request.dart';
import 'package:intl/intl.dart';

class PharmacyHistoryDetailScreen extends StatelessWidget {
  final PrescriptionRequest request;

  const PharmacyHistoryDetailScreen({
    super.key,
    required this.request,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Prescription Details',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatusHeader(),
                  const SizedBox(height: 16),
                  _buildDivider(),
                  const SizedBox(height: 16),
                  _buildInfoRow('Patient', '${request.patientName}, ${request.patientAge}'),
                  const SizedBox(height: 12),
                  _buildInfoRow('Doctor', request.doctorName),
                  const SizedBox(height: 12),
                  _buildInfoRow('Date', DateFormat('dd MMM yyyy, hh:mm a').format(request.dateIssued)),
                  const SizedBox(height: 12),
                  _buildInfoRow('Prescription ID', request.rxCode),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Prescription Details Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Prescription Details',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...request.medications.map((med) => _buildMedicationItem(med)),
                ],
              ),
            ),

            // Additional Notes
            if (request.status == PrescriptionStatus.notAvailable) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3F3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFFE0E0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.info_outline, color: Color(0xFFD32F2F), size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Not Available',
                          style: TextStyle(
                            color: Color(0xFFD32F2F),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'This prescription could not be filled because the medication is currently out of stock. We have notified the patient and will process the order as soon as stock is available.',
                      style: TextStyle(
                        color: Color(0xFFD32F2F),
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Last updated: ${DateFormat('MMM d, yyyy hh:mm a').format(DateTime.now().subtract(const Duration(hours: 2)))}',
                      style: TextStyle(
                        color: const Color(0xFFD32F2F).withOpacity(0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHeader() {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (request.status) {
      case PrescriptionStatus.fullyDispensed:
        statusColor = const Color(0xFF4CA054);
        statusIcon = Icons.check_circle_outline;
        statusText = 'Fully Dispensed';
        break;
      case PrescriptionStatus.partiallyDispensed:
        statusColor = const Color(0xFFE2B43F);
        statusIcon = Icons.history_outlined;
        statusText = 'Partially Dispensed';
        break;
      case PrescriptionStatus.notAvailable:
        statusColor = const Color(0xFFD32F2F);
        statusIcon = Icons.error_outline;
        statusText = 'Not Available';
        break;
      case PrescriptionStatus.issued:
        statusColor = AppColors.primaryDark;
        statusIcon = Icons.pending_actions_outlined;
        statusText = 'Prescription Issued';
        break;
    }

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(statusIcon, color: statusColor, size: 24),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              statusText,
              style: TextStyle(
                color: statusColor,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              'Status',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 13,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.grey[200]!,
            Colors.grey[100]!,
            Colors.grey[200]!,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMedicationItem(Medication medication) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 8),
            decoration: const BoxDecoration(
              color: Colors.black,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${medication.name} ${medication.dosage}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  medication.instructions,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}