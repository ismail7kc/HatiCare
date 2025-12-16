import 'package:flutter/material.dart';
import 'package:haticare/core/theme/app_colors.dart';
import 'package:haticare/features/laboratory/presentation/widgets/test_request_card.dart';
import 'package:haticare/features/laboratory/presentation/screens/test_request_detail_screen.dart';
import 'package:provider/provider.dart';
import '../providers/laboratory_user_provider.dart';

class LaboratoryHistoryScreen extends StatefulWidget {
  const LaboratoryHistoryScreen({super.key});

  @override
  State<LaboratoryHistoryScreen> createState() => _LaboratoryHistoryScreenState();
}

class _LaboratoryHistoryScreenState extends State<LaboratoryHistoryScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  Future<void> _onRefresh() async {
    final provider = context.read<LaboratoryUserProvider>();
    // Fetch profile to refresh approval status and data
    await provider.fetchProfile(forceRefresh: true);
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
              Text(
                'Test Request History',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _onRefresh,
                  color: AppColors.primary,
                  child: laboratoryProvider.isLoading
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const [
                            SizedBox(height: 200),
                            Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                              ),
                            ),
                          ],
                        )
                      : laboratoryProvider.completedTestRequests.isEmpty
                          ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: [
                                SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                                Center(
                                  child: Text(
                                    'No history available',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                  ),
                                ),
                              ],
                            )
                          : ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              itemCount: laboratoryProvider.completedTestRequests.length,
                              itemBuilder: (context, index) {
                                final testRequest = laboratoryProvider.completedTestRequests[index];
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
