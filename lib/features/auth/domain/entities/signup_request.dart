import 'package:haticare/features/auth/domain/entities/user_role.dart';

class SignupRequest {
  const SignupRequest({
    required this.role,
    required this.email,
    required this.password,
    this.confirmPassword,
    this.firstName,
    this.lastName,
    this.phoneNumber,
    this.gender,
    this.dateOfBirth,
    this.companyName,
    this.companyAddress,
    this.licenseNumber,
    this.licenseType,
    this.yearsOfExperience,
    this.specialization,
    this.licenseIssuingAuthority,
    this.licenseDocumentPath,
    this.pharmacyName,
    this.ownerName,
    this.businessEmail,
    this.businessPhone,
    this.addressLine1,
    this.addressLine2,
    this.city,
    this.state,
    this.postalCode,
    this.country,
    this.pharmacyLicenseNumber,
    this.taxIdentificationNumber,
    this.pharmacyLicenseDocumentPath,
  });

  final UserRole role;
  final String email;
  final String password;
  final String? confirmPassword;
  final String? firstName;
  final String? lastName;

  // Doctor specific
  final String? phoneNumber;
  final String? gender;
  final String? dateOfBirth;
  final String? companyName;
  final String? companyAddress;
  final String? licenseNumber;
  final String? licenseType;
  final String? yearsOfExperience;
  final String? specialization;
  final String? licenseIssuingAuthority;
  final String? licenseDocumentPath;

  // Pharmacy specific
  final String? pharmacyName;
  final String? ownerName;
  final String? businessEmail;
  final String? businessPhone;
  final String? addressLine1;
  final String? addressLine2;
  final String? city;
  final String? state;
  final String? postalCode;
  final String? country;
  final String? pharmacyLicenseNumber;
  final String? pharmacyLicenseDocumentPath;
  final String? taxIdentificationNumber;

  Map<String, dynamic> toJson() {
    switch (role) {
      case UserRole.doctor:
        return _clean({
          'email': email,
          'password': password,
          'confirm_password': confirmPassword,
          'user_type': 'doctor',
          'phone_number': phoneNumber,
          'first_name': firstName,
          'last_name': lastName,
          'gender': _normalizedGender,
          'date_of_birth': dateOfBirth,
        });
      case UserRole.pharmacy:
        return _clean({
          'email': email,
          'password': password,
          'confirm_password': confirmPassword,
          'user_type': 'pharmacy',
          'phone_number': businessPhone,
          'contact_person': ownerName,
        });
    }
  }

  Map<String, dynamic> _clean(Map<String, dynamic> map) {
    map.removeWhere(
      (key, value) =>
          value == null || (value is String && value.trim().isEmpty),
    );
    return map;
  }

  String? get _normalizedGender {
    if (gender == null || gender!.isEmpty) return null;
    final value = gender!.trim().toUpperCase();
    switch (value) {
      case 'MALE':
      case 'M':
        return 'M';
      case 'FEMALE':
      case 'F':
        return 'F';
      case 'OTHER':
      case 'O':
        return 'O';
      default:
        return value.length == 1 ? value : null;
    }
  }
}
