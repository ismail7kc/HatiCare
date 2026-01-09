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
    return [
      TestRequest(
        requestId: 'IB268920',
        patientName: 'Alex Johnson, 31',
        doctorName: 'Dr. John Doe',
        dateIssued: '30/10/2025',
        tests: [
          'Complete Blood Culture (CBC)',
          'Uric Acid Test',
          'Lipid Profile',
        ],
        status: 'Issued',
      ),
      TestRequest(
        requestId: 'IB268921',
        patientName: 'Sarah Smith, 28',
        doctorName: 'Dr. Jane Smith',
        dateIssued: '29/10/2025',
        tests: [
          'Thyroid Function Test',
          'Glucose Test',
        ],
        status: 'Issued',
      ),
      TestRequest(
        requestId: 'IB268922',
        patientName: 'Michael Brown, 45',
        doctorName: 'Dr. Robert Wilson',
        dateIssued: '28/10/2025',
        tests: [
          'Complete Blood Culture (CBC)',
          'Liver Function Test',
          'Kidney Function Test',
          'Electrolytes Panel',
        ],
        status: 'Pending',
      ),
    ];
  }

  static List<TestRequest> getDummyCompletedTestRequests() {
    return [
      TestRequest(
        requestId: 'IB268910',
        patientName: 'Emily Davis, 35',
        doctorName: 'Dr. Lisa Anderson',
        dateIssued: '25/10/2025',
        tests: [
          'Complete Blood Culture (CBC)',
          'Uric Acid Test',
        ],
        status: 'Completed',
      ),
      TestRequest(
        requestId: 'IB268911',
        patientName: 'James Wilson, 52',
        doctorName: 'Dr. Mark Johnson',
        dateIssued: '24/10/2025',
        tests: [
          'Thyroid Function Test',
          'Glucose Test',
          'Lipid Profile',
        ],
        status: 'Completed',
      ),
    ];
  }
}
