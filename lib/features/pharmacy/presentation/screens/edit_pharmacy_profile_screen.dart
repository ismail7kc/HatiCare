import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:haticare/core/theme/app_colors.dart';
import 'package:haticare/core/widgets/app_primary_button.dart';
import 'package:haticare/features/pharmacy/presentation/viewmodels/pharmacy_profile_view_model.dart';
import 'package:haticare/features/pharmacy/presentation/screens/pharmacy_home_screen.dart';

class EditPharmacyProfileScreen extends StatelessWidget {
  final String pharmacyId;
  final bool isForceComplete;
  final bool openedFromSettings;

  const EditPharmacyProfileScreen({
    super.key,
    required this.pharmacyId,
    this.isForceComplete = false,
    this.openedFromSettings = false,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PharmacyProfileViewModel(
        pharmacyId: pharmacyId,
        openedFromSettings: openedFromSettings,
      ),
      child: _EditPharmacyProfileView(
        isForceComplete: isForceComplete,
        openedFromSettings: openedFromSettings,
      ),
    );
  }
}

class _EditPharmacyProfileView extends StatelessWidget {
  final bool isForceComplete;
  final bool openedFromSettings;

  const _EditPharmacyProfileView({
    this.isForceComplete = false,
    this.openedFromSettings = false,
  });

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<PharmacyProfileViewModel>();

    if (viewModel.shouldNavigateToHome) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          viewModel.resetNavigation();

          if (openedFromSettings) {
            // Return to settings screen
            Navigator.of(context).pop();
          } else {
            // Navigate to home screen
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const PharmacyHomeScreen()),
              (route) => false,
            );
          }
        }
      });
    }

    return WillPopScope(
      onWillPop: () async {
        // If force complete mode, prevent back navigation entirely
        if (isForceComplete) {
          return false;
        }
        // If opened from settings, allow back on step 1
        if (openedFromSettings && viewModel.currentStep == 1) {
          return true;
        }
        // Otherwise allow back navigation between steps
        if (viewModel.currentStep == 2) {
          viewModel.moveBackToPreviousPage();
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF9FAFB),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF9FAFB),
          elevation: 0,
          title: const Text(
            'Edit Pharmacy Profile',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          centerTitle: true,
          automaticallyImplyLeading: false,
          leading: (openedFromSettings || (viewModel.currentStep == 2 && !isForceComplete))
              ? IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: () {
                    if (viewModel.currentStep == 2) {
                      viewModel.moveBackToPreviousPage();
                    } else {
                      Navigator.of(context).pop();
                    }
                  },
                )
              : null,
        ),
        body: viewModel.isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Progress indicator
                _buildProgressIndicator(viewModel.currentStep),
                const SizedBox(height: 24),

                // Page content
                if (viewModel.currentStep == 1)
                  _buildPage1(context, viewModel)
                else
                  _buildPage2(context, viewModel),

                const SizedBox(height: 24),

                // Error message
                if (viewModel.errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: Text(
                      viewModel.errorMessage!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 14,
                      ),
                    ),
                  ),

                const SizedBox(height: 24),

                // Action buttons
                if (viewModel.currentStep == 1)
                  AppPrimaryButton(
                    label: 'Next',
                    onPressed: viewModel.isSubmitting
                        ? null
                        : () => viewModel.moveToNextPage(),
                  )
                else
                  AppPrimaryButton(
                    label: viewModel.isSubmitting ? 'Submitting...' : 'Submit',
                    onPressed: viewModel.isSubmitting
                        ? null
                        : () => viewModel.submitProfile(),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(int currentStep) {
    return Row(
      children: [
        // Step 1
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: currentStep >= 1 ? AppColors.primaryDark : Colors.grey[300],
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '1',
              style: TextStyle(
                color: currentStep >= 1 ? Colors.white : Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        // Connector
        Expanded(
          child: Container(
            height: 2,
            color: currentStep >= 2 ? AppColors.primaryDark : Colors.grey[300],
            margin: const EdgeInsets.symmetric(horizontal: 8),
          ),
        ),
        // Step 2
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: currentStep >= 2 ? AppColors.primaryDark : Colors.grey[300],
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '2',
              style: TextStyle(
                color: currentStep >= 2 ? Colors.white : Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPage1(BuildContext context, PharmacyProfileViewModel viewModel) {
    return Form(
      key: viewModel.formKeyPage1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Basic Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),

          // Non-editable fields
          _buildNonEditableField(
            label: 'Contact Person',
            controller: viewModel.contactPersonController,
          ),
          const SizedBox(height: 16),

          _buildNonEditableField(
            label: 'Email',
            controller: viewModel.emailController,
          ),
          const SizedBox(height: 16),

          // Editable fields
          _buildEditableField(
            label: 'Pharmacy Name',
            controller: viewModel.pharmacyNameController,
            validator: viewModel.validatePharmacyName,
            hintText: 'Enter pharmacy name',
          ),
          const SizedBox(height: 16),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Phone Number',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              IntlPhoneField(
                initialValue: viewModel.initialPhoneNumber,
                decoration: InputDecoration(
                  hintText: 'Enter phone number',
                  counterText: '',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.red, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  filled: true,
                  fillColor: Colors.white,
                ),
                initialCountryCode: viewModel.countryCode,
                showCountryFlag: true,
                showDropdownIcon: true,
                dropdownIconPosition: IconPosition.trailing,
                dropdownIcon: const Icon(
                  Icons.arrow_drop_down,
                  color: Colors.grey,
                ),
                flagsButtonPadding: const EdgeInsets.only(left: 12, right: 8),
                onChanged: (phone) {
                  viewModel.updatePhoneNumber(phone);
                },
                validator: (value) {
                  if (value == null || value.number.isEmpty) {
                    return 'Please enter a valid phone number';
                  }
                  return null;
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          _buildEditableField(
            label: 'Address Line 1',
            controller: viewModel.addressLine1Controller,
            validator: viewModel.validateAddress,
            hintText: 'Enter street address',
          ),
          const SizedBox(height: 16),

          _buildEditableField(
            label: 'City',
            controller: viewModel.cityController,
            validator: viewModel.validateCity,
            hintText: 'Enter city',
          ),
          const SizedBox(height: 16),

          _buildEditableField(
            label: 'State',
            controller: viewModel.stateController,
            validator: viewModel.validateState,
            hintText: 'Enter state',
          ),
          const SizedBox(height: 16),

          _buildEditableField(
            label: 'Zip Code',
            controller: viewModel.zipCodeController,
            validator: viewModel.validateZipCode,
            hintText: 'Enter zip code',
          ),
          const SizedBox(height: 16),

          _buildEditableField(
            label: 'Country',
            controller: viewModel.countryController,
            validator: viewModel.validateCountry,
            hintText: 'Enter country',
          ),
        ],
      ),
    );
  }

  Widget _buildPage2(BuildContext context, PharmacyProfileViewModel viewModel) {
    return Form(
      key: viewModel.formKeyPage2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Only show profile picture if not opened from settings
          if (!openedFromSettings) ...[
            // Profile Picture
            const Text(
              'Profile Picture',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 12),

            Center(
              child: GestureDetector(
                onTap: () => _showImagePickerBottomSheet(context, viewModel),
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primaryDark,
                      width: 2,
                    ),
                  ),
                  child: viewModel.profilePicture != null
                      ? ClipOval(
                          child: Image.file(
                            viewModel.profilePicture!,
                            fit: BoxFit.cover,
                          ),
                        )
                      : viewModel.profilePictureUrl != null && viewModel.profilePictureUrl!.isNotEmpty
                          ? ClipOval(
                              child: Image.network(
                                viewModel.profilePictureUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    Icons.camera_alt,
                                    size: 40,
                                    color: AppColors.primaryDark,
                                  );
                                },
                              ),
                            )
                          : const Icon(
                              Icons.camera_alt,
                              size: 40,
                              color: AppColors.primaryDark,
                            ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                viewModel.profilePicture != null || (viewModel.profilePictureUrl != null && viewModel.profilePictureUrl!.isNotEmpty)
                    ? 'Tap to change'
                    : 'Tap to add photo',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Tax Identification Number
          _buildEditableField(
            label: 'Tax Identification Number',
            controller: viewModel.taxIdController,
            validator: viewModel.validateTaxId,
            hintText: 'Enter tax identification number',
          ),
          const SizedBox(height: 16),

          // License Number
          _buildEditableField(
            label: 'License Number',
            controller: viewModel.licenseNumberController,
            validator: viewModel.validateLicenseNumber,
            hintText: 'Enter license number',
          ),
          const SizedBox(height: 24),

          // License Document
          const Text(
            'License Document',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),

          _buildFileUploadButton(
            label: viewModel.licenseDocument1 != null
                ? 'License Document (Selected)'
                : (viewModel.licenseDocument1Url != null && viewModel.licenseDocument1Url!.isNotEmpty)
                    ? 'License Document (Uploaded)'
                    : 'Upload License Document',
            onPressed: () => _pickFile(context, viewModel, 1),
            isSelected: viewModel.licenseDocument1 != null || (viewModel.licenseDocument1Url != null && viewModel.licenseDocument1Url!.isNotEmpty),
          ),
        ],
      ),
    );
  }

  Widget _buildNonEditableField({
    required String label,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          enabled: false,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildEditableField({
    required String label,
    required TextEditingController controller,
    required String? Function(String?) validator,
    required String hintText,
    bool isPhoneNumber = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: isPhoneNumber ? TextInputType.phone : TextInputType.text,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(color: Colors.grey),
            counterText: isPhoneNumber ? '' : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: AppColors.primaryDark,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFileUploadButton({
    required String label,
    required VoidCallback onPressed,
    required bool isSelected,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(
        isSelected ? Icons.check_circle : Icons.upload_file,
        color: Colors.white,
      ),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected
            ? Colors.green
            : AppColors.primaryDark,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Future<File?> _cropImage(File imageFile) async {
    try {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: imageFile.path,
        compressQuality: 85,
        maxWidth: 800,
        maxHeight: 800,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Image',
            toolbarColor: AppColors.primaryDark,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: false,
          ),
          IOSUiSettings(
            title: 'Crop Image',
            aspectRatioLockEnabled: false,
          ),
        ],
      );

      if (croppedFile != null) {
        return File(croppedFile.path);
      }
      return null;
    } catch (e) {
      debugPrint('Error cropping image: $e');
      return null;
    }
  }

  void _showImagePickerBottomSheet(
    BuildContext context,
    PharmacyProfileViewModel viewModel,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Select Profile Picture',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take Picture'),
                onTap: () async {
                  Navigator.pop(context);
                  final picker = ImagePicker();
                  final pickedFile = await picker.pickImage(
                    source: ImageSource.camera,
                    imageQuality: 85,
                    maxWidth: 800,
                  );
                  if (pickedFile != null) {
                    final croppedFile = await _cropImage(File(pickedFile.path));
                    if (croppedFile != null) {
                      viewModel.setProfilePicture(croppedFile);
                    }
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.image),
                title: const Text('Select From Gallery'),
                onTap: () async {
                  Navigator.pop(context);
                  final picker = ImagePicker();
                  final pickedFile = await picker.pickImage(
                    source: ImageSource.gallery,
                    imageQuality: 85,
                    maxWidth: 800,
                  );
                  if (pickedFile != null) {
                    final croppedFile = await _cropImage(File(pickedFile.path));
                    if (croppedFile != null) {
                      viewModel.setProfilePicture(croppedFile);
                    }
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickFile(
    BuildContext context,
    PharmacyProfileViewModel viewModel,
    int documentNumber,
  ) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      if (documentNumber == 1) {
        viewModel.setLicenseDocument1(file);
      } else if (documentNumber == 2) {
        viewModel.setLicenseDocument2(file);
      }
    }
  }
}
