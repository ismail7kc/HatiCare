import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:haticare/core/theme/app_colors.dart';
import 'package:haticare/features/common/customNav_Bottom.dart';
import 'package:haticare/features/common/presentation/screens/notifications_screen.dart';
import 'package:haticare/features/doctor/ApiClient/api_client.dart';
import 'package:haticare/features/laboratory/presentation/lab_repository_layer.dart';
import 'package:haticare/features/laboratory/presentation/screens/laboratory_history_screen.dart';
import 'package:haticare/features/laboratory/presentation/screens/laboratory_settings_screen.dart';
import 'package:haticare/features/laboratory/presentation/screens/test_request_detail_screen.dart';
import 'package:haticare/features/laboratory/presentation/viewmodels/lab_prescriptionVM.dart';
import 'package:haticare/features/laboratory/presentation/widgets/test_request_card.dart';
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
  State<LaboratoryHomeTabScreen> createState() =>
      _LaboratoryHomeTabScreenState();
}

class _LaboratoryHomeTabScreenState extends State<LaboratoryHomeTabScreen>
    with AutomaticKeepAliveClientMixin {
  late TextEditingController _rxCodeController;

  @override
  bool get wantKeepAlive => true;

  late final LabPrescriptionvm labPrescriptionVm;

  @override
  void initState() {
    super.initState();
    _rxCodeController = TextEditingController();
    
    // show lab prescription list
    labPrescriptionVm = LabPrescriptionvm(LabRepositoryLayer(ApiClient()));
    labPrescriptionVm.laboratoryPrescriptionList();
  }

  @override
  void dispose() {
    _rxCodeController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    final provider = context.read<LaboratoryUserProvider>();
    await provider.fetchProfile(forceRefresh: true);
  }

  Future<void> _verifyRxCode(LaboratoryUserProvider provider) async {
    // Check approval status first
    if (!provider.isApproved) {
      _showVerificationDialog(
        title: 'Account Not Approved',
        message: provider.approvalMessage.isNotEmpty
            ? provider.approvalMessage
            : 'Your laboratory account is not approved. Only approved laboratories can verify test requests.',
        isSuccess: false,
      );
      return;
    }

    await provider.verifyRxCode(_rxCodeController.text);

    if (provider.errorMessage != null) {
      _showVerificationDialog(
        title: 'Verification Failed',
        message: provider.errorMessage!,
        isSuccess: false,
      );
    } else if (provider.verifiedRxCode.isNotEmpty) {
      _showVerificationDialog(
        title: 'Verification Successful',
        message:
            'RX Code verified successfully. Test request details are now displayed below.',
        isSuccess: true,
      );
    }
  }

  void _showVerificationDialog({
    required String title,
    required String message,
    required bool isSuccess,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                isSuccess ? Icons.check_circle : Icons.error,
                color: isSuccess ? Colors.green : Colors.red,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          content: Text(message, style: const TextStyle(fontSize: 14)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'OK',
                style: TextStyle(
                  color: AppColors.primaryDark,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final laboratoryProvider = context.watch<LaboratoryUserProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          color: AppColors.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      AppColors.primary,
                                    ),
                                  ),
                                )
                              : CircleAvatar(
                                  radius: 25,
                                  backgroundImage:
                                      laboratoryProvider
                                          .profilePictureUrl
                                          .isNotEmpty
                                      ? NetworkImage(
                                          laboratoryProvider.profilePictureUrl,
                                        )
                                      : null,
                                  child:
                                      laboratoryProvider
                                          .profilePictureUrl
                                          .isEmpty
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
                              laboratoryProvider.isLoading
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
                                      laboratoryProvider
                                              .laboratoryName
                                              .isNotEmpty
                                          ? (laboratoryProvider
                                                        .laboratoryName
                                                        .length >
                                                    15
                                                ? '${laboratoryProvider.laboratoryName.substring(0, 15)}...'
                                                : laboratoryProvider
                                                      .laboratoryName)
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
                  ),
                  const SizedBox(height: 20),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Verify Test Request',
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
                                controller: _rxCodeController,
                                textCapitalization:
                                    TextCapitalization.characters,
                                keyboardType: TextInputType.text,
                                onChanged: (value) {
                                  if (value != value.toUpperCase()) {
                                    _rxCodeController.text = value
                                        .toUpperCase();
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
                                  laboratoryProvider.verifiedRxCode.isNotEmpty
                                  ? () {
                                      laboratoryProvider.clearSearch();
                                      _rxCodeController.clear();
                                    }
                                  : () {
                                      _verifyRxCode(laboratoryProvider);
                                    },
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 0,
                                backgroundColor:
                                    laboratoryProvider.verifiedRxCode.isNotEmpty
                                    ? Colors.red
                                    : Colors.transparent,
                                shadowColor: Colors.transparent,
                              ),
                              child: Ink(
                                decoration: BoxDecoration(
                                  gradient:
                                      laboratoryProvider
                                          .verifiedRxCode
                                          .isNotEmpty
                                      ? null
                                      : AppColors.primaryGradient,
                                  color:
                                      laboratoryProvider
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
                                      : Text(
                                          laboratoryProvider
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
                  const SizedBox(height: 24),

                  if (!laboratoryProvider.isApproved &&
                      laboratoryProvider.approvalMessage.isNotEmpty)
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
                                  laboratoryProvider.approvalMessage,
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

                  if (!laboratoryProvider.isApproved &&
                      laboratoryProvider.approvalMessage.isNotEmpty)
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

                  laboratoryProvider.isLoading
                      ? Container(
                          padding: const EdgeInsets.all(40),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.primary,
                              ),
                            ),
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
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'No New Requests Yet.',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: laboratoryProvider.testRequests.length,
                          itemBuilder: (context, index) {
                            final testRequest =
                                laboratoryProvider.testRequests[index];
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
