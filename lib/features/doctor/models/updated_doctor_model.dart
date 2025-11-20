
class Doctor {
  final String firstName;
  final String lastName;
  final String email;
  final String phoneNumber;
  final String licenseNumber;
  final String licenseType;
  final String specialization;
  final int yearsOfExperience;
  final String licenseIssuingAuthority;
  final String gender;
  final DateTime? dob;

  Doctor({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
    required this.licenseNumber,
    required this.licenseType,
    required this.specialization,
    required this.yearsOfExperience,
    required this.licenseIssuingAuthority,
    required this.gender,
    this.dob,
  });

  factory Doctor.fromJson(Map<String, dynamic> json) {
    return Doctor(
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      email: json['user_email'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      licenseNumber: json['license_number'] ?? '',
      licenseType: json['license_type'] ?? '',
      specialization: json['specialization'] ?? '',
      yearsOfExperience: json['years_of_experience'] is int
          ? json['years_of_experience']
          : int.tryParse(json['years_of_experience']?.toString() ?? '0') ?? 0,
      licenseIssuingAuthority: json['license_issuing_authority'] ?? '',
      gender: json['gender'] ?? '',
      dob: json['date_of_birth'] != null
          ? DateTime.tryParse(json['date_of_birth'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'first_name': firstName,
      'last_name': lastName,
      'user_email': email,
      'phone_number': phoneNumber,
      'license_number': licenseNumber,
      'license_type': licenseType,
      'specialization': specialization,
      'years_of_experience': yearsOfExperience,
      'license_issuing_authority': licenseIssuingAuthority,
      'gender': gender,
      'date_of_birth': dob?.toIso8601String(),
    };
  }
}
