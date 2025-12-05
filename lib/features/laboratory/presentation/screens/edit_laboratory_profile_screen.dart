import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/phone_number.dart';
import 'package:provider/provider.dart';

import 'package:haticare/core/theme/app_colors.dart';
import 'package:haticare/core/widgets/app_primary_button.dart';
import 'package:haticare/core/widgets/app_text_field.dart';
import 'package:haticare/features/laboratory/presentation/viewmodels/laboratory_profile_view_model.dart';

class EditLaboratoryProfileScreen extends StatefulWidget {
  final String laboratoryId;
  final bool isForceComplete;
  final bool openedFromSettings;

  const EditLaboratoryProfileScreen({
    super.key,
    required this.laboratoryId,
    this.isForceComplete = false,
    this.openedFromSettings = false,
  });

  @override
  State<EditLaboratoryProfileScreen> createState() => _EditLaboratoryProfileScreenState();
}

class _EditLaboratoryProfileScreenState extends State<EditLaboratoryProfileScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => LaboratoryProfileViewModel(
        laboratoryId: widget.laboratoryId,
        openedFromSettings: !widget.isForceComplete,
      ),
      child: Consumer<LaboratoryProfileViewModel>(
        builder: (context, viewModel, child) {
          viewModel.setContext(context);
          return WillPopScope(
            onWillPop: () async {
              if (widget.isForceComplete) {
                return false;
              }
              if (_currentPage > 0) {
                _pageController.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
                return false;
              }
              return true;
            },
            child: Scaffold(
              backgroundColor: Colors.white,
              appBar: AppBar(
                backgroundColor: Colors.white,
                elevation: 0,
                leading: widget.isForceComplete
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.black),
                        onPressed: () {
                          if (!widget.openedFromSettings && _currentPage > 0) {
                            _pageController.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          } else {
                            Navigator.pop(context);
                          }
                        },
                      ),
                title: Text(
                  'Edit Laboratory Profile',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                centerTitle: false,
              ),
              body: viewModel.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : widget.openedFromSettings
                      ? _buildSinglePageForm(viewModel)
                      : Column(
                          children: [
                            // Progress indicator
                            _buildProgressIndicator(viewModel),

                            // Form pages
                            Expanded(
                              child: PageView(
                                controller: _pageController,
                                onPageChanged: (index) {
                                  setState(() {
                                    _currentPage = index;
                                  });
                                },
                                children: [
                                  _buildPage1(viewModel),
                                  _buildPage2(viewModel),
                                ],
                              ),
                            ),
                          ],
                        ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSinglePageForm(LaboratoryProfileViewModel viewModel) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Edit Laboratory Profile',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 24),

          // Contact Person (Non-editable)
          _LabeledField(
            label: 'Contact Person',
            child: AppTextField(
              controller: viewModel.contactPersonController,
              label: 'Contact Person',
              hint: 'Dr. Ali Khan',
              enabled: false,
              prefixIcon: const Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: 16),

          // Email (Non-editable)
          _LabeledField(
            label: 'Email',
            child: AppTextField(
              controller: viewModel.emailController,
              label: 'Email',
              hint: 'laboratory@example.com',
              enabled: false,
              prefixIcon: const Icon(Icons.email_outlined),
            ),
          ),
          const SizedBox(height: 16),

          // Laboratory Name (Editable)
          _LabeledField(
            label: 'Laboratory Name',
            child: AppTextField(
              controller: viewModel.laboratoryNameController,
              label: 'Laboratory Name',
              hint: 'Ab Laboratory',
              textCapitalization: TextCapitalization.words,
              prefixIcon: const Icon(Icons.business_outlined),
            ),
          ),
          const SizedBox(height: 16),

          // Phone Number (Editable)
          _LabeledField(
            label: 'Phone Number',
            child: IntlPhoneField(
              controller: viewModel.phoneNumberController,
              initialCountryCode: viewModel.countryCode.replaceAll('+', ''),
              onChanged: viewModel.updatePhone,
              onCountryChanged: (country) {
                viewModel.updateCountryCode(country.dialCode);
              },
              decoration: InputDecoration(
                hintText: '1234567890',
                filled: true,
                fillColor: AppColors.surface,
                prefixIcon: const Icon(Icons.phone_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Address Section
          _LabeledField(
            label: 'Address',
            child: AppTextField(
              controller: viewModel.addressLine1Controller,
              label: 'Address',
              hint: 'Street 12',
              textCapitalization: TextCapitalization.words,
              prefixIcon: const Icon(Icons.location_on_outlined),
            ),
          ),
          const SizedBox(height: 16),

          // Country (Editable)
          _LabeledField(
            label: 'Country',
            child: AppTextField(
              controller: viewModel.countryController,
              label: 'Country',
              hint: 'Pakistan',
              textCapitalization: TextCapitalization.words,
              prefixIcon: const Icon(Icons.public_outlined),
            ),
          ),
          const SizedBox(height: 16),

          // State (Editable)
          _LabeledField(
            label: 'State',
            child: AppTextField(
              controller: viewModel.stateController,
              label: 'State',
              hint: 'Punjab',
              textCapitalization: TextCapitalization.words,
              prefixIcon: const Icon(Icons.location_city_outlined),
            ),
          ),
          const SizedBox(height: 16),

          // City (Editable)
          _LabeledField(
            label: 'City',
            child: AppTextField(
              controller: viewModel.cityController,
              label: 'City',
              hint: 'Lahore',
              textCapitalization: TextCapitalization.words,
              prefixIcon: const Icon(Icons.location_city_outlined),
            ),
          ),
          const SizedBox(height: 16),

          // ZIP Code (Editable)
          _LabeledField(
            label: 'ZIP Code',
            child: AppTextField(
              controller: viewModel.zipCodeController,
              label: 'ZIP Code',
              hint: '54000',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              prefixIcon: const Icon(Icons.local_post_office_outlined),
            ),
          ),
          const SizedBox(height: 24),

          // Profile Picture - Centered and smaller
          Center(
            child: Column(
              children: [
                const Text(
                  'Profile Picture',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6C7278),
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => _showImagePicker(context, viewModel, isProfilePicture: true),
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(40),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: viewModel.profilePictureFile != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(40),
                            child: Image.file(
                              viewModel.profilePictureFile!,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.camera_alt_outlined,
                                size: 24,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Add',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Tax Identification Number
          _LabeledField(
            label: 'Tax Identification Number',
            child: AppTextField(
              controller: viewModel.taxIdentificationNumberController,
              label: 'Tax ID',
              hint: '12345678',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              prefixIcon: const Icon(Icons.receipt_outlined),
            ),
          ),
          const SizedBox(height: 16),

          // License Number
          _LabeledField(
            label: 'License Number',
            child: AppTextField(
              controller: viewModel.licenseNumberController,
              label: 'License Number',
              hint: 'LIC-123468',
              textCapitalization: TextCapitalization.characters,
              prefixIcon: const Icon(Icons.verified_outlined),
            ),
          ),
          const SizedBox(height: 16),

          // License Document
          _LabeledField(
            label: 'License Document',
            child: GestureDetector(
              onTap: () => _showImagePicker(context, viewModel, isProfilePicture: false),
              child: Container(
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: viewModel.licenseDocumentFile != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.file(
                          viewModel.licenseDocumentFile!,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.description_outlined,
                            size: 32,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Add License Document',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Error Message
          if (viewModel.errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red.shade600, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      viewModel.errorMessage!,
                      style: TextStyle(color: Colors.red.shade600, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Success Message
          if (viewModel.successMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline, color: Colors.green.shade600, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      viewModel.successMessage!,
                      style: TextStyle(color: Colors.green.shade600, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Submit Button
          AppPrimaryButton(
            label: 'Save Profile',
            onPressed: viewModel.isSubmitting ? null : viewModel.submitProfile,
            isLoading: viewModel.isSubmitting,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(LaboratoryProfileViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                color: _currentPage >= 0 ? AppColors.primary : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                color: _currentPage >= 1 ? AppColors.primary : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage1(LaboratoryProfileViewModel viewModel) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Basic Information',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 24),

          // Contact Person (Non-editable)
          _LabeledField(
            label: 'Contact Person',
            child: AppTextField(
              controller: viewModel.contactPersonController,
              label: 'Contact Person',
              hint: 'Dr. Ali Khan',
              enabled: false,
              prefixIcon: const Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: 16),

          // Email (Non-editable)
          _LabeledField(
            label: 'Email',
            child: AppTextField(
              controller: viewModel.emailController,
              label: 'Email',
              hint: 'laboratory@example.com',
              enabled: false,
              prefixIcon: const Icon(Icons.email_outlined),
            ),
          ),
          const SizedBox(height: 16),

          // Laboratory Name (Editable)
          _LabeledField(
            label: 'Laboratory Name',
            child: AppTextField(
              controller: viewModel.laboratoryNameController,
              label: 'Laboratory Name',
              hint: 'Ab Laboratory',
              textCapitalization: TextCapitalization.words,
              prefixIcon: const Icon(Icons.business_outlined),
            ),
          ),
          const SizedBox(height: 16),

          // Phone Number (Editable)
          _LabeledField(
            label: 'Phone Number',
            child: IntlPhoneField(
              controller: viewModel.phoneNumberController,
              initialCountryCode: viewModel.countryCode.replaceAll('+', ''),
              onChanged: viewModel.updatePhone,
              onCountryChanged: (country) {
                viewModel.updateCountryCode(country.dialCode);
              },
              decoration: InputDecoration(
                hintText: '1234567890',
                filled: true,
                fillColor: AppColors.surface,
                prefixIcon: const Icon(Icons.phone_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Address Section
          _LabeledField(
            label: 'Address',
            child: AppTextField(
              controller: viewModel.addressLine1Controller,
              label: 'Address',
              hint: 'Street 12',
              textCapitalization: TextCapitalization.words,
              prefixIcon: const Icon(Icons.location_on_outlined),
            ),
          ),
          const SizedBox(height: 16),

          // Country (Editable)
          _LabeledField(
            label: 'Country',
            child: AppTextField(
              controller: viewModel.countryController,
              label: 'Country',
              hint: 'Pakistan',
              textCapitalization: TextCapitalization.words,
              prefixIcon: const Icon(Icons.public_outlined),
            ),
          ),
          const SizedBox(height: 16),

          // State (Editable)
          _LabeledField(
            label: 'State',
            child: AppTextField(
              controller: viewModel.stateController,
              label: 'State',
              hint: 'Punjab',
              textCapitalization: TextCapitalization.words,
              prefixIcon: const Icon(Icons.location_city_outlined),
            ),
          ),
          const SizedBox(height: 16),

          // City (Editable)
          _LabeledField(
            label: 'City',
            child: AppTextField(
              controller: viewModel.cityController,
              label: 'City',
              hint: 'Lahore',
              textCapitalization: TextCapitalization.words,
              prefixIcon: const Icon(Icons.location_city_outlined),
            ),
          ),
          const SizedBox(height: 16),

          // ZIP Code (Editable)
          _LabeledField(
            label: 'ZIP Code',
            child: AppTextField(
              controller: viewModel.zipCodeController,
              label: 'ZIP Code',
              hint: '54000',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              prefixIcon: const Icon(Icons.local_post_office_outlined),
            ),
          ),
          const SizedBox(height: 32),

          // Next Button
          AppPrimaryButton(
            label: 'Next',
            onPressed: () {
              _pageController.nextPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPage2(LaboratoryProfileViewModel viewModel) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Additional Information',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 24),

          // Profile Picture - Centered and larger
          Center(
            child: Column(
              children: [
                const Text(
                  'Profile Picture',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6C7278),
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => _showImagePicker(context, viewModel, isProfilePicture: true),
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(60),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: viewModel.profilePictureFile != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(60),
                            child: Image.file(
                              viewModel.profilePictureFile!,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.camera_alt_outlined,
                                size: 32,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Add Photo',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Tax Identification Number
          _LabeledField(
            label: 'Tax Identification Number',
            child: AppTextField(
              controller: viewModel.taxIdentificationNumberController,
              label: 'Tax ID',
              hint: '12345678',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              prefixIcon: const Icon(Icons.receipt_outlined),
            ),
          ),
          const SizedBox(height: 16),

          // License Number
          _LabeledField(
            label: 'License Number',
            child: AppTextField(
              controller: viewModel.licenseNumberController,
              label: 'License Number',
              hint: 'LIC-123468',
              textCapitalization: TextCapitalization.characters,
              prefixIcon: const Icon(Icons.verified_outlined),
            ),
          ),
          const SizedBox(height: 16),

          // License Document
          _LabeledField(
            label: 'License Document',
            child: GestureDetector(
              onTap: () => _showImagePicker(context, viewModel, isProfilePicture: false),
              child: Container(
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: viewModel.licenseDocumentFile != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.file(
                          viewModel.licenseDocumentFile!,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.description_outlined,
                            size: 40,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap to add license document',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Error Message
          if (viewModel.errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red.shade600, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      viewModel.errorMessage!,
                      style: TextStyle(color: Colors.red.shade600, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Success Message
          if (viewModel.successMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline, color: Colors.green.shade600, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      viewModel.successMessage!,
                      style: TextStyle(color: Colors.green.shade600, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Submit Button
          AppPrimaryButton(
            label: 'Save Profile',
            onPressed: viewModel.isSubmitting ? null : viewModel.submitProfile,
            isLoading: viewModel.isSubmitting,
          ),

          // Back Button (only show when not forced)
          if (!widget.isForceComplete) ...[
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                _pageController.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              child: const Text('Back'),
            ),
          ],
        ],
      ),
    );
  }

  void _showImagePicker(BuildContext context, LaboratoryProfileViewModel viewModel, {required bool isProfilePicture}) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                if (isProfilePicture) {
                  viewModel.pickProfilePicture(ImageSource.camera);
                } else {
                  viewModel.pickLicenseDocument(ImageSource.camera);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose From Gallery'),
              onTap: () {
                Navigator.pop(context);
                if (isProfilePicture) {
                  viewModel.pickProfilePicture(ImageSource.gallery);
                } else {
                  viewModel.pickLicenseDocument(ImageSource.gallery);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.label,
    required this.child,
    this.spacing = 8,
  });

  final String label;
  final Widget child;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF6C7278),
          ),
        ),
        SizedBox(height: spacing),
        child,
      ],
    );
  }
}
