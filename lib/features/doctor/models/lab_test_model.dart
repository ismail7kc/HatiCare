class LabTest {
  final int id;
  final String name;

  LabTest({
    required this.id,
    required this.name,
  });

  factory LabTest.fromJson(Map<String, dynamic> json) {
    return LabTest(
      id: json['id'],
      name: json['name'],
    );
  }
}
