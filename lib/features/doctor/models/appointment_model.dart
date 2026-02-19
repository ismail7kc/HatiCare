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

class TriageData {
  final String severity;
  final int priorityScore;
  final List<String> suggestedSpecializations;
  final String primarySpecializationName;

  TriageData({
    required this.severity,
    required this.priorityScore,
    required this.suggestedSpecializations,
    required this.primarySpecializationName,
  });

  factory TriageData.fromJson(Map<String, dynamic> json) {
    return TriageData(
      severity: json['severity'] ?? '',
      priorityScore: json['priority_score'] ?? 0,
      suggestedSpecializations:
          (json['suggested_specializations'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      primarySpecializationName: json['primary_specialization_name'] ?? '',
    );
  }
}

class AppointmentModel {
  final int id;
  final Patient patient;
  final String patientName;
  final String rawComplaint;
  final String severity;
  final String severityColor;
  final String status;
  final DateTime createdAt;
  final TriageData triageData;

  int serverRemainingSeconds;
  int remainingSeconds;
  double progress;

  DateTime lastUpdateTime;

  AppointmentModel({
    required this.id,
    required this.patient,
    required this.patientName,
    required this.rawComplaint,
    required this.severity,
    required this.severityColor,
    required this.status,
    required this.createdAt,
    required this.triageData,
    required this.serverRemainingSeconds,
  }) : remainingSeconds = serverRemainingSeconds,
       progress = serverRemainingSeconds / 30,
       lastUpdateTime = DateTime.now();

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    final int remainingFromServer = json['remaining_seconds'] ?? 30;

    return AppointmentModel(
      id: json['id'] ?? 0,
      patient: Patient.fromJson(json['patient'] ?? {}),
      patientName: json['patient_name'] ?? '',
      rawComplaint: json['raw_complaint'] ?? '',
      severity: json['severity'] ?? '',
      severityColor: json['severity_color'] ?? '',
      status: json['status'] ?? '',
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      triageData: TriageData.fromJson(json['triage_data'] ?? {}),
      serverRemainingSeconds: remainingFromServer,
    );
  }

  void resetFromServer(int newRemaining) {
    serverRemainingSeconds = newRemaining;
    remainingSeconds = newRemaining;
    progress = remainingSeconds / 30;
    lastUpdateTime = DateTime.now();
  }

  void tick() {
    if (remainingSeconds > 0) {
      remainingSeconds -= 1;
      progress = remainingSeconds / 30;
    }
  }
}
