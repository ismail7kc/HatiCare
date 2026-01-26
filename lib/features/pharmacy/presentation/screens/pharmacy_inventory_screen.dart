import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:haticare/core/theme/app_colors.dart';
import 'package:haticare/features/pharmacy/models/prescription_request.dart';
import 'package:provider/provider.dart';
import '../providers/pharmacy_user_provider.dart';
import '../widgets/pharmacy_inventory_card.dart';
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

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _rxCodeController = TextEditingController();
    _loadInventory();
  }

  Future<void> _loadInventory() async {
    final provider = context.read<PharmacyUserProvider>();
    // Fetch prescriptions using inventory-specific endpoint
    await provider.fetchPrescriptionsForInventory();
  }

  Future<void> _onRefresh() async {
    final provider = context.read<PharmacyUserProvider>();
    await provider.fetchPrescriptionsForInventory();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _rxCodeController.dispose();
    super.dispose();
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
            return RefreshIndicator(
              onRefresh: _onRefresh,
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
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
                                    controller: _searchController,
                                    textCapitalization:
                                        TextCapitalization.characters,
                                    keyboardType: TextInputType.text,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                        RegExp(r'[A-Z0-9]'),
                                      ),
                                    ],
                                    onChanged: (value) {
                                      if (value != value.toUpperCase()) {
                                        _searchController.text = value
                                            .toUpperCase();
                                        _searchController.selection =
                                            TextSelection.fromPosition(
                                              TextPosition(
                                                offset: value.length,
                                              ),
                                            );
                                      }
                                      setState(() {});
                                    },
                                    decoration: InputDecoration(
                                      hintText: 'Search RX Code (min 3 chars)',
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
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                ElevatedButton(
                                  onPressed: _searchController.text.length >= 3
                                      ? () {
                                          setState(() {});
                                        }
                                      : null,
                                  style: ElevatedButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    elevation: 0,
                                    backgroundColor:
                                        _searchController.text.length >= 3
                                        ? Colors.transparent
                                        : Colors.grey[300],
                                    shadowColor: Colors.transparent,
                                  ),
                                  child: Ink(
                                    decoration: BoxDecoration(
                                      gradient:
                                          _searchController.text.length >= 3
                                          ? AppColors.primaryGradient
                                          : null,
                                      color: _searchController.text.length >= 3
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
                                      child: const Text(
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
                    // Temporary debug info
                    Container(
                      padding: const EdgeInsets.all(8),
                      margin: const EdgeInsets.only(bottom: 8),
                      color: Colors.grey[100],
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'DEBUG: Is Approved: ${pharmacyProvider.isApproved}',
                            style: TextStyle(fontSize: 10),
                          ),
                          Text(
                            'DEBUG: Prescriptions Count: ${pharmacyProvider.prescriptions.length}',
                            style: TextStyle(fontSize: 10),
                          ),
                          Text(
                            'DEBUG: Loading: ${pharmacyProvider.prescriptionsLoading}',
                            style: TextStyle(fontSize: 10),
                          ),
                          if (pharmacyProvider.errorMessage != null)
                            Text(
                              'DEBUG: Error: ${pharmacyProvider.errorMessage}',
                              style: TextStyle(fontSize: 10, color: Colors.red),
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Builder(
                        builder: (context) {
                          if (!pharmacyProvider.isApproved) {
                            return _buildNotApprovedState();
                          }

                          if (pharmacyProvider.prescriptionsLoading &&
                              pharmacyProvider.prescriptions.isEmpty) {
                            return const Center(
                              child: CircularProgressIndicator(
                                color: AppColors.primary,
                              ),
                            );
                          }

                          final query = _searchController.text;
                          print(
                            'DEBUG: Search query: "$query" (length: ${query.length})',
                          );
                          print(
                            'DEBUG: Total prescriptions: ${pharmacyProvider.prescriptions.length}',
                          );
                          print('DEBUG: Query length < 3: ${query.length < 3}');

                          final prescriptionsToDisplay = query.length < 3
                              ? pharmacyProvider.prescriptions
                              : pharmacyProvider.prescriptions.where((
                                  prescription,
                                ) {
                                  final rxCode =
                                      prescription['rex_code']
                                          ?.toString()
                                          .toLowerCase() ??
                                      '';
                                  final matches = rxCode.contains(
                                    query.toLowerCase(),
                                  );
                                  print(
                                    'DEBUG: Checking RX Code "$rxCode" against query "$query": $matches',
                                  );
                                  return matches;
                                }).toList();

                          print(
                            'DEBUG: Prescriptions to display: ${prescriptionsToDisplay.length}',
                          );

                          if (pharmacyProvider.prescriptions.isNotEmpty) {
                            print(
                              'DEBUG: First prescription data: ${pharmacyProvider.prescriptions.first}',
                            );
                            print(
                              'DEBUG: First prescription keys: ${pharmacyProvider.prescriptions.first.keys.toList()}',
                            );
                          }

                          if (prescriptionsToDisplay.isEmpty) {
                            return SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              child: _buildEmptyInventoryState(
                                searchQuery: _searchController.text,
                              ),
                            );
                          }

                          return ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                            children: [
                              ...prescriptionsToDisplay.asMap().entries.map((
                                entry,
                              ) {
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
                                                  '${med['frequency'] ?? ''} ${med['duration'] ?? ''} ${med['notes'] ?? ''}'
                                                      .trim(),
                                            ),
                                          )
                                          .toList();
                                } else if (prescriptionData['items'] is List) {
                                  medications = (prescriptionData['items'] as List)
                                      .map(
                                        (med) => Medication(
                                          name: med['name'] ?? 'Unknown',
                                          dosage: med['dose'] ?? 'N/A',
                                          instructions:
                                              '${med['frequency'] ?? ''} ${med['duration'] ?? ''} ${med['notes'] ?? ''}'
                                                  .trim(),
                                        ),
                                      )
                                      .toList();
                                }

                                PrescriptionStatus status =
                                    _getStatusFromString(
                                      prescriptionData['pharmacy_status']
                                              ?.toString() ??
                                          'assigned',
                                    );

                                final request = PrescriptionRequest(
                                  id:
                                      prescriptionData['prescription_id']
                                          ?.toString() ??
                                      'N/A',
                                  rxCode: prescriptionData['rex_code'] ?? 'N/A',
                                  patientName:
                                      prescriptionData['patient_name'] ??
                                      'Unknown Patient',
                                  patientAge: 0,
                                  // Not in API response
                                  patientGender: 'Male',
                                  // Not in API response
                                  patientDob: '1992-11-15',
                                  // Not in API response
                                  doctorName: 'Dr. Unknown',
                                  // Not in API response
                                  doctorSpecialty: 'General Physician',
                                  // Not in API response
                                  dateIssued: DateTime.now(),
                                  // Not in API response
                                  status: status,
                                  medications:
                                      [], // Empty list since medications not in this API response
                                );

                                request.patientPhone =
                                    prescriptionData['patient_phone'] ?? '';
                                request.notes = ''; // Not in API response
                                request.fulfillmentScore =
                                    0.0; // Not in API response

                                final rxCode =
                                    prescriptionData['rex_code']?.toString() ??
                                    'N/A';
                                final isVerified =
                                    prescriptionData['is_verified'] == true;

                                return Padding(
                                  padding: EdgeInsets.only(
                                    bottom:
                                        index ==
                                            prescriptionsToDisplay.length - 1
                                        ? 16
                                        : 16,
                                  ),
                                  child: PharmacyInventoryCard(
                                    request: request,
                                    isVerified: true,
                                    // Always true since we're removing verification
                                    onVerify: null,
                                    // No verification functionality
                                    onTap: () => _handleCardTap(
                                      request,
                                    ), // Always allow tap
                                  ),
                                );
                              }),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildNotApprovedState() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Center(
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
                'Your pharmacy account must be approved to view inventory.',
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyInventoryState({String searchQuery = ''}) {
    final bool isSearching = searchQuery.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSearching
                ? Icons.search_off_outlined
                : Icons.inventory_2_outlined,
            size: 64,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 20),
          Text(
            isSearching ? 'No Prescription Found' : 'No assigned prescriptions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isSearching
                ? 'No prescription available for RX code: "$searchQuery"'
                : 'Pull down to refresh',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  PrescriptionStatus _getStatusFromString(String statusStr) {
    switch (statusStr.toLowerCase()) {
      case 'assigned':
        return PrescriptionStatus.issued;
      case 'delivered':
        return PrescriptionStatus.delivered;
      case 'completed':
        return PrescriptionStatus.fullyDispensed;
      case 'full':
        return PrescriptionStatus.fullyDispensed;
      case 'partial':
        return PrescriptionStatus.partiallyDispensed;
      default:
        return PrescriptionStatus.issued;
    }
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
}
