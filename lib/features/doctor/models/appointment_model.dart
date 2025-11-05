class AppointmentModel {
  final String patientName;
  final int patientAge;
  final String reasonForVisit;
  final String appointmentTime;
  final double progressValue;
  final int minutesLeft;
  final List<String> symptoms;

  AppointmentModel({
    required this.patientName,
    required this.patientAge,
    required this.reasonForVisit,
    required this.appointmentTime,
    required this.progressValue,
    required this.minutesLeft,
    required this.symptoms,
  });

  static List<AppointmentModel> sampleData = [
    AppointmentModel(
      patientName: "Alex Johnson",
      patientAge: 31,
      reasonForVisit:
          "Patient reports persistent dizziness and headaches for the last 3 days.",
      appointmentTime: "Today at 4:30 PM",
      progressValue: 0.65,
      minutesLeft: 15,
      symptoms: ["Sneezing", "Itchy Eyes", "Runny nose"],
    ),
    AppointmentModel(
      patientName: "Sarah Connor",
      patientAge: 27,
      reasonForVisit:
          "Experiencing lower back pain and fatigue for the past week.",
      appointmentTime: "Today at 5:15 PM",
      progressValue: 0.4,
      minutesLeft: 25,
      symptoms: ["Back Pain", "Fatigue"],
    ),
    AppointmentModel(
      patientName: "Michael Brown",
      patientAge: 45,
      reasonForVisit: "Follow-up visit for blood pressure monitoring.",
      appointmentTime: "Today at 6:00 PM",
      progressValue: 0.85,
      minutesLeft: 8,
      symptoms: ["Dizziness", "Headache"],
    ),
  ];
}
