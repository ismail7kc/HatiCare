import 'package:flutter/material.dart';
import 'package:haticare/core/theme/app_colors.dart';
import 'package:haticare/features/common/customNav_Bottom.dart';
import 'package:haticare/features/doctor/presentation/screens/consultation_history.dart';
import 'package:haticare/features/doctor/presentation/screens/doctor_home_screen.dart';

class PharmacyHomeScreen extends StatelessWidget {
  const PharmacyHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomBottomNav(
      screens: const [
        PharmacyDashboardScreen(),
        ConsultationHistoryScreen(),
        SettingsScreenWithAppBar(),
      ],
      tabs: const [
        TabItemData(title: 'Home', iconPath: 'assets/icons/home.svg'),
        TabItemData(title: 'History', iconPath: 'assets/icons/history.svg'),
        TabItemData(title: 'Settings', iconPath: 'assets/icons/setting.svg'),
      ],
    );
  }
}

class PharmacyDashboardScreen extends StatelessWidget {
  const PharmacyDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text('Pharmacy Home'),
          titleTextStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.w600,
              ),
          centerTitle: true,
          bottom: const TabBar(
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            tabs: [
              Tab(text: 'Dashboard'),
              Tab(text: 'Inventory'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _PharmacyDashboardTab(),
            _PharmacyInventoryTab(),
          ],
        ),
      ),
    );
  }
}

class _PharmacyDashboardTab extends StatelessWidget {
  const _PharmacyDashboardTab();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Welcome, Pharmacy!',
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppColors.primaryDark,
              fontWeight: FontWeight.w600,
            ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _PharmacyInventoryTab extends StatelessWidget {
  const _PharmacyInventoryTab();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Inventory coming soon',
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.textSecondary,
            ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
