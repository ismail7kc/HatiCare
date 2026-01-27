
enum PrescriptionStatus {
  issued,
  fullyDispensed,
  partiallyDispensed,
  delivered,
}

class PrescriptionRequest {
  final String id;
  final String rxCode;
  final String patientName;
  final int patientAge;
  final String patientGender;
  final String patientDob;
  final String doctorName;
  final String doctorSpecialty;
  final DateTime dateIssued;
  final PrescriptionStatus status;
  final List<Medication> medications;
  
  // Additional fields for API data
  late String patientPhone;
  late String notes;
  late double fulfillmentScore;

  PrescriptionRequest({
    required this.id,
    required this.rxCode,
    required this.patientName,
    required this.patientAge,
    this.patientGender = 'Male',
    this.patientDob = '1992-11-15',
    required this.doctorName,
    this.doctorSpecialty = 'General Physician',
    required this.dateIssued,
    required this.status,
    required this.medications,
  });

  // Factory constructor to create instance from JSON
  factory PrescriptionRequest.fromJson(Map<String, dynamic> json) {
    try {
      // Parse medications
      List<Medication> medications = [];
      if (json['medications'] != null) {
        final medsList = json['medications'] as List<dynamic>;
        medications = medsList.map((med) => Medication.fromJson(med as Map<String, dynamic>)).toList();
      }

      // Parse date
      DateTime dateIssued = DateTime.now();
      if (json['date_issued'] != null) {
        dateIssued = DateTime.parse(json['date_issued'].toString());
      } else if (json['dateIssued'] != null) {
        dateIssued = DateTime.parse(json['dateIssued'].toString());
      }

      // Parse status
      PrescriptionStatus status = PrescriptionStatus.issued;
      if (json['status'] != null) {
        final statusStr = json['status'].toString().toLowerCase();
        switch (statusStr) {
          case 'issued':
            status = PrescriptionStatus.issued;
            break;
          case 'fully_dispensed':
          case 'fullydispensed':
            status = PrescriptionStatus.fullyDispensed;
            break;
          case 'partially_dispensed':
          case 'partiallydispensed':
            status = PrescriptionStatus.partiallyDispensed;
            break;
          case 'delivered':
            status = PrescriptionStatus.delivered;
            break;
        }
      }

      return PrescriptionRequest(
        id: json['id']?.toString() ?? '',
        rxCode: json['rx_code']?.toString() ?? json['rxCode']?.toString() ?? '',
        patientName: json['patient_name']?.toString() ?? json['patientName']?.toString() ?? '',
        patientAge: int.tryParse(json['patient_age']?.toString() ?? json['patientAge']?.toString() ?? '0') ?? 0,
        patientGender: json['patient_gender']?.toString() ?? json['patientGender']?.toString() ?? 'Unknown',
        patientDob: json['patient_dob']?.toString() ?? json['patientDob']?.toString() ?? '',
        doctorName: json['doctor_name']?.toString() ?? json['doctorName']?.toString() ?? '',
        doctorSpecialty: json['doctor_specialty']?.toString() ?? json['doctorSpecialty']?.toString() ?? 'General Physician',
        dateIssued: dateIssued,
        status: status,
        medications: medications,
      );
    } catch (e) {
      // Return a default object if parsing fails
      return PrescriptionRequest(
        id: json['id']?.toString() ?? '',
        rxCode: json['rx_code']?.toString() ?? json['rxCode']?.toString() ?? '',
        patientName: json['patient_name']?.toString() ?? json['patientName']?.toString() ?? 'Unknown',
        patientAge: int.tryParse(json['patient_age']?.toString() ?? json['patientAge']?.toString() ?? '0') ?? 0,
        doctorName: json['doctor_name']?.toString() ?? json['doctorName']?.toString() ?? 'Unknown Doctor',
        dateIssued: DateTime.now(),
        status: PrescriptionStatus.issued,
        medications: [],
      );
    }
  }

  String get statusText {
    switch (status) {
      case PrescriptionStatus.issued:
        return 'Issued';
      case PrescriptionStatus.fullyDispensed:
        return 'Fully Dispensed';
      case PrescriptionStatus.partiallyDispensed:
        return 'Partially Dispensed';
      case PrescriptionStatus.delivered:
        return 'Delivered';
    }
  }

  static List<PrescriptionRequest> getDummyRequests() {
    return [
      PrescriptionRequest(
        id: '1',
        rxCode: 'Rx268920',
        patientName: 'Alex Johnson',
        patientAge: 31,
        doctorName: 'Dr. John Doe',
        dateIssued: DateTime(2025, 10, 30, 16, 30),
        status: PrescriptionStatus.issued,
        medications: [
          Medication(
            name: 'Paracetamol',
            dosage: '500mg',
            instructions: '1 tab, 3 times a day for 3 days',
          ),
          Medication(
            name: 'Ibuprofen',
            dosage: '400mg',
            instructions: 'as needed for pain',
          ),
        ],
      ),
      PrescriptionRequest(
        id: '2',
        rxCode: 'Rx268921',
        patientName: 'Sarah Williams',
        patientAge: 45,
        doctorName: 'Dr. Emily Smith',
        dateIssued: DateTime(2025, 10, 30, 14, 15),
        status: PrescriptionStatus.issued,
        medications: [
          Medication(
            name: 'Amoxicillin',
            dosage: '250mg',
            instructions: '1 capsule, 3 times a day for 7 days',
          ),
          Medication(
            name: 'Vitamin C',
            dosage: '1000mg',
            instructions: '1 tablet daily',
          ),
        ],
      ),
      PrescriptionRequest(
        id: '3',
        rxCode: 'Rx268922',
        patientName: 'Michael Brown',
        patientAge: 28,
        doctorName: 'Dr. Robert Lee',
        dateIssued: DateTime(2025, 10, 30, 11, 45),
        status: PrescriptionStatus.issued,
        medications: [
          Medication(
            name: 'Cetirizine',
            dosage: '10mg',
            instructions: '1 tablet once daily',
          ),
        ],
      ),
      PrescriptionRequest(
        id: '4',
        rxCode: 'Rx268923',
        patientName: 'Emma Davis',
        patientAge: 52,
        doctorName: 'Dr. John Doe',
        dateIssued: DateTime(2025, 10, 30, 9, 20),
        status: PrescriptionStatus.issued,
        medications: [
          Medication(
            name: 'Metformin',
            dosage: '500mg',
            instructions: '1 tablet twice daily with meals',
          ),
          Medication(
            name: 'Aspirin',
            dosage: '75mg',
            instructions: '1 tablet once daily',
          ),
          Medication(
            name: 'Atorvastatin',
            dosage: '20mg',
            instructions: '1 tablet at bedtime',
          ),
        ],
      ),
    ];
  }

  static List<PrescriptionRequest> getDummyHistory() {
    return [
      PrescriptionRequest(
        id: '5',
        rxCode: 'Rx-256782',
        patientName: 'Alex Johnson',
        patientAge: 31,
        doctorName: 'Dr. John Smith, MD',
        dateIssued: DateTime(2025, 10, 30),
        status: PrescriptionStatus.fullyDispensed,
        medications: [
          Medication(
            name: 'Amoxicillin',
            dosage: '500mg',
            instructions: 'Every 8 hours for 7 days',
          ),
        ],
      ),
      PrescriptionRequest(
        id: '6',
        rxCode: 'Rx-267892',
        patientName: 'Alex Johnson',
        patientAge: 31,
        doctorName: 'Dr. John Smith, MD',
        dateIssued: DateTime(2025, 10, 30),
        status: PrescriptionStatus.fullyDispensed,
        medications: [
          Medication(
            name: 'Amoxicillin',
            dosage: '500mg',
            instructions: 'Every 8 hours for 7 days',
          ),
        ],
      ),
      PrescriptionRequest(
        id: '7',
        rxCode: 'Rx-267893',
        patientName: 'Alex Johnson',
        patientAge: 31,
        doctorName: 'Dr. John Smith, MD',
        dateIssued: DateTime(2025, 10, 30),
        status: PrescriptionStatus.partiallyDispensed,
        medications: [
          Medication(
            name: 'Amoxicillin',
            dosage: '500mg',
            instructions: 'Every 8 hours for 7 days',
          ),
        ],
      ),
      PrescriptionRequest(
        id: '8',
        rxCode: 'Rx-XL5672890',
        patientName: 'Alex Johnson',
        patientAge: 31,
        doctorName: 'Dr. John Smith, MD',
        dateIssued: DateTime(2025, 10, 30),
        status: PrescriptionStatus.fullyDispensed,
        medications: [
          Medication(
            name: 'Amoxicillin',
            dosage: '500mg',
            instructions: 'Every 8 hours for 7 days',
          ),
        ],
      ),
    ];
  }
}

class Medication {
  final String name;
  final String dosage;
  final String instructions;

  Medication({
    required this.name,
    required this.dosage,
    required this.instructions,
  });

  // Factory constructor to create instance from JSON
  factory Medication.fromJson(Map<String, dynamic> json) {
    return Medication(
      name: json['name']?.toString() ?? '',
      dosage: json['dosage']?.toString() ?? json['strength']?.toString() ?? '',
      instructions: json['instructions']?.toString() ?? '',
    );
  }
}
