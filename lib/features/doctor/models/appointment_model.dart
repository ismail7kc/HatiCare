class Patient {
  final int id;
  final String fullName;
  final String phoneNumber;
  final int age;
  final String gender;
  final String city;
  final String state;
  final String country;

  Patient({
    required this.id,
    required this.fullName,
    required this.phoneNumber,
    required this.age,
    required this.gender,
    required this.city,
    required this.state,
    required this.country,
  });

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id: json['id'] ?? 0,
      fullName: json['full_name'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      age: json['age'] ?? 0,
      gender: json['gender'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      country: json['country'] ?? '',
    );
  }
}

class AppointmentModel {
  final int? id;
  final Patient? patient;
  final String? patientName;
  final String? rawComplaint;
  final String? severity;
  final String? status;
  final DateTime? createdAt;
  final String? primarySpecialization;

  AppointmentModel({
    this.id,
    this.patient,
    this.patientName,
    this.rawComplaint,
    this.severity,
    this.status,
    this.createdAt,
    this.primarySpecialization,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    return AppointmentModel(
      id: json['id'] ?? 0,
      patient: json['patient'] != null ? Patient.fromJson(json['patient']) : null,
      patientName: json['patient_name'] ?? '',
      rawComplaint: json['raw_complaint'] ?? '',
      severity: json['severity'] ?? '',
      status: json['status'] ?? '',
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      primarySpecialization:
          json['triage_data']?['primary_specialization_name'] ?? '',
    );
  }
}
