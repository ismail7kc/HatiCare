import 'package:flutter/material.dart';
import 'package:haticare/core/theme/app_colors.dart';
import 'package:haticare/features/common/customNav_Bottom.dart';
import 'package:haticare/features/doctor/presentation/screens/consultation_history.dart';
import 'package:haticare/features/doctor/presentation/screens/doctor_home_screen.dart';

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
        ConsultationHistoryScreen(),
        SettingsScreenWithAppBar(),
      ],
      tabs: const [
        TabItemData(title: "Home", iconPath: 'assets/home.svg'),
        TabItemData(title: "History", iconPath: 'assets/history.svg'),
        TabItemData(title: "Settings", iconPath: 'assets/setting.svg'),
      ],
    );
  }
}

class PharmacyHomeTabScreen extends StatelessWidget {
  const PharmacyHomeTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
      ),
      body: Center(
        child: Text(
          'Welcome, Pharmacy!',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: AppColors.primaryDark,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
