import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:haticare/core/theme/app_colors.dart';
import 'package:haticare/core/services/device_id_provider.dart';
import 'package:haticare/features/auth/domain/repositories/auth_repository.dart';
import 'package:haticare/features/auth/presentation/screens/login_screen.dart';
import 'package:haticare/features/common/shared_prefs_helper.dart';
import 'package:haticare/features/pharmacy/presentation/screens/pharmacy_notifications_screen.dart';
import 'package:haticare/features/pharmacy/presentation/screens/pharmacy_privacy_policy_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PharmacySettingsScreen extends StatelessWidget {
  const PharmacySettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor:  Color(0xFFF9FAFB),
        elevation: 0,
        title: const Text(
          'Settings',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 24),
            // Profile Section
            _buildProfileSection(context),
            const SizedBox(height: 32),

            // Account Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Account',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildSettingsCard(
                    context,
                    svgIcon: 'assets/icons/edit_profile_icon.svg',
                    title: 'Edit Profile',
                    onTap: () {
                      // Navigate to edit profile
                    },
                  ),
                  const SizedBox(height: 6),
                  _buildSettingsCard(
                    context,
                    svgIcon: 'assets/icons/notification_icon.svg',
                    title: 'Notifications',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PharmacyNotificationsScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 6),
                  _buildSettingsCard(
                    context,
                    svgIcon: 'assets/icons/privacy_policy_icon.svg',
                    title: 'Privacy Policy',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PharmacyPrivacyPolicyScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Support Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Support',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildSettingsCard(
                    context,
                    svgIcon: 'assets/icons/help_center_icon.svg',
                    title: 'Help Center',
                    onTap: () {
                      // Navigate to help center
                    },
                  ),
                  const SizedBox(height: 6),
                  _buildSettingsCard(
                    context,
                    svgIcon: 'assets/icons/contact_support_icon.svg',
                    title: 'Contact Support',
                    onTap: () {
                      // Navigate to contact support
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Logout Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildLogoutCard(context),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              /// ✅ Gradient Circle
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person,
                  color: Colors.white,
                  size: 40,
                ),
              ),

              /// ✅ Edit Button
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.edit,
                      color: Colors.white,
                      size: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          FutureBuilder<SharedPreferences>(
            future: SharedPreferences.getInstance(),
            builder: (context, snapshot) {
              String name = 'User';
              if (snapshot.hasData) {
                final prefs = snapshot.data!;
                final firstName = prefs.getString('user_first_name') ?? '';
                if (firstName.isNotEmpty) {
                  name = firstName;
                }
              }
              return Text(
                name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              );
            },
          ),

          const SizedBox(height: 6),

          const Text(
            'General Physician',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            'License: GMC-12345',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard(
    BuildContext context, {
    required String svgIcon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.white),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Row(
            children: [
              SvgPicture.asset(
                svgIcon,
                width: 24,
                height: 24,
                colorFilter: const ColorFilter.mode(
                  Colors.black87,
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.black,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutCard(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.white),
      ),
      child: InkWell(
        onTap: () => _showLogoutDialog(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Row(
            children: [
              const Icon(
                Icons.logout,
                color: Colors.red,
                size: 24,
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Logout',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.red,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.logout,
                color: Colors.red,
                size: 28,
              ),
              SizedBox(width: 12),
              Text(
                'Logout',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: const Text(
            'Are you sure you want to logout?',
            style: TextStyle(
              fontSize: 16,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                await _handleLogout(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Logout',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    // Get repository before showing dialog
    final authRepository = context.read<AuthRepository>();
    
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return const Center(
          child: CircularProgressIndicator(
            color: Colors.white,
          ),
        );
      },
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      final deviceId = await DeviceIdProvider().getDeviceId();
      final refreshToken = prefs.getString('refresh_token') ?? '';
      
      // Call logout API
      await authRepository.logout(
        deviceId: deviceId,
        refreshToken: refreshToken,
      );

      // Clear all login data
      SharedPrefsHelper.clearRefreshToken();
      await prefs.remove('access_token');
      await prefs.remove('device_id');
      await prefs.remove('user_type');
      await prefs.remove('user_email');
      await prefs.remove('user_first_name');
      await prefs.remove('user_last_name');
      await prefs.setBool('is_logged_in', false);

      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        
        // Small delay to ensure dialog is closed
        await Future.delayed(const Duration(milliseconds: 100));
        
        if (!context.mounted) return;
        
        // Navigate to login screen and clear all previous routes
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
        
        // Show success message
        await Future.delayed(const Duration(milliseconds: 300));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Logged out successfully'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        
        // Small delay to ensure dialog is closed
        await Future.delayed(const Duration(milliseconds: 100));
        
        if (!context.mounted) return;
        
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout failed: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
