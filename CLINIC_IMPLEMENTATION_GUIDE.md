# HatiCare Clinic/Laboratory Module - Implementation Guide

## Quick Overview
Add clinic/laboratory role to HatiCare for entering patient test results and managing consultations.

---

## Step 1: Update User Role Enum

**File:** `lib/features/auth/domain/entities/user_role.dart`

```dart
enum UserRole { doctor, pharmacy, clinic }
```

---

## Step 2: Create Clinic Feature Directory Structure

```
lib/features/clinic/
├── presentation/
│   ├── screens/
│   │   ├── clinic_home_screen.dart
│   │   ├── enter_test_result_screen.dart
│   │   ├── patient_search_screen.dart
│   │   ├── test_result_history_screen.dart
│   │   └── clinic_settings_screen.dart
│   └── viewmodels/
│       ├── clinic_home_view_model.dart
│       └── test_result_view_model.dart
├── domain/
│   ├── entities/
│   │   ├── test_result.dart
│   │   ├── patient.dart
│   │   └── clinic.dart
│   └── repositories/
│       └── clinic_repository.dart
└── data/
    ├── datasources/
    │   └── clinic_remote_data_source.dart
    └── repositories/
        └── clinic_repository_impl.dart
```

---

## Step 3: Core Entities

### Test Result Entity
**File:** `lib/features/clinic/domain/entities/test_result.dart`

```dart
class TestResult {
  final String id;
  final String patientId;
  final String patientName;
  final String patientPhone;
  final String testType;        // TB, Malaria, HIV, etc.
  final String result;          // Positive, Negative, etc.
  final String status;
  final String notes;
  final DateTime testDate;
  final DateTime createdAt;
  final String clinicId;
  final bool requiresFollowUp;
  final String? referralRecommendation;

  TestResult({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.patientPhone,
    required this.testType,
    required this.result,
    required this.status,
    required this.notes,
    required this.testDate,
    required this.createdAt,
    required this.clinicId,
    required this.requiresFollowUp,
    this.referralRecommendation,
  });
}
```

### Patient Entity
**File:** `lib/features/clinic/domain/entities/patient.dart`

```dart
class Patient {
  final String id;
  final String name;
  final String phone;
  final String? email;
  final DateTime? dateOfBirth;
  final String? gender;
  final String? address;
  final List<String> testResultIds;
  final DateTime createdAt;

  Patient({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    this.dateOfBirth,
    this.gender,
    this.address,
    required this.testResultIds,
    required this.createdAt,
  });
}
```

### Clinic Entity
**File:** `lib/features/clinic/domain/entities/clinic.dart`

```dart
class Clinic {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String address;
  final String city;
  final String state;
  final String country;
  final String licenseNumber;
  final String? profilePicture;
  final bool profileCompleted;
  final DateTime createdAt;

  Clinic({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.address,
    required this.city,
    required this.state,
    required this.country,
    required this.licenseNumber,
    this.profilePicture,
    required this.profileCompleted,
    required this.createdAt,
  });
}
```

---

## Step 4: Repository Interface

**File:** `lib/features/clinic/domain/repositories/clinic_repository.dart`

```dart
abstract class ClinicRepository {
  // Test Results
  Future<TestResult> submitTestResult(TestResult testResult);
  Future<List<TestResult>> getTestResultHistory({
    required String clinicId,
    int limit = 20,
    int offset = 0,
  });
  
  // Patients
  Future<Patient> searchPatient(String phone);
  Future<Patient> createPatient(Patient patient);
  Future<Patient> getPatientHistory(String patientId);
  
  // Clinic Profile
  Future<Clinic> getClinicProfile(String clinicId);
  Future<Clinic> updateClinicProfile(Clinic clinic);
  
  // SMS Notifications
  Future<void> sendResultToPatient(String patientPhone, String resultSummary);
}
```

---

## Step 5: Remote Data Source

**File:** `lib/features/clinic/data/datasources/clinic_remote_data_source.dart`

```dart
import 'package:dio/dio.dart';

class ClinicRemoteDataSource {
  final Dio _dio;
  static const String baseUrl = 'https://your-api.com/api';

  ClinicRemoteDataSource(this._dio);

  // Submit Test Result
  Future<Map<String, dynamic>> submitTestResult(
    Map<String, dynamic> data,
    String token,
  ) async {
    try {
      final response = await _dio.post(
        '$baseUrl/clinic/test-results/',
        data: data,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception('Failed to submit: ${e.message}');
    }
  }

  // Get Test Results
  Future<List<Map<String, dynamic>>> getTestResults(
    String clinicId,
    String token, {
    int limit = 20,
  }) async {
    try {
      final response = await _dio.get(
        '$baseUrl/clinic/$clinicId/test-results/',
        queryParameters: {'limit': limit},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return List<Map<String, dynamic>>.from(response.data['results']);
    } on DioException catch (e) {
      throw Exception('Failed to fetch: ${e.message}');
    }
  }

  // Search Patient
  Future<Map<String, dynamic>> searchPatient(
    String phone,
    String token,
  ) async {
    try {
      final response = await _dio.get(
        '$baseUrl/clinic/patients/search/',
        queryParameters: {'phone': phone},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('Patient not found');
      }
      throw Exception('Search failed: ${e.message}');
    }
  }

  // Create Patient
  Future<Map<String, dynamic>> createPatient(
    Map<String, dynamic> data,
    String token,
  ) async {
    try {
      final response = await _dio.post(
        '$baseUrl/clinic/patients/',
        data: data,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception('Create failed: ${e.message}');
    }
  }
}
```

---

## Step 6: Repository Implementation

**File:** `lib/features/clinic/data/repositories/clinic_repository_impl.dart`

```dart
import 'package:shared_preferences/shared_preferences.dart';
import 'package:haticare/features/clinic/domain/repositories/clinic_repository.dart';
import 'package:haticare/features/clinic/domain/entities/test_result.dart';
import 'package:haticare/features/clinic/domain/entities/patient.dart';
import 'package:haticare/features/clinic/domain/entities/clinic.dart';
import 'package:haticare/features/clinic/data/datasources/clinic_remote_data_source.dart';

class ClinicRepositoryImpl implements ClinicRepository {
  final ClinicRemoteDataSource _remoteDataSource;
  final SharedPreferences _prefs;

  ClinicRepositoryImpl(this._remoteDataSource, this._prefs);

  String get _token => _prefs.getString('auth_token') ?? '';
  String get _clinicId => _prefs.getString('clinic_id') ?? '';

  @override
  Future<TestResult> submitTestResult(TestResult testResult) async {
    try {
      final data = {
        'patient_name': testResult.patientName,
        'patient_phone': testResult.patientPhone,
        'test_type': testResult.testType,
        'result': testResult.result,
        'status': testResult.status,
        'notes': testResult.notes,
        'test_date': testResult.testDate.toIso8601String(),
        'requires_follow_up': testResult.requiresFollowUp,
      };

      final response = await _remoteDataSource.submitTestResult(data, _token);
      
      // Send SMS to patient
      await sendResultToPatient(
        testResult.patientPhone,
        'Your test result: ${testResult.result}',
      );

      return testResult.copyWith(id: response['id']);
    } catch (e) {
      throw Exception('Submit failed: $e');
    }
  }

  @override
  Future<List<TestResult>> getTestResultHistory({
    required String clinicId,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final data = await _remoteDataSource.getTestResults(clinicId, _token, limit: limit);
      return data.map((item) => _mapToTestResult(item)).toList();
    } catch (e) {
      throw Exception('Fetch failed: $e');
    }
  }

  @override
  Future<Patient> searchPatient(String phone) async {
    try {
      final data = await _remoteDataSource.searchPatient(phone, _token);
      return _mapToPatient(data);
    } catch (e) {
      throw Exception('Search failed: $e');
    }
  }

  @override
  Future<Patient> createPatient(Patient patient) async {
    try {
      final data = {
        'name': patient.name,
        'phone': patient.phone,
        'email': patient.email,
        'gender': patient.gender,
        'address': patient.address,
      };
      final response = await _remoteDataSource.createPatient(data, _token);
      return _mapToPatient(response);
    } catch (e) {
      throw Exception('Create failed: $e');
    }
  }

  @override
  Future<Patient> getPatientHistory(String patientId) async {
    throw UnimplementedError();
  }

  @override
  Future<Clinic> getClinicProfile(String clinicId) async {
    throw UnimplementedError();
  }

  @override
  Future<Clinic> updateClinicProfile(Clinic clinic) async {
    throw UnimplementedError();
  }

  @override
  Future<void> sendResultToPatient(String patientPhone, String resultSummary) async {
    // Integrate with SMS service (Twilio, AWS SNS, etc.)
    print('SMS to $patientPhone: $resultSummary');
  }

  TestResult _mapToTestResult(Map<String, dynamic> data) {
    return TestResult(
      id: data['id'],
      patientId: data['patient_id'],
      patientName: data['patient_name'],
      patientPhone: data['patient_phone'],
      testType: data['test_type'],
      result: data['result'],
      status: data['status'],
      notes: data['notes'],
      testDate: DateTime.parse(data['test_date']),
      createdAt: DateTime.parse(data['created_at']),
      clinicId: data['clinic_id'],
      requiresFollowUp: data['requires_follow_up'] ?? false,
    );
  }

  Patient _mapToPatient(Map<String, dynamic> data) {
    return Patient(
      id: data['id'],
      name: data['name'],
      phone: data['phone'],
      email: data['email'],
      gender: data['gender'],
      address: data['address'],
      testResultIds: List<String>.from(data['test_result_ids'] ?? []),
      createdAt: DateTime.parse(data['created_at']),
    );
  }
}
```

---

## Step 7: ViewModel

**File:** `lib/features/clinic/presentation/viewmodels/test_result_view_model.dart`

```dart
import 'package:flutter/material.dart';
import 'package:haticare/features/clinic/domain/repositories/clinic_repository.dart';
import 'package:haticare/features/clinic/domain/entities/test_result.dart';
import 'package:haticare/features/clinic/domain/entities/patient.dart';

class TestResultViewModel extends ChangeNotifier {
  final ClinicRepository _repository;

  TestResultViewModel(this._repository);

  bool isLoading = false;
  bool isSubmitting = false;
  String? errorMessage;
  String? successMessage;
  List<TestResult> testResults = [];
  Patient? selectedPatient;

  final patientPhoneController = TextEditingController();
  final testTypeController = TextEditingController();
  final resultController = TextEditingController();
  final notesController = TextEditingController();

  String selectedStatus = 'negative';
  bool requiresFollowUp = false;
  DateTime selectedTestDate = DateTime.now();

  // Search patient by phone
  Future<void> searchPatient(String phone) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      selectedPatient = await _repository.searchPatient(phone);
    } catch (e) {
      errorMessage = 'Patient not found. Create new patient.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Create new patient
  Future<void> createNewPatient(String name, String phone) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final patient = Patient(
        id: '',
        name: name,
        phone: phone,
        testResultIds: [],
        createdAt: DateTime.now(),
      );
      selectedPatient = await _repository.createPatient(patient);
      successMessage = 'Patient created';
    } catch (e) {
      errorMessage = 'Failed to create patient';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Submit test result
  Future<void> submitTestResult() async {
    if (selectedPatient == null) {
      errorMessage = 'Select or create patient first';
      notifyListeners();
      return;
    }

    isSubmitting = true;
    errorMessage = null;
    successMessage = null;
    notifyListeners();

    try {
      final result = TestResult(
        id: '',
        patientId: selectedPatient!.id,
        patientName: selectedPatient!.name,
        patientPhone: selectedPatient!.phone,
        testType: testTypeController.text,
        result: resultController.text,
        status: selectedStatus,
        notes: notesController.text,
        testDate: selectedTestDate,
        createdAt: DateTime.now(),
        clinicId: '',
        requiresFollowUp: requiresFollowUp,
      );

      await _repository.submitTestResult(result);
      successMessage = 'Result submitted. SMS sent to patient.';
      _clearForm();
    } catch (e) {
      errorMessage = 'Failed: $e';
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }

  // Fetch history
  Future<void> fetchTestResultHistory(String clinicId) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      testResults = await _repository.getTestResultHistory(clinicId: clinicId);
    } catch (e) {
      errorMessage = 'Failed to fetch';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void _clearForm() {
    patientPhoneController.clear();
    testTypeController.clear();
    resultController.clear();
    notesController.clear();
    selectedStatus = 'negative';
    requiresFollowUp = false;
    selectedTestDate = DateTime.now();
    selectedPatient = null;
  }

  @override
  void dispose() {
    patientPhoneController.dispose();
    testTypeController.dispose();
    resultController.dispose();
    notesController.dispose();
    super.dispose();
  }
}
```

---

## Step 8: Update Auth to Support Clinic Role

**File:** `lib/features/auth/presentation/screens/login_screen.dart`

Add clinic role handling in the login success callback:

```dart
// After successful login, check role
if (response['data']['role'] == 'clinic') {
  final clinicId = response['data']['id'];
  await prefs.setString('clinic_id', clinicId);
  
  // Check if profile completed
  final isProfileCompleted = response['data']['profile_completed'] ?? false;
  await prefs.setBool('clinic_profile_completed', isProfileCompleted);
  
  if (!isProfileCompleted) {
    // Force profile completion
    Navigator.pushReplacementNamed(context, '/editClinicProfile');
  } else {
    Navigator.pushReplacementNamed(context, '/clinicHome');
  }
}
```

---

## Step 9: Add Clinic Routes

**File:** `lib/main.dart`

```dart
// Add to MaterialApp routes
routes: {
  '/clinicHome': (context) => const ClinicHomeScreen(),
  '/enterTestResult': (context) => const EnterTestResultScreen(),
  '/testResultHistory': (context) => const TestResultHistoryScreen(),
  '/editClinicProfile': (context) => const EditClinicProfileScreen(),
},
```

---

## Step 10: Create Basic UI Screens

### Clinic Home Screen
**File:** `lib/features/clinic/presentation/screens/clinic_home_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:haticare/features/clinic/presentation/viewmodels/test_result_view_model.dart';

class ClinicHomeScreen extends StatefulWidget {
  const ClinicHomeScreen({super.key});

  @override
  State<ClinicHomeScreen> createState() => _ClinicHomeScreenState();
}

class _ClinicHomeScreenState extends State<ClinicHomeScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<TestResultViewModel>().fetchTestResultHistory('');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Clinic Dashboard')),
      body: Consumer<TestResultViewModel>(
        builder: (context, viewModel, _) {
          if (viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, '/enterTestResult');
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Enter Test Result'),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, '/testResultHistory');
                  },
                  icon: const Icon(Icons.history),
                  label: const Text('View History'),
                ),
                const SizedBox(height: 24),
                Text(
                  'Recent Results (${viewModel.testResults.length})',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                if (viewModel.testResults.isEmpty)
                  const Center(child: Text('No results yet'))
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: viewModel.testResults.length,
                    itemBuilder: (context, index) {
                      final result = viewModel.testResults[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(result.patientName),
                          subtitle: Text('${result.testType}: ${result.result}'),
                          trailing: Chip(
                            label: Text(result.status),
                            backgroundColor: result.status == 'positive'
                                ? Colors.red[100]
                                : Colors.green[100],
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
```

---

## API Endpoints Required

Your backend should provide:

```
POST   /api/clinic/test-results/          - Submit test result
GET    /api/clinic/{clinicId}/test-results/ - Get test history
GET    /api/clinic/patients/search/       - Search patient by phone
POST   /api/clinic/patients/              - Create new patient
GET    /api/clinic/{clinicId}/            - Get clinic profile
PATCH  /api/clinic/{clinicId}/            - Update clinic profile
```

---

## SMS Integration

For sending results to patients, integrate with:
- **Twilio** - SMS service
- **AWS SNS** - Amazon Simple Notification Service
- **Local SMS Gateway** - For offline capability

---

## Next Steps

1. Create remaining UI screens (EnterTestResultScreen, TestResultHistoryScreen)
2. Implement clinic profile completion flow
3. Add SMS service integration
4. Add e-referral functionality
5. Implement patient history tracking
6. Add offline capability for SMS-based access

---

## Key Features Summary

✅ Clinic registration and profile management
✅ Patient search and creation
✅ Test result submission
✅ Automatic SMS notification to patients
✅ Test result history tracking
✅ Follow-up consultation requests
✅ E-referral generation
✅ Treatment history maintenance
