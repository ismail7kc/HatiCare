class PatientResponse {
  final int count;
  // final String? next;
  // final String? previous;
  final Results results;

  PatientResponse({
    required this.count,
    // this.next,
    // this.previous,
    required this.results,
  });

  factory PatientResponse.fromJson(Map<String, dynamic> json) {
    return PatientResponse(
      count: json['count'],
      // next: json['next'],
      // previous: json['previous'],
      results: Results.fromJson(json['results']),
    );
  }
}

class Results {
  final bool success;
  final int count;
  final List<PatientData> data;

  Results({
    required this.success,
    required this.count,
    required this.data,
  });

  factory Results.fromJson(Map<String, dynamic> json) {
    return Results(
      success: json['success'],
      count: json['count'],
      data: List<PatientData>.from(
        (json['data'] as List).map((x) => PatientData.fromJson(x)),
      ),
    );
  }
}

class PatientData {
  final int id;
  final Patient patient;
  final String patientName;
  final String rawComplaint;
  final TriageData triageData;
  final String severity;
  final String status;
  final DateTime createdAt;

  PatientData({
    required this.id,
    required this.patient,
    required this.patientName,
    required this.rawComplaint,
    required this.triageData,
    required this.severity,
    required this.status,
    required this.createdAt,
  });

  factory PatientData.fromJson(Map<String, dynamic> json) {
    return PatientData(
      id: json['id'],
      patient: Patient.fromJson(json['patient']),
      patientName: json['patient_name'],
      rawComplaint: json['raw_complaint'],
      triageData: TriageData.fromJson(json['triage_data']),
      severity: json['severity'],
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

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
      id: json['id'],
      fullName: json['full_name'],
      phoneNumber: json['phone_number'],
      age: json['age'],
      gender: json['gender'],
      city: json['city'],
      state: json['state'] ?? '',
      country: json['country'] ?? '',
    );
  }
}

class TriageData {
  final String severity;
  final List<String> suggestedSpecializations;
  final String primarySpecializationName;

  TriageData({
    required this.severity,
    required this.suggestedSpecializations,
    required this.primarySpecializationName,
  });

  factory TriageData.fromJson(Map<String, dynamic> json) {
    return TriageData(
      severity: json['severity'],
      suggestedSpecializations:
          List<String>.from(json['suggested_specializations']),
      primarySpecializationName: json['primary_specialization_name'],
    );
  }
}
