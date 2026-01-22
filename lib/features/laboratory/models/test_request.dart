class TestRequest {
  final String requestId;
  final String patientName;
  final String doctorName;
  final String dateIssued;
  final List<String> tests;
  final String status;

  TestRequest({
    required this.requestId,
    required this.patientName,
    required this.doctorName,
    required this.dateIssued,
    required this.tests,
    required this.status,
  });

  static List<TestRequest> getDummyTestRequests() {
    return [];
  }

  static List<TestRequest> getDummyCompletedTestRequests() {
    return [];
  }
}
