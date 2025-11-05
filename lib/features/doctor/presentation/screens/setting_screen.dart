import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SettingsContent extends StatelessWidget {
  const SettingsContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 20),

        CircleAvatar(
          radius: 40,
          child: Stack(
            alignment: Alignment.bottomRight,
            children: [
              Center(
                child: SvgPicture.asset(
                  'assets/icons/person_icon.svg',
                  width: 80,
                  height: 80,
                ),
              ),

              CircleAvatar(
                radius: 12,
                backgroundColor: const Color(0xFF243E8A),
                child: const Icon(Icons.edit, size: 14, color: Colors.white),
              ),

              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const CircleAvatar(
                    backgroundColor: Color(0xFF243E8A),
                    child: Icon(Icons.edit, size: 14, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        const Text(
          'Dr. John Doe',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),

        const Text(
          'General Physician',
          style: TextStyle(fontSize: 15, color: Colors.grey),
        ),

        const Text(
          'License: GMC-12345',
          style: TextStyle(fontSize: 15, color: Colors.grey),
        ),

        const SizedBox(height: 32),

        // Account Section
        _buildSection(
          title: 'Account',
          items: [
            SettingItem(icon: Icons.person_outline, title: 'Edit Profile'),
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

        // Support Section
        _buildSection(
          title: 'Support',
          items: [
            SettingItem(icon: Icons.help_outline, title: 'Help Center'),
            SettingItem(icon: Icons.phone_outlined, title: 'Contact Support'),
          ],
        ),

        const SizedBox(height: 24),

        // Logout
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SettingItem(
            icon: Icons.logout,
            title: 'Logout',
            titleColor: const Color(0xFFFF3B30),
            showArrow: false,
            hasShadow: false,
            hasBorder: false,
          ),
        ),

        const Spacer(),
      ],
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

  const SettingItem({
    required this.icon,
    required this.title,
    this.titleColor,
    this.showArrow = true,
    this.hasShadow = true,
    this.hasBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        // ── Border ──
        border: hasBorder
            ? Border.all(color: const Color(0xFFE5E5EA), width: 0.5)
            : null,
        // ── Shadow ──
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
          Icon(icon, size: 20, color: Colors.grey[700]),
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
    );
  }
}
