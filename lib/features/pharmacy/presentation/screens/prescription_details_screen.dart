import 'package:haticare/core/theme/app_colors.dart';
import 'package:haticare/features/pharmacy/models/prescription_request.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:chucker_flutter/chucker_flutter.dart';
import '../../../../core/config/app_config.dart';
import 'package:flutter/material.dart';

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
                        color: AppColors.primaryLight.withValues(alpha: 0.1),
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
                    // Show different buttons based on status
                    if (widget.request.status == PrescriptionStatus.issued)
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _showAvailabilityBottomSheet(),
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
                                'Fully Available',
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
                              onPressed: () => _showAvailabilityBottomSheet(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFFFF9800),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                'Partially Available',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
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
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                'Mark as Delivered',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
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

  Future<void> _showAvailabilityBottomSheet() async {
    debugPrint('Opening availability bottom sheet...');
    debugPrint('Medications count: ${widget.request.medications.length}');
    
    // Create a map to track availability for each medication
    Map<int, Map<String, dynamic>> medicationAvailability = {};
    for (int i = 0; i < widget.request.medications.length; i++) {
      final instructions = widget.request.medications[i].instructions;
      debugPrint('Medication $i instructions: $instructions');
      final requiredQty = _extractQuantity(instructions) ?? 1;
      debugPrint('Extracted quantity: $requiredQty');
      
      medicationAvailability[i] = {
        'isAvailable': true,
        'requiredQty': requiredQty,
        'availableQty': requiredQty, // Default to full availability
      };
    }

    debugPrint('Medication availability map created: $medicationAvailability');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        debugPrint('Building bottom sheet...');
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            debugPrint('StatefulBuilder called');
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
                          'Set available quantities for each medicine',
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
                        debugPrint('Building medication item $index');
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
                                      debugPrint('Checkbox changed for item $index: $value');
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
                                          'Required: ${availability['requiredQty']} ${medication.dosage}',
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
                                                      debugPrint('Decrease quantity for item $index');
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
                                                debugPrint('Increase quantity for item $index');
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
                            onPressed: () {
                              debugPrint('Cancel button pressed');
                              Navigator.pop(context);
                            },
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
                              debugPrint('Confirm button pressed');
                              Navigator.pop(context);
                              _submitAvailabilityFromBottomSheet(medicationAvailability);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Confirm',
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

  Future<void> _submitAvailabilityFromBottomSheet(
    Map<int, Map<String, dynamic>> medicationAvailability,
  ) async {
    final List<Map<String, dynamic>> items = [];
    bool anyAvailable = false;
    bool allFullyAvailable = true;

    for (int i = 0; i < widget.request.medications.length; i++) {
      final medication = widget.request.medications[i];
      final availability = medicationAvailability[i]!;

      final int requiredQty = (availability['requiredQty'] as int?) ?? 1;
      final bool isAvailable = availability['isAvailable'] as bool? ?? false;
      final int availableQty = isAvailable ? (availability['availableQty'] as int? ?? 0) : 0;

      if (availableQty > 0) {
        anyAvailable = true;
      }

      if (availableQty < requiredQty) {
        allFullyAvailable = false;
      }

      if (isAvailable) {
        items.add({
          'name': medication.name,
          'strength': medication.dosage,
          'required_qty': requiredQty,
          'available_qty': availableQty,
          'notes': availableQty >= requiredQty
              ? 'In stock'
              : 'Only $availableQty available',
        });
      }
    }

    if (items.isEmpty) {
      await _submitAvailability(
        availability: 'none',
        items: const [],
        comment: 'None of the requested medicines are available.',
      );
      return;
    }

    String availabilityStatus;
    String comment;

    if (!anyAvailable) {
      availabilityStatus = 'none';
      comment = 'None of the requested medicines are available.';
    } else if (allFullyAvailable) {
      availabilityStatus = 'full';
      comment = 'All medicines fully available.';
    } else {
      availabilityStatus = 'partial';
      comment = _buildPartialAvailabilityComment(items);
    }

    await _submitAvailability(
      availability: availabilityStatus,
      items: items,
      comment: comment,
    );
  }

  int? _extractQuantity(String instructions) {
    final regex = RegExp(r'(\d+)');
    final match = regex.firstMatch(instructions);
    return match != null ? int.tryParse(match.group(1)!) : null;
  }

  Future<void> _submitAvailability({
    required String availability,
    required List<Map<String, dynamic>> items,
    required String comment,
  }) async {
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
      
      final statusId = widget.request.id.isNotEmpty 
          ? widget.request.id 
          : widget.request.rxCode;
      
      debugPrint('Using status ID: $statusId');
      debugPrint('Prescription ID: ${widget.request.id}');
      debugPrint('RX Code: ${widget.request.rxCode}');

      final body = {
        'availability': availability,
        'items': items,
        'comment': comment,
      };

      final uri = Uri.parse('${AppConfig.baseUrl}prescriptions/pharmacy/status/$statusId/availability/');
      final client = ChuckerHttpClient(http.Client());
      final response = await client.patch(
        uri,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 30));

      // Dismiss loading dialog first
      Navigator.pop(context); // Pop loading dialog
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final successMessage = availability == 'full'
            ? 'Prescription marked as fully available'
            : availability == 'none'
                ? 'Prescription marked as unavailable'
                : 'Availability updated successfully';
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(successMessage),
              backgroundColor: Colors.green,
            ),
          );
          // Close detail screen and trigger home screen reload
          Navigator.pop(context, true); // Pop detail screen with result
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update availability: ${response.statusCode}'),
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
            content: Text('Error updating availability: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateAvailability(String availability) async {
    final List<Map<String, dynamic>> items = [];

    if (availability == 'full') {
      for (final medication in widget.request.medications) {
        final requiredQty = _extractQuantity(medication.instructions) ?? 1;
        items.add({
          'name': medication.name,
          'strength': medication.dosage,
          'required_qty': requiredQty,
          'available_qty': requiredQty,
          'notes': 'In stock',
        });
      }
    }

    final String comment;
    if (availability == 'full') {
      comment = 'All medicines fully available.';
    } else if (availability == 'none') {
      comment = 'None of the requested medicines are available.';
    } else {
      comment = 'Availability updated.';
    }

    await _submitAvailability(
      availability: availability,
      items: availability == 'none' ? [] : items,
      comment: comment,
    );
  }

  Future<void> _updatePartialAvailability(
    Map<int, Map<String, dynamic>> medicationAvailability,
  ) async {
    final List<Map<String, dynamic>> items = [];
    bool anyAvailable = false;
    bool allFullyAvailable = true;

    for (int i = 0; i < widget.request.medications.length; i++) {
      final medication = widget.request.medications[i];
      final availability = medicationAvailability[i]!;

      final int requiredQty = (availability['requiredQty'] as int?) ?? 1;
      final bool isAvailable = availability['isAvailable'] as bool? ?? false;
      final int availableQty = isAvailable ? (availability['availableQty'] as int? ?? 0) : 0;

      if (availableQty > 0) {
        anyAvailable = true;
      }

      if (availableQty < requiredQty) {
        allFullyAvailable = false;
      }

      items.add({
        'name': medication.name,
        'strength': medication.dosage,
        'required_qty': requiredQty,
        'available_qty': availableQty,
        'notes': isAvailable
            ? (availableQty >= requiredQty
                ? 'In stock'
                : 'Only $availableQty available')
            : 'Out of stock',
      });
    }

    if (items.isEmpty) {
      await _submitAvailability(
        availability: 'none',
        items: const [],
        comment: 'None of the requested medicines are available.',
      );
      return;
    }

    String availabilityStatus;
    String comment;

    if (!anyAvailable) {
      availabilityStatus = 'none';
      comment = 'None of the requested medicines are available.';
    } else if (allFullyAvailable) {
      availabilityStatus = 'full';
      comment = 'All medicines fully available.';
    } else {
      availabilityStatus = 'partial';
      comment = _buildPartialAvailabilityComment(items);
    }

    final List<Map<String, dynamic>> payloadItems =
        availabilityStatus == 'none' ? <Map<String, dynamic>>[] : items;

    await _submitAvailability(
      availability: availabilityStatus,
      items: payloadItems,
      comment: comment,
    );
  }

  String _buildPartialAvailabilityComment(List<Map<String, dynamic>> items) {
    final List<String> parts = [];

    for (final item in items) {
      final String name = item['name'] as String? ?? '';
      final int requiredQty = item['required_qty'] as int? ?? 0;
      final int availableQty = item['available_qty'] as int? ?? 0;

      if (availableQty == 0) {
        parts.add('$name out of stock');
      } else if (availableQty < requiredQty) {
        parts.add('$name partially available ($availableQty of $requiredQty)');
      } else {
        parts.add('$name fully available');
      }
    }

    return parts.join(', ');
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
                      'Please verify the patient and their RX code before confirming delivery.',
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
          // Navigate back to refresh the list
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
        'rex_code': widget.request.rxCode,
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
}