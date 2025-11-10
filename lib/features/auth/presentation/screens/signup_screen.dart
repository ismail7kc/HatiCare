import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:haticare/core/theme/app_colors.dart';
import 'package:haticare/core/widgets/app_primary_button.dart';
import 'package:haticare/core/widgets/app_text_field.dart';
import 'package:haticare/features/auth/domain/entities/user_role.dart';
import 'package:haticare/features/auth/domain/repositories/auth_repository.dart';
import 'package:haticare/features/auth/presentation/screens/unified_otp_verification_screen.dart';
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
  late final List<Widget> _tabChildren;

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

    _tabChildren = [
      _DoctorSection(key: const ValueKey('doctor')),
      _PharmacySection(key: const ValueKey('pharmacy')),
    ];
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
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Selector<SignupViewModel, _SignupState>(
      selector: (_, viewModel) => _SignupState(
        shouldNavigateToOtp: viewModel.shouldNavigateToOtp,
        isDoctor: viewModel.isDoctor,
        errorMessage: viewModel.errorMessage,
        successMessage: viewModel.successMessage,
        isSubmitting: viewModel.isSubmitting,
        autovalidate: viewModel.autovalidate,
      ),
      builder: (context, state, _) {
        final viewModel = context.read<SignupViewModel>();

        if (state.shouldNavigateToOtp) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              final signupRequest = state.isDoctor
                  ? viewModel.pendingDoctorSignupRequest
                  : viewModel.pendingPharmacySignupRequest;

              final email = state.isDoctor
                  ? viewModel.doctorEmailController.text.trim()
                  : viewModel.pharmacyEmailController.text.trim();

              if (signupRequest != null) {
                viewModel.markOtpNavigationHandled();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => UnifiedOtpVerificationScreen(
                      email: email,
                      signupRequest: signupRequest,
                    ),
                  ),
                ).then((_) {
                  viewModel.clearPendingRequest();
                });
              } else {
                viewModel.markOtpNavigationHandled();
              }
            }
          });
        }

        final targetIndex = state.isDoctor ? 0 : 1;
        if (_tabController.index != targetIndex &&
            !_tabController.indexIsChanging) {
          _tabController.index = targetIndex;
        }

        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 32,
                  ),
                  child: Form(
                    key: viewModel.formKey,
                    autovalidateMode: state.autovalidate
                        ? AutovalidateMode.onUserInteraction
                        : AutovalidateMode.disabled,
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
                            unselectedLabelStyle: textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w500),
                            dividerColor: Colors.transparent,
                            onTap: (index) {
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
                            physics: const ClampingScrollPhysics(),
                            children: _tabChildren,
                          ),
                        ),
                        if (state.errorMessage != null) ...[
                          const SizedBox(height: 16),
                          Text(
                            state.errorMessage!,
                            style: textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        if (state.successMessage != null) ...[
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
                                    state.successMessage!,
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
      },
    );
  }
}

class _SignupState {
  final bool shouldNavigateToOtp;
  final bool isDoctor;
  final String? errorMessage;
  final String? successMessage;
  final bool isSubmitting;
  final bool autovalidate;

  _SignupState({
    required this.shouldNavigateToOtp,
    required this.isDoctor,
    required this.errorMessage,
    required this.successMessage,
    required this.isSubmitting,
    required this.autovalidate,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _SignupState &&
          runtimeType == other.runtimeType &&
          shouldNavigateToOtp == other.shouldNavigateToOtp &&
          isDoctor == other.isDoctor &&
          errorMessage == other.errorMessage &&
          successMessage == other.successMessage &&
          isSubmitting == other.isSubmitting &&
          autovalidate == other.autovalidate;

  @override
  int get hashCode =>
      shouldNavigateToOtp.hashCode ^
      isDoctor.hashCode ^
      errorMessage.hashCode ^
      successMessage.hashCode ^
      isSubmitting.hashCode ^
      autovalidate.hashCode;
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
      borderSide: BorderSide(
        color: Theme.of(context).colorScheme.error,
        width: 1.4,
      ),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    counterText: '',
  );
}

class _DoctorSection extends StatelessWidget {
  const _DoctorSection({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.read<SignupViewModel>();
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
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
          const SizedBox(height: 4),
          _LabeledField(
            label: 'Phone Number',
            child: IntlPhoneField(
              controller: viewModel.phoneNumberController,
              initialCountryCode: 'US',
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              dropdownIcon: const Icon(
                Icons.arrow_drop_down,
                color: AppColors.primary,
              ),
              showCountryFlag: true,
              showDropdownIcon: true,
              dropdownIconPosition: IconPosition.trailing,
              flagsButtonPadding: const EdgeInsets.only(left: 12),
              dropdownTextStyle: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary),
              style: Theme.of(context).textTheme.bodyMedium,
              decoration: _phoneFieldDecoration(context, hint: '1234567890'),
              validator: viewModel.validateDoctorPhone,
              onChanged: viewModel.updateDoctorPhone,
              onCountryChanged: (country) {
                viewModel.updateDoctorCountryCode(country.dialCode);
              },
              onSaved: viewModel.updateDoctorPhone,
            ),
          ),
          const SizedBox(height: 4),
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
          const SizedBox(height: 4),
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
          const SizedBox(height: 4),
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
          const SizedBox(height: 10),
          Selector<SignupViewModel, bool>(
            selector: (_, vm) => vm.isSubmitting,
            builder: (context, isSubmitting, _) {
              final vm = context.read<SignupViewModel>();
              return AppPrimaryButton(
                label: 'Create Account',
                onPressed: isSubmitting ? null : vm.submit,
                isLoading: isSubmitting,
              );
            },
          ),
          const SizedBox(height: 6),
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
      ),
    );
  }
}

class _PharmacySection extends StatelessWidget {
  const _PharmacySection({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.read<SignupViewModel>();
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _LabeledField(
            label: 'Contact Person',
            child: AppTextField(
              controller: viewModel.ownerNameController,
              label: 'Contact Person',
              hint: 'Dr. Ali Khan',
              textCapitalization: TextCapitalization.words,
              prefixIcon: const Icon(Icons.person_outline),
              validator: viewModel.validateOwnerName,
            ),
          ),
          const SizedBox(height: 4),
          _LabeledField(
            label: 'Phone Number',
            child: IntlPhoneField(
              controller: viewModel.businessPhoneController,
              initialCountryCode: 'US',
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              dropdownIcon: const Icon(
                Icons.arrow_drop_down,
                color: AppColors.primary,
              ),
              showCountryFlag: true,
              showDropdownIcon: true,
              dropdownIconPosition: IconPosition.trailing,
              flagsButtonPadding: const EdgeInsets.only(left: 12),
              dropdownTextStyle: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary),
              style: Theme.of(context).textTheme.bodyMedium,
              decoration: _phoneFieldDecoration(context, hint: '1234567890'),
              validator: viewModel.validateBusinessPhone,
              onChanged: viewModel.updateBusinessPhone,
              onCountryChanged: (country) {
                viewModel.updateBusinessCountryCode(country.dialCode);
              },
              onSaved: viewModel.updateBusinessPhone,
            ),
          ),
          const SizedBox(height: 4),
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
          const SizedBox(height: 4),
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
          const SizedBox(height: 4),
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
          const SizedBox(height: 10),
          Selector<SignupViewModel, bool>(
            selector: (_, vm) => vm.isSubmitting,
            builder: (context, isSubmitting, _) {
              final vm = context.read<SignupViewModel>();
              return AppPrimaryButton(
                label: 'Create Account',
                onPressed: isSubmitting ? null : vm.submit,
                isLoading: isSubmitting,
              );
            },
          ),
          const SizedBox(height: 6),
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
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.label,
    required this.child,
    this.spacing = 2,
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

class _DatePickerField extends StatelessWidget {
  const _DatePickerField({required this.controller, this.validator});

  final TextEditingController controller;
  final String? Function(String?)? validator;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      // Format date as YYYY-MM-DD
      final formattedDate =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      controller.text = formattedDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      decoration: InputDecoration(
        filled: true,
        fillColor: AppColors.surface,
        hintText: 'YYYY-MM-DD',
        hintStyle: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        prefixIcon: const Icon(
          Icons.calendar_month_outlined,
          color: AppColors.primary,
        ),
        suffixIcon: const Icon(Icons.arrow_drop_down, color: AppColors.primary),
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
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.error,
            width: 1.4,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      style: Theme.of(context).textTheme.bodyMedium,
      validator: validator,
      onTap: () => _selectDate(context),
    );
  }
}

class _GenderDropdown extends StatelessWidget {
  const _GenderDropdown({
    required this.value,
    required this.onChanged,
    this.validator,
  });

  final String? value;
  final ValueChanged<String?> onChanged;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      decoration: InputDecoration(
        filled: true,
        fillColor: AppColors.surface,
        prefixIcon: const Icon(
          Icons.person_2_outlined,
          color: AppColors.primary,
        ),
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
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.error,
            width: 1.4,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      hint: Text(
        'Select Gender',
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
      ),
      icon: const Icon(Icons.arrow_drop_down, color: AppColors.primary),
      items: const [
        DropdownMenuItem(value: 'Male', child: Text('Male')),
        DropdownMenuItem(value: 'Female', child: Text('Female')),
        DropdownMenuItem(value: 'Other', child: Text('Other')),
      ],
      onChanged: onChanged,
      validator: validator,
    );
  }
}
