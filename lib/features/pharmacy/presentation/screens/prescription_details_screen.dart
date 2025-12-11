import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:haticare/core/theme/app_colors.dart';
import 'package:haticare/features/pharmacy/domain/entities/prescription_request.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:chucker_flutter/chucker_flutter.dart';
import '../../../../core/config/app_config.dart';

class PrescriptionDetailsScreen extends StatefulWidget {
  final PrescriptionRequest request;

  const PrescriptionDetailsScreen({super.key, required this.request});

  @override
  State<PrescriptionDetailsScreen> createState() => _PrescriptionDetailsScreenState();
}

class _PrescriptionDetailsScreenState extends State<PrescriptionDetailsScreen> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Prescription Details'),
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
                        color: AppColors.primaryLight.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        widget.request.statusText,
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
                    Row(
                      children: [
                        Icon(
                          Icons.medication_outlined,
                          color: Colors.black,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
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
                      Row(
                        children: [
                          Icon(
                            Icons.note_outlined,
                            color: Colors.black,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
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
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _showPartialAvailabilityBottomSheet(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFFE2B43F),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Dispense Partially',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _updateAvailability('full'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF4CA054),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Dispense Fully',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
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

  void _showPartialAvailabilityBottomSheet(BuildContext context) {
    // Create a map to track availability for each medication
    Map<int, Map<String, dynamic>> medicationAvailability = {};
    for (int i = 0; i < widget.request.medications.length; i++) {
      medicationAvailability[i] = {
        'isAvailable': true,
        'availableQty': 0, // Will be set based on required quantity
        'requiredQty': _extractQuantity(widget.request.medications[i].instructions) ?? 1,
      };
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  // Handle bar
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Header
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Medicine Availability',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Select which medicines are available at your pharmacy',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Medications list
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: widget.request.medications.length,
                      itemBuilder: (context, index) {
                        final medication = widget.request.medications[index];
                        final availability = medicationAvailability[index]!;
                        
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[200]!),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Checkbox(
                                    value: availability['isAvailable'],
                                    onChanged: (value) {
                                      setModalState(() {
                                        availability['isAvailable'] = value ?? false;
                                        if (value == true) {
                                          availability['availableQty'] = availability['requiredQty'];
                                        } else {
                                          availability['availableQty'] = 0;
                                        }
                                      });
                                    },
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          medication.name,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Text(
                                          medication.dosage,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              if (availability['isAvailable'])
                                Padding(
                                  padding: const EdgeInsets.only(left: 40, top: 8),
                                  child: Row(
                                    children: [
                                      Text(
                                        'Available Quantity:',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Container(
                                        decoration: BoxDecoration(
                                          border: Border.all(color: Colors.grey[300]!),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Row(
                                          children: [
                                            InkWell(
                                              onTap: availability['availableQty'] > 1
                                                  ? () {
                                                      setModalState(() {
                                                        availability['availableQty']--;
                                                      });
                                                    }
                                                  : null,
                                              child: Container(
                                                padding: const EdgeInsets.all(8),
                                                child: Icon(
                                                  Icons.remove,
                                                  size: 18,
                                                  color: availability['availableQty'] > 1
                                                      ? Colors.black
                                                      : Colors.grey,
                                                ),
                                              ),
                                            ),
                                            Container(
                                              width: 50,
                                              alignment: Alignment.center,
                                              child: Text(
                                                '${availability['availableQty']}',
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                            InkWell(
                                              onTap: () {
                                                setModalState(() {
                                                  availability['availableQty']++;
                                                });
                                              },
                                              child: Container(
                                                padding: const EdgeInsets.all(8),
                                                child: const Icon(
                                                  Icons.add,
                                                  size: 18,
                                                  color: Colors.black,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  // Action buttons
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: BorderSide(color: Colors.grey[300]!),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _updatePartialAvailability(medicationAvailability);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Apply',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  int? _extractQuantity(String instructions) {
    // Try to extract quantity from instructions like "15 tablets" or "quantity: 6"
    final regex = RegExp(r'(\d+)\s*(?:tablet|capsule|pill|ml|mg|g|unit|qty|quantity)?', caseSensitive: false);
    final match = regex.firstMatch(instructions);
    return match != null ? int.tryParse(match.group(1)!) : null;
  }

  Future<void> _updateAvailability(String availability) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token') ?? '';
      final statusId = widget.request.id;

      // Prepare items list
      List<Map<String, dynamic>> items = [];
      
      if (availability == 'full') {
        // All medicines fully available
        for (final medication in widget.request.medications) {
          final quantity = _extractQuantity(medication.instructions) ?? 1;
          items.add({
            'name': medication.name,
            'strength': medication.dosage,
            'required_qty': quantity,
            'available_qty': quantity + 5, // Add some buffer stock
            'notes': 'In stock',
          });
        }
      }

      final body = {
        'availability': availability,
        'items': items,
        'comment': availability == 'full' 
            ? 'All medicines fully available.'
            : 'Availability updated.',
      };

      final uri = Uri.parse('${AppConfig.baseUrl}prescriptions/pharmacy/$statusId/availability/');
      final client = ChuckerHttpClient(http.Client());
      final response = await client.patch(
        uri,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 30));

      Navigator.pop(context); // Close loading dialog

      if (response.statusCode >= 200 && response.statusCode < 300) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(availability == 'full' 
                ? 'Prescription marked as fully available'
                : 'Availability updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // Go back to home screen
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update availability: ${response.statusCode}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating availability: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _updatePartialAvailability(Map<int, Map<String, dynamic>> medicationAvailability) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token') ?? '';
      final statusId = widget.request.id;

      // Prepare items list based on user selection
      List<Map<String, dynamic>> items = [];
      bool anyAvailable = false;
      
      for (int i = 0; i < widget.request.medications.length; i++) {
        final medication = widget.request.medications[i];
        final availability = medicationAvailability[i]!;
        
        if (availability['isAvailable']) {
          anyAvailable = true;
          items.add({
            'name': medication.name,
            'strength': medication.dosage,
            'required_qty': availability['requiredQty'],
            'available_qty': availability['availableQty'],
            'notes': availability['availableQty'] >= availability['requiredQty']
                ? 'In stock'
                : 'Only ${availability['availableQty']} available',
          });
        }
      }

      String availabilityStatus = 'none';
      String comment = 'None of the requested medicines are available.';
      
      if (anyAvailable) {
        availabilityStatus = 'partial';
        comment = 'Some medicines are available, others are not.';
      }

      final body = {
        'availability': availabilityStatus,
        'items': items,
        'comment': comment,
      };

      final uri = Uri.parse('${AppConfig.baseUrl}prescriptions/pharmacy/$statusId/availability/');
      final client = ChuckerHttpClient(http.Client());
      final response = await client.patch(
        uri,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 30));

      Navigator.pop(context);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Availability updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update availability: ${response.statusCode}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating availability: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}