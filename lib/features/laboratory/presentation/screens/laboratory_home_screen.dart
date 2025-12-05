import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:haticare/core/theme/app_colors.dart';
import 'package:haticare/features/common/customNav_Bottom.dart';
import 'package:haticare/features/laboratory/presentation/screens/laboratory_history_screen.dart';
import 'package:haticare/features/laboratory/presentation/screens/laboratory_settings_screen.dart';
import 'package:haticare/features/common/presentation/screens/notifications_screen.dart';
import 'package:haticare/features/laboratory/presentation/widgets/test_request_card.dart';
import 'package:haticare/features/laboratory/presentation/screens/test_request_detail_screen.dart';
import 'package:provider/provider.dart';
import '../providers/laboratory_user_provider.dart';

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
          LaboratoryHistoryScreen(),
          LaboratorySettingsScreen(),
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

class LaboratoryHomeTabScreen extends StatefulWidget {
  const LaboratoryHomeTabScreen({super.key});

  @override
  State<LaboratoryHomeTabScreen> createState() => _LaboratoryHomeTabScreenState();
}

class _LaboratoryHomeTabScreenState extends State<LaboratoryHomeTabScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // Provider already fetches on initialization
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final laboratoryProvider = context.watch<LaboratoryUserProvider>();

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
                      laboratoryProvider.isLoading
                          ? const CircleAvatar(
                              radius: 25,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                              ),
                            )
                          : CircleAvatar(
                              radius: 25,
                              backgroundImage: laboratoryProvider.profilePictureUrl.isNotEmpty
                                  ? NetworkImage(laboratoryProvider.profilePictureUrl)
                                  : null,
                              child: laboratoryProvider.profilePictureUrl.isEmpty
                                  ? const Icon(Icons.person, size: 30)
                                  : null,
                            ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                          ),
                          Text(
                            laboratoryProvider.laboratoryName,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
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
              Expanded(
                child: SingleChildScrollView(
                  child: laboratoryProvider.isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                          ),
                        )
                      : laboratoryProvider.testRequests.isEmpty
                          ? Container(
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
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: laboratoryProvider.testRequests.length,
                              itemBuilder: (context, index) {
                                final testRequest = laboratoryProvider.testRequests[index];
                                return TestRequestCard(
                                  testRequest: testRequest,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => TestRequestDetailScreen(
                                        testRequest: testRequest,
                                      ),
                                    ),
                                  );
                                },
                                );
                              },
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
