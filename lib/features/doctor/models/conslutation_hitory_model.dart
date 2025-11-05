class ConsultationHistoryModel {
  final String patientName;
  final int patientAge;
  final String date;
  final String duration;
  final String status;
  final bool isPrescriptionIssued;

  ConsultationHistoryModel({
    required this.patientName,
    required this.patientAge,
    required this.date,
    required this.duration,
    required this.status,
    required this.isPrescriptionIssued,
  });

  static List<ConsultationHistoryModel> sampleData = [
    ConsultationHistoryModel(
      patientName: "Alex Johnson",
      patientAge: 31,
      date: "30/10/2025",
      duration: "1 min",
      status: "Prescription Issued",
      isPrescriptionIssued: true,
    ),
    ConsultationHistoryModel(
      patientName: "Robert Brown",
      patientAge: 28,
      date: "30/10/2025",
      duration: "1 min",
      status: "Consultation Ended",
      isPrescriptionIssued: false,
    ),
    ConsultationHistoryModel(
      patientName: "Alex Johnson",
      patientAge: 31,
      date: "30/10/2025",
      duration: "1 min",
      status: "Prescription Issued",
      isPrescriptionIssued: true,
    ),
  ];
}
