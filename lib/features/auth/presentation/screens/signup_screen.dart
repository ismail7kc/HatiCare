import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:haticare/core/theme/app_colors.dart';
import 'package:haticare/core/widgets/app_dropdown_field.dart';
import 'package:haticare/core/widgets/app_primary_button.dart';
import 'package:haticare/core/widgets/app_text_field.dart';
import 'package:haticare/features/auth/domain/entities/user_role.dart';
import 'package:haticare/features/auth/domain/repositories/auth_repository.dart';
import 'package:haticare/features/auth/presentation/screens/unified_otp_verification_screen.dart';
import 'package:haticare/features/auth/presentation/viewmodels/signup_view_model.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/phone_number.dart';
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

class _SignupViewState extends State<_SignupView> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
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
        isLaboratory: viewModel.isLaboratory,
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
                  : (state.isLaboratory
                      ? viewModel.pendingLaboratorySignupRequest
                      : viewModel.pendingPharmacySignupRequest);

              final email = state.isDoctor
                  ? viewModel.doctorEmailController.text.trim()
                  : (state.isLaboratory
                      ? viewModel.laboratoryEmailController.text.trim()
                      : viewModel.pharmacyEmailController.text.trim());

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

        // Show error as toast
        if (state.errorMessage != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.white),
                      const SizedBox(width: 12),
                      Expanded(child: Text(state.errorMessage!)),
                    ],
                  ),
                  duration: const Duration(seconds: 4),
                  behavior: SnackBarBehavior.floating,
                  margin: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
                  backgroundColor: Colors.red[700],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 6,
                ),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 32,
                  ),
                  child: Form(
                    key: viewModel.formKey,
                    autovalidateMode: state.autovalidate
                        ? AutovalidateMode.onUnfocus
                        : AutovalidateMode.disabled,
                    child: SingleChildScrollView(
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
                          Selector<SignupViewModel, UserRole>(
                            selector: (_, vm) => vm.selectedRole,
                            builder: (context, selectedRole, _) {
                              return AppDropdownField<UserRole>(
                                label: 'Select Role',
                                items: const [
                                  DropdownMenuItem(value: UserRole.doctor, child: Text('Doctor')),
                                  DropdownMenuItem(value: UserRole.pharmacy, child: Text('Pharmacy')),
                                  DropdownMenuItem(value: UserRole.laboratory, child: Text('Laboratory')),
                                ],
                                value: selectedRole,
                                onChanged: (role) {
                                  if (role != null && viewModel.selectedRole != role) {
                                    viewModel.selectRole(role);
                                  }
                                },
                                validator: (value) => value == null ? 'Please select a role' : null,
                                hint: 'Select role',
                                prefixIcon: const Icon(Icons.business_outlined, color: AppColors.primary),
                              );
                            },
                          ),
                          const SizedBox(height: 24),
                          Selector<SignupViewModel, UserRole>(
                            selector: (_, vm) => vm.selectedRole,
                            builder: (context, selectedRole, _) {
                              return SingleChildScrollView(
                                physics: const ClampingScrollPhysics(),
                                padding: const EdgeInsets.only(bottom: 24),
                                child: selectedRole == UserRole.doctor
                                    ? const _DoctorSection()
                                    : (selectedRole == UserRole.pharmacy
                                        ? const _PharmacySection()
                                        : const _LaboratorySection()),
                              );
                            },
                          ),
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
          ),
        );
      },
    );
  }
}

class _SignupState {
  final bool shouldNavigateToOtp;
  final bool isDoctor;
  final bool isLaboratory;
  final String? errorMessage;
  final String? successMessage;
  final bool isSubmitting;
  final bool autovalidate;

  _SignupState({
    required this.shouldNavigateToOtp,
    required this.isDoctor,
    required this.isLaboratory,
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
          isLaboratory == other.isLaboratory &&
          errorMessage == other.errorMessage &&
          successMessage == other.successMessage &&
          isSubmitting == other.isSubmitting &&
          autovalidate == other.autovalidate;

  @override
  int get hashCode =>
      shouldNavigateToOtp.hashCode ^
      isDoctor.hashCode ^
      isLaboratory.hashCode ^
      errorMessage.hashCode ^
      successMessage.hashCode ^
      isSubmitting.hashCode ^
      autovalidate.hashCode;
}

InputDecoration _phoneFieldDecoration(BuildContext context, {String? hint, bool hasError = false}) {
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: BorderSide(color: hasError ? Theme.of(context).colorScheme.error : Colors.grey.shade300),
  );

  final focusedBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: BorderSide(
      color: hasError ? Theme.of(context).colorScheme.error : AppColors.primary,
      width: 1.4,
    ),
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
    errorStyle: const TextStyle(height: 0),
  );
}

class _PhoneFieldWrapper extends StatefulWidget {
  const _PhoneFieldWrapper({
    required this.label,
    required this.controller,
    required this.validator,
    required this.onChanged,
    required this.onCountryChanged,
    required this.initialCountryCode,
    this.hint = '1234567890',
  });

  final String label;
  final TextEditingController controller;
  final String? Function(PhoneNumber?)? validator;
  final Function(PhoneNumber?)? onChanged;
  final Function(dynamic)? onCountryChanged;
  final String initialCountryCode;
  final String hint;

  @override
  State<_PhoneFieldWrapper> createState() => _PhoneFieldWrapperState();
}

class _PhoneFieldWrapperState extends State<_PhoneFieldWrapper> {
  String? _errorText;
  PhoneNumber? _phoneNumber;

  @override
  void initState() {
    super.initState();
    // Don't add listener - validation happens through FormField
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _validatePhone() {
    // Only validate when explicitly called, not on every change
    // This prevents duplicate error messages
    final error = widget.validator?.call(_phoneNumber);
    if (mounted) {
      setState(() {
        _errorText = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.label,
          style: textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF6C7278),
          ),
        ),
        const SizedBox(height: 2),
        FormField<PhoneNumber>(
          initialValue: _phoneNumber,
          validator: (value) {
            final error = widget.validator?.call(value);
            if (mounted) {
              setState(() {
                _errorText = error;
              });
            }
            return error;
          },
          builder: (FormFieldState<PhoneNumber> state) {
            return IntlPhoneField(
              controller: widget.controller,
              initialCountryCode: widget.initialCountryCode,
              dropdownIcon: const Icon(
                Icons.arrow_drop_down,
                color: AppColors.primary,
              ),
              showCountryFlag: true,
              showDropdownIcon: true,
              dropdownIconPosition: IconPosition.trailing,
              flagsButtonPadding: const EdgeInsets.only(left: 12),
              dropdownTextStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary),
              style: Theme.of(context).textTheme.bodyMedium,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: _phoneFieldDecoration(context, hint: widget.hint, hasError: _errorText != null),
              onChanged: (phone) {
                _phoneNumber = phone;
                widget.onChanged?.call(phone);
                // Clear error immediately when user types
                if (_errorText != null && mounted) {
                  setState(() {
                    _errorText = null;
                  });
                }
                state.didChange(phone);
              },
              onCountryChanged: widget.onCountryChanged,
              onSaved: widget.onChanged,
            );
          },
        ),
        if (_errorText != null) ...[
          const SizedBox(height: 4),
          Text(
            _errorText!,
            style: textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.error,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
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
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
                    ],
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
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          _PhoneFieldWrapper(
            label: 'Phone Number',
            controller: viewModel.phoneNumberController,
            validator: viewModel.validateDoctorPhone,
            onChanged: viewModel.updateDoctorPhone,
            onCountryChanged: (country) {
              if (country != null && country is Map && country.containsKey('dial_code')) {
                viewModel.updateDoctorCountryCode(country['dial_code'] as String);
              }
            },
            initialCountryCode: 'US',
            hint: '1234567890',
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Selector<SignupViewModel, String>(
                  selector: (_, vm) => vm.genderController.text,
                  builder: (context, genderValue, _) {
                    return AppDropdownField<String>(
                      label: 'Gender',
                      items: const [
                        DropdownMenuItem(value: 'Male', child: Text('Male')),
                        DropdownMenuItem(value: 'Female', child: Text('Female')),
                        DropdownMenuItem(value: 'Other', child: Text('Other')),
                      ],
                      value: genderValue.isEmpty ? null : genderValue,
                      onChanged: viewModel.setDoctorGender,
                      validator: viewModel.validateDoctorGender,
                      hint: 'Gender',
                      prefixIcon: const Icon(Icons.person_2_outlined, color: AppColors.primary),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _LabeledField(
                  label: 'Date of Birth',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _DatePickerField(
                        controller: viewModel.dateOfBirthController,
                        validator: viewModel.validateDoctorDob,
                      ),
                      const SizedBox(height: 4),
                    ],
                  ),
                ),
              ),
            ],
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
              hint: 'Enter Contact Person Name',
              textCapitalization: TextCapitalization.words,
              prefixIcon: const Icon(Icons.person_outline),
              validator: viewModel.validateOwnerName,
            ),
          ),
          const SizedBox(height: 4),
          _PhoneFieldWrapper(
            label: 'Phone Number',
            controller: viewModel.businessPhoneController,
            validator: viewModel.validateBusinessPhone,
            onChanged: viewModel.updateBusinessPhone,
            onCountryChanged: (country) {
              if (country != null && country is Map && country.containsKey('dial_code')) {
                viewModel.updateBusinessCountryCode(country['dial_code'] as String);
              }
            },
            initialCountryCode: 'US',
            hint: '1234567890',
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

class _LaboratorySection extends StatelessWidget {
  const _LaboratorySection({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.read<SignupViewModel>();
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _LabeledField(
          label: 'Contact Person',
          child: AppTextField(
            controller: viewModel.laboratoryContactPersonController,
            label: 'Contact Person',
            hint: 'Enter Contact Person Name',
            textCapitalization: TextCapitalization.words,
            prefixIcon: const Icon(Icons.person_outline),
            validator: viewModel.validateLaboratoryContactPerson,
          ),
        ),
        const SizedBox(height: 4),
        _PhoneFieldWrapper(
          label: 'Phone Number',
          controller: viewModel.laboratoryPhoneController,
          validator: viewModel.validateLaboratoryPhone,
          onChanged: viewModel.updateLaboratoryPhone,
          onCountryChanged: (country) {
            if (country != null && country is Map && country.containsKey('dial_code')) {
              viewModel.updateLaboratoryCountryCode(country['dial_code'] as String);
            }
          },
          initialCountryCode: 'US',
          hint: '1234567890',
        ),
        const SizedBox(height: 4),
        _LabeledField(
          label: 'Email',
          child: AppTextField(
            controller: viewModel.laboratoryEmailController,
            label: 'Email',
            hint: 'laboratory@example.com',
            keyboardType: TextInputType.emailAddress,
            prefixIcon: const Icon(Icons.email_outlined),
            validator: viewModel.validateLaboratoryEmail,
          ),
        ),
        const SizedBox(height: 4),
        _LabeledField(
          label: 'Password',
          child: AppTextField(
            controller: viewModel.laboratoryPasswordController,
            label: 'Password',
            hint: 'Enter Your Password',
            prefixIcon: const Icon(Icons.lock_outline),
            obscureText: true,
            enableObscureToggle: true,
            validator: viewModel.validateLaboratoryPassword,
          ),
        ),
        const SizedBox(height: 4),
        _LabeledField(
          label: 'Confirm Password',
          child: AppTextField(
            controller: viewModel.laboratoryConfirmPasswordController,
            label: 'Confirm Password',
            hint: 'Re-enter your password',
            prefixIcon: const Icon(Icons.lock_outline),
            obscureText: true,
            enableObscureToggle: true,
            validator: viewModel.validateLaboratoryConfirmPassword,
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
        errorStyle: const TextStyle(height: 0),
      ),
      style: Theme.of(context).textTheme.bodyMedium,
      validator: validator,
      onTap: () => _selectDate(context),
    );
  }
}
