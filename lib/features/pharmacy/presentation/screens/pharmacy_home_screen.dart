import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:haticare/core/theme/app_colors.dart';
import 'package:haticare/features/common/customNav_Bottom.dart';
import 'package:haticare/features/pharmacy/models/prescription_request.dart';
import 'package:haticare/features/pharmacy/presentation/screens/pharmacy_history_screen.dart';
import 'package:haticare/features/pharmacy/presentation/screens/pharmacy_inventory_screen.dart';
import 'package:haticare/features/pharmacy/presentation/screens/pharmacy_notifications_screen.dart';
import 'package:haticare/features/pharmacy/presentation/screens/pharmacy_settings_screen.dart';
import 'package:haticare/features/pharmacy/presentation/screens/prescription_details_screen.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/pharmacy_user_provider.dart';

class PharmacyHomeScreen extends StatefulWidget {
  const PharmacyHomeScreen({super.key});

  @override
  State<PharmacyHomeScreen> createState() => _PharmacyHomeScreenState();
}

class _PharmacyHomeScreenState extends State<PharmacyHomeScreen> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PharmacyUserProvider(),
      child: CustomBottomNav(
        screens: const [
          PharmacyHomeTabScreen(),
          PharmacyInventoryScreen(),
          PharmacyHistoryScreen(),
          PharmacySettingsScreen(),
        ],
        tabs: const [
          TabItemData(title: "Home", iconPath: 'assets/icons/home.svg'),
          TabItemData(title: "Inventory", iconPath: 'assets/icons/inventory.svg'),
          TabItemData(title: "History", iconPath: 'assets/icons/history.svg'),
          TabItemData(title: "Settings", iconPath: 'assets/icons/setting.svg'),
        ],
      ),
    );
  }
}

class PharmacyHomeTabScreen extends StatefulWidget {
  const PharmacyHomeTabScreen({super.key});

  @override
  State<PharmacyHomeTabScreen> createState() => _PharmacyHomeTabScreenState();
}

class _PharmacyHomeTabScreenState extends State<PharmacyHomeTabScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // Fetch prescriptions on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PharmacyUserProvider>().fetchPrescriptions();
    });
  }

  Future<void> _onRefresh() async {
    final provider = context.read<PharmacyUserProvider>();
    // Fetch profile to check approval status
    await provider.fetchProfile(forceRefresh: true);
    // Fetch prescriptions if approved
    if (provider.isApproved) {
      await provider.fetchPrescriptions();
    }
  }

  // Calculate available count for summary card
  int _getAvailableCount(List<dynamic> prescriptions) {
    int available = 0;
    int partiallyAvailable = 0;
    for (final prescription in prescriptions) {
      final availability =
          prescription['availability']?.toString().toLowerCase() ?? 'pending';
      if (availability.contains('full')) {
        available++;
      } else if (availability.contains('partial')) {
        partiallyAvailable++;
      }
    }
    return available + partiallyAvailable;
  }

  // Calculate delivered count
  int _getDeliveredCount(List<dynamic> prescriptions) {
    int delivered = 0;
    for (final prescription in prescriptions) {
      final availability =
          prescription['availability']?.toString().toLowerCase() ?? 'pending';
      if (availability.contains('delivered')) {
        delivered++;
      }
    }
    return delivered;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    final pharmacyProvider = context.watch<PharmacyUserProvider>();
    final availableCount = _getAvailableCount(pharmacyProvider.prescriptions);
    final deliveredCount = _getDeliveredCount(pharmacyProvider.prescriptions);
    final prescriptionsRaw = pharmacyProvider.prescriptions;
    final isLoadingPrescriptions = pharmacyProvider.prescriptionsLoading;
    final hasFetchedPrescriptions = prescriptionsRaw.isNotEmpty;

    final List<Map<String, dynamic>> newRequestsRaw = prescriptionsRaw
        .whereType<Map<String, dynamic>>()
        .where((p) {
          final statusStr =
              p['availability']?.toString().toLowerCase() ?? '';
          return !statusStr.contains('delivered') &&
              !statusStr.contains('full') &&
              !statusStr.contains('partial');
        })
        .toList();

    final List<PrescriptionRequest> newRequestPrescriptions = [];
    if (newRequestsRaw.isNotEmpty) {
      newRequestPrescriptions
          .addAll(newRequestsRaw.map(_mapToPrescriptionRequest));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header View
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      pharmacyProvider.isLoading
                          ? const CircleAvatar(
                              radius: 25,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.primary,
                                ),
                              ),
                            )
                          : CircleAvatar(
                              radius: 25,
                              backgroundImage:
                                  pharmacyProvider.profilePictureUrl.isNotEmpty
                                      ? NetworkImage(
                                          pharmacyProvider.profilePictureUrl,
                                        )
                                      : null,
                              child: pharmacyProvider.profilePictureUrl.isEmpty
                                  ? const Icon(Icons.person, size: 30)
                                  : null,
                            ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Welcome Back,",
                            style: TextStyle(color: Colors.grey),
                          ),
                          pharmacyProvider.isLoading
                              ? const SizedBox(
                                  width: 100,
                                  height: 18,
                                  child: LinearProgressIndicator(
                                    backgroundColor: Colors.grey,
                                    valueColor:
                                        AlwaysStoppedAnimation<Color>(
                                      AppColors.primary,
                                    ),
                                  ),
                                )
                              : Text(
                                  pharmacyProvider.pharmacyName.isNotEmpty
                                      ? (pharmacyProvider.pharmacyName.length >
                                              15
                                          ? '${pharmacyProvider.pharmacyName.substring(0, 15)}...'
                                          : pharmacyProvider.pharmacyName)
                                      : 'Pharmacy',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                        ],
                      ),
                    ],
                  ),
                  Stack(
                    children: [
                      IconButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const PharmacyNotificationsScreen(),
                            ),
                          );
                        },
                        icon: SvgPicture.asset(
                          'assets/icons/notification.svg',
                          height: 26,
                          color: Colors.black87,
                        ),
                      ),
                      const Positioned(
                        right: 8,
                        top: 8,
                        child: CircleAvatar(
                          radius: 4,
                          backgroundColor: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              if (!pharmacyProvider.isApproved &&
                  pharmacyProvider.approvalMessage.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.orange.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_outlined,
                        color: Colors.orange[700],
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Account Status',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.orange[700],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              pharmacyProvider.approvalMessage,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.orange[600],
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              if (!pharmacyProvider.isApproved &&
                  pharmacyProvider.approvalMessage.isNotEmpty)
                const SizedBox(height: 24),

              if (!pharmacyProvider.isApproved)
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.lock_outline,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Waiting for Approval',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Your pharmacy account must be approved to view prescription statistics.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              else ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Container(
                        height: 80,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF54DCDF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(left: 16.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$availableCount',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2443A9),
                                ),
                              ),
                              const Text(
                                'Available Prescriptions',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF2443A9),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        height: 80,
                        margin: const EdgeInsets.only(left: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF07498A),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(left: 16.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$deliveredCount',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const Text(
                                'Delivered Prescriptions',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'New Requests',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _onRefresh,
                    color: AppColors.primary,
                    child:
                        isLoadingPrescriptions && !hasFetchedPrescriptions
                            ? ListView(
                                physics:
                                    const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.only(
                                  bottom: 80,
                                  top: 80,
                                ),
                                children: const [
                                  Center(child: CircularProgressIndicator()),
                                ],
                              )
                            : newRequestPrescriptions.isEmpty
                                ? ListView(
                                    physics:
                                        const AlwaysScrollableScrollPhysics(),
                                    padding: const EdgeInsets.only(
                                      bottom: 80,
                                      top: 40,
                                    ),
                                    children: const [
                                      Center(
                                        child: Text(
                                          'No new prescription requests yet.',
                                          style: TextStyle(
                                            color: Colors.grey,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : ListView.builder(
                                    physics:
                                        const AlwaysScrollableScrollPhysics(),
                                    padding:
                                        const EdgeInsets.only(bottom: 80),
                                    itemCount: newRequestPrescriptions.length,
                                    itemBuilder: (context, index) {
                                      final request =
                                          newRequestPrescriptions[index];
                                      return Padding(
                                        padding: EdgeInsets.only(
                                          bottom: index <
                                                  newRequestPrescriptions
                                                          .length -
                                                      1
                                              ? 12
                                              : 0,
                                        ),
                                        child: _buildRequestCard(request),
                                      );
                                    },
                                  ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }


  Future<void> _openPrescriptionDetails(PrescriptionRequest request) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PrescriptionDetailsScreen(request: request),
      ),
    );

    if (result == true && mounted) {
      await _onRefresh();
    }
  }

  PrescriptionRequest _mapToPrescriptionRequest(Map<String, dynamic> data) {
    List<Medication> medications = [];
    if (data['medications'] is List) {
      medications = (data['medications'] as List)
          .map((med) {
            if (med is Map<String, dynamic>) {
              return Medication(
                name: med['name']?.toString() ?? 'Unknown',
                dosage: med['dose']?.toString() ?? '',
                instructions:
                    '${med['frequency'] ?? ''} ${med['duration'] ?? ''} ${med['notes'] ?? ''}'
                        .trim(),
              );
            }
            return Medication(
              name: med.toString(),
              dosage: '',
              instructions: '',
            );
          })
          .toList();
    }

    PrescriptionStatus status = PrescriptionStatus.issued;
    final statusStr = data['availability']?.toString().toLowerCase() ?? '';
    if (statusStr.contains('delivered')) {
      status = PrescriptionStatus.delivered;
    } else if (statusStr.contains('full')) {
      status = PrescriptionStatus.fullyDispensed;
    } else if (statusStr.contains('partial')) {
      status = PrescriptionStatus.partiallyDispensed;
    }

    DateTime issuedDate = DateTime.now();
    final createdAt = data['created_at']?.toString() ??
        data['issued_at']?.toString() ??
        data['date_issued']?.toString() ?? '';
    if (createdAt.isNotEmpty) {
      issuedDate = DateTime.tryParse(createdAt) ?? issuedDate;
    }

    final request = PrescriptionRequest(
      id: data['prescription_id']?.toString() ?? data['status_id']?.toString() ?? 'N/A',
      rxCode: _formatRxCode(data),
      patientName: data['patient_name']?.toString() ?? 'Unknown Patient',
      patientAge: int.tryParse(data['patient_age']?.toString() ?? '0') ?? 0,
      patientGender: data['patient_gender']?.toString() ?? 'Male',
      patientDob: data['patient_dob']?.toString() ?? '1992-11-15',
      doctorName: data['doctor_name']?.toString() ?? 'Dr. Unknown',
      doctorSpecialty:
          data['doctor_specialty']?.toString() ?? 'General Physician',
      dateIssued: issuedDate,
      status: status,
      medications: medications,
    );

    request.patientPhone = data['patient_phone']?.toString() ?? '';
    request.notes = data['notes']?.toString() ?? '';
    final fulfillment = data['fulfillment_score'];
    request.fulfillmentScore = fulfillment is num
        ? fulfillment.toDouble()
        : double.tryParse(fulfillment?.toString() ?? '0') ?? 0;

    return request;
  }

  String _formatRxCode(Map<String, dynamic> data) {
    final rexCode = data['rex_code']?.toString();
    if (rexCode != null && rexCode.isNotEmpty) {
      return rexCode;
    }

    final rxCode = data['rx_code']?.toString();
    if (rxCode != null && rxCode.isNotEmpty) {
      return rxCode;
    }

    final prescriptionCode = data['prescription_code']?.toString();
    if (prescriptionCode != null && prescriptionCode.isNotEmpty) {
      return prescriptionCode;
    }

    final last4 = data['rex_code_last4']?.toString();
    if (last4 != null && last4.isNotEmpty) {
      return 'RX...$last4';
    }

    return 'N/A';
  }


  Widget _buildRequestCard(PrescriptionRequest request) {
    final formattedDate = DateFormat('dd-MM-yyyy').format(request.dateIssued);
    final formattedTime = DateFormat('h:mm a').format(request.dateIssued);
    final medicationSummary = request.medications
        .map((med) => med.name)
        .where((name) => name.isNotEmpty)
        .join(', ');

    return InkWell(
      onTap: () => _openPrescriptionDetails(request),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SvgPicture.asset(
                    'assets/icons/new_prescription_icon.svg',
                    width: 28,
                    height: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ShaderMask(
                      shaderCallback: (bounds) =>
                          AppColors.primaryGradient.createShader(bounds),
                      child: const Text(
                        'New Prescription',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        formattedDate,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        formattedTime,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  )
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  SvgPicture.asset(
                    'assets/icons/patient_icon.svg',
                    width: 22,
                    height: 22,
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Patient',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        '${request.patientName}, ${request.patientAge}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (medicationSummary.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  medicationSummary,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.primary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  SvgPicture.asset(
                    'assets/icons/doctor_icon.svg',
                    width: 22,
                    height: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Doctor',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          request.doctorName,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SvgPicture.asset(
                    'assets/icons/arrow_forward_line_icon.svg',
                    width: 26,
                    height: 26,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
