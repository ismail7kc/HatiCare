class DoctorMedication {
  final String name;
  final String dose;
  final String frequency;
  final String duration;
  final int quantity;
  final String notes;

  DoctorMedication({
    required this.name,
    required this.dose,
    required this.frequency,
    required this.duration,
    required this.quantity,
    required this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      "name": name,
      "dose": dose,
      "frequency": frequency,
      "duration": duration,
      "quantity": quantity,
      "notes": notes,
    };
  }
}
