import 'package:flutter/material.dart';

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
  final String workflow;
  final String riskLevel;
  final int priorityScore;
  final List<String> suggestedSpecializations;
  final String primarySpecializationName;
  final Map<String, dynamic> scoreCard;

  TriageData({
    required this.workflow,
    required this.riskLevel,
    required this.priorityScore,
    required this.suggestedSpecializations,
    required this.primarySpecializationName,
    required this.scoreCard,
  });

  factory TriageData.fromJson(
    Map<String, dynamic> json, {
    String primarySpecializationName = '',
  }) {
    final Map<String, dynamic> scoreCard = Map<String, dynamic>.from(
      json['score_card'] ?? {},
    );

    int priorityScore = 0;

    if (scoreCard.isNotEmpty) {
      priorityScore = scoreCard.values.whereType<num>().fold<int>(
        0,
        (sum, value) => sum + value.toInt(),
      );
    }

    return TriageData(
      workflow: json['workflow']?.toString() ?? '',
      riskLevel:
          json['risk_level']?.toString() ?? json['severity']?.toString() ?? '',
      priorityScore: json['priority_score'] is num
          ? (json['priority_score'] as num).toInt()
          : priorityScore,
      suggestedSpecializations:
          (json['suggested_specializations'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      primarySpecializationName:
          json['primary_specialization_name']?.toString() ??
          primarySpecializationName,
      scoreCard: scoreCard,
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
  final List<String> reportedSymptoms;

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
    required this.reportedSymptoms,
  }) : remainingSeconds = serverRemainingSeconds,
       progress = serverRemainingSeconds / 30,
       lastUpdateTime = DateTime.now();

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    final int remainingFromServer = json['remaining_seconds'] is num
        ? (json['remaining_seconds'] as num).toInt()
        : 30;

    final Map<String, dynamic> triageJson = Map<String, dynamic>.from(
      json['triage_data'] ?? {},
    );

    return AppointmentModel(
      id: json['id'] is num ? (json['id'] as num).toInt() : 0,

      patient: Patient.fromJson(json['patient'] ?? {}),

      patientName: json['patient_name']?.toString() ?? '',

      rawComplaint: json['raw_complaint']?.toString() ?? '',

      severity:
          json['severity']?.toString() ??
          triageJson['risk_level']?.toString() ??
          '',

      severityColor: json['severity_color']?.toString() ?? '',

      status: json['status']?.toString() ?? '',

      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),

      triageData: TriageData.fromJson(
        triageJson,
        primarySpecializationName:
            json['primary_specialization_name']?.toString() ?? '',
      ),

      serverRemainingSeconds: remainingFromServer,
      reportedSymptoms: List<String>.from(json['reported_symptoms'] ?? []),
    );
  }

  String get primaryConcern {
    final tag = winningTag;

    if (tag.isEmpty) {
      return "General Consultation";
    }

    return tag;
  }

  String get riskLevelText {
    switch (triageData.riskLevel.toUpperCase()) {
      case 'RED':
        return 'Emergency';
      case 'ORANGE':
        return 'High Risk';
      case 'YELLOW':
        return 'Moderate Risk';
      case 'GREEN':
        return 'Low Risk';
      default:
        return triageData.riskLevel.isNotEmpty
            ? triageData.riskLevel
            : 'Not Available';
    }
  }

  String get cleanRawComplaint {
    String complaint = rawComplaint.trim();

    if (complaint.startsWith('{')) {
      complaint = complaint.substring(1).trim();
    }

    if (complaint.endsWith('}')) {
      complaint = complaint.substring(0, complaint.length - 1).trim();
    }

    return complaint;
  }

  String get friendlyComplaint {
    if (rawComplaint.trim().isEmpty) {
      return "General Consultation";
    }

    final regex = RegExp(r"'([^']+?)':\s*(\d+)");

    final matches = regex.allMatches(rawComplaint);

    if (matches.isEmpty) {
      return "General Consultation";
    }

    String highestRisk = '';
    int highestScore = -1;

    for (final match in matches) {
      final name = match.group(1) ?? '';
      final score = int.tryParse(match.group(2) ?? '') ?? 0;

      if (score > highestScore) {
        highestScore = score;
        highestRisk = name;
      }
    }

    if (highestRisk.isEmpty) {
      return "General Consultation";
    }

    return highestRisk;
  }

  String get friendlyRiskLevel {
    switch (triageData.riskLevel.toUpperCase()) {
      case 'RED':
        return 'Emergency';

      case 'ORANGE':
        return 'High Risk';

      case 'YELLOW':
        return 'Moderate Risk';

      case 'GREEN':
        return 'Low Risk';

      default:
        return triageData.riskLevel.isNotEmpty
            ? triageData.riskLevel
            : 'Not Available';
    }
  }

  String get friendlyWorkflow {
    final workflow = triageData.workflow.trim();

    if (workflow.isEmpty) {
      return "General Assessment";
    }

    return workflow;
  }

  String get winningTag {
    if (triageData.scoreCard.isEmpty) {
      return '';
    }

    String winningKey = '';
    num highestScore = -1;

    triageData.scoreCard.forEach((key, value) {
      if (value is num && value > highestScore) {
        highestScore = value;
        winningKey = key;
      }
    });

    return winningKey;
  }

  String get friendlyWinningTag {
    final tag = winningTag.trim();

    if (tag.isEmpty) {
      return "No primary concern identified";
    }

    return tag;
  }

  int? get winningScore {
    if (triageData.scoreCard.isEmpty) {
      return null;
    }

    final tag = winningTag;

    if (tag.isEmpty) {
      return null;
    }

    final score = triageData.scoreCard[tag];

    if (score is num) {
      return score.toInt();
    }

    return null;
  }

  Color get severityDisplayColor {
    switch (triageData.riskLevel.toUpperCase()) {
      case 'RED':
        return Colors.red;

      case 'ORANGE':
        return Colors.orange;

      case 'YELLOW':
        return Colors.amber;

      case 'GREEN':
        return Colors.green;

      default:
        return Colors.grey;
    }
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
