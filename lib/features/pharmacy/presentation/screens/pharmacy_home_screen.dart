import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:haticare/core/theme/app_colors.dart';
import 'package:haticare/features/common/customNav_Bottom.dart';
import 'package:haticare/features/pharmacy/domain/entities/prescription_request.dart';
import 'package:haticare/features/pharmacy/presentation/screens/pharmacy_history_screen.dart';
import 'package:haticare/features/pharmacy/presentation/screens/pharmacy_settings_screen.dart';
import 'package:haticare/features/pharmacy/presentation/screens/pharmacy_notifications_screen.dart';
import 'package:haticare/features/pharmacy/presentation/widgets/prescription_request_card.dart';
import 'package:haticare/features/pharmacy/presentation/screens/prescription_details_screen.dart';
import 'package:provider/provider.dart';
import '../providers/pharmacy_user_provider.dart';
import 'package:haticare/features/pharmacy/domain/entities/prescription_request.dart' show Medication, PrescriptionStatus;

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
          PharmacyHistoryScreen(),
          PharmacySettingsScreen(),
        ],
        tabs: const [
          TabItemData(title: "Home", iconPath: 'assets/icons/home.svg'),
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

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    final pharmacyProvider = context.watch<PharmacyUserProvider>();

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
                                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                              ),
                            )
                          : CircleAvatar(
                              radius: 25,
                              backgroundImage: pharmacyProvider.profilePictureUrl.isNotEmpty
                                  ? NetworkImage(pharmacyProvider.profilePictureUrl)
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
                                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                                  ),
                                )
                              : Text(
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
                              builder: (context) => const PharmacyNotificationsScreen(),
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
              const SizedBox(height: 20),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Verify Prescription Section
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
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
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    decoration: InputDecoration(
                                      hintText: 'Enter Rx Code (e.g., RX12345)',
                                      hintStyle: const TextStyle(
                                        color: Color(0xFF858585),
                                        fontSize: 14,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(color: Colors.grey[300]!),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(color: Colors.grey[300]!),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                          color: AppColors.primaryDark,
                                          width: 2,
                                        ),
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                ElevatedButton(
                                  onPressed: () {},
                                  style: ElevatedButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    elevation: 0,
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                  ),
                                  child: Ink(
                                    decoration: BoxDecoration(
                                      gradient: AppColors.primaryGradient,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 26,
                                        vertical: 12,
                                      ),
                                      alignment: Alignment.center,
                                      child: const Text(
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
                      const SizedBox(height: 24),

                      // New Requests Section
                      const Text(
                        'New Requests',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Prescription Requests List
                      if (pharmacyProvider.prescriptionsLoading)
                        Container(
                          padding: const EdgeInsets.all(40),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                            ),
                          ),
                        )
                      else if (pharmacyProvider.prescriptions.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(40),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              pharmacyProvider.errorMessage ?? 'No New Requests Yet.',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: pharmacyProvider.prescriptions.length,
                          itemBuilder: (context, index) {
                            final prescriptionData = pharmacyProvider.prescriptions[index];
                            
                            // Parse medications list from API response structure
                            List<Medication> medications = [];
                            if (prescriptionData['medications'] is List) {
                              medications = (prescriptionData['medications'] as List)
                                  .map((med) => Medication(
                                    name: med['name'] ?? 'Unknown',
                                    dosage: med['dose'] ?? 'N/A', // API uses 'dose' not 'dosage'
                                    instructions: '${med['frequency'] ?? ''} ${med['duration'] ?? ''} ${med['notes'] ?? ''}'.trim(),
                                  ))
                                  .toList();
                            }
                            
                            // Parse status from availability field
                            PrescriptionStatus status = PrescriptionStatus.issued;
                            final statusStr = prescriptionData['availability']?.toString().toLowerCase() ?? 'pending';
                            if (statusStr.contains('fully')) {
                              status = PrescriptionStatus.fullyDispensed;
                            } else if (statusStr.contains('partial')) {
                              status = PrescriptionStatus.partiallyDispensed;
                            }
                            
                            // Parse date (using current date since API doesn't provide date)
                            DateTime dateIssued = DateTime.now();
                            
                            // Convert API response to PrescriptionRequest
                            final request = PrescriptionRequest(
                              id: prescriptionData['prescription_id']?.toString() ?? 'N/A',
                              rxCode: 'RX...${prescriptionData['rex_code_last4'] ?? 'N/A'}',
                              patientName: prescriptionData['patient_name'] ?? 'Unknown Patient',
                              patientAge: int.tryParse(prescriptionData['patient_age']?.toString() ?? '0') ?? 0, // API might provide age, default to 0
                              patientGender: prescriptionData['patient_gender'] ?? 'Male',
                              patientDob: '1992-11-15',
                              doctorName: prescriptionData['doctor_name'] ?? 'Dr. Unknown',
                              doctorSpecialty: prescriptionData['doctor_specialty'] ?? 'General Physician',
                              dateIssued: dateIssued,
                              status: status,
                              medications: medications,
                            );
                            
                            // Store additional data for details screen
                            request.patientPhone = prescriptionData['patient_phone'] ?? '';
                            request.notes = prescriptionData['notes'] ?? '';
                            request.fulfillmentScore = prescriptionData['fulfillment_score'] ?? 0.0;
                            
                            return PrescriptionRequestCard(
                              request: request,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PrescriptionDetailsScreen(
                                      request: request,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
