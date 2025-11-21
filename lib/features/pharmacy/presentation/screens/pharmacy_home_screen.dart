import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:haticare/core/theme/app_colors.dart';
import 'package:haticare/features/common/customNav_Bottom.dart';
import 'package:haticare/features/pharmacy/domain/entities/prescription_request.dart';
import 'package:haticare/features/pharmacy/presentation/screens/pharmacy_history_screen.dart';
import 'package:haticare/features/pharmacy/presentation/screens/pharmacy_settings_screen.dart';
import 'package:haticare/features/pharmacy/presentation/widgets/prescription_request_card.dart';
import 'package:haticare/features/pharmacy/presentation/screens/prescription_details_screen.dart';


class PharmacyHomeScreen extends StatefulWidget {
  const PharmacyHomeScreen({super.key});

  @override
  State<PharmacyHomeScreen> createState() => _PharmacyHomeScreenState();
}

class _PharmacyHomeScreenState extends State<PharmacyHomeScreen> {
  @override
  Widget build(BuildContext context) {
    return CustomBottomNav(
      screens: const [
        PharmacyHomeTabScreen(), // Added pharmacy specific home tab
        PharmacyHistoryScreen(),
        PharmacySettingsScreen(),
      ],
      tabs: const [
        TabItemData(title: "Home", iconPath: 'assets/icons/home.svg'),
        TabItemData(title: "History", iconPath: 'assets/icons/history.svg'),
        TabItemData(title: "Settings", iconPath: 'assets/icons/setting.svg'),
      ],
    );
  }
}

class PharmacyHomeTabScreen extends StatefulWidget {
  const PharmacyHomeTabScreen({super.key});

  @override
  State<PharmacyHomeTabScreen> createState() => _PharmacyHomeTabScreenState();
}

class _PharmacyHomeTabScreenState extends State<PharmacyHomeTabScreen> {
  late List<PrescriptionRequest> prescriptionRequests;

  @override
  void initState() {
    super.initState();
    prescriptionRequests = PrescriptionRequest.getDummyRequests();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header View - Same as Doctor Home Screen
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 25,
                        // backgroundImage: AssetImage('assets/doctor.jpg'),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            "Welcome Back,",
                            style: TextStyle(color: Colors.grey),
                          ),
                          Text(
                            "Dr. John Doe",
                            style: TextStyle(
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
                      SvgPicture.asset(
                        'assets/icons/notification.svg',
                        height: 26,
                        color: Colors.black87,
                      ),
                      const Positioned(
                        right: 0,
                        top: 0,
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
                  padding: const EdgeInsets.symmetric(horizontal: 10,vertical: 16),
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
                                hintStyle: TextStyle(
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
                                  borderSide: BorderSide(
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
              if (prescriptionRequests.isEmpty)
                Container(
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      'No New Requests Yet.',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: prescriptionRequests.length,
                  itemBuilder: (context, index) {
                    final request = prescriptionRequests[index];
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
