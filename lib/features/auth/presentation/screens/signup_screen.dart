import 'package:flutter/material.dart';
import 'package:haticare/core/theme/app_colors.dart';
import 'package:haticare/core/widgets/app_primary_button.dart';
import 'package:haticare/core/widgets/app_text_field.dart';
import 'package:haticare/features/auth/domain/entities/user_role.dart';
import 'package:haticare/features/auth/domain/repositories/auth_repository.dart';
import 'package:haticare/features/auth/presentation/viewmodels/signup_view_model.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:provider/provider.dart';

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<SignupViewModel>(
      create: (context) => SignupViewModel(context.read<AuthRepository>()),
      child: const _SignupView(),
    );
  }
}

class _SignupView extends StatefulWidget {
  const _SignupView();

  @override
  State<_SignupView> createState() => _SignupViewState();
}

class _SignupViewState extends State<_SignupView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    final viewModel = context.read<SignupViewModel>();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: viewModel.isDoctor ? 0 : 1,
    );
    _tabController.addListener(_handleTabChange);
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) return;
    final viewModel = context.read<SignupViewModel>();
    final role = _tabController.index == 0
        ? UserRole.doctor
        : UserRole.pharmacy;
    if (viewModel.selectedRole != role) {
      viewModel.selectRole(role);
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<SignupViewModel>();
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    final targetIndex = viewModel.isDoctor ? 0 : 1;
    if (_tabController.index != targetIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _tabController.index != targetIndex) {
          _tabController.animateTo(
            targetIndex,
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeInOut,
          );
        }
      });
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Form(
                key: viewModel.formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 24),
                    Text(
                      'Create New Account',
                      style: textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Please fill in the details below to create your account',
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F2FC),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        indicatorSize: TabBarIndicatorSize.tab,
                        indicator: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        labelColor: Colors.white,
                        unselectedLabelColor: const Color(0xFF7D7D91),
                        labelStyle: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        unselectedLabelStyle: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                        dividerColor: Colors.transparent,
                        onTap: (index) {
                          if (_tabController.index != index) {
                            _tabController.animateTo(
                              index,
                              duration: const Duration(milliseconds: 180),
                              curve: Curves.easeInOut,
                            );
                          }
                          final role = index == 0
                              ? UserRole.doctor
                              : UserRole.pharmacy;
                          if (viewModel.selectedRole != role) {
                            viewModel.selectRole(role);
                          }
                        },
                        tabs: const [
                          Tab(text: 'Doctor'),
                          Tab(text: 'Pharmacy'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        physics: const BouncingScrollPhysics(),
                        children: [
                          SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.only(bottom: 24),
                            child: _DoctorSection(
                              viewModel: viewModel,
                              textTheme: textTheme,
                            ),
                          ),
                          SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.only(bottom: 24),
                            child: _PharmacySection(
                              viewModel: viewModel,
                              textTheme: textTheme,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (viewModel.errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        viewModel.errorMessage!,
                        style: textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    if (viewModel.successMessage != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.check_circle,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                viewModel.successMessage!,
                                style: textTheme.bodySmall?.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

InputDecoration _phoneFieldDecoration(BuildContext context, {String? hint}) {
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: BorderSide(color: Colors.grey.shade300),
  );

  final focusedBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
  );

  return InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: AppColors.surface,
    enabledBorder: border,
    disabledBorder: border,
    border: border,
    focusedBorder: focusedBorder,
    errorBorder: border.copyWith(
      borderSide: BorderSide(color: Theme.of(context).colorScheme.error),
    ),
    focusedErrorBorder: focusedBorder.copyWith(
      borderSide:
          BorderSide(color: Theme.of(context).colorScheme.error, width: 1.4),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
  );
}

class _DoctorSection extends StatelessWidget {
  const _DoctorSection({required this.viewModel, required this.textTheme});

  final SignupViewModel viewModel;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _LabeledField(
                label: 'First Name',
                child: AppTextField(
                  controller: viewModel.firstNameController,
                  label: 'First Name',
                  hint: 'John',
                  textCapitalization: TextCapitalization.words,
                  prefixIcon: const Icon(Icons.person_outline),
                  validator: viewModel.validateFirstName,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _LabeledField(
                label: 'Last Name',
                child: AppTextField(
                  controller: viewModel.lastNameController,
                  label: 'Last Name',
                  hint: 'Doe',
                  textCapitalization: TextCapitalization.words,
                  prefixIcon: const Icon(Icons.person_outline),
                  validator: viewModel.validateLastName,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _LabeledField(
          label: 'Phone Number',
          child: IntlPhoneField(
            controller: viewModel.phoneNumberController,
            initialCountryCode: 'US',
            disableLengthCheck: true,
            dropdownIcon: const Icon(
              Icons.arrow_drop_down,
              color: AppColors.primary,
            ),
            showCountryFlag: true,
            showDropdownIcon: true,
            dropdownIconPosition: IconPosition.trailing,
            flagsButtonPadding: const EdgeInsets.only(left: 12),
            dropdownTextStyle:
                Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textPrimary,
                    ),
            style: Theme.of(context).textTheme.bodyMedium,
            decoration: _phoneFieldDecoration(
              context,
              hint: '1234567890',
            ),
            validator: (phone) =>
                viewModel.validateDoctorPhone(phone?.completeNumber),
            onChanged: viewModel.updateDoctorPhone,
            onSaved: viewModel.updateDoctorPhone,
          ),
        ),
        const SizedBox(height: 10),
        _LabeledField(
          label: 'Email',
          child: AppTextField(
            controller: viewModel.doctorEmailController,
            label: 'Email',
            hint: 'hello@example.com',
            keyboardType: TextInputType.emailAddress,
            prefixIcon: const Icon(Icons.email_outlined),
            validator: viewModel.validateDoctorEmail,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _LabeledField(
                label: 'Date of Birth',
                child: AppTextField(
                  controller: viewModel.dateOfBirthController,
                  label: 'Date of Birth',
                  hint: 'YYYY/MM/DD',
                  keyboardType: TextInputType.datetime,
                  prefixIcon: const Icon(Icons.calendar_month_outlined),
                  validator: viewModel.validateDoctorDob,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _LabeledField(
                label: 'Gender',
                child: AppTextField(
                  controller: viewModel.genderController,
                  label: 'Gender',
                  hint: 'Male',
                  textCapitalization: TextCapitalization.words,
                  prefixIcon: const Icon(Icons.person_2_outlined),
                  validator: viewModel.validateDoctorGender,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _LabeledField(
          label: 'Company Name',
          child: AppTextField(
            controller: viewModel.companyNameController,
            label: 'Company Name',
            hint: 'ABC Corp',
            prefixIcon: const Icon(Icons.apartment_outlined),
            validator: viewModel.validateDoctorCompanyName,
          ),
        ),
        const SizedBox(height: 10),
        _LabeledField(
          label: 'Company Address',
          child: AppTextField(
            controller: viewModel.companyAddressController,
            label: 'Company Address',
            hint: '123 Main St',
            prefixIcon: const Icon(Icons.location_on_outlined),
            validator: viewModel.validateDoctorCompanyAddress,
          ),
        ),
        const SizedBox(height: 10),
        _LabeledField(
          label: 'License Number',
          child: AppTextField(
            controller: viewModel.licenseNumberController,
            label: 'License Number',
            hint: 'XXXXXX',
            prefixIcon: const Icon(Icons.badge_outlined),
            validator: viewModel.validateDoctorLicenseNumber,
          ),
        ),
        const SizedBox(height: 10),
        _LabeledField(
          label: 'License Type',
          child: AppTextField(
            controller: viewModel.licenseTypeController,
            label: 'License Type',
            hint: 'Full License',
            prefixIcon: const Icon(Icons.assignment_outlined),
            validator: viewModel.validateDoctorLicenseType,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _LabeledField(
                label: 'Years of Experience',
                child: AppTextField(
                  controller: viewModel.yearsOfExperienceController,
                  label: 'Years of Experience',
                  hint: '1',
                  keyboardType: TextInputType.number,
                  prefixIcon: const Icon(Icons.timeline_outlined),
                  validator: viewModel.validateDoctorExperience,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _LabeledField(
                label: 'Specialization',
                child: AppTextField(
                  controller: viewModel.specializationController,
                  label: 'Specialization',
                  hint: 'Cardiology',
                  prefixIcon: const Icon(Icons.local_hospital_outlined),
                  validator: viewModel.validateDoctorSpecialization,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _LabeledField(
          label: 'License Issuing Authority',
          child: AppTextField(
            controller: viewModel.licenseIssuingAuthorityController,
            label: 'License Issuing Authority',
            hint: 'Medical Board',
            prefixIcon: const Icon(Icons.account_balance_outlined),
            validator: viewModel.validateDoctorIssuingAuthority,
          ),
        ),
        const SizedBox(height: 10),
        _LabeledField(
          label: 'License Document',
          child: _DocumentPickerTile(
            title: 'License Document',
            fileName: viewModel.doctorLicenseDocumentName,
            onTap: () async {
              // TODO: integrate real file picker
              viewModel.setDoctorLicenseDocument(
                path: '/mock/path/license.pdf',
                name: 'license.pdf',
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        _LabeledField(
          label: 'Password',
          child: AppTextField(
            controller: viewModel.doctorPasswordController,
            label: 'Password',
            hint: 'Enter Your Password',
            prefixIcon: const Icon(Icons.lock_outline),
            obscureText: true,
            enableObscureToggle: true,
            validator: viewModel.validateDoctorPassword,
          ),
        ),
        const SizedBox(height: 10),
        _LabeledField(
          label: 'Confirm Password',
          child: AppTextField(
            controller: viewModel.doctorConfirmPasswordController,
            label: 'Confirm Password',
            hint: 'Re-enter your password',
            prefixIcon: const Icon(Icons.lock_outline),
            obscureText: true,
            enableObscureToggle: true,
            validator: viewModel.validateDoctorConfirmPassword,
          ),
        ),
        const SizedBox(height: 20),
        AppPrimaryButton(
          label: 'Create Account',
          onPressed: viewModel.isSubmitting ? null : viewModel.submit,
          isLoading: viewModel.isSubmitting,
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Already have an account? ',
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            TextButton(
              onPressed: viewModel.isSubmitting
                  ? null
                  : () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                foregroundColor: AppColors.primary,
              ),
              child: const Text(
                'Log in',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PharmacySection extends StatelessWidget {
  const _PharmacySection({required this.viewModel, required this.textTheme});

  final SignupViewModel viewModel;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _LabeledField(
          label: 'Pharmacy Name',
          child: AppTextField(
            controller: viewModel.pharmacyNameController,
            label: 'Pharmacy Name',
            hint: 'HealthPlus Pharmacy',
            prefixIcon: const Icon(Icons.local_pharmacy_outlined),
            validator: viewModel.validatePharmacyName,
          ),
        ),
        const SizedBox(height: 10),
        _LabeledField(
          label: 'Owner / Manager Name',
          child: AppTextField(
            controller: viewModel.ownerNameController,
            label: 'Owner / Manager Name',
            hint: 'Jane Smith',
            textCapitalization: TextCapitalization.words,
            prefixIcon: const Icon(Icons.person_outline),
            validator: viewModel.validateOwnerName,
          ),
        ),
        const SizedBox(height: 10),
        _LabeledField(
          label: 'Business Phone Number',
          child: IntlPhoneField(
            controller: viewModel.businessPhoneController,
            initialCountryCode: 'US',
            disableLengthCheck: true,
            dropdownIcon: const Icon(
              Icons.arrow_drop_down,
              color: AppColors.primary,
            ),
            showCountryFlag: true,
            showDropdownIcon: true,
            dropdownIconPosition: IconPosition.trailing,
            flagsButtonPadding: const EdgeInsets.only(left: 12),
            dropdownTextStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textPrimary,
                ),
            style: Theme.of(context).textTheme.bodyMedium,
            decoration: _phoneFieldDecoration(
              context,
              hint: '1234567890',
            ),
            validator: (phone) =>
                viewModel.validateBusinessPhone(phone?.completeNumber),
            onChanged: viewModel.updateBusinessPhone,
            onSaved: viewModel.updateBusinessPhone,
          ),
        ),
        const SizedBox(height: 10),
        _LabeledField(
          label: 'Email',
          child: AppTextField(
            controller: viewModel.pharmacyEmailController,
            label: 'Email',
            hint: 'pharmacy@example.com',
            keyboardType: TextInputType.emailAddress,
            prefixIcon: const Icon(Icons.email_outlined),
            validator: viewModel.validatePharmacyEmail,
          ),
        ),
        const SizedBox(height: 10),
        _LabeledField(
          label: 'Address Line 1',
          child: AppTextField(
            controller: viewModel.addressLine1Controller,
            label: 'Address Line 1',
            hint: '123 Main St',
            prefixIcon: const Icon(Icons.location_on_outlined),
            validator: viewModel.validateAddressLine1,
          ),
        ),
        const SizedBox(height: 10),
        _LabeledField(
          label: 'Address Line 2 (Optional)',
          child: AppTextField(
            controller: viewModel.addressLine2Controller,
            label: 'Address Line 2 (Optional)',
            hint: 'Suite 200',
            prefixIcon: const Icon(Icons.location_on_outlined),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _LabeledField(
                label: 'City',
                child: AppTextField(
                  controller: viewModel.cityController,
                  label: 'City',
                  hint: 'Los Angeles',
                  prefixIcon: const Icon(Icons.location_city_outlined),
                  validator: viewModel.validateCity,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _LabeledField(
                label: 'State / Province',
                child: AppTextField(
                  controller: viewModel.stateController,
                  label: 'State / Province',
                  hint: 'California',
                  prefixIcon: const Icon(Icons.map_outlined),
                  validator: viewModel.validateState,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _LabeledField(
                label: 'ZIP / Postal Code',
                child: AppTextField(
                  controller: viewModel.postalCodeController,
                  label: 'ZIP / Postal Code',
                  hint: '90001',
                  keyboardType: TextInputType.number,
                  prefixIcon: const Icon(Icons.local_post_office_outlined),
                  validator: viewModel.validatePostalCode,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _LabeledField(
                label: 'Country',
                child: AppTextField(
                  controller: viewModel.countryController,
                  label: 'Country',
                  hint: 'United States',
                  prefixIcon: const Icon(Icons.public_outlined),
                  validator: viewModel.validateCountry,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _LabeledField(
          label: 'Pharmacy License Number',
          child: AppTextField(
            controller: viewModel.pharmacyLicenseNumberController,
            label: 'Pharmacy License Number',
            hint: 'LIC-123456',
            prefixIcon: const Icon(Icons.badge_outlined),
            validator: viewModel.validatePharmacyLicenseNumber,
          ),
        ),
        const SizedBox(height: 10),
        _LabeledField(
          label: 'License Document',
          child: _DocumentPickerTile(
            title: 'License Document',
            fileName: viewModel.pharmacyLicenseDocumentName,
            onTap: () async {
              // TODO: integrate real file picker
              viewModel.setPharmacyLicenseDocument(
                path: '/mock/path/pharmacy_license.pdf',
                name: 'pharmacy_license.pdf',
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        _LabeledField(
          label: 'Tax Identification Number (Optional)',
          child: AppTextField(
            controller: viewModel.taxIdentificationNumberController,
            label: 'Tax Identification Number (Optional)',
            hint: 'TIN-123456789',
            prefixIcon: const Icon(Icons.numbers_outlined),
          ),
        ),
        const SizedBox(height: 10),
        _LabeledField(
          label: 'Password',
          child: AppTextField(
            controller: viewModel.pharmacyPasswordController,
            label: 'Password',
            hint: 'Enter Your Password',
            prefixIcon: const Icon(Icons.lock_outline),
            obscureText: true,
            enableObscureToggle: true,
            validator: viewModel.validatePharmacyPassword,
          ),
        ),
        const SizedBox(height: 10),
        _LabeledField(
          label: 'Confirm Password',
          child: AppTextField(
            controller: viewModel.pharmacyConfirmPasswordController,
            label: 'Confirm Password',
            hint: 'Re-enter your password',
            prefixIcon: const Icon(Icons.lock_outline),
            obscureText: true,
            enableObscureToggle: true,
            validator: viewModel.validatePharmacyConfirmPassword,
          ),
        ),
        const SizedBox(height: 20),
        AppPrimaryButton(
          label: 'Create Account',
          onPressed: viewModel.isSubmitting ? null : viewModel.submit,
          isLoading: viewModel.isSubmitting,
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Already have an account? ',
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            TextButton(
              onPressed: viewModel.isSubmitting
                  ? null
                  : () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                foregroundColor: AppColors.primary,
              ),
              child: const Text(
                'Log in',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.label,
    required this.child,
    this.spacing = 6,
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
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: spacing),
        child,
      ],
    );
  }
}

class _DocumentPickerTile extends StatelessWidget {
  const _DocumentPickerTile({
    required this.title,
    required this.fileName,
    required this.onTap,
  });

  final String title;
  final String? fileName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE0E3EA)),
        ),
        child: Row(
          children: [
            const Icon(Icons.upload_file_outlined, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    fileName ?? 'Tap to upload document',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: fileName == null
                          ? AppColors.textSecondary
                          : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(Icons.chevron_right, color: Colors.grey.shade500),
          ],
        ),
      ),
    );
  }
}
