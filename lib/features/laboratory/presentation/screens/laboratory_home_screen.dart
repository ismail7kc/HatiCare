import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:haticare/core/theme/app_colors.dart';
import 'package:haticare/core/widgets/prescription_list_item.dart';
import 'package:haticare/features/common/customNav_Bottom.dart';
import 'package:haticare/features/common/screens/notifications_screen.dart';
import 'package:haticare/features/laboratory/presentation/screens/laboratory_history_screen.dart';
import 'package:haticare/features/laboratory/presentation/screens/laboratory_inventory_screen.dart';
import 'package:haticare/features/laboratory/presentation/screens/laboratory_settings_screen.dart';
import 'package:provider/provider.dart';

import '../providers/laboratory_user_provider.dart';

class ProfileNotifier {
  static final ValueNotifier<String?> profileImageUrl = ValueNotifier(null);
  static final ValueNotifier<String?> doctorName = ValueNotifier(null);
}

class LaboratoryHomeScreen extends StatefulWidget {
  const LaboratoryHomeScreen({super.key});

  @override
  State<LaboratoryHomeScreen> createState() => _LaboratoryHomeScreenState();
}

class _LaboratoryHomeScreenState extends State<LaboratoryHomeScreen> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LaboratoryUserProvider(),
      child: CustomBottomNav(
        screens: const [
          LaboratoryHomeTabScreen(),
          LaboratoryInventoryScreen(),
          LaboratoryHistoryScreen(),
          LaboratorySettingsScreen(),
        ],
        tabs: const [
          TabItemData(title: "Home", iconPath: 'assets/icons/home.svg'),
          TabItemData(title: "Assigned", iconPath: 'assets/icons/inventory.svg',),
          TabItemData(title: "History", iconPath: 'assets/icons/history.svg'),
          TabItemData(title: "Settings", iconPath: 'assets/icons/setting.svg'),
        ],
      ),
    );
  }
}

class LaboratoryHomeTabScreen extends StatefulWidget {
  const LaboratoryHomeTabScreen({super.key});

  @override
  State<LaboratoryHomeTabScreen> createState() =>
      _LaboratoryHomeTabScreenState();
}

class _LaboratoryHomeTabScreenState extends State<LaboratoryHomeTabScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<LaboratoryUserProvider>();
      await provider.fetchProfile(forceRefresh: true);
      await provider.fetchPrescriptions();
    });
  }

  Future<void> _onRefresh() async {
    final provider = context.read<LaboratoryUserProvider>();
    await provider.fetchProfile(forceRefresh: true);

    await provider.fetchPrescriptions();
  }

  int _getAvailableCount(List<dynamic> prescriptions) {
    int available = 0;
    for (final prescription in prescriptions) {
      final status =
          prescription['status']?.toString().toLowerCase() ?? 'pending';
      if (status.contains('pending') || status.contains('new')) {
        available++;
      }
    }
    return available;
  }

  int _getDeliveredCount(List<dynamic> prescriptions) {
    int delivered = 0;
    for (final prescription in prescriptions) {
      final status =
          prescription['status']?.toString().toLowerCase() ?? 'pending';
      if (status.contains('completed') || status.contains('delivered')) {
        delivered++;
      }
    }
    return delivered;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final laboratoryProvider = context.watch<LaboratoryUserProvider>();
    final availableCount = _getAvailableCount(laboratoryProvider.prescriptions);
    final deliveredCount = _getDeliveredCount(laboratoryProvider.prescriptions);
    final prescriptions = laboratoryProvider.prescriptions;
    final isLoading = laboratoryProvider.prescriptionsLoading;
    final errorMessage = laboratoryProvider.errorMessage;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Section
              ValueListenableBuilder<String?>(
                valueListenable: ProfileNotifier.profileImageUrl,
                builder: (context, imageUrl, _) {
                  final profileUrl =
                      imageUrl ?? laboratoryProvider.profilePictureUrl;
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          profileUrl.isNotEmpty
                              ? CircleAvatar(
                                  radius: 25,
                                  backgroundImage: NetworkImage(profileUrl),
                                )
                              : const CircleAvatar(
                                  radius: 25,
                                  child: Icon(Icons.person, size: 30),
                                ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Welcome Back,",
                                style: TextStyle(color: Colors.grey),
                              ),
                              Text(
                                laboratoryProvider.laboratoryName.isNotEmpty
                                    ? (laboratoryProvider
                                                  .laboratoryName
                                                  .length >
                                              15
                                          ? '${laboratoryProvider.laboratoryName.substring(0, 15)}...'
                                          : laboratoryProvider.laboratoryName)
                                    : 'Laboratory',
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
                                  builder: (_) => const NotificationsScreen(),
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
                  );
                },
              ),

              const SizedBox(height: 20),

              // Counter Cards
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 80,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF54DCDF), Color(0xFF4CA054)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
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
                                'Available Lab Tests',
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
                          gradient: const LinearGradient(
                            colors: [Color(0xFF07498A), Color(0xFF0A2463)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
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
                                'Completed Lab Tests',
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
                    child: _buildAssignedBody(
                      isLoading: isLoading,
                      prescriptions: prescriptions,
                      errorMessage: errorMessage,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAssignedBody({
    required bool isLoading,
    required List<dynamic> prescriptions,
    required String? errorMessage,
  }) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 56, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(
                errorMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, color: Colors.black87),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => _onRefresh(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (prescriptions.isEmpty) {
      return LayoutBuilder(
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
                    Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 12),
                    const Text(
                      'No new request',
                      style: TextStyle(fontSize: 16, color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: prescriptions.length,
      itemBuilder: (context, index) {
        final raw = prescriptions[index];
        final mapped = _mapAssignedToListItem(raw);
        return Padding(
          padding: EdgeInsets.only(bottom: index < prescriptions.length - 1 ? 12 : 0),
          child: PrescriptionListItem(
            data: mapped,
            itemType: ItemType.labTest,
            onTap: () => _openPrescriptionDetails(mapped),
          ),
        );
      },
    );
  }

  Map<String, dynamic> _mapAssignedToListItem(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      return {
        'prescription_id': raw['prescription_id'] ?? raw['id'],
        'patient_name': raw['patient_name'] ?? 'Unknown Patient',
        'patient_phone': raw['patient_phone'],
        'doctor_name': raw['doctor_name'] ?? 'Doctor',
        'created_at': raw['verified_at'] ?? raw['created_at'],
        'availability': raw['availability'],
        'status': raw['pharmacy_status'] ?? raw['status'],
        'lab_tests': raw['lab_tests'] ?? raw['tests'] ?? [],
        'notes': raw['notes'],
      };
    }

    return {
      'prescription_id': raw?.toString() ?? '',
      'patient_name': 'Unknown Patient',
      'doctor_name': 'Doctor',
      'lab_tests': const [],
    };
  }


  Future<void> _openPrescriptionDetails(
    Map<String, dynamic> prescription,
  ) async {
    // Navigate to prescription details screen
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _buildPrescriptionDetailsScreen(prescription),
      ),
    );
    // Refresh list after returning from details
    _onRefresh();
  }

  Widget _buildPrescriptionDetailsScreen(Map<String, dynamic> prescription) {
    final statusId =
        prescription['status_id']?.toString() ??
        prescription['prescription_id']?.toString() ??
        '';

    return Scaffold(
      backgroundColor: Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Lab Tests Details'),
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
                          'Prescription ID',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '#${prescription['prescription_id']?.toString() ?? 'N/A'}',
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
                        prescription['availability']
                                ?.toString()
                                .toUpperCase() ??
                            'PENDING',
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
                      prescription['patient_name']?.toString() ?? 'Unknown',
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      'Issuing Doctor:',
                      prescription['doctor_name']?.toString() ?? 'Dr. Unknown',
                    ),
                    if (prescription['patient_phone']?.toString().isNotEmpty ==
                        true) ...[
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        'Patient Phone:',
                        prescription['patient_phone']?.toString() ?? '',
                      ),
                    ],
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      'Date Issued:',
                      prescription['created_at']?.toString().isNotEmpty == true
                          ? DateTime.tryParse(
                                      prescription['created_at']?.toString() ??
                                          '',
                                    ) !=
                                    null
                                ? '${DateTime.tryParse(prescription['created_at']?.toString() ?? '')?.day.toString().padLeft(2, '0')}/${DateTime.tryParse(prescription['created_at']?.toString() ?? '')?.month.toString().padLeft(2, '0')}/${DateTime.tryParse(prescription['created_at']?.toString() ?? '')?.year}'
                                : 'N/A'
                          : 'N/A',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Lab Tests Card
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
                          Icons.science_outlined,
                          color: Colors.black,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Lab Tests',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (prescription['lab_tests'] is List)
                      ...(prescription['lab_tests'] as List)
                          .asMap()
                          .entries
                          .map((entry) {
                            final index = entry.key;
                            final labTest = entry.value;
                            return Column(
                              children: [
                                if (index > 0) const SizedBox(height: 12),
                                _buildLabTestItem(labTest),
                              ],
                            );
                          }),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Notes Card (if available)
              if (prescription['notes']?.toString().isNotEmpty == true)
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
                        prescription['notes']?.toString() ?? '',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),

                // Accept Prescription Button
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Consumer<LaboratoryUserProvider>(
                    builder: (context, provider, child) {
                      final isEnabled = statusId.isNotEmpty;
                      
                      return SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: isEnabled 
                                ? AppColors.primaryGradient 
                                : null,
                            color: isEnabled ? null : Colors.grey,
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: isEnabled
                                ? [
                                    BoxShadow(
                                      color: AppColors.primaryDark.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: isEnabled
                                  ? () async {
                                      await provider.acceptPrescription(statusId);

                                      if (provider.errorMessage == null) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Prescription accepted successfully!',
                                            ),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                        Navigator.pop(context); // Go back to list
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(provider.errorMessage!),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    }
                                  : null,
                              borderRadius: BorderRadius.circular(25),
                              child: Container(
                                alignment: Alignment.center,
                                child: provider.isVerifying
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    : const Text(
                                        'Accept Prescription',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 24), // Bottom spacing
              ],
            ),
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

  Widget _buildLabTestItem(dynamic labTest) {
    final name = labTest is Map<String, dynamic>
        ? labTest['name']?.toString() ?? 'Unknown Test'
        : labTest.toString();
    final id = labTest is Map<String, dynamic>
        ? labTest['id']?.toString() ?? ''
        : '';

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
                  text: name,
                  style: const TextStyle(fontWeight: FontWeight.normal),
                ),
                if (id.isNotEmpty)
                  TextSpan(
                    text: ' (ID: $id)',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
