import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:haticare/features/common/shared_prefs_helper.dart';
import 'package:haticare/features/doctor/presentation/screens/edit_profile_screen.dart';
import 'package:provider/provider.dart';
import 'package:haticare/features/doctor/presentation/viewModel/logout_viewModel.dart';
import 'package:haticare/features/auth/presentation/screens/login_screen.dart';

class SettingsContent extends StatelessWidget {
  const SettingsContent({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AuthDViewModel>();
    final firstName = SaveLoginResponse.loginData?['first_name'] ?? '';
    final lastName = SaveLoginResponse.loginData?['last_name'] ?? '';
    final profileImageUrl =
        SaveLoginResponse.loginData?['profile_picture'] ?? '';
    final docName = '$firstName $lastName';

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12.withOpacity(0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 40,
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Center(
                            child: profileImageUrl.isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(50),
                                    child: Image.network(
                                      profileImageUrl,
                                      width: 100,
                                      height: 100,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : SvgPicture.asset(
                                    'assets/icons/person_icon.svg',
                                    width: 80,
                                    height: 80,
                                  ),
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: const CircleAvatar(
                                backgroundColor: Color(0xFF243E8A),
                                child: Icon(
                                  Icons.edit,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      docName.trim().isNotEmpty ? docName : 'Loading...',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Text(
                      'General Physician',
                      style: TextStyle(fontSize: 15, color: Colors.grey),
                    ),
                    const Text(
                      'License: GMC-12345',
                      style: TextStyle(fontSize: 15, color: Colors.grey),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              _buildSection(
                title: 'Account',
                items: [
                  SettingItem(
                    icon: Icons.person_outline,
                    title: 'Edit Profile',
                    onTap: () {
                      debugPrint('Edit Button Tappable');
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const EditProfileScreen(),
                        ),
                      );
                    },
                  ),
                  SettingItem(
                    icon: Icons.notifications_outlined,
                    title: 'Notifications',
                  ),
                  SettingItem(
                    icon: Icons.privacy_tip_outlined,
                    title: 'Privacy Policy',
                  ),
                ],
              ),

              const SizedBox(height: 24),

              _buildSection(
                title: 'Support',
                items: [
                  SettingItem(icon: Icons.help_outline, title: 'Help Center'),
                  SettingItem(
                    icon: Icons.phone_outlined,
                    title: 'Contact Support',
                  ),
                ],
              ),
              // const SizedBox(height: 24),

              Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 0),
                child: GestureDetector(
                  onTap: () async {
                    final shouldLogout = await showDialog<bool>(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: const Text('Confirm Logout'),
                          content: const Text(
                            'Are you sure you want to logout?',
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: const Text(
                                'Logout',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        );
                      },
                    );

                    if (shouldLogout == true) {
                      final success = await viewModel.logout();
                      if (success && context.mounted) {
                        Navigator.of(
                          context,
                          rootNavigator: true,
                        ).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                          (route) => false,
                        );
                      }
                    }
                  },

                  child: _buildSection(
                    title: '',
                    items: [
                      SettingItem(
                        icon: Icons.logout,
                        title: 'Logout',
                        titleColor: const Color(0xFFFF3B30),
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

  Widget _buildSection({required String title, required List<Widget> items}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 8),
        ...items,
      ],
    );
  }
}

class SettingItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color? titleColor;
  final bool showArrow;
  final bool hasShadow;
  final bool hasBorder;
  final VoidCallback? onTap;

  const SettingItem({
    required this.icon,
    required this.title,
    this.titleColor,
    this.showArrow = true,
    this.hasShadow = true,
    this.hasBorder = true,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: hasBorder
              ? Border.all(color: const Color(0xFFE5E5EA), width: 0.5)
              : null,
          boxShadow: hasShadow
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Icon(icon, size: 28, color: Colors.grey[700]),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  color: titleColor ?? Colors.black,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (showArrow) const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
