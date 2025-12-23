import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:haticare/core/theme/app_colors.dart';
import 'package:haticare/core/widgets/app_primary_button.dart';
import 'package:haticare/core/widgets/app_dropdown_field.dart';
import 'package:haticare/core/widgets/custom_dropdown_dialog.dart';
import 'package:haticare/features/common/presentation/screens/upload_document_screen.dart';
import 'package:haticare/features/doctor/presentation/viewModel/doctor_profile_view_model.dart';
import 'package:intl/intl.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:provider/provider.dart';

import '../providers/doctor_user_provider.dart';

class EditProfileScreen extends StatelessWidget {
  final bool openedFromSettings;

  const EditProfileScreen({super.key, this.openedFromSettings = false});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DoctorProfileViewModel(
        doctorId: '',
        openedFromSettings: openedFromSettings,
      ),
      child: _EditProfileView(openedFromSettings: openedFromSettings),
    );
  }
}

class _EditProfileView extends StatelessWidget {
  final bool openedFromSettings;

  const _EditProfileView({this.openedFromSettings = false});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<DoctorProfileViewModel>();

    if (viewModel.shouldNavigateToHome) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          viewModel.resetNavigation();

          // Update the provider to refresh doctor data
          context.read<DoctorUserProvider>().fetchProfile(forceRefresh: true);

          // Navigate back first
          Navigator.of(context).pop();

          // Show success message after navigation
          Future.delayed(const Duration(milliseconds: 100), () {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Doctor profile updated successfully'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 2),
                ),
              );
            }
          });
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

        // If opened from settings on step 1, show confirmation dialog only if changes were made
        if (openedFromSettings && viewModel.currentStep == 1) {
          if (viewModel.hasChanges) {
            return await _showExitConfirmationDialog(context) ?? false;
          }
          return true;
        }

        return true;
      },
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          backgroundColor: const Color(0xFFF9FAFB),
          appBar: AppBar(
            backgroundColor: const Color(0xFFF9FAFB),
            elevation: 0,
            title: const Text(
              'Edit Doctor Profile',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            centerTitle: true,
            automaticallyImplyLeading: true,
            leading: (openedFromSettings || viewModel.currentStep == 2)
                ? IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black),
                    onPressed: () async {
                      if (viewModel.currentStep == 2) {
                        viewModel.moveBackToPreviousPage();
                      } else if (openedFromSettings) {
                        if (viewModel.hasChanges) {
                          final shouldExit =
                              await _showExitConfirmationDialog(context) ??
                              false;
                          if (shouldExit && context.mounted) {
                            Navigator.of(context).pop();
                          }
                        } else {
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
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  child: Column(
                    children: [
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
                                  color: Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.red.withOpacity(0.3),
                                  ),
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
                                label: viewModel.isSubmitting
                                    ? 'Submitting...'
                                    : 'Submit',
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
            color: currentStep >= 1 ? AppColors.primary : Colors.grey[300],
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
            color: currentStep >= 2 ? AppColors.primary : Colors.grey[300],
            margin: const EdgeInsets.symmetric(horizontal: 8),
          ),
        ),
        // Step 2
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: currentStep >= 2 ? AppColors.primary : Colors.grey[300],
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

  Widget _buildPage1(BuildContext context, DoctorProfileViewModel viewModel) {
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

          Row(
            children: [
              Expanded(
                child: _buildEditableField(
                  label: "First Name",
                  controller: viewModel.firstNameController,
                  hintText: "Enter first name",
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z]')),
                  ],
                  validator: viewModel.validateFirstName,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildEditableField(
                  label: "Last Name",
                  controller: viewModel.lastNameController,
                  hintText: "Enter last name",
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z]')),
                  ],
                  validator: viewModel.validateLastName,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          _buildNonEditableField(
            label: "Email",
            controller: viewModel.emailController,
          ),
          const SizedBox(height: 16),

          // Phone Number Field
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Phone Number',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6C7278),
                ),
              ),
              const SizedBox(height: 8),
              IntlPhoneField(
                key: ValueKey('phone_${viewModel.phoneFieldKey}'),
                initialValue: viewModel.initialPhoneNumber,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  hintText: 'Enter phone number',
                  hintStyle: const TextStyle(color: AppColors.textSecondary),
                  counterText: '',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Colors.red, width: 1.5),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Colors.red, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
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

          // Gender and Date of Birth in Row
          Row(
            children: [
              // Gender Dropdown
              Expanded(
                child: AppDropdownField<String>(
                  label: 'Gender',
                  items: const [
                    DropdownMenuItem(value: 'Male', child: Text('Male')),
                    DropdownMenuItem(value: 'Female', child: Text('Female')),
                    DropdownMenuItem(value: 'Other', child: Text('Other')),
                  ],
                  value: viewModel.gender,
                  onChanged: (value) {
                    viewModel.updateGender(value);
                  },
                  validator: viewModel.validateGender,
                  hint: 'Select gender',
                  prefixIcon: const Icon(
                    Icons.person_2_outlined,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Date of Birth
              Expanded(
                child: AppDropdownField<String>(
                  label: 'Date of Birth',
                  items: const [],
                  value: viewModel.selectedDate != null
                      ? DateFormat(
                          'MMM dd, yyyy',
                        ).format(viewModel.selectedDate!)
                      : null,
                  onChanged: (value) {
                    // This will be handled by onTap
                  },
                  validator: viewModel.validateDateOfBirth,
                  hint: 'Select Date',
                  prefixIcon: const Icon(
                    Icons.calendar_today_outlined,
                    color: AppColors.primary,
                  ),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: viewModel.selectedDate ?? DateTime.now(),
                      firstDate: DateTime(1950),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      viewModel.updateDateOfBirth(picked);
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPage2(BuildContext context, DoctorProfileViewModel viewModel) {
    return Form(
      key: viewModel.formKeyPage2,
      autovalidateMode: AutovalidateMode.disabled,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Professional Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),

          _buildEditableField(
            label: "License Number",
            controller: viewModel.licenseNumberController,
            hintText: "Enter license number",
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
              LengthLimitingTextInputFormatter(20),
            ],
            validator: viewModel.validateLicenseNumber,
          ),

          const SizedBox(height: 16),

          // License Type Dropdown with Search
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'License Type',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6C7278),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                readOnly: true,
                controller: TextEditingController(
                  text: viewModel.selectedLicenseType ?? '',
                ),
                decoration: InputDecoration(
                  hintText: 'Select license type',
                  hintStyle: const TextStyle(color: AppColors.textSecondary),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Colors.red),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Colors.red, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  suffixIcon: const Icon(
                    Icons.arrow_drop_down,
                    color: Colors.grey,
                  ),
                  prefixIcon: const Icon(
                    Icons.card_membership_outlined,
                    color: AppColors.primary,
                  ),
                ),
                validator: viewModel.validateLicenseType,
                onTap: () async {
                  final selected = await showCustomDropdownDialog(
                    context: context,
                    title: 'Select License Type',
                    items: viewModel.licenseTypes,
                    selectedValue: viewModel.selectedLicenseType,
                    searchHint: 'Search license type...',
                  );
                  if (selected != null) {
                    viewModel.updateLicenseType(selected);
                  }
                },
              ),
            ],
          ),

          const SizedBox(height: 16),

          _buildEditableField(
            label: "Years of Experience",
            controller: viewModel.yearsExperienceController,
            hintText: "Enter years of experience",
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              NoZeroInputFormatter(),
            ],
            validator: viewModel.validateYearsExperience,
          ),
          const SizedBox(height: 16),

          // License Media
          const Text(
            'License Media',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6C7278),
            ),
          ),
          const SizedBox(height: 12),

          _buildFileUploadButton(
            context: context,
            label: _getLicenseDocumentLabel(viewModel),
            onPressed: () async {
              final result = await Navigator.of(context, rootNavigator: true)
                  .push<Map<String, dynamic>>(
                    MaterialPageRoute(
                      builder: (_) => const UploadDocumentScreen(
                        title: 'Upload License Document',
                        subtitle:
                            'Please capture or upload your license document',
                      ),
                    ),
                  );

              if (result != null && result['file'] != null) {
                final file = result['file'] as File;
                final body = {'license_document': file};
                await viewModel.updateDoctorInfo(body);
                // Refresh doctor profile after upload
                viewModel.fetchDoctorProfile(forceRefresh: true);
              }
            },
            isSelected:
                viewModel.licenseDocumentFile != null ||
                (viewModel.licenseDocumentUrl != null &&
                    viewModel.licenseDocumentUrl!.isNotEmpty),
          ),

          const SizedBox(height: 16),

          // Document ID
          const Text(
            'Document ID',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6C7278),
            ),
          ),
          const SizedBox(height: 12),

          _buildFileUploadButton(
            context: context,
            label: _getIdDocumentLabel(viewModel),
            onPressed: () async {
              final result = await Navigator.of(context, rootNavigator: true)
                  .push<Map<String, dynamic>>(
                    MaterialPageRoute(
                      builder: (_) => const UploadDocumentScreen(
                        title: 'Upload ID Document',
                        subtitle: 'Please capture or upload your ID document',
                      ),
                    ),
                  );

              if (result != null && result['file'] != null) {
                final file = result['file'] as File;
                final body = {'id_document': file};
                await viewModel.updateDoctorInfo(body);
                // Refresh doctor profile after upload
                viewModel.fetchDoctorProfile(forceRefresh: true);
              }
            },
            isSelected:
                viewModel.idDocumentFile != null ||
                (viewModel.idDocumentUrl != null &&
                    viewModel.idDocumentUrl!.isNotEmpty),
          ),

          const SizedBox(height: 16),

          // Specialization Dropdown with Search
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Specialization',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6C7278),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                readOnly: true,
                controller: TextEditingController(
                  text: viewModel.selectedSpecialization ?? '',
                ),
                decoration: InputDecoration(
                  hintText: 'Select specialization',
                  hintStyle: const TextStyle(color: AppColors.textSecondary),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Colors.red),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Colors.red, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  suffixIcon: const Icon(
                    Icons.arrow_drop_down,
                    color: Colors.grey,
                  ),
                  prefixIcon: const Icon(
                    Icons.medical_services_outlined,
                    color: AppColors.primary,
                  ),
                ),
                validator: viewModel.validateSpecialization,
                onTap: () async {
                  final selected = await showCustomDropdownDialog(
                    context: context,
                    title: 'Select Specialization',
                    items: viewModel.specializationNames,
                    selectedValue: viewModel.selectedSpecialization,
                    searchHint: 'Search specialization...',
                  );
                  if (selected != null) {
                    viewModel.updateSpecialization(selected);
                  }
                },
              ),
            ],
          ),

          const SizedBox(height: 16),

          _buildEditableField(
            label: "License Issuing Authority",
            controller: viewModel.licenseAuthorityController,
            hintText: "Enter license issuing authority",
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\s]')),
              LengthLimitingTextInputFormatter(50),
            ],
            validator: viewModel.validateLicenseAuthority,
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
          content: const Text(
            'Are you sure you want to exit? Any unsaved changes will be lost.',
          ),
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

  String _getLicenseDocumentLabel(DoctorProfileViewModel viewModel) {
    // 1️⃣ Show local picked file ONLY if upload still in progress
    if (viewModel.licenseDocumentFile != null) {
      return viewModel.licenseDocumentFile!.path.split('/').last;
    }

    // 2️⃣ Show server file name
    final url = viewModel.licenseDocumentUrl;
    if (url != null && url.isNotEmpty) {
      try {
        final uri = Uri.parse(url);
        return uri.pathSegments.isNotEmpty
            ? uri.pathSegments.last
            : 'License Document';
      } catch (_) {
        return 'License Document';
      }
    }

    // 3️⃣ Default
    return 'Upload License Document';
  }

  String _getIdDocumentLabel(DoctorProfileViewModel viewModel) {
    // If a new file is selected
    if (viewModel.idDocumentFile != null) {
      return viewModel.idDocumentFile!.path.split('/').last;
    }

    // If there's an existing document URL from API
    if (viewModel.idDocumentUrl != null &&
        viewModel.idDocumentUrl!.isNotEmpty) {
      try {
        final uri = Uri.parse(viewModel.idDocumentUrl!);
        final segments = uri.pathSegments;
        if (segments.isNotEmpty) {
          return segments.last;
        }
      } catch (e) {
        debugPrint('Error parsing document URL: $e');
      }
      return 'ID Document (Uploaded)';
    }

    // Default label when no document
    return 'Upload ID Document';
  }

  Widget _buildFileUploadButton({
    required BuildContext context,
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
        backgroundColor: isSelected ? Colors.green : AppColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _buildEditableField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF6C7278),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(color: AppColors.textSecondary),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
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
            color: Color(0xFF6C7278),
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
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          style: const TextStyle(color: Colors.grey, fontSize: 14),
        ),
      ],
    );
  }
}

// TO PREVENT NON ZERO VALUE
class NoZeroInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;

    if (text == "0" || text == "00") {
      return oldValue;
    }

    if (text.length > 2) {
      return oldValue;
    }

    return newValue;
  }
}
