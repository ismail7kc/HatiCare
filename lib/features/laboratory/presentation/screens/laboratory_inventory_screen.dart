import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:haticare/core/theme/app_colors.dart';
import 'package:provider/provider.dart';

import '../providers/laboratory_user_provider.dart';
import 'prescription_detail_screen.dart';

enum TestRequestStatus { issued, inProgress, completed }

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
  List<dynamic> _filteredPrescriptions = [];

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
    setState(() {
      _filteredPrescriptions = provider.assignedRequests;
    });
  }

  Future<void> _onRefresh() async {
    await _loadInventory();
    _rxCodeController.clear();
  }

  void _filterPrescriptions(String query, List<dynamic> allPrescriptions) {
    if (query.isEmpty) {
      setState(() {
        _filteredPrescriptions = allPrescriptions;
      });
      return;
    }

    final queryUpper = query.toUpperCase();
    setState(() {
      _filteredPrescriptions = allPrescriptions.where((prescription) {
        final rxCode = prescription['rex_code']?.toString().toUpperCase() ?? '';
        return rxCode.contains(queryUpper);
      }).toList();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _onRefresh();
    });
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
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Assigned',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
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
                            'Search Prescription',
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
                                  textCapitalization:
                                      TextCapitalization.characters,
                                  keyboardType: TextInputType.text,
                                  inputFormatters: [
                                    LengthLimitingTextInputFormatter(8),
                                    FilteringTextInputFormatter.allow(
                                      RegExp(r'[A-Z0-9]'),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    // Convert to uppercase
                                    if (value != value.toUpperCase()) {
                                      _rxCodeController.text = value
                                          .toUpperCase();
                                      _rxCodeController.selection =
                                          TextSelection.fromPosition(
                                            TextPosition(offset: value.length),
                                          );
                                    }
                                    // Trigger filtering
                                    _filterPrescriptions(
                                      _rxCodeController.text,
                                      laboratoryProvider.assignedRequests,
                                    );
                                  },
                                  decoration: InputDecoration(
                                    hintText:
                                        'Enter Rx Code (8 chars, e.g., 599147EF)',
                                    hintStyle: const TextStyle(
                                      color: Color(0xFF858585),
                                      fontSize: 14,
                                    ),
                                    suffixIcon:
                                        _rxCodeController.text.isNotEmpty
                                        ? IconButton(
                                            icon: const Icon(
                                              Icons.clear,
                                              size: 20,
                                            ),
                                            onPressed: () {
                                              _rxCodeController.clear();
                                              _filterPrescriptions(
                                                '',
                                                laboratoryProvider
                                                    .assignedRequests,
                                              );
                                            },
                                          )
                                        : null,
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
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    Colors.white,
                                                  ),
                                            ),
                                          )
                                        : const Text(
                                            'Search',
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

                  Padding(
                    padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Assigned Prescriptions',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (_rxCodeController.text.isNotEmpty)
                          Text(
                            'Showing ${_filteredPrescriptions.length} of ${laboratoryProvider.assignedRequests.length}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        if (!laboratoryProvider.isApproved) {
                          return _buildNotApprovedState();
                        }

                        // Show loading state while fetching assigned prescriptions
                        if (laboratoryProvider.assignedRequestsLoading) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                            ),
                          );
                        }

                        // Use filtered prescriptions for display
                        final testRequestsToDisplay = _filteredPrescriptions;

                        if (testRequestsToDisplay.isEmpty) {
                          // Check if it's empty due to filtering or no data
                          if (_rxCodeController.text.isNotEmpty &&
                              laboratoryProvider.assignedRequests.isNotEmpty) {
                            return _buildNoMatchingPrescriptions();
                          }
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
                                    'No New Request',
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
                                    labTests =
                                        (testRequestData['lab_tests'] as List)
                                            .map(
                                              (test) => LabTest(
                                                name: test['name'] ?? 'Unknown',
                                                dosage: test['dose'] ?? 'N/A',
                                                instructions:
                                                    '${test['frequency'] ?? ''} ${test['duration'] ?? ''} ${test['notes'] ?? ''}'
                                                        .trim(),
                                              ),
                                            )
                                            .toList();
                                  }

                                  final request = LabTestRequest(
                                    id:
                                        testRequestData['prescription_id']
                                            ?.toString() ??
                                        'N/A',
                                    rxCode:
                                        'RX...${testRequestData['rex_code_last4'] ?? 'N/A'}',
                                    patientName:
                                        testRequestData['patient_name'] ??
                                        'Unknown Patient',
                                    patientAge:
                                        int.tryParse(
                                          testRequestData['patient_age']
                                                  ?.toString() ??
                                              '0',
                                        ) ??
                                        0,
                                    patientGender:
                                        testRequestData['patient_gender'] ?? '',
                                    patientDob:
                                        testRequestData['patient_dob'] ?? '',
                                    doctorName:
                                        testRequestData['doctor_name'] ??
                                        'Dr. Unknown',
                                    doctorSpecialty:
                                        testRequestData['doctor_specialty'] ??
                                        '',
                                    dateIssued:
                                        DateTime.tryParse(
                                          testRequestData['created_at']
                                                  ?.toString() ??
                                              '',
                                        ) ??
                                        DateTime.now(),
                                    status: TestRequestStatus.issued,
                                    labTests: labTests,
                                  );

                                  request.patientPhone =
                                      testRequestData['patient_phone'] ?? '';
                                  request.notes =
                                      testRequestData['notes'] ?? '';
                                  request.fulfillmentScore =
                                      testRequestData['fulfillment_score'] ??
                                      0.0;

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 2),
                                    child: _buildTestRequestCard(
                                      request,
                                      testRequestData,
                                    ),
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
            Icon(Icons.lock_outline, size: 64, color: Colors.grey[300]),
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
              'Your laboratory account must be approved to view Assigned Prescriptions.',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyInventoryState() {
    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: AppColors.primary,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: SizedBox(
              height: constraints.maxHeight,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.science_outlined,
                      size: 64,
                      color: Colors.grey[300],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No Assigned Items',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[400],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Pull down to refresh',
                      style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTestRequestCard(
    LabTestRequest request,
    Map<String, dynamic> testRequestData,
  ) {
    // Determine status badge
    final isCompleted = request.status == TestRequestStatus.completed;
    String statusText;
    Color statusBgColor;
    Color statusTextColor;

    if (isCompleted) {
      statusText = 'COMPLETED';
      statusBgColor = const Color(0xFF4CA054).withValues(alpha: 0.1);
      statusTextColor = const Color(0xFF4CA054);
    } else {
      statusText = 'ASSIGNED';
      statusBgColor = const Color(0xFF4CA054).withValues(alpha: 0.1);
      statusTextColor = const Color(0xFF4CA054);
    }

    return InkWell(
      onTap: () => _handleCardTap(testRequestData),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(20),
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
        child: Column(
          children: [
            // Row 1: Prescription ID (Title) and Status Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  request.id.toString(),
                  // e.g. A6CC6D56
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusBgColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: statusTextColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Row 2: Person Icon + Patient Name
            Row(
              children: [
                Icon(Icons.person_outline, size: 20, color: Colors.grey[600]),
                const SizedBox(width: 12),
                Text(
                  request.patientName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),

            // Row 3: Phone Number (Indented)
            if (request.patientPhone.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 32, top: 4),
                child: Row(
                  children: [
                    Text(
                      request.patientPhone,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 12),

            // Row 4: Availability/Tests Content
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.inventory_2_outlined, // Box icon
                  size: 20,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: const TextSpan(
                          children: [
                            TextSpan(
                              text: 'N/A ',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
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
          ],
        ),
      ),
    );
  }

  Future<void> _handleCardTap(Map<String, dynamic> testRequestData) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            PrescriptionDetailScreen(prescription: testRequestData),
      ),
    );

    if (result == true && mounted) {
      await _loadInventory();
    }
  }

  Widget _buildNoMatchingPrescriptions() {
    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.5,
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off, size: 80, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'No Matching Prescriptions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'No prescriptions found for "${_rxCodeController.text}"',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () {
                  _rxCodeController.clear();
                  final provider = context.read<LaboratoryUserProvider>();
                  _filterPrescriptions('', provider.assignedRequests);
                },
                icon: const Icon(Icons.clear),
                label: const Text('Clear Search'),
                style: TextButton.styleFrom(foregroundColor: AppColors.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
