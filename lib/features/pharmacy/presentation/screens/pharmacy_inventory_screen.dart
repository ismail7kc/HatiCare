import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:haticare/core/theme/app_colors.dart';
import 'package:haticare/features/pharmacy/models/prescription_request.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/pharmacy_user_provider.dart';
import 'assigned_detail_screen.dart';

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
              crossAxisAlignment: CrossAxisAlignment.start,
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
                const SizedBox(height: 4),

                // Inventory Content
                const Padding(
                  padding: EdgeInsets.only(left: 18.0),
                  child: Text(
                    'Assigned Prescriptions',
                    textAlign: TextAlign.start,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Builder(
                    builder: (context) {
                      if (!pharmacyProvider.isApproved) {
                        return _buildNotApprovedState();
                      }

                      final prescriptionsToDisplay =
                          pharmacyProvider.prescriptions;

                      if (prescriptionsToDisplay.isEmpty) {
                        return _buildEmptyInventoryState();
                      }

                      return RefreshIndicator(
                        onRefresh: _onRefresh,
                        color: AppColors.primary,
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          children: [
                            if (prescriptionsToDisplay.isEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 24,
                                ),
                                alignment: Alignment.center,
                                child: const Text(
                                  'No assigned prescriptions yet.',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                ),
                              )
                            else
                              ...prescriptionsToDisplay.asMap().entries.map(
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
                                              prescriptionsToDisplay.length - 1
                                          ? 16
                                          : 16,
                                    ),
                                    child: _buildAssignedPrescriptionCard(
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







  Future<void> _handleCardTap(PrescriptionRequest request) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AssignedDetailScreen(request: request),
      ),
    );

    // Refresh prescriptions if returned true (data was updated)
    if (result == true && mounted) {
      await _loadInventory();
    }
  }

  Widget _buildAssignedPrescriptionCard(PrescriptionRequest request, Map<String, dynamic> prescriptionData) {
    final formattedDate = DateFormat('dd-MM-yyyy').format(request.dateIssued);
    final medicationSummary = request.medications
        .map((med) => med.name)
        .where((name) => name.isNotEmpty)
        .join(', ');

    return InkWell(
      onTap: () => _handleCardTap(request),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with RX Code and Date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'RX Code : ${request.rxCode}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                Text(
                  formattedDate,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Patient Information with Icon
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${request.patientName}, ${request.patientAge}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Medications with Arrow
            Row(
              children: [
                Expanded(
                  child: Text(
                    medicationSummary,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.primary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                SvgPicture.asset(
                  'assets/icons/arrow_forward_line_icon.svg',
                  width: 20,
                  height: 20,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
