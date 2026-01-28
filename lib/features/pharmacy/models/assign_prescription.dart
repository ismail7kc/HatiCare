class AssignedPrescription {
  final String id;
  final String rxCode;
  final String patientName;
  final String patientPhone;
  final String patientCity;
  final String doctor;
  final String pharmacyStatus;
  final String availability;
  final bool isVerified;
  final DateTime? verifiedAt;
  final DateTime? completedAt;
  final List<Medication> medications;

  AssignedPrescription({
    required this.id,
    required this.rxCode,
    required this.patientName,
    required this.patientPhone,
    required this.patientCity,
    required this.doctor,
    required this.pharmacyStatus,
    required this.availability,
    required this.isVerified,
    required this.verifiedAt,
    required this.completedAt,
    required this.medications,
  });

  factory AssignedPrescription.fromJson(Map<String, dynamic> json) {
    DateTime? tryParse(String? value) {
      if (value == null || value.isEmpty) return null;
      return DateTime.tryParse(value);
    }

    return AssignedPrescription(
      id: json['prescription_id']?.toString() ?? '',
      rxCode: json['rex_code']?.toString() ?? '',
      patientName: json['patient_name']?.toString() ?? 'Unknown Patient',
      patientPhone: json['patient_phone']?.toString() ?? '-',
      patientCity: json['patient_city']?.toString() ?? '',
      doctor: json['doctor']?.toString() ?? '',
      pharmacyStatus: json['pharmacy_status']?.toString() ?? 'assigned',
      availability: json['availability']?.toString() ?? 'pending',
      isVerified: json['is_verified'] == true,
      verifiedAt: tryParse(json['verified_at']?.toString()),
      completedAt: tryParse(json['completed_at']?.toString()),
      medications: (json['medications'] as List<dynamic>? ?? [])
          .map((e) => Medication.fromJson(e))
          .toList(),
    );
  }
}


class Medication {
  final String dose;
  final String name;
  final String notes;
  final String duration;
  final int quantity;
  final String frequency;

  Medication({
    required this.dose,
    required this.name,
    required this.notes,
    required this.duration,
    required this.quantity,
    required this.frequency,
  });

  factory Medication.fromJson(Map<String, dynamic> json) {
    return Medication(
      dose: json['dose']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      notes: json['notes']?.toString() ?? '',
      duration: json['duration']?.toString() ?? '',
      quantity: json['quantity'] ?? 0,
      frequency: json['frequency']?.toString() ?? '',
    );
  }
}
