import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:path/path.dart' as path;
import 'package:haticare/core/theme/app_colors.dart';
import 'package:haticare/core/widgets/app_dropdown_field.dart';
import 'package:haticare/core/widgets/app_primary_button.dart';
import 'package:haticare/core/widgets/custom_dropdown_dialog.dart';
import 'package:haticare/features/pharmacy/presentation/viewmodels/pharmacy_profile_view_model.dart';
import 'package:haticare/features/pharmacy/presentation/screens/pharmacy_home_screen.dart';
import 'package:haticare/features/common/presentation/screens/upload_document_screen.dart';

// Custom formatter to prevent double spaces
class SingleSpaceFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Replace multiple consecutive spaces with a single space
    final newText = newValue.text.replaceAll(RegExp(r'\s{2,}'), ' ');
    
    // If the text was changed (spaces were reduced), return the new value
    if (newText != newValue.text) {
      return TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newText.length),
      );
    }
    
    return newValue;
  }
}

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
        // Allow navigating back to step 1 from step 2
        if (viewModel.currentStep == 2) {
          viewModel.moveBackToPreviousPage();
          return false;
        }

        // If force complete mode, prevent leaving the screen
        if (isForceComplete) {
          return false;
        }

        // If opened from settings on step 1, show confirmation dialog only if changes were made
        if (openedFromSettings && viewModel.currentStep == 1) {
          if (viewModel.hasChanges) {
            return await _showExitConfirmationDialog(context) ?? false;
          }
          return true;
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
          leading: (openedFromSettings || viewModel.currentStep == 2)
              ? IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () async {
              if (viewModel.currentStep == 2) {
                viewModel.moveBackToPreviousPage();
              } else if (openedFromSettings) {
                // Show confirmation dialog only if changes were made
                if (viewModel.hasChanges) {
                  final shouldExit = await _showExitConfirmationDialog(context) ?? false;
                  if (shouldExit && context.mounted) {
                    Navigator.of(context).pop();
                  }
                } else {
                  // No changes, just exit
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                }
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
          child: Column(
            children: [
              // Show "Complete your profile" banner only for first-time users
              if (isForceComplete && !openedFromSettings)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(top: 16, left: 16, right: 16),
                  decoration: BoxDecoration(
                    color: AppColors.primaryDark.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.primaryDark.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: AppColors.primaryDark, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Complete your profile to continue using the app',
                          style: TextStyle(
                            color: AppColors.primaryDark,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
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
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
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
      autovalidateMode: AutovalidateMode.disabled,
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

          // Editable fields
          _buildEditableField(
            label: 'Contact Person',
            controller: viewModel.contactPersonController,
            validator: (_) => viewModel.validateContactPerson(viewModel.contactPersonController.text),
            hintText: 'Enter contact person name',
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
              SingleSpaceFormatter(),
            ],
            viewModel: viewModel,
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
            validator: (_) => viewModel.getValidationError('pharmacyName') ?? viewModel.validatePharmacyName(viewModel.pharmacyNameController.text),
            hintText: 'Enter pharmacy name',
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
              SingleSpaceFormatter(),
            ],
            onChanged: () => viewModel.clearValidationError('pharmacyName'),
            viewModel: viewModel,
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
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
            validator: (_) => viewModel.getValidationError('address') ?? viewModel.validateAddress(viewModel.addressLine1Controller.text),
            hintText: 'Enter street address',
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\s,.-]')),
              SingleSpaceFormatter(),
            ],
            onChanged: () => viewModel.clearValidationError('address'),
            viewModel: viewModel,
          ),
          const SizedBox(height: 16),

          // Country dropdown
          _buildCountryDropdown(context, viewModel),
          const SizedBox(height: 16),

          // State dropdown
          _buildStateDropdown(context, viewModel),
          const SizedBox(height: 16),

          // City dropdown
          _buildCityDropdown(context, viewModel),
          const SizedBox(height: 16),

          // Zip Code
          _buildEditableField(
            label: 'Zip Code',
            controller: viewModel.zipCodeController,
            validator: (_) => viewModel.getValidationError('zipCode') ?? viewModel.validateZipCode(viewModel.zipCodeController.text),
            hintText: 'Enter zip code',
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
              LengthLimitingTextInputFormatter(20),
            ],
            onChanged: () => viewModel.clearValidationError('zipCode'),
            viewModel: viewModel,
          ),
        ],
      ),
    );
  }

  Widget _buildPage2(BuildContext context, PharmacyProfileViewModel viewModel) {
    return Form(
      key: viewModel.formKeyPage2,
      autovalidateMode: AutovalidateMode.disabled,
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
              child: Column(
                children: [
                  Text(
                    viewModel.profilePicture != null || (viewModel.profilePictureUrl != null && viewModel.profilePictureUrl!.isNotEmpty)
                        ? 'Tap to change'
                        : 'Tap to add photo',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (viewModel.attemptedSubmit && viewModel.profilePicture == null && (viewModel.profilePictureUrl == null || viewModel.profilePictureUrl!.isEmpty))
                    const Text(
                      'Profile picture required',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
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
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
              LengthLimitingTextInputFormatter(20),
            ],
          ),
          const SizedBox(height: 16),

          // License Number
          _buildEditableField(
            label: 'License Number',
            controller: viewModel.licenseNumberController,
            validator: viewModel.validateLicenseNumber,
            hintText: 'Enter license number',
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
              LengthLimitingTextInputFormatter(20),
            ],
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
            label: _getLicenseDocumentLabel(viewModel),
            onPressed: () => _navigateToUploadDocument(context, viewModel, 1),
            isSelected: viewModel.licenseDocument1 != null || (viewModel.licenseDocument1Url != null && viewModel.licenseDocument1Url!.isNotEmpty),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showExitConfirmationDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Discard Changes?'),
          content: const Text('Are you sure you want to exit? Any unsaved changes will be lost.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Exit'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCountryDropdown(BuildContext context, PharmacyProfileViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Country',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: viewModel.countryController,
          readOnly: true,
          decoration: InputDecoration(
            hintText: 'Select country',
            filled: true,
            fillColor: Colors.white,
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
              borderSide: const BorderSide(color: AppColors.primaryDark, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            suffixIcon: Icon(Icons.arrow_drop_down, color: Colors.grey[400]),
          ),
          onTap: () async {
            final selected = await showCustomDropdownDialog(
              context: context,
              title: 'Select Country',
              items: viewModel.getCountryNames(),
              selectedValue: viewModel.selectedCountry,
              searchHint: 'Search countries...',
            );
            if (selected != null) {
              viewModel.selectCountry(selected);
              viewModel.clearValidationError('country');
            }
          },
        ),
      ],
    );
  }

  Widget _buildStateDropdown(BuildContext context, PharmacyProfileViewModel viewModel) {
    final isEnabled = viewModel.selectedCountry != null && viewModel.selectedCountry!.isNotEmpty;
    final states = isEnabled ? viewModel.getStateNames() : [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'State',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: viewModel.stateController,
          readOnly: true,
          decoration: InputDecoration(
            hintText: 'Select state',
            filled: true,
            fillColor: isEnabled ? Colors.white : Colors.grey[100],
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
              borderSide: const BorderSide(color: AppColors.primaryDark, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            suffixIcon: Icon(
              Icons.arrow_drop_down,
              color: isEnabled ? Colors.grey[400] : Colors.grey[300],
            ),
          ),
          onTap: isEnabled
              ? () async {
                  final selected = await showCustomDropdownDialog(
                    context: context,
                    title: 'Select State',
                    items: viewModel.getStateNames(),
                    selectedValue: viewModel.selectedState,
                    searchHint: 'Search states...',
                  );
                  if (selected != null) {
                    viewModel.selectState(selected);
                    viewModel.clearValidationError('state');
                  }
                }
              : null,
        ),
      ],
    );
  }

  Widget _buildCityDropdown(BuildContext context, PharmacyProfileViewModel viewModel) {
    final isEnabled = viewModel.selectedState != null && viewModel.selectedState!.isNotEmpty;
    final cities = isEnabled ? viewModel.getCityNames() : [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'City',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: viewModel.cityController,
          readOnly: true,
          decoration: InputDecoration(
            hintText: 'Select city',
            filled: true,
            fillColor: isEnabled ? Colors.white : Colors.grey[100],
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
              borderSide: const BorderSide(color: AppColors.primaryDark, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            suffixIcon: Icon(
              Icons.arrow_drop_down,
              color: isEnabled ? Colors.grey[400] : Colors.grey[300],
            ),
          ),
          onTap: isEnabled
              ? () async {
                  final selected = await showCustomDropdownDialog(
                    context: context,
                    title: 'Select City',
                    items: viewModel.getCityNames(),
                    selectedValue: viewModel.selectedCity,
                    searchHint: 'Search cities...',
                  );
                  if (selected != null) {
                    viewModel.selectCity(selected);
                    viewModel.clearValidationError('city');
                  }
                }
              : null,
        ),
      ],
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
    List<TextInputFormatter>? inputFormatters,
    VoidCallback? onChanged,
    PharmacyProfileViewModel? viewModel,
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
        if (isPhoneNumber && viewModel != null)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IntlPhoneField(
                controller: controller,
                initialCountryCode: viewModel.countryCode,
                initialValue: viewModel.initialPhoneNumber,
                onCountryChanged: (country) {
                  // Update the country code in the view model
                  viewModel.updatePhoneNumber(null); // Clear to reset
                },
                onChanged: (phone) {
                  viewModel.updatePhoneNumber(phone);
                  if (onChanged != null) onChanged();
                },
                validator: (phone) {
                  // Return null for phone validation as it's handled differently
                  return null;
                },
                decoration: InputDecoration(
                  hintText: hintText,
                  filled: true,
                  fillColor: Colors.white,
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
                    borderSide: const BorderSide(color: AppColors.primaryDark, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          )
        else
          TextFormField(
            controller: controller,
            validator: validator,
            autovalidateMode: AutovalidateMode.onUnfocus,
            onChanged: (value) {
              if (onChanged != null) onChanged();
            },
            decoration: InputDecoration(
              hintText: hintText,
              filled: true,
              fillColor: Colors.white,
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
                borderSide: const BorderSide(color: AppColors.primaryDark, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
            inputFormatters: inputFormatters,
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
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Image',
            toolbarColor: AppColors.primaryDark,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
            hideBottomControls: false,
            cropGridRowCount: 3,
            cropGridColumnCount: 3,
          ),
          IOSUiSettings(
            title: 'Crop Image',
            aspectRatioLockEnabled: false,
            resetAspectRatioEnabled: true,
            aspectRatioPickerButtonHidden: false,
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
        return SafeArea(
          child: Container(
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
                    _handleImagePick(context, ImageSource.camera, viewModel, isProfilePicture: true);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.image),
                  title: const Text('Select From Gallery'),
                  onTap: () async {
                    Navigator.pop(context);
                    _handleImagePick(context, ImageSource.gallery, viewModel, isProfilePicture: true);
                  },
                ),
              ],
            ),

          ),
        );
      },
    );
  }

  Future<void> _handleImagePick(
      BuildContext context,
      ImageSource source,
      PharmacyProfileViewModel viewModel,
      {bool isProfilePicture = false, int? documentNumber}
      ) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: source == ImageSource.camera ? 800 : 1920,
        maxHeight: source == ImageSource.camera ? 800 : 1920,
      );

      if (pickedFile != null) {
        final croppedFile = await _cropImage(File(pickedFile.path));
        if (croppedFile != null) {
          if (isProfilePicture) {
            viewModel.setProfilePicture(croppedFile);
          } else if (documentNumber != null) {
            if (documentNumber == 1) {
              viewModel.setLicenseDocument1(croppedFile);
            } else if (documentNumber == 2) {
              viewModel.setLicenseDocument2(croppedFile);
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  static String _getLicenseDocumentLabel(PharmacyProfileViewModel viewModel) {
    // If a new file is selected
    if (viewModel.licenseDocument1 != null) {
      return path.basename(viewModel.licenseDocument1!.path);
    }

    // If there's an existing document URL from API
    if (viewModel.licenseDocument1Url != null && viewModel.licenseDocument1Url!.isNotEmpty) {
      try {
        // Extract filename from URL
        final uri = Uri.parse(viewModel.licenseDocument1Url!);
        final segments = uri.pathSegments;
        if (segments.isNotEmpty) {
          return segments.last;
        }
      } catch (e) {
        debugPrint('Error parsing document URL: $e');
      }
      return 'License Document (Uploaded)';
    }

    // Default label when no document
    return 'Upload License Document';
  }

  Future<void> _navigateToUploadDocument(
      BuildContext context,
      PharmacyProfileViewModel viewModel,
      int documentNumber,
      ) async {
    final result = await Navigator.of(context, rootNavigator: true).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (_) => const UploadDocumentScreen(
          title: 'Upload License Document',
          subtitle: 'Please capture or upload your license document',
        ),
      ),
    );

    if (result != null && result['file'] != null) {
      final file = result['file'] as File;
      if (documentNumber == 1) {
        viewModel.setLicenseDocument1(file);
      } else if (documentNumber == 2) {
        viewModel.setLicenseDocument2(file);
      }
    }
  }
}