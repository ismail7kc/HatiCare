import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:haticare/features/common/shared_prefs_helper.dart';
import 'package:haticare/features/doctor/ApiClient/api_client.dart';
import 'package:haticare/features/doctor/RepositoryLayer/repository_layer.dart';
import 'package:haticare/features/doctor/presentation/screens/doctor_home_screen.dart';
import 'package:haticare/features/doctor/presentation/screens/edit_profile_screen.dart';
import 'package:haticare/features/doctor/presentation/viewModel/edit_viewModel.dart';
import 'package:haticare/features/pharmacy/presentation/screens/pharmacy_contact_support_screen.dart';
import 'package:haticare/features/pharmacy/presentation/screens/pharmacy_help_center_screen.dart';
import 'package:haticare/features/pharmacy/presentation/screens/pharmacy_notifications_screen.dart';
import 'package:haticare/features/pharmacy/presentation/screens/pharmacy_privacy_policy_screen.dart';
import 'package:provider/provider.dart';
import 'package:haticare/features/doctor/presentation/viewModel/logout_viewModel.dart';
import 'package:haticare/features/auth/presentation/screens/login_screen.dart';
import 'package:image_picker/image_picker.dart';

class SettingsContent extends StatefulWidget {
  const SettingsContent({super.key});

  @override
  State<SettingsContent> createState() => SettingsContentState();
}

class SettingsContentState extends State<SettingsContent> {
  File? image;
  late EditViewmodel editViewModel;
  bool isUploading = false;

  @override
  void initState() {
    super.initState();
    editViewModel = EditViewmodel(RepositoryLayer(ApiClient()));
  }

  Future<void> pickImage() async {
    final XFile? pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      final File selectedImage = File(pickedFile.path);

      setState(() {
        image = selectedImage;
        isUploading = true;
      });
    }
    await uploadProfileImage(image!);

    setState(() {
      isUploading = false;
    });
  }

  Future<void> uploadProfileImage(File imageFile) async {
    try {
      final response = await editViewModel.sendProfileImageToServr(imageFile);

      if (response['success'] == true) {
        debugPrint("✅ Profile image uploaded successfully!");

        final updatedImageUrl = response['data']['profile_picture'];

        SaveLoginResponse.loginData?['profile_picture'] = updatedImageUrl;
        ProfileNotifier.profileImageUrl.value = updatedImageUrl;

        setState(() {});

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Profile image updated successfully!"),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        debugPrint("Upload failed: ${response['message'] ?? response}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Upload failed"),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint("Error uploading image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error uploading image"),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AuthDViewModel>();
    final firstName = SaveLoginResponse.loginData?['first_name'] ?? '';
    final lastName = SaveLoginResponse.loginData?['last_name'] ?? '';
    final profileImageUrl = SaveLoginResponse.loginData?['profile_picture'] ?? '';
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
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(50),
                              child: image != null
                                  ? Image.file(
                                      image!,
                                      width: 100,
                                      height: 100,
                                      fit: BoxFit.cover,
                                    )
                                  : (profileImageUrl.isNotEmpty
                                        ? Image.network(
                                            profileImageUrl,
                                            width: 100,
                                            height: 100,
                                            fit: BoxFit.cover,
                                          )
                                        : SvgPicture.asset(
                                            'assets/icons/person_icon.svg',
                                            width: 80,
                                            height: 80,
                                          )),
                            ),
                          ),

                          if (isUploading)
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: Colors.black45,
                                borderRadius: BorderRadius.circular(50),
                              ),
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 3,
                                ),
                              ),
                            ),

                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: GestureDetector(
                              onTap: pickImage,
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                                child: CircleAvatar(
                                  backgroundColor: Color(0xFF243E8A),
                                  child: Icon(
                                    Icons.edit,
                                    size: 14,
                                    color: Colors.white,
                                  ),
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
                    icon: 'assets/icons/edit_profile_icon.svg',
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
                    icon: 'assets/icons/notification_icon.svg',
                    title: 'Notifications',
                    onTap: () {
                      debugPrint('Notification Tapped');
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const PharmacyNotificationsScreen(),
                        ),
                      );
                    },
                  ),
                  SettingItem(
                    icon: 'assets/icons/privacy_policy_icon.svg',
                    title: 'Privacy Policy',
                    onTap: () {
                      debugPrint('Notification Tapped');
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const PharmacyPrivacyPolicyScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 24),

              _buildSection(
                title: 'Support',
                items: [
                  SettingItem(
                    icon: 'assets/icons/help_center_icon.svg',
                    title: 'Help Center',
                    onTap: () {
                      debugPrint("Help Center tapped");
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PharmacyHelpCenterScreen(),
                        ),
                      );
                    },
                  ),
                  SettingItem(
                    icon: 'assets/icons/contact_support_icon.svg',
                    title: 'Contact Support',
                    onTap: () {
                      debugPrint("Contact Support tapped");
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PharmacyContactSupportScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),

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
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (_) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        },
                      );

                      try {
                        final success = await viewModel.logout();

                        if (context.mounted) Navigator.of(context).pop();

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
                        } else if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "Failed to logout. Please try again.",
                              ),
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) Navigator.of(context).pop();

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "Something went wrong. Please try again.",
                              ),
                            ),
                          );
                        }
                      }
                    }
                  },

                  child: _buildSection(
                    title: '',
                    items: [
                      SettingItem(
                        icon: 'assets/icons/logout.svg',
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
  final String icon;
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
            SvgPicture.asset(icon, width: 28, height: 28),

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
