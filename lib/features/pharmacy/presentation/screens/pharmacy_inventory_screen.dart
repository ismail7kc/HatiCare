import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:haticare/core/theme/app_colors.dart';
import 'package:haticare/features/pharmacy/entities/prescription_request.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/pharmacy_user_provider.dart';
import 'prescription_details_screen.dart';

class PharmacyInventoryScreen extends StatefulWidget {
  const PharmacyInventoryScreen({super.key});

  @override
  State<PharmacyInventoryScreen> createState() =>
      _PharmacyInventoryScreenState();
}

class _PharmacyInventoryScreenState extends State<PharmacyInventoryScreen> {
  late TextEditingController _searchController;
  late TextEditingController _rxCodeController;

  // Dummy prescription data for demonstration
  final List<Map<String, dynamic>> _dummyPrescriptions = [
    {
      'prescription_id': '1',
      'rex_code_last4': '1234',
      'patient_name': 'John Doe',
      'patient_age': '45',
      'patient_gender': 'Male',
      'patient_phone': '+1 234-567-8900',
      'doctor_name': 'Dr. Sarah Wilson',
      'doctor_specialty': 'Cardiologist',
      'availability': 'fully available',
      'notes': 'Patient has mild allergy to penicillin',
      'fulfillment_score': 100.0,
      'medications': [
        {
          'name': 'Lisinopril',
          'dose': '10mg',
          'frequency': 'Once daily',
          'duration': '30 days',
          'notes': 'Take with food'
        },
        {
          'name': 'Metformin',
          'dose': '500mg',
          'frequency': 'Twice daily',
          'duration': '30 days',
          'notes': 'After meals'
        },
      ],
    },
    {
      'prescription_id': '2',
      'rex_code_last4': '5678',
      'patient_name': 'Emily Johnson',
      'patient_age': '32',
      'patient_gender': 'Female',
      'patient_phone': '+1 234-567-8901',
      'doctor_name': 'Dr. Michael Chen',
      'doctor_specialty': 'General Physician',
      'availability': 'partially available',
      'notes': 'Patient is pregnant',
      'fulfillment_score': 50.0,
      'medications': [
        {
          'name': 'Amoxicillin',
          'dose': '250mg',
          'frequency': 'Three times daily',
          'duration': '7 days',
          'notes': 'Complete full course'
        },
        {
          'name': 'Ibuprofen',
          'dose': '400mg',
          'frequency': 'As needed',
          'duration': 'As needed',
          'notes': 'Max 3 times daily'
        },
      ],
    },
    {
      'prescription_id': '3',
      'rex_code_last4': '9012',
      'patient_name': 'Robert Smith',
      'patient_age': '58',
      'patient_gender': 'Male',
      'patient_phone': '+1 234-567-8902',
      'doctor_name': 'Dr. Sarah Wilson',
      'doctor_specialty': 'Cardiologist',
      'availability': 'delivered',
      'notes': 'Patient monitoring required',
      'fulfillment_score': 100.0,
      'medications': [
        {
          'name': 'Amlodipine',
          'dose': '5mg',
          'frequency': 'Once daily',
          'duration': '30 days',
          'notes': 'Take in morning'
        },
      ],
    },
    {
      'prescription_id': '4',
      'rex_code_last4': '3456',
      'patient_name': 'Maria Garcia',
      'patient_age': '28',
      'patient_gender': 'Female',
      'patient_phone': '+1 234-567-8903',
      'doctor_name': 'Dr. James Lee',
      'doctor_specialty': 'Dermatologist',
      'availability': 'fully available',
      'notes': 'Follow up in 2 weeks',
      'fulfillment_score': 100.0,
      'medications': [
        {
          'name': 'Doxycycline',
          'dose': '100mg',
          'frequency': 'Twice daily',
          'duration': '14 days',
          'notes': 'Avoid direct sunlight'
        },
        {
          'name': 'Hydrocortisone',
          'dose': '1%',
          'frequency': 'Apply twice daily',
          'duration': '7 days',
          'notes': 'Topical cream'
        },
      ],
    },
  ];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _rxCodeController = TextEditingController();
    _loadInventory();
  }

  Future<void> _loadInventory() async {
    final provider = context.read<PharmacyUserProvider>();
    await provider.fetchPrescriptions();
  }

  Future<void> _onRefresh() async {
    await _loadInventory();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _rxCodeController.dispose();
    super.dispose();
  }

  Future<void> _verifyRxCode(PharmacyUserProvider provider) async {
    // Check approval status first
    if (!provider.isApproved) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Your pharmacy account is not approved.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    await provider.verifyRxCode(_rxCodeController.text);

    // Show dialog based on verification result
    if (provider.errorMessage != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage!),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } else if (provider.verifiedRxCode.isNotEmpty) {
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('RX Code verified! Go to Inventory to deliver.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        // Clear to input field
        _rxCodeController.clear();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Inventory',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Consumer<PharmacyUserProvider>(
          builder: (context, pharmacyProvider, child) {
            return Column(
              children: [
                // Verify Prescription Section
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Verify Prescription',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _rxCodeController,
                                textCapitalization: TextCapitalization
                                    .characters,
                                keyboardType: TextInputType.text,
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'[A-Z0-9]'),
                                  ),
                                ],
                                onChanged: (value) {
                                  if (value != value.toUpperCase()) {
                                    _rxCodeController.text =
                                        value.toUpperCase();
                                    _rxCodeController.selection =
                                        TextSelection.fromPosition(
                                          TextPosition(offset: value.length),
                                        );
                                  }
                                },
                                decoration: InputDecoration(
                                  hintText: 'Enter Rx Code (e.g., RX12345)',
                                  hintStyle: const TextStyle(
                                    color: Color(0xFF858585),
                                    fontSize: 14,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: Colors.grey[300]!,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: Colors.grey[300]!,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: AppColors.primaryDark,
                                      width: 2,
                                    ),
                                  ),
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            ElevatedButton(
                              onPressed: pharmacyProvider.isApproved
                                  ? () {
                                _verifyRxCode(pharmacyProvider);
                              }
                                  : null,
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 0,
                                backgroundColor: pharmacyProvider.isApproved
                                    ? Colors.transparent
                                    : Colors.grey[300],
                                shadowColor: Colors.transparent,
                              ),
                              child: Ink(
                                decoration: BoxDecoration(
                                  gradient: pharmacyProvider.isApproved
                                      ? AppColors.primaryGradient
                                      : null,
                                  color: pharmacyProvider.isApproved
                                      ? null
                                      : Colors.grey[300],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 8,
                                  ),
                                  alignment: Alignment.center,
                                  child: pharmacyProvider.isVerifying
                                      ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                      : const Text(
                                    'Verify',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Inventory Content
                Expanded(
                  child: Builder(
                    builder: (context) {
                      if (!pharmacyProvider.isApproved) {
                        return _buildNotApprovedState();
                      }

                      // Use dummy prescriptions if no real data available
                      final prescriptionsToDisplay =
                          pharmacyProvider.prescriptions.isEmpty
                              ? _dummyPrescriptions
                              : pharmacyProvider.prescriptions;

                      final newRequests = prescriptionsToDisplay.where((p) {
                        final statusStr =
                            p['availability']?.toString().toLowerCase() ?? '';
                        return !statusStr.contains('delivered') &&
                            !statusStr.contains('full') &&
                            !statusStr.contains('partial');
                      }).toList();

                      final availablePrescriptions =
                          prescriptionsToDisplay.where((p) {
                        final statusStr =
                            p['availability']?.toString().toLowerCase() ?? '';
                        return statusStr.contains('full') ||
                            statusStr.contains('partial') ||
                            statusStr.contains('delivered');
                      }).toList();

                      if (newRequests.isEmpty && availablePrescriptions.isEmpty) {
                        return _buildEmptyInventoryState();
                      }

                      return RefreshIndicator(
                        onRefresh: _onRefresh,
                        color: AppColors.primary,
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                          children: [
                            if (newRequests.isNotEmpty) ...[
                              const Text(
                                'New Requests',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ...newRequests.map((prescriptionData) {
                                List<Medication> medications = [];
                                if (prescriptionData['medications'] is List) {
                                  medications = (prescriptionData['medications'] as List)
                                      .map(
                                        (med) => Medication(
                                          name: med['name'] ?? 'Unknown',
                                          dosage: med['dose'] ?? 'N/A',
                                          instructions:
                                              '${med['frequency'] ?? ''} ${med['duration'] ?? ''} ${med['notes'] ?? ''}'.trim(),
                                        ),
                                      )
                                      .toList();
                                }

                                final request = PrescriptionRequest(
                                  id: prescriptionData['prescription_id']
                                          ?.toString() ??
                                      'N/A',
                                  rxCode:
                                      'RX...${prescriptionData['rex_code_last4'] ?? 'N/A'}',
                                  patientName: prescriptionData['patient_name'] ??
                                      'Unknown Patient',
                                  patientAge: int.tryParse(
                                          prescriptionData['patient_age']
                                              ?.toString() ??
                                              '0') ??
                                      0,
                                  patientGender:
                                      prescriptionData['patient_gender'] ?? 'Male',
                                  patientDob: '1992-11-15',
                                  doctorName:
                                      prescriptionData['doctor_name'] ?? 'Dr. Unknown',
                                  doctorSpecialty:
                                      prescriptionData['doctor_specialty'] ??
                                      'General Physician',
                                  dateIssued: DateTime.now(),
                                  status: PrescriptionStatus.issued,
                                  medications: medications,
                                );

                                request.patientPhone =
                                    prescriptionData['patient_phone'] ?? '';
                                request.notes =
                                    prescriptionData['notes'] ?? '';
                                request.fulfillmentScore =
                                    prescriptionData['fulfillment_score'] ?? 0.0;

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: _buildNewRequestCard(
                                      request, prescriptionData),
                                );
                              }),
                              const SizedBox(height: 24),
                            ],

                            const Text(
                              'Available Prescriptions',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),

                            if (availablePrescriptions.isEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 24,
                                ),
                                alignment: Alignment.center,
                                child: const Text(
                                  'No available prescriptions yet.',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                ),
                              )
                            else
                              ...availablePrescriptions.asMap().entries.map(
                                (entry) {
                                  final index = entry.key;
                                  final prescriptionData = entry.value;

                                  List<Medication> medications = [];
                                  if (prescriptionData['medications'] is List) {
                                    medications =
                                        (prescriptionData['medications'] as List)
                                            .map(
                                              (med) => Medication(
                                                name: med['name'] ?? 'Unknown',
                                                dosage: med['dose'] ?? 'N/A',
                                                instructions:
                                                    '${med['frequency'] ?? ''} ${med['duration'] ?? ''} ${med['notes'] ?? ''}'.trim(),
                                              ),
                                            )
                                            .toList();
                                  }

                                  PrescriptionStatus status =
                                      PrescriptionStatus.issued;
                                  final statusStr = prescriptionData['availability']
                                          ?.toString()
                                          .toLowerCase() ??
                                      'pending';

                                  if (statusStr.contains('delivered')) {
                                    status = PrescriptionStatus.delivered;
                                  } else if (statusStr.contains('fully')) {
                                    status = PrescriptionStatus.fullyDispensed;
                                  } else if (statusStr.contains('partial')) {
                                    status =
                                        PrescriptionStatus.partiallyDispensed;
                                  }

                                  final request = PrescriptionRequest(
                                    id: prescriptionData['prescription_id']
                                            ?.toString() ??
                                        'N/A',
                                    rxCode:
                                        'RX...${prescriptionData['rex_code_last4'] ?? 'N/A'}',
                                    patientName:
                                        prescriptionData['patient_name'] ??
                                        'Unknown Patient',
                                    patientAge: int.tryParse(
                                            prescriptionData['patient_age']
                                                ?.toString() ??
                                                '0') ??
                                        0,
                                    patientGender: prescriptionData['patient_gender'] ??
                                        'Male',
                                    patientDob: '1992-11-15',
                                    doctorName: prescriptionData['doctor_name'] ??
                                        'Dr. Unknown',
                                    doctorSpecialty:
                                        prescriptionData['doctor_specialty'] ??
                                        'General Physician',
                                    dateIssued: DateTime.now(),
                                    status: status,
                                    medications: medications,
                                  );

                                  request.patientPhone =
                                      prescriptionData['patient_phone'] ?? '';
                                  request.notes =
                                      prescriptionData['notes'] ?? '';
                                  request.fulfillmentScore =
                                      prescriptionData['fulfillment_score'] ??
                                          0.0;

                                  return Padding(
                                    padding: EdgeInsets.only(
                                      bottom: index ==
                                              availablePrescriptions.length - 1
                                          ? 16
                                          : 16,
                                    ),
                                    child: _buildPrescriptionCard(
                                        request, prescriptionData),
                                  );
                                },
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildNotApprovedState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_outline,
              size: 64,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 20),
            Text(
              'Inventory Not Available',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your pharmacy account must be approved to view inventory.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyInventoryState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 20),
            Text(
              'No Items in Inventory',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Verify an RX code to add prescriptions',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewRequestCard(PrescriptionRequest request,
      Map<String, dynamic> prescriptionData,) {
    final medicationsList = prescriptionData['medications'] as List? ?? [];
    final medicationsText = medicationsList
        .map((med) => med['name'] ?? '')
        .join(' • ');

    return InkWell(
      onTap: () => _handleCardTap(request),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
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
        child: Row(
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
                  request.patientName.isNotEmpty ? request.patientName[0]
                      .toUpperCase() : 'P',
                  style: const TextStyle(
                    fontSize: 20,
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        request.patientName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF6B6B).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'NEW',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFF6B6B),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${request.rxCode} • ${request.patientAge} years',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    medicationsText,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.primary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrescriptionCard(PrescriptionRequest request,
      Map<String, dynamic> prescriptionData,) {
    final isFullyAvailable = request.status ==
        PrescriptionStatus.fullyDispensed;
    final isPartiallyAvailable = request.status ==
        PrescriptionStatus.partiallyDispensed;
    final isDelivered = request.status == PrescriptionStatus.delivered;

    // Use same green color for all statuses (available, delivered, partial)
    const cardBorderColor = Color(0xFF4CA054);
    const statusBadgeColor = Color(0xFF4CA054);
    String statusText;

    if (isDelivered) {
      statusText = 'Delivered';
    } else if (isFullyAvailable) {
      statusText = 'Fully Available';
    } else if (isPartiallyAvailable) {
      statusText = 'Partially Available';
    } else {
      statusText = 'Issued';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.15),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: cardBorderColor,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with status badge
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9).withValues(alpha: 0.5),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: SvgPicture.asset(
                      'assets/icons/person_card_icon.svg',
                      colorFilter: const ColorFilter.mode(
                        Colors.white,
                        BlendMode.srcIn,
                      ),
                      width: 28,
                      height: 28,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${request.patientName}, ${request.patientAge}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${request.rxCode} • ${DateFormat('dd/MM/yyyy').format(
                            request.dateIssued)}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(statusBadgeColor, statusText),
              ],
            ),
          ),

          // Doctor Info
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                Icon(
                  Icons.local_hospital_outlined,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 6),
                Text(
                  request.doctorName,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),

          // Medications List
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Medications',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 12),
                ...request.medications
                    .asMap()
                    .entries
                    .map((entry) {
                  final index = entry.key;
                  final medication = entry.value;
                  return Padding(
                    padding: EdgeInsets.only(
                        bottom: index < request.medications.length - 1
                            ? 12
                            : 0),
                    child: _buildMedicationItem(medication, Colors.green),
                  );
                }),
              ],
            ),
          ),

          // Action Button
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _handleCardTap(request),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDelivered ? Colors.grey[300] : AppColors
                      .primary,
                  foregroundColor: isDelivered ? Colors.grey[600] : Colors
                      .white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: isDelivered
                    ? const Text(
                  'Already Delivered',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                )
                    : const Text(
                  'View Details & Deliver',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(Color color, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildMedicationItem(Medication medication, Color dotColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: dotColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              Icons.medication_outlined,
              size: 18,
              color: dotColor,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${medication.name} ${medication.dosage}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  medication.instructions,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleCardTap(PrescriptionRequest request) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PrescriptionDetailsScreen(request: request),
      ),
    );

    // Refresh prescriptions if returned true (data was updated)
    if (result == true && mounted) {
      await _loadInventory();
    }
  }
}
