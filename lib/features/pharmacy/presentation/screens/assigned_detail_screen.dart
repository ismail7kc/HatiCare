import 'dart:convert';
import 'package:chucker_flutter/chucker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../../../../core/config/app_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../models/prescription_request.dart';
import '../providers/pharmacy_user_provider.dart';

class AssignedDetailScreen extends StatefulWidget {
  final PrescriptionRequest request;

  const AssignedDetailScreen({
    super.key,
    required this.request,
  });

  @override
  State<AssignedDetailScreen> createState() => _AssignedDetailScreenState();
}

class _AssignedDetailScreenState extends State<AssignedDetailScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Assigned Prescription Details'),
        titleTextStyle: const TextStyle(
          color: Colors.black,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Rx Code Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Rx Code',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.request.rxCode,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Issued',
                        style: TextStyle(
                          color: AppColors.primaryDark,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Patient Info Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _buildInfoRow(
                      'Patient:',
                      '${widget.request.patientName}, ${widget.request.patientAge}',
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow('Issuing Doctor:', widget.request.doctorName),
                    const SizedBox(height: 12),
                    if (widget.request.patientPhone.isNotEmpty)
                      _buildInfoRow('Patient Phone:', widget.request.patientPhone),
                    if (widget.request.patientPhone.isNotEmpty) const SizedBox(height: 12),
                    _buildInfoRow(
                      'Date Issued:',
                      DateFormat('dd/MM/yyyy').format(widget.request.dateIssued),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Medications Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.medication_outlined,
                          color: Colors.black,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        const Text(
                          'Medications',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ...widget.request.medications.asMap().entries.map((entry) {
                      final index = entry.key;
                      final medication = entry.value;
                      return Column(
                        children: [
                          if (index > 0) const SizedBox(height: 12),
                          _buildMedicationItem(medication),
                        ],
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Notes Card (if available)
              if (widget.request.notes.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.note_outlined,
                            color: Colors.black,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          const Text(
                            'Note',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.request.notes,
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              if (widget.request.notes.isNotEmpty) const SizedBox(height: 16),

              // Actions Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Actions',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Show only Complete button for assigned prescriptions
                    if (widget.request.status == PrescriptionStatus.issued)
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _completePrescription(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                elevation: 0,
                              ),
                              child: Ink(
                                decoration: BoxDecoration(
                                  gradient: AppColors.primaryGradient,
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  alignment: Alignment.center,
                                  child: const Text(
                                    'Complete',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    else if (widget.request.status == PrescriptionStatus.fullyDispensed ||
                             widget.request.status == PrescriptionStatus.partiallyDispensed)
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _markAsDelivered(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                elevation: 0,
                              ),
                              child: Ink(
                                decoration: BoxDecoration(
                                  gradient: AppColors.primaryGradient,
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  alignment: Alignment.center,
                                  child: const Text(
                                    'Mark as Delivered',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Color(0xFF4CA054)),
                        ),
                        child: const Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle, color: Color(0xFF4CA054), size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Medication Delivered',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF4CA054),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMedicationItem(Medication medication) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Container(
            width: 4,
            height: 4,
            decoration: const BoxDecoration(
              color: Colors.black,
              shape: BoxShape.circle,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 14,
                height: 1.5,
              ),
              children: [
                TextSpan(
                  text: '${medication.name} ${medication.dosage} ',
                  style: const TextStyle(fontWeight: FontWeight.normal),
                ),
                TextSpan(
                  text: '(${medication.instructions})',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _completePrescription() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token') ?? '';

      if (accessToken.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No authentication token found'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      final body = {
        'rex_code': widget.request.rxCode.replaceFirst('RX...', ''),
      };

      final uri = Uri.parse('${AppConfig.baseUrl}prescriptions/pharmacy/complete/');
      final client = ChuckerHttpClient(http.Client());
      final response = await client.post(
        uri,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Prescription completed successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to complete prescription: ${response.statusCode}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error completing prescription: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _markAsDelivered() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delivery'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Are you sure you want to mark this prescription as delivered?',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Text(
              'RX Code: ${widget.request.rxCode}',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            Text(
              'Patient: ${widget.request.patientName}',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_outlined, color: Colors.orange[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Please verify patient and their RX code before confirming delivery.',
                      style: TextStyle(fontSize: 12, color: Colors.orange[700]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF4CA054),
            ),
            child: const Text('Confirm Delivery'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token') ?? '';
      final prescriptionId = widget.request.id;

      // Call API to mark as delivered
      final uri = Uri.parse('${AppConfig.baseUrl}prescriptions/pharmacy/$prescriptionId/deliver/');
      final client = ChuckerHttpClient(http.Client());
      final response = await client.patch(
        uri,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'status': 'delivered',
          'delivered_at': DateTime.now().toIso8601String(),
        }),
      ).timeout(const Duration(seconds: 30));

      // Dismiss loading dialog
      if (context.mounted) {
        Navigator.pop(context);
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Show success message
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Medication marked as delivered successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
          // Navigate back to refresh list
          Navigator.pop(context, true);
        }
      } else {
        // Show error message
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to mark as delivered: ${response.statusCode}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // Dismiss loading dialog
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error marking as delivered: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
