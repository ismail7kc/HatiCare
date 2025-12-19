import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:haticare/core/theme/app_colors.dart';
import 'package:haticare/features/common/shared_prefs_helper.dart';
import 'package:haticare/features/doctor/presentation/screens/doctor_home_screen.dart';
import 'package:haticare/features/doctor/presentation/screens/edit_profile_screen.dart';
import 'package:haticare/features/doctor/presentation/providers/doctor_user_provider.dart';
import 'package:haticare/features/pharmacy/presentation/screens/pharmacy_contact_support_screen.dart';
import 'package:haticare/features/pharmacy/presentation/screens/pharmacy_help_center_screen.dart';
import 'package:haticare/features/pharmacy/presentation/screens/pharmacy_notifications_screen.dart';
import 'package:haticare/features/pharmacy/presentation/screens/pharmacy_privacy_policy_screen.dart';
import 'package:provider/provider.dart';
import 'package:haticare/features/doctor/presentation/viewModel/logout_viewModel.dart';
import 'package:haticare/features/auth/presentation/screens/login_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:chucker_flutter/chucker_flutter.dart';
import '../../../../core/config/app_config.dart';

class SettingsContent extends StatefulWidget {
  const SettingsContent({super.key});

  @override
  State<SettingsContent> createState() => SettingsContentState();
}

class SettingsContentState extends State<SettingsContent> {
  bool _isUpdating = false;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
  }

  Future<File?> _cropImage(File imageFile) async {
    try {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: imageFile.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        compressQuality: 85,
        maxWidth: 800,
        maxHeight: 800,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Profile Picture',
            toolbarColor: AppColors.primaryDark,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
          ),
          IOSUiSettings(
            title: 'Crop Profile Picture',
            aspectRatioLockEnabled: true,
          ),
        ],
      );
      if (croppedFile != null) {
        return File(croppedFile.path);
      }

      return null;
    } catch (e) {
      debugPrint('Error cropping image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to crop image: ${e.toString()}')),
        );
      }
      return null;
    }
  }

  Future<void> _updateProfilePicture(File imageFile) async {
    if (!mounted || _isUploading) return;

    setState(() {
      _isUpdating = true;
      _isUploading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final doctorId = SaveLoginResponse.loginData?['id'] ?? '';
      final accessToken = prefs.getString('access_token') ?? '';

      if (doctorId.toString().isEmpty) {
        throw Exception('Doctor ID not found');
      }

      final uri = Uri.parse('${AppConfig.baseUrl}doc/doctors/$doctorId/');
      final request = http.MultipartRequest('PATCH', uri);
      request.headers['Authorization'] = 'Bearer $accessToken';
      request.files.add(await http.MultipartFile.fromPath(
        'profile_picture',
        imageFile.path,
      ));

      final client = ChuckerHttpClient(http.Client());
      final response = await client.send(request);
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final jsonResponse = jsonDecode(responseBody);
        if (!mounted) return;

        final dynamic responseData = jsonResponse is Map
            ? (jsonResponse['data'] ?? jsonResponse)
            : {};
        final newImageUrl = responseData['profile_picture']?.toString();

        if (newImageUrl != null && newImageUrl.isNotEmpty) {
          // Add cache-busting timestamp
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final updatedUrl = newImageUrl.contains('?')
              ? '$newImageUrl&t=$timestamp'
              : '$newImageUrl?t=$timestamp';

          // Update provider
          if (mounted) {
            context.read<DoctorUserProvider>().updateProfilePicture(updatedUrl);
          }

          // Update ProfileNotifier for immediate UI update
          ProfileNotifier.profileImageUrl.value = updatedUrl;

          // Show success message
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Profile picture updated successfully'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          }
        }
      } else {
        throw Exception('Failed to update profile picture: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error updating profile picture: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
          _isUploading = false;
        });
      }
    }
  }

  void _showImagePickerBottomSheet() {
    showModalBottomSheet(
      context: context,
      isDismissible: !_isUploading,
      enableDrag: !_isUploading,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isUploading) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Uploading image...'),
                    ],
                  ),
                ),
              ] else ...[
                const Text(
                  'Select Profile Picture',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Take Picture'),
                  onTap: () async {
                    Navigator.pop(context);
                    await _pickImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.image),
                  title: const Text('Select From Gallery'),
                  onTap: () async {
                    Navigator.pop(context);
                    await _pickImage(ImageSource.gallery);
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 800,
      );

      if (pickedFile != null && mounted) {
        final croppedFile = await _cropImage(File(pickedFile.path));
        if (croppedFile != null && mounted) {
          await _updateProfilePicture(croppedFile);
        }
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to ${source == ImageSource.camera ? 'take' : 'select'} image. Please try again.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AuthDViewModel>();
    final doctorProvider = context.watch<DoctorUserProvider>();

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
                        doctorProvider.isLoading
                            ? Container(
                                width: 80,
                                height: 80,
                                decoration: const BoxDecoration(
                                  gradient: AppColors.primaryGradient,
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                ),
                              )
                            : _isUpdating
                            ? Container(
                                width: 80,
                                height: 80,
                                decoration: const BoxDecoration(
                                  gradient: AppColors.primaryGradient,
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                ),
                              )
                            : doctorProvider.profilePictureUrl.isNotEmpty
                            ? ClipOval(
                                child: Image.network(
                                  doctorProvider.profilePictureUrl,
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
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
                                    );
                                  },
                                ),
                              )
                            : Container(
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
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: GestureDetector(
                            onTap: _isUpdating ? null : _showImagePickerBottomSheet,
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
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    doctorProvider.isLoading
                        ? const SizedBox(
                            width: 100,
                            height: 20,
                            child: LinearProgressIndicator(),
                          )
                        : Text(
                            doctorProvider.doctorName.isNotEmpty
                                ? (doctorProvider.doctorName.length > 15
                                    ? '${doctorProvider.doctorName.substring(0, 15)}...'
                                    : doctorProvider.doctorName)
                                : 'User',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                    const SizedBox(height: 6),
                    doctorProvider.isLoading
                        ? const SizedBox(
                            width: 100,
                            height: 14,
                            child: LinearProgressIndicator(),
                          )
                        : Text(
                            doctorProvider.specialty.isNotEmpty ? doctorProvider.specialty : 'Specialty',
                            style: const TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                    const SizedBox(height: 4),
                    doctorProvider.isLoading
                        ? const SizedBox(
                            width: 100,
                            height: 13,
                            child: LinearProgressIndicator(),
                          )
                        : Text(
                            doctorProvider.licenseNumber.isNotEmpty
                                ? 'License: ${doctorProvider.licenseNumber}'
                                : 'License: N/A',
                            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                          ),
                  ],
                ),
              ),

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
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const EditProfileScreen(),
                          ),
                        );
                        // Refresh provider data after returning
                        if (context.mounted) {
                          context.read<DoctorUserProvider>().fetchProfile(forceRefresh: true);
                        }
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
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PharmacyHelpCenterScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 6),
                    _buildSettingsCard(
                      context,
                      svgIcon: 'assets/icons/contact_support_icon.svg',
                      title: 'Contact Support',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PharmacyContactSupportScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Logout Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildLogoutCard(context, viewModel),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
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
        side: const BorderSide(color: Colors.white),
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
              const Icon(Icons.arrow_forward_ios, color: Colors.black, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutCard(BuildContext context, AuthDViewModel viewModel) {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Colors.white),
      ),
      child: InkWell(
        onTap: () => _showLogoutDialog(context, viewModel),
        borderRadius: BorderRadius.circular(12),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Row(
            children: [
              Icon(Icons.logout, color: Colors.red, size: 24),
              SizedBox(width: 16),
              Expanded(
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

  void _showLogoutDialog(BuildContext context, AuthDViewModel viewModel) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.logout, color: Colors.red, size: 28),
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
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                await _handleLogout(context, viewModel);
              },
              child: const Text(
                'Logout',
                style: TextStyle(
                  color: Colors.red,
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

  Future<void> _handleLogout(BuildContext context, AuthDViewModel viewModel) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return const Center(
          child: CircularProgressIndicator(color: Colors.white),
        );
      },
    );

    try {
      final success = await viewModel.logout();

      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();

        // Small delay to ensure dialog is closed
        await Future.delayed(const Duration(milliseconds: 100));

        if (!context.mounted) return;

        if (success) {
          // Navigate to login screen and clear all previous routes
          Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to logout. Please try again.'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();

        // Small delay to ensure dialog is closed
        await Future.delayed(const Duration(milliseconds: 100));

        if (!context.mounted) return;

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
