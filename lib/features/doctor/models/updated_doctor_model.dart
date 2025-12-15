class Doctor {
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? phoneNumber;
  final String? licenseNumber;
  final String? licenseType;
  final String? specialization;
  final int? yearsOfExperience;
  final String? licenseIssuingAuthority;
  final String? gender;
  final DateTime? dob;
  final String? profilePicture;

  Doctor({
    this.firstName,
    this.lastName,
    this.email,
    this.phoneNumber,
    this.licenseNumber,
    this.licenseType,
    this.specialization,
    this.yearsOfExperience,
    this.licenseIssuingAuthority,
    this.gender,
    this.dob,
    this.profilePicture,
  });

  factory Doctor.fromJson(Map<String, dynamic> json) {
    return Doctor(
      firstName: json['first_name'],
      lastName: json['last_name'],
      email: json['user_email'],
      phoneNumber: json['phone_number'],
      licenseNumber: json['license_number'],
      licenseType: json['license_type'],
      specialization: json['specialization'],
      yearsOfExperience: json['years_of_experience'] is int ? json['years_of_experience'] : int.tryParse(json['years_of_experience']?.toString() ?? '0'),
      licenseIssuingAuthority: json['license_issuing_authority'],
      gender: json['gender'],
      dob: json['date_of_birth'] != null ? DateTime.tryParse(json['date_of_birth']) : null,
      profilePicture: json['profile_picture'],
    );
  }
}

