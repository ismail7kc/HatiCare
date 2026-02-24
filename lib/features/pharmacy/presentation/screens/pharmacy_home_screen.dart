import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:haticare/core/theme/app_colors.dart';
import 'package:haticare/core/widgets/prescription_list_item.dart';
import 'package:haticare/features/common/customNav_Bottom.dart';
import 'package:haticare/features/pharmacy/models/prescription_request.dart';
import 'package:haticare/features/pharmacy/presentation/screens/pharmacy_history_screen.dart';
import 'package:haticare/features/pharmacy/presentation/screens/pharmacy_assigned_screen.dart';
import 'package:haticare/features/pharmacy/presentation/screens/pharmacy_settings_screen.dart';
import 'package:provider/provider.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../../common/screens/notifications_screen.dart';
import '../providers/pharmacy_user_provider.dart';
import '../../presentation/utils/profile_notifier.dart';
import 'prescription_details_screen.dart';

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
          PharmacyAssignedScreen(),
          PharmacyHistoryScreen(),
          PharmacySettingsScreen(),
        ],
        tabs: const [
          TabItemData(title: "Home", iconPath: 'assets/icons/home.svg'),
          TabItemData(
            title: "Assigned",
            iconPath: 'assets/icons/inventory.svg',
          ),
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

  // socket propetties
  WebSocketChannel? _channel;
  bool _isConnecting = false;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<PharmacyUserProvider>();
      await provider.fetchProfile(forceRefresh: true);
      if (!mounted) return;

      if (provider.isApproved) {
        provider.fetchPrescriptions();
        provider.fetchAssignedPrescriptions();
        provider.fetchHistory();
      } else {
        provider.fetchPrescriptions();
      }
    });

    webSocketConnectionApi();
  }

  Future<void> webSocketConnectionApi() async {
    if (_isConnecting || _isDisposed) return;
    _isConnecting = true;

    final provider = context.read<PharmacyUserProvider>();
    final userId = provider.userId.isNotEmpty ? provider.userId : 'userid';
    final socketUrl =
        'wss://api.haticare.com/ws/pharmacy/queue/?user_id=$userId';

    debugPrint("WebSocket URL: $socketUrl");
    debugPrint("Pharmacy User ID: $userId");

    try {
      _channel = WebSocketChannel.connect(Uri.parse(socketUrl));

      _channel!.stream.listen(
        (message) async {
          if (_isDisposed) return;

          debugPrint("WS RAW: $message");

          try {
            final data = jsonDecode(message);
            final isSuccess = data['success'] == true;
            if (isSuccess && data['data'] != null) {
              context.read<PharmacyUserProvider>().handleWebSocketUpdate(data);
            }

            if (_isDisposed) return;
          } catch (e) {
            debugPrint("WS parse error: $e");
          }
        },
        onDone: () {
          debugPrint("WS Closed");
          _reconnect();
        },
        onError: (error) {
          debugPrint("WS Error: $error");
          _reconnect();
        },
        cancelOnError: true,
      );
    } catch (e) {
      debugPrint("WS connect error: $e");
      _reconnect();
    }
  }

  void _reconnect() {
    if (_isDisposed) return;

    _isConnecting = false;

    Future.delayed(const Duration(seconds: 3), () {
      if (!_isDisposed) {
        webSocketConnectionApi();
      }
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    _channel?.sink.close();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    final provider = context.read<PharmacyUserProvider>();
    // Fetch profile to check approval status
    await provider.fetchProfile(forceRefresh: true);
    if (!mounted) return;

    await Future.wait([
      provider.fetchPrescriptions(),
      provider.fetchAssignedPrescriptions(),
      provider.fetchHistory(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    final pharmacyProvider = context.watch<PharmacyUserProvider>();
    final availableCount = pharmacyProvider.assignedRequests.length;
    final deliveredCount = pharmacyProvider.historyRequests.length;
    final prescriptionsRaw = pharmacyProvider.prescriptions;

    final List<Map<String, dynamic>> newRequestsRaw = prescriptionsRaw
        .whereType<Map<String, dynamic>>()
        .where((p) {
          final statusStr = p['availability']?.toString().toLowerCase() ?? '';
          return !statusStr.contains('delivered') &&
              !statusStr.contains('full') &&
              !statusStr.contains('partial');
        })
        .toList();

    final List<PrescriptionRequest> newRequestPrescriptions = [];
    if (newRequestsRaw.isNotEmpty) {
      newRequestPrescriptions.addAll(
        newRequestsRaw.map(_mapToPrescriptionRequest),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header View
              ValueListenableBuilder<String?>(
                valueListenable: ProfileNotifier.profileImageUrl,
                builder: (context, imageUrl, _) {
                  final profileUrl =
                      imageUrl ?? pharmacyProvider.profilePictureUrl;
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
                                pharmacyProvider.pharmacyName.isNotEmpty
                                    ? (pharmacyProvider.pharmacyName.length > 15
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
                                      const NotificationsScreen(),
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
              const SizedBox(height: 24),

              if (!pharmacyProvider.isApproved &&
                  pharmacyProvider.approvalMessage.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
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
                  child: RefreshIndicator(
                    onRefresh: _onRefresh,
                    color: AppColors.primary,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
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
                              'Your pharmacy account must be approved to view prescription statistics.\n\nPull down to refresh and check approval status.',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
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
                                  color: Colors.white,
                                ),
                              ),
                              const Text(
                                'Assigned Prescriptions',
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
                                'Completed Prescriptions',
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
                    child: newRequestPrescriptions.isEmpty
                        ? LayoutBuilder(
                            builder: (context, constraints) {
                              return SingleChildScrollView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                child: SizedBox(
                                  height: constraints.maxHeight,
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.local_pharmacy_outlined,
                                          size: 64,
                                          color: Colors.grey[300],
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          'No New Request',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.grey[400],
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Pull down to refresh',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey[500],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          )
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.only(bottom: 80),
                            itemCount: newRequestPrescriptions.length,
                            itemBuilder: (context, index) {
                              final request = newRequestPrescriptions[index];
                              return Padding(
                                padding: EdgeInsets.only(
                                  bottom:
                                      index < newRequestPrescriptions.length - 1
                                      ? 12
                                      : 0,
                                ),
                                child: PrescriptionListItem(
                                  data: {
                                    'patient_name': request.patientName,
                                    'patient_age': request.patientAge
                                        .toString(),
                                    'doctor_name': request.doctorName,
                                    'created_at': request.dateIssued
                                        .toIso8601String(),
                                    'medications': request.medications
                                        .map(
                                          (med) => {
                                            'name': med.name,
                                            'dose': med.dosage,
                                            'frequency': med.instructions,
                                          },
                                        )
                                        .toList(),
                                  },
                                  itemType: ItemType.prescription,
                                  onTap: () =>
                                      _openPrescriptionDetails(request),
                                ),
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
      medications = (data['medications'] as List).map((med) {
        if (med is Map<String, dynamic>) {
          return Medication(
            name: med['name']?.toString() ?? 'Unknown',
            dosage: med['dose']?.toString() ?? '',
            instructions:
                '${med['frequency'] ?? ''} ${med['duration'] ?? ''} ${med['notes'] ?? ''}'
                    .trim(),
          );
        }
        return Medication(name: med.toString(), dosage: '', instructions: '');
      }).toList();
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
    final createdAt =
        data['created_at']?.toString() ??
        data['issued_at']?.toString() ??
        data['date_issued']?.toString() ??
        '';
    if (createdAt.isNotEmpty) {
      issuedDate = DateTime.tryParse(createdAt) ?? issuedDate;
    }

    final request = PrescriptionRequest(
      id:
          data['status_id']?.toString() ??
          data['prescription_id']?.toString() ??
          'N/A',
      rxCode: _formatRxCode(data),
      patientName: data['patient_name']?.toString() ?? 'Unknown Patient',
      patientAge: int.tryParse(data['patient_age']?.toString() ?? '0') ?? 0,
      patientGender: data['patient_gender']?.toString() ?? 'Male',
      patientDob: data['patient_dob']?.toString() ?? '1992-11-15',
      doctorName:
          data['doctor']?.toString() ??
          data['doctor_name']?.toString() ??
          data['doctorName']?.toString() ??
          'Dr. Unknown',
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
}
