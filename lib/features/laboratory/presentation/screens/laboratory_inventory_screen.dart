import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:haticare/core/theme/app_colors.dart';
import 'package:haticare/features/laboratory/models/test_request.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/laboratory_user_provider.dart';
import 'test_request_detail_screen.dart';

enum TestRequestStatus {
  issued,
  inProgress,
  completed,
}

class LabTestRequest {
  final String id;
  final String rxCode;
  final String patientName;
  final int patientAge;
  final String patientGender;
  final String patientDob;
  final String doctorName;
  final String doctorSpecialty;
  final DateTime dateIssued;
  final TestRequestStatus status;
  final List<LabTest> labTests;
  
  // Additional fields for API data
  late String patientPhone;
  late String notes;
  late double fulfillmentScore;

  LabTestRequest({
    required this.id,
    required this.rxCode,
    required this.patientName,
    required this.patientAge,
    required this.patientGender,
    required this.patientDob,
    required this.doctorName,
    required this.doctorSpecialty,
    required this.dateIssued,
    required this.status,
    required this.labTests,
  });
}

class LabTest {
  final String name;
  final String dosage;
  final String instructions;

  LabTest({
    required this.name,
    required this.dosage,
    required this.instructions,
  });
}

class LaboratoryInventoryScreen extends StatefulWidget {
  const LaboratoryInventoryScreen({super.key});

  @override
  State<LaboratoryInventoryScreen> createState() =>
      _LaboratoryInventoryScreenState();
}

class _LaboratoryInventoryScreenState extends State<LaboratoryInventoryScreen> {
  late TextEditingController _searchController;
  late TextEditingController _rxCodeController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _rxCodeController = TextEditingController();
    _loadInventory();
  }

  Future<void> _loadInventory() async {
    final provider = context.read<LaboratoryUserProvider>();
    await provider.fetchAssignedPrescriptions();
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

  Future<void> _verifyRxCode(LaboratoryUserProvider provider) async {
    // Check approval status first
    if (!provider.isApproved) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Your laboratory account is not approved.'),
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
            content: Text('RX Code verified! Go to Inventory to process.'),
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
        child: Consumer<LaboratoryUserProvider>(
          builder: (context, laboratoryProvider, child) {
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
                              onPressed: laboratoryProvider.isApproved
                                  ? () {
                                _verifyRxCode(laboratoryProvider);
                              }
                                  : null,
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 0,
                                backgroundColor: laboratoryProvider.isApproved
                                    ? Colors.transparent
                                    : Colors.grey[300],
                                shadowColor: Colors.transparent,
                              ),
                              child: Ink(
                                decoration: BoxDecoration(
                                  gradient: laboratoryProvider.isApproved
                                      ? AppColors.primaryGradient
                                      : null,
                                  color: laboratoryProvider.isApproved
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
                                  child: laboratoryProvider.isVerifying
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
                      if (!laboratoryProvider.isApproved) {
                        return _buildNotApprovedState();
                      }

                      // Show loading state while fetching prescriptions
                      if (laboratoryProvider.prescriptionsLoading) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        );
                      }

                      // Use real test requests from provider
                      final testRequestsToDisplay = laboratoryProvider.prescriptions;

                      if (testRequestsToDisplay.isEmpty) {
                        return _buildEmptyInventoryState();
                      }

                      return RefreshIndicator(
                        onRefresh: _onRefresh,
                        color: AppColors.primary,
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          children: [
                            if (testRequestsToDisplay.isEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 24,
                                ),
                                alignment: Alignment.center,
                                child: const Text(
                                  'No new request',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                ),
                              )
                            else
                              ...testRequestsToDisplay.map((testRequestData) {
                                List<LabTest> labTests = [];
                                if (testRequestData['lab_tests'] is List) {
                                  labTests = (testRequestData['lab_tests'] as List)
                                      .map(
                                        (test) => LabTest(
                                          name: test['name'] ?? 'Unknown',
                                          dosage: test['dose'] ?? 'N/A',
                                          instructions:
                                              '${test['frequency'] ?? ''} ${test['duration'] ?? ''} ${test['notes'] ?? ''}'.trim(),
                                        ),
                                      )
                                      .toList();
                                }

                                final request = LabTestRequest(
                                  id: testRequestData['prescription_id']
                                          ?.toString() ??
                                      'N/A',
                                  rxCode:
                                      'RX...${testRequestData['rex_code_last4'] ?? 'N/A'}',
                                  patientName: testRequestData['patient_name'] ??
                                      'Unknown Patient',
                                  patientAge: int.tryParse(
                                          testRequestData['patient_age']
                                              ?.toString() ??
                                              '0') ??
                                      0,
                                  patientGender:
                                      testRequestData['patient_gender'] ?? '',
                                  patientDob: testRequestData['patient_dob'] ?? '',
                                  doctorName:
                                      testRequestData['doctor_name'] ?? 'Dr. Unknown',
                                  doctorSpecialty:
                                      testRequestData['doctor_specialty'] ?? '',
                                  dateIssued: DateTime.tryParse(
                                      testRequestData['created_at']?.toString() ?? '') ?? DateTime.now(),
                                  status: TestRequestStatus.issued,
                                  labTests: labTests,
                                );

                                request.patientPhone =
                                    testRequestData['patient_phone'] ?? '';
                                request.notes =
                                    testRequestData['notes'] ?? '';
                                request.fulfillmentScore =
                                    testRequestData['fulfillment_score'] ?? 0.0;

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: _buildNewRequestCard(
                                      request, testRequestData),
                                );
                              }),
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
              'Your laboratory account must be approved to view inventory.',
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
              Icons.science_outlined,
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
          ],
        ),
      ),
    );
  }

  Widget _buildNewRequestCard(LabTestRequest request,
      Map<String, dynamic> testRequestData,) {
    final labTestsList = testRequestData['lab_tests'] as List? ?? [];
    final labTestsText = labTestsList
        .map((test) => test['name'] ?? '')
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
                    labTestsText,
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

  Widget _buildTestRequestCard(LabTestRequest request,
      Map<String, dynamic> testRequestData,) {
    final isFullyAvailable = request.status ==
        TestRequestStatus.completed;
    final isPartiallyAvailable = request.status ==
        TestRequestStatus.inProgress;
    final isCompleted = request.status == TestRequestStatus.completed;

    // Use same green color for all statuses (available, completed, partial)
    const cardBorderColor = Color(0xFF4CA054);
    const statusBadgeColor = Color(0xFF4CA054);
    String statusText;

    if (isCompleted) {
      statusText = 'Completed';
    } else if (isFullyAvailable) {
      statusText = 'Fully Available';
    } else if (isPartiallyAvailable) {
      statusText = 'In Progress';
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

          // Lab Tests List
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Lab Tests',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 12),
                ...request.labTests
                    .asMap()
                    .entries
                    .map((entry) {
                  final index = entry.key;
                  final labTest = entry.value;
                  return Padding(
                    padding: EdgeInsets.only(
                        bottom: index < request.labTests.length - 1
                            ? 12
                            : 0),
                    child: _buildLabTestItem(labTest, Colors.green),
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
                  backgroundColor: isCompleted ? Colors.grey[300] : AppColors
                      .primary,
                  foregroundColor: isCompleted ? Colors.grey[600] : Colors
                      .white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: isCompleted
                    ? const Text(
                  'Already Completed',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                )
                    : const Text(
                  'View Details & Process',
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

  Widget _buildLabTestItem(LabTest labTest, Color dotColor) {
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
              Icons.science_outlined,
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
                  '${labTest.name} ${labTest.dosage}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  labTest.instructions,
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

  Future<void> _handleCardTap(LabTestRequest request) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TestRequestDetailScreen(
          testRequest: TestRequest(
            requestId: request.id,
            patientName: '${request.patientName}, ${request.patientAge}',
            doctorName: request.doctorName,
            dateIssued: DateFormat('dd/MM/yyyy').format(request.dateIssued),
            tests: request.labTests.map((test) => test.name).toList(),
            status: _getStatusText(request.status),
          ),
        ),
      ),
    );

    // Refresh test requests if returned true (data was updated)
    if (result == true && mounted) {
      await _loadInventory();
    }
  }

  String _getStatusText(TestRequestStatus status) {
    switch (status) {
      case TestRequestStatus.issued:
        return 'Issued';
      case TestRequestStatus.inProgress:
        return 'In Progress';
      case TestRequestStatus.completed:
        return 'Completed';
    }
  }
}
