import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:haticare/core/theme/app_colors.dart';
import 'package:provider/provider.dart';
import '../providers/laboratory_user_provider.dart';

class LaboratoryInventoryScreen extends StatefulWidget {
  const LaboratoryInventoryScreen({super.key});

  @override
  State<LaboratoryInventoryScreen> createState() => _LaboratoryInventoryScreenState();
}

class _LaboratoryInventoryScreenState extends State<LaboratoryInventoryScreen> {
  late TextEditingController _searchController;
  late TextEditingController _rxCodeController;
  List<dynamic> _filteredPrescriptions = [];
  List<dynamic> _availableTests = [];
  List<dynamic> _unavailableTests = [];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _rxCodeController = TextEditingController();
    _loadPrescriptions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _rxCodeController.dispose();
    super.dispose();
  }

  Future<void> _loadPrescriptions() async {
    final provider = context.read<LaboratoryUserProvider>();
    await provider.fetchAssignedPrescriptions();
    _categorizeTests(provider.prescriptions);
  }

  void _categorizeTests(List<dynamic> prescriptions) {
    _availableTests = [];
    _unavailableTests = [];
    _filteredPrescriptions = prescriptions;

    for (var prescription in prescriptions) {
      // Check if test is marked as available (you can add a field in your API)
      // For now, we'll use a simple toggle state
      if (prescription['is_available'] == true) {
        _availableTests.add(prescription);
      } else {
        _unavailableTests.add(prescription);
      }
    }
    
    setState(() {});
  }

  void _filterTests(String query) {
    if (query.isEmpty) {
      _categorizeTests(context.read<LaboratoryUserProvider>().prescriptions);
      return;
    }

    final filtered = context.read<LaboratoryUserProvider>().prescriptions
        .where((prescription) {
          final patientName = prescription['patient_name']?.toString().toLowerCase() ?? '';
          final testName = _getLabTestNames(prescription).toLowerCase();
          return patientName.contains(query.toLowerCase()) || 
                 testName.contains(query.toLowerCase());
        }).toList();
    
    _categorizeTests(filtered);
  }

  String _getLabTestNames(Map<String, dynamic> prescription) {
    if (prescription['lab_tests'] is List) {
      return (prescription['lab_tests'] as List)
          .map((test) => test is Map<String, dynamic> 
              ? test['name']?.toString() ?? ''
              : test.toString())
          .join(', ');
    }
    return '';
  }

  Future<void> _toggleTestAvailability(Map<String, dynamic> prescription, bool isAvailable) async {
    final prescriptionId = prescription['prescription_id']?.toString() ?? '';
    
    // Update local state first for immediate UI feedback
    setState(() {
      prescription['is_available'] = isAvailable;
      _categorizeTests(context.read<LaboratoryUserProvider>().prescriptions);
    });

    // Call API to update test availability
    await context.read<LaboratoryUserProvider>().updateTestAvailability(prescriptionId, isAvailable);
    
    // Refresh the list to get updated data
    await _refreshPrescriptions();
  }

  Future<void> _refreshPrescriptions() async {
    final provider = context.read<LaboratoryUserProvider>();
    await provider.fetchAssignedPrescriptions();
    _categorizeTests(provider.prescriptions);
  }

  Future<void> _verifyRxCode(LaboratoryUserProvider provider) async {
    if (_rxCodeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter an RX code'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_rxCodeController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('RX code must be at least 6 characters'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    await provider.verifyRxCode(_rxCodeController.text);

    if (provider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage!),
          backgroundColor: Colors.red,
        ),
      );
    } else if (provider.verifiedRxCode.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('RX Code verified successfully. Test request details are now displayed below.'),
          backgroundColor: Colors.green,
        ),
      );
      // Refresh to show verified test requests
      await _refreshPrescriptions();
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
          'Lab Test Inventory',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _refreshPrescriptions,
            icon: const Icon(Icons.refresh, color: Colors.black),
          ),
        ],
      ),
      body: Consumer<LaboratoryUserProvider>(
        builder: (context, provider, child) {
          if (provider.prescriptionsLoading) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            );
          }

          if (provider.prescriptions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    'assets/icons/empty_inventory.svg',
                    width: 120,
                    height: 120,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Lab Tests Available',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Lab tests will appear here once prescribed',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Verify RX Code Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Verify Test Request',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _rxCodeController,
                            enabled: provider.verifiedRxCode.isEmpty,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                            decoration: InputDecoration(
                              hintText: provider.verifiedRxCode.isNotEmpty
                                  ? provider.verifiedRxCode
                                  : 'Enter RX Code',
                              hintStyle: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                              filled: true,
                              fillColor: Colors.white.withValues(alpha: 0.1),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        ElevatedButton(
                          onPressed:
                              provider.verifiedRxCode.isNotEmpty
                              ? () {
                                  provider.clearSearch();
                                  _rxCodeController.clear();
                                }
                              : () {
                                  _verifyRxCode(provider);
                                },
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                            backgroundColor:
                                provider
                                        .verifiedRxCode
                                        .isNotEmpty
                                    ? Colors.red
                                    : Colors.transparent,
                            shadowColor: Colors.transparent,
                          ),
                          child: Ink(
                            decoration: BoxDecoration(
                              gradient:
                                  provider
                                          .verifiedRxCode
                                          .isNotEmpty
                                      ? null
                                      : AppColors.primaryGradient,
                              color:
                                  provider
                                          .verifiedRxCode
                                          .isNotEmpty
                                      ? null
                                      : null,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 26,
                                vertical: 12,
                              ),
                              alignment: Alignment.center,
                              child: provider.isVerifying
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
                                  : Text(
                                          provider
                                                  .verifiedRxCode
                                                  .isNotEmpty
                                              ? 'Clear'
                                              : 'Verify',
                                          style: const TextStyle(
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

              // Search Bar
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  onChanged: _filterTests,
                  decoration: InputDecoration(
                    hintText: 'Search by patient name or test...',
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),

              // Summary Cards
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        'Available',
                        _availableTests.length,
                        Colors.green,
                        Icons.check_circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSummaryCard(
                        'Unavailable',
                        _unavailableTests.length,
                        Colors.orange,
                        Icons.pending,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Test Lists
              Expanded(
                child: DefaultTabController(
                  length: 2,
                  child: Column(
                    children: [
                      TabBar(
                        labelColor: AppColors.primary,
                        unselectedLabelColor: Colors.grey,
                        indicatorColor: AppColors.primary,
                        tabs: [
                          Tab(text: 'Available (${_availableTests.length})'),
                          Tab(text: 'Unavailable (${_unavailableTests.length})'),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            _buildTestList(_availableTests, true),
                            _buildTestList(_unavailableTests, false),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(String title, int count, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestList(List<dynamic> tests, bool isAvailable) {
    if (tests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isAvailable ? Icons.check_circle : Icons.pending,
              size: 64,
              color: isAvailable ? Colors.green : Colors.orange,
            ),
            const SizedBox(height: 16),
            Text(
              isAvailable ? 'No Available Tests' : 'No Unavailable Tests',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tests.length,
      itemBuilder: (context, index) {
        final prescription = tests[index];
        return _buildTestCard(prescription, isAvailable);
      },
    );
  }

  Widget _buildTestCard(Map<String, dynamic> prescription, bool isAvailable) {
    final patientName = prescription['patient_name']?.toString() ?? 'Unknown Patient';
    final prescriptionId = prescription['prescription_id']?.toString() ?? '';
    final labTests = _getLabTestNames(prescription);
    final createdAt = prescription['created_at']?.toString() ?? '';
    
    DateTime issuedDate = DateTime.now();
    if (createdAt.isNotEmpty) {
      issuedDate = DateTime.tryParse(createdAt) ?? issuedDate;
    }
    
    final formattedDate = '${issuedDate.day}-${issuedDate.month}-${issuedDate.year}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isAvailable ? Colors.green.shade300 : Colors.grey.shade300,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isAvailable 
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isAvailable ? Icons.check_circle : Icons.pending,
                    color: isAvailable ? Colors.green : Colors.grey,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Lab Test #$prescriptionId',
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
                ),
                Switch(
                  value: isAvailable,
                  onChanged: (value) => _toggleTestAvailability(prescription, value),
                  activeColor: AppColors.primary,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Patient: $patientName',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            if (labTests.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Tests: $labTests',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
