import 'package:flutter/material.dart';
import 'package:haticare/features/auth/domain/entities/signup_request.dart';
import 'package:haticare/features/auth/domain/entities/user_role.dart';
import 'package:haticare/features/auth/domain/exceptions/auth_exceptions.dart';
import 'package:haticare/features/auth/domain/repositories/auth_repository.dart';
import 'package:intl_phone_field/phone_number.dart';

class SignupViewModel extends ChangeNotifier {
  SignupViewModel(this._repository) {
    _setupErrorClearingListeners();
  }

  final AuthRepository _repository;

  final formKey = GlobalKey<FormState>();
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final doctorEmailController = TextEditingController();
  final doctorPasswordController = TextEditingController();
  final doctorConfirmPasswordController = TextEditingController();
  final pharmacyEmailController = TextEditingController();
  final pharmacyPasswordController = TextEditingController();
  final pharmacyConfirmPasswordController = TextEditingController();
  final phoneNumberController = TextEditingController();
  String? _doctorPhoneNumber;
  PhoneNumber? _doctorPhoneMeta;
  String _doctorCountryCode = '+1';
  final genderController = TextEditingController();
  final dateOfBirthController = TextEditingController();
  final companyNameController = TextEditingController();
  final companyAddressController = TextEditingController();
  final licenseNumberController = TextEditingController();
  final licenseTypeController = TextEditingController();
  final yearsOfExperienceController = TextEditingController();
  final specializationController = TextEditingController();
  final licenseIssuingAuthorityController = TextEditingController();

  final pharmacyNameController = TextEditingController();
  final ownerNameController = TextEditingController();
  final businessPhoneController = TextEditingController();
  String? _businessPhoneNumber;
  PhoneNumber? _businessPhoneMeta;
  String _businessCountryCode = '+1';
  final addressLine1Controller = TextEditingController();
  final addressLine2Controller = TextEditingController();
  final cityController = TextEditingController();
  final stateController = TextEditingController();
  final postalCodeController = TextEditingController();
  final countryController = TextEditingController();
  final pharmacyLicenseNumberController = TextEditingController();
  final taxIdentificationNumberController = TextEditingController();

  UserRole selectedRole = UserRole.doctor;
  bool isSubmitting = false;
  bool autovalidate = true;
  String? errorMessage;
  String? successMessage;
  bool _otpReadyForNavigation = false;

  String? doctorLicenseDocumentPath;
  String? doctorLicenseDocumentName;

  String? pharmacyLicenseDocumentPath;
  String? pharmacyLicenseDocumentName;

  SignupRequest? _pendingDoctorSignupRequest;
  SignupRequest? _pendingPharmacySignupRequest;

  void selectRole(UserRole role) {
    if (selectedRole == role) return;
    selectedRole = role;
    errorMessage = null;
    successMessage = null;
    autovalidate = true;
    _otpReadyForNavigation = false;
    _doctorPhoneNumber = null;
    _doctorPhoneMeta = null;
    _businessPhoneNumber = null;
    _businessPhoneMeta = null;
    formKey.currentState?.reset();
    notifyListeners();
  }

  void _setupErrorClearingListeners() {
    // Doctor fields
    firstNameController.addListener(_clearErrorOnChange);
    lastNameController.addListener(_clearErrorOnChange);
    phoneNumberController.addListener(_clearErrorOnChange);
    genderController.addListener(_clearErrorOnChange);
    dateOfBirthController.addListener(_clearErrorOnChange);
    doctorEmailController.addListener(_clearErrorOnChange);
    doctorPasswordController.addListener(_clearErrorOnChange);
    doctorConfirmPasswordController.addListener(_clearErrorOnChange);

    // Pharmacy fields
    ownerNameController.addListener(_clearErrorOnChange);
    businessPhoneController.addListener(_clearErrorOnChange);
    pharmacyEmailController.addListener(_clearErrorOnChange);
    pharmacyPasswordController.addListener(_clearErrorOnChange);
    pharmacyConfirmPasswordController.addListener(_clearErrorOnChange);
  }

  void _clearErrorOnChange() {
    if (errorMessage != null) {
      errorMessage = null;
      notifyListeners();
    }
  }

  int? _expectedNationalLength(String? isoCode) {
    if (isoCode == null) return null;
    switch (isoCode.toUpperCase()) {
      case 'PK':
        return 10;
      case 'US':
      case 'CA':
        return 10;
      default:
        return null;
    }
  }

  String _normalizeCountryCodeString(String code) {
    final trimmed = code.trim();
    if (trimmed.isEmpty) return '';
    return trimmed.startsWith('+') ? trimmed : '+$trimmed';
  }

  String? _normalizePhoneNumber(PhoneNumber? phone) {
    if (phone == null) return null;
    final sanitizedCountryCode = phone.countryCode.replaceAll(RegExp(r'[^0-9]'), '');
    final sanitizedPhone = phone.number.replaceAll(RegExp(r'[^0-9]'), '');
    if (sanitizedPhone.isEmpty) return null;
    return sanitizedCountryCode.isEmpty
        ? sanitizedPhone
        : '+$sanitizedCountryCode$sanitizedPhone';
  }

  bool get isDoctor => selectedRole == UserRole.doctor;
  bool get isPharmacy => selectedRole == UserRole.pharmacy;
  bool get shouldNavigateToOtp => _otpReadyForNavigation;

  String? _requiredValidator(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter $fieldName';
    }
    return null;
  }

  String? validateFirstName(String? value) {
    if (!isDoctor) return null;
    return _requiredValidator(value, 'first name');
  }

  String? validateLastName(String? value) {
    if (!isDoctor) return null;
    return _requiredValidator(value, 'last name');
  }

  String? _validateEmailFormat(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    final emailRegex = RegExp(r'^\S+@\S+\.\S+$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? _validatePasswordStrength(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    return null;
  }

  String? validateDoctorEmail(String? value) {
    if (!isDoctor) return null;
    return _validateEmailFormat(value);
  }

  String? validateDoctorPassword(String? value) {
    if (!isDoctor) return null;
    return _validatePasswordStrength(value);
  }

  String? validateDoctorConfirmPassword(String? value) {
    if (!isDoctor) return null;
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != doctorPasswordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  String? validatePharmacyEmail(String? value) {
    if (!isPharmacy) return null;
    return _validateEmailFormat(value);
  }

  String? validatePharmacyPassword(String? value) {
    if (!isPharmacy) return null;
    return _validatePasswordStrength(value);
  }

  String? validatePharmacyConfirmPassword(String? value) {
    if (!isPharmacy) return null;
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != pharmacyPasswordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  void updateDoctorPhone(PhoneNumber? phone) {
    _doctorPhoneMeta = phone;
    if (phone != null) {
      _doctorCountryCode = phone.countryCode;
      _doctorPhoneNumber = _normalizePhoneNumber(phone);
    }
  }

  void updateDoctorCountryCode(String countryCode) {
    _doctorCountryCode = _normalizeCountryCodeString(countryCode);
  }

  void updateBusinessPhone(PhoneNumber? phone) {
    _businessPhoneMeta = phone;
    if (phone != null) {
      _businessCountryCode = phone.countryCode;
      _businessPhoneNumber = _normalizePhoneNumber(phone);
    }
  }

  void updateBusinessCountryCode(String countryCode) {
    _businessCountryCode = _normalizeCountryCodeString(countryCode);
  }

  String? validateDoctorPhone(PhoneNumber? phone) {
    if (!isDoctor) return null;
    final candidate = phone ?? _doctorPhoneMeta;
    if (candidate == null || candidate.number.trim().isEmpty) {
      return 'Enter phone number';
    }

    final digits = candidate.number.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) {
      return 'Enter phone number';
    }

    _doctorPhoneNumber = _normalizePhoneNumber(candidate);
    return null;
  }

  String? validateDoctorGender(String? value) {
    if (!isDoctor) return null;
    return _requiredValidator(value, 'gender');
  }

  void setDoctorGender(String? gender) {
    genderController.text = (gender ?? '').trim();
    notifyListeners();
  }

  String? validateDoctorDob(String? value) {
    if (!isDoctor) return null;
    return _requiredValidator(value, 'date of birth');
  }

  String? validateDoctorCompanyName(String? value) {
    if (!isDoctor) return null;
    return _requiredValidator(value, 'company name');
  }

  String? validateDoctorCompanyAddress(String? value) {
    if (!isDoctor) return null;
    return _requiredValidator(value, 'company address');
  }

  String? validateDoctorLicenseNumber(String? value) {
    if (!isDoctor) return null;
    return _requiredValidator(value, 'license number');
  }

  String? validateDoctorLicenseType(String? value) {
    if (!isDoctor) return null;
    return _requiredValidator(value, 'license type');
  }

  String? validateDoctorExperience(String? value) {
    if (!isDoctor) return null;
    final message = _requiredValidator(value, 'years of experience');
    if (message != null) return message;
    if (int.tryParse(value!) == null) {
      return 'Enter a valid number';
    }
    return null;
  }

  String? validateDoctorSpecialization(String? value) {
    if (!isDoctor) return null;
    return _requiredValidator(value, 'specialization');
  }

  String? validateDoctorIssuingAuthority(String? value) {
    if (!isDoctor) return null;
    return _requiredValidator(value, 'license issuing authority');
  }

  String? validatePharmacyName(String? value) {
    if (!isPharmacy) return null;
    return _requiredValidator(value, 'pharmacy name');
  }

  String? validateOwnerName(String? value) {
    if (!isPharmacy) return null;
    return _requiredValidator(value, 'owner / manager name');
  }

  String? validateBusinessPhone(PhoneNumber? phone) {
    if (!isPharmacy) return null;
    final candidate = phone ?? _businessPhoneMeta;
    if (candidate == null || candidate.number.trim().isEmpty) {
      return 'Enter business phone number';
    }

    final digits = candidate.number.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) {
      return 'Enter business phone number';
    }

    _businessPhoneNumber = _normalizePhoneNumber(candidate);
    return null;
  }

  String? validateAddressLine1(String? value) {
    if (!isPharmacy) return null;
    return _requiredValidator(value, 'address line 1');
  }

  String? validateCity(String? value) {
    if (!isPharmacy) return null;
    return _requiredValidator(value, 'city');
  }

  String? validateState(String? value) {
    if (!isPharmacy) return null;
    return _requiredValidator(value, 'state / province');
  }

  String? validatePostalCode(String? value) {
    if (!isPharmacy) return null;
    return _requiredValidator(value, 'ZIP / Postal Code');
  }

  String? validateCountry(String? value) {
    if (!isPharmacy) return null;
    return _requiredValidator(value, 'country');
  }

  String? validatePharmacyLicenseNumber(String? value) {
    if (!isPharmacy) return null;
    return _requiredValidator(value, 'pharmacy license number');
  }

  void setDoctorLicenseDocument({required String path, required String name}) {
    doctorLicenseDocumentPath = path;
    doctorLicenseDocumentName = name;
    errorMessage = null;
    notifyListeners();
  }

  void setPharmacyLicenseDocument({required String path, required String name}) {
    pharmacyLicenseDocumentPath = path;
    pharmacyLicenseDocumentName = name;
    errorMessage = null;
    notifyListeners();
  }

  Future<void> submit() async {
    _otpReadyForNavigation = false;
    
    if (!formKey.currentState!.validate()) {
      return;
    }

    isSubmitting = true;
    errorMessage = null;
    successMessage = null;
    notifyListeners();

    try {
      final request = SignupRequest(
        role: selectedRole,
        email: isDoctor
            ? doctorEmailController.text.trim()
            : pharmacyEmailController.text.trim(),
        password:
            isDoctor ? doctorPasswordController.text : pharmacyPasswordController.text,
        confirmPassword: isDoctor
            ? doctorConfirmPasswordController.text
            : pharmacyConfirmPasswordController.text,
        firstName: isDoctor ? firstNameController.text.trim() : null,
        lastName: isDoctor ? lastNameController.text.trim() : null,
        phoneNumber: isDoctor
            ? (_doctorPhoneNumber ?? phoneNumberController.text.trim())
            : null,
        gender: isDoctor ? genderController.text.trim() : null,
        dateOfBirth: isDoctor ? dateOfBirthController.text.trim() : null,
        ownerName: isPharmacy ? ownerNameController.text.trim() : null,
        businessPhone: isPharmacy
            ? (_businessPhoneNumber ?? businessPhoneController.text.trim())
            : null,
      );
      
      // For both doctor and pharmacy, generate OTP first
      Map<String, dynamic> otpResponse;
      if (isDoctor) {
        _pendingDoctorSignupRequest = request;
        otpResponse = await _repository.generateOtp(email: request.email);
      } else {
        // For pharmacy, also use OTP flow
        _pendingPharmacySignupRequest = request;
        otpResponse = await _repository.generateOtp(email: request.email);
      }

      successMessage =
          _successMessageFromResponse(otpResponse) ?? 'OTP sent successfully';
      _otpReadyForNavigation = true;
    } catch (error) {
      _otpReadyForNavigation = false;
      if (error is PasswordMismatchException) {
        errorMessage = 'Passwords do not match';
      } else if (error is AuthApiException) {
        errorMessage = error.message;
      } else {
        errorMessage = 'Signup failed. Please try again.';
      }
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }

  SignupRequest? get pendingDoctorSignupRequest => _pendingDoctorSignupRequest;
  SignupRequest? get pendingPharmacySignupRequest => _pendingPharmacySignupRequest;

  void clearPendingRequest() {
    _pendingDoctorSignupRequest = null;
    _pendingPharmacySignupRequest = null;
    _otpReadyForNavigation = false;
  }

  void markOtpNavigationHandled() {
    if (_otpReadyForNavigation) {
      _otpReadyForNavigation = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    doctorEmailController.dispose();
    doctorPasswordController.dispose();
    doctorConfirmPasswordController.dispose();
    pharmacyEmailController.dispose();
    pharmacyPasswordController.dispose();
    pharmacyConfirmPasswordController.dispose();
    phoneNumberController.dispose();
    genderController.dispose();
    dateOfBirthController.dispose();
    companyNameController.dispose();
    companyAddressController.dispose();
    licenseNumberController.dispose();
    licenseTypeController.dispose();
    yearsOfExperienceController.dispose();
    specializationController.dispose();
    licenseIssuingAuthorityController.dispose();
    pharmacyNameController.dispose();
    ownerNameController.dispose();
    businessPhoneController.dispose();
    addressLine1Controller.dispose();
    addressLine2Controller.dispose();
    cityController.dispose();
    stateController.dispose();
    postalCodeController.dispose();
    countryController.dispose();
    pharmacyLicenseNumberController.dispose();
    taxIdentificationNumberController.dispose();
    super.dispose();
  }

  String? _successMessageFromResponse(Map<String, dynamic> response) {
    if (response['message'] is String) {
      return response['message'] as String;
    }
    if (response['detail'] is String) {
      return response['detail'] as String;
    }
    if (response['status'] is String) {
      return response['status'] as String;
    }
    return null;
  }
}
