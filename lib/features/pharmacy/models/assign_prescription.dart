class AssignedPrescription {
  final String id;
  final String rxCode;
  final String patientName;
  final String patientPhone;
  final String pharmacyStatus;
  final String availability;
  final bool isVerified;
  final DateTime? verifiedAt;
  final DateTime? completedAt;

  AssignedPrescription({
    required this.id,
    required this.rxCode,
    required this.patientName,
    required this.patientPhone,
    required this.pharmacyStatus,
    required this.availability,
    required this.isVerified,
    required this.verifiedAt,
    required this.completedAt,
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
      pharmacyStatus: json['pharmacy_status']?.toString() ?? 'assigned',
      availability: json['availability']?.toString() ?? 'pending',
      isVerified: json['is_verified'] == true,
      verifiedAt: tryParse(json['verified_at']?.toString()),
      completedAt: tryParse(json['completed_at']?.toString()),
    );
  }
}