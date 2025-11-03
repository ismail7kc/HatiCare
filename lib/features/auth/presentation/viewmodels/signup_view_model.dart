import 'package:flutter/material.dart';
import 'package:haticare/features/auth/domain/entities/signup_request.dart';
import 'package:haticare/features/auth/domain/entities/user_role.dart';
import 'package:haticare/features/auth/domain/exceptions/auth_exceptions.dart';
import 'package:haticare/features/auth/domain/repositories/auth_repository.dart';
import 'package:intl_phone_field/phone_number.dart';

class SignupViewModel extends ChangeNotifier {
  SignupViewModel(this._repository);

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
  String? errorMessage;
  String? successMessage;

  String? doctorLicenseDocumentPath;
  String? doctorLicenseDocumentName;

  String? pharmacyLicenseDocumentPath;
  String? pharmacyLicenseDocumentName;

  void selectRole(UserRole role) {
    if (selectedRole == role) return;
    selectedRole = role;
    errorMessage = null;
    successMessage = null;
    _doctorPhoneNumber = null;
    _businessPhoneNumber = null;
    formKey.currentState?.reset();
    notifyListeners();
  }

  bool get isDoctor => selectedRole == UserRole.doctor;
  bool get isPharmacy => selectedRole == UserRole.pharmacy;

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
    final raw = phone?.completeNumber ?? phoneNumberController.text;
    final trimmed = raw.trim();
    _doctorPhoneNumber = trimmed.isEmpty ? null : trimmed;
  }

  void updateBusinessPhone(PhoneNumber? phone) {
    final raw = phone?.completeNumber ?? businessPhoneController.text;
    final trimmed = raw.trim();
    _businessPhoneNumber = trimmed.isEmpty ? null : trimmed;
  }

  String? validateDoctorPhone(String? value) {
    if (!isDoctor) return null;
    final phone = _doctorPhoneNumber ?? value;
    return _requiredValidator(phone, 'phone number');
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

  String? validateBusinessPhone(String? value) {
    if (!isPharmacy) return null;
    final phone = _businessPhoneNumber ?? value;
    return _requiredValidator(phone, 'business phone number');
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
    if (!formKey.currentState!.validate()) {
      return;
    }

    if (isDoctor && doctorLicenseDocumentPath == null) {
      errorMessage = 'Please upload your license document';
      notifyListeners();
      return;
    }

    if (isPharmacy && pharmacyLicenseDocumentPath == null) {
      errorMessage = 'Please upload your pharmacy license document';
      notifyListeners();
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
        companyName: isDoctor ? companyNameController.text.trim() : null,
        companyAddress: isDoctor ? companyAddressController.text.trim() : null,
        licenseNumber: isDoctor ? licenseNumberController.text.trim() : null,
        licenseType: isDoctor ? licenseTypeController.text.trim() : null,
        yearsOfExperience: isDoctor ? yearsOfExperienceController.text.trim() : null,
        specialization: isDoctor ? specializationController.text.trim() : null,
        licenseIssuingAuthority:
            isDoctor ? licenseIssuingAuthorityController.text.trim() : null,
        licenseDocumentPath: isDoctor ? doctorLicenseDocumentPath : null,
        pharmacyName: isPharmacy ? pharmacyNameController.text.trim() : null,
        ownerName: isPharmacy ? ownerNameController.text.trim() : null,
        businessPhone: isPharmacy
            ? (_businessPhoneNumber ?? businessPhoneController.text.trim())
            : null,
        addressLine1: isPharmacy ? addressLine1Controller.text.trim() : null,
        addressLine2: isPharmacy ? addressLine2Controller.text.trim() : null,
        city: isPharmacy ? cityController.text.trim() : null,
        state: isPharmacy ? stateController.text.trim() : null,
        postalCode: isPharmacy ? postalCodeController.text.trim() : null,
        country: isPharmacy ? countryController.text.trim() : null,
        pharmacyLicenseNumber:
            isPharmacy ? pharmacyLicenseNumberController.text.trim() : null,
        taxIdentificationNumber:
            isPharmacy ? taxIdentificationNumberController.text.trim() : null,
        pharmacyLicenseDocumentPath:
            isPharmacy ? pharmacyLicenseDocumentPath : null,
      );
      final response = await _repository.signup(request: request);
      successMessage = _successMessageFromResponse(response) ??
          'Signup submitted successfully.';
    } catch (error) {
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
