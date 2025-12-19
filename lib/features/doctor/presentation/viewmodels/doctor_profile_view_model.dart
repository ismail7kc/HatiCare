import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl_phone_field/phone_number.dart';
import 'package:chucker_flutter/chucker_flutter.dart';
import 'package:intl/intl.dart';

import '../../../../core/config/app_config.dart';
import '../../ApiClient/api_client.dart';
import '../../RepositoryLayer/repository_layer.dart';
import '../../models/updated_doctor_model.dart';
import '../viewModel/edit_viewModel.dart';

class DoctorProfileViewModel extends ChangeNotifier {
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneNumberController = TextEditingController();
  String? _phoneNumber;
  String _countryCode = 'US';
  String? _initialPhoneNumber;
  int _phoneFieldKey = 0; // Counter to force IntlPhoneField rebuild

  final licenseNumberController = TextEditingController();
  final yearsExperienceController = TextEditingController();
  final licenseAuthorityController = TextEditingController();

  String? gender;
  DateTime? selectedDate;
  String? selectedSpecialization;
  String? selectedLicenseType;

  // License and ID documents
  String? licenseDocumentUrl;
  String? idDocumentUrl;
  File? licenseDocumentFile;
  File? idDocumentFile;

  int currentStep = 1;
  bool isSubmitting = false;
  bool isLoading = true;
  String? errorMessage;
  String? successMessage;
  bool _shouldNavigateToHome = false;

  final String doctorId;
  final bool openedFromSettings;
  final GlobalKey<FormState> formKeyPage1 = GlobalKey<FormState>();
  final GlobalKey<FormState> formKeyPage2 = GlobalKey<FormState>();

  // API Client
  late final ApiClient apiClient;
  late final RepositoryLayer repository;
  late final EditViewmodel editViewModel;

  // Specializations
  List<String> specializationNames = [];

  // License Types
  final List<String> licenseTypes = [
    "Permanent medical licenses",
    "Temporary medical license",
    "Locum tenens license",
    "Institutional practice limited license",
    "Faculty license",
    "Residency training license",
    "Fellowship training license"
  ];

  // Change tracking
  late Map<String, dynamic> _initialValues;
  bool _hasChanges = false;

  bool get hasChanges => _hasChanges;
  bool get shouldNavigateToHome => _shouldNavigateToHome;

  DoctorProfileViewModel({
    required this.doctorId,
    this.openedFromSettings = false,
  }) {
    apiClient = ApiClient();
    repository = RepositoryLayer(apiClient);
    editViewModel = EditViewmodel(repository);

    isLoading = true; // Always start with loading
    _addTextControllerListeners();
    _initialize();
  }

  void _addTextControllerListeners() {
    firstNameController.addListener(_checkForChanges);
    lastNameController.addListener(_checkForChanges);
    licenseNumberController.addListener(_checkForChanges);
    yearsExperienceController.addListener(_checkForChanges);
    licenseAuthorityController.addListener(_checkForChanges);
  }

  Future<void> _initialize() async {
    await _loadSpecializations();
    await _initializeProfile();
  }

  Future<void> _loadSpecializations() async {
    try {
      await editViewModel.fetchSpecialization();
      specializationNames = editViewModel.specializationNames;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading specializations: $e');
    }
  }

  Future<void> _initializeProfile() async {
    await _loadDoctorData();
    // Always fetch profile from API
    await fetchDoctorProfile();
  }

  Future<void> _loadDoctorData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final firstName = prefs.getString('user_first_name') ?? '';
      final lastName = prefs.getString('user_last_name') ?? '';
      final userEmail = prefs.getString('user_email') ?? '';
      final phoneNumber = prefs.getString('user_phone_number') ?? '';

      firstNameController.text = firstName;
      lastNameController.text = lastName;
      emailController.text = userEmail;

      if (phoneNumber.isNotEmpty) {
        final parsedPhone = _parsePhoneNumber(phoneNumber);
        final countryCode = parsedPhone['countryCode'] ?? 'US';
        final numberOnly = parsedPhone['number'] ?? '';

        _initialPhoneNumber = numberOnly;
        _phoneNumber = phoneNumber;
        _countryCode = countryCode;
      }

      _initializeChangeTracking();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading doctor data: $e');
    }
  }

  void _initializeChangeTracking() {
    _initialValues = {
      'firstName': firstNameController.text,
      'lastName': lastNameController.text,
      'phoneNumber': _phoneNumber ?? '',
      'gender': gender,
      'dob': selectedDate,
      'licenseNumber': licenseNumberController.text,
      'licenseType': selectedLicenseType,
      'specialization': selectedSpecialization,
      'yearsExperience': yearsExperienceController.text,
      'licenseAuthority': licenseAuthorityController.text,
    };
    _hasChanges = false;
  }

  void _checkForChanges() {
    final currentValues = {
      'firstName': firstNameController.text,
      'lastName': lastNameController.text,
      'phoneNumber': _phoneNumber ?? '',
      'gender': gender,
      'dob': selectedDate,
      'licenseNumber': licenseNumberController.text,
      'licenseType': selectedLicenseType,
      'specialization': selectedSpecialization,
      'yearsExperience': yearsExperienceController.text,
      'licenseAuthority': licenseAuthorityController.text,
    };

    _hasChanges = currentValues.toString() != _initialValues.toString();
    notifyListeners();
  }

  Map<String, String> _parsePhoneNumber(String phoneNumber) {
    const countryCodeMap = {
      '+1': 'US',
      '+44': 'GB',
      '+92': 'PK',
      '+91': 'IN',
      '+86': 'CN',
      '+81': 'JP',
      '+33': 'FR',
      '+49': 'DE',
      '+39': 'IT',
      '+34': 'ES',
      '+61': 'AU',
      '+64': 'NZ',
      '+27': 'ZA',
      '+55': 'BR',
      '+52': 'MX',
    };

    String countryCode = 'US';
    String numberOnly = phoneNumber;

    String cleanedNumber = phoneNumber.replaceAll(RegExp(r'[^+\d]'), '');

    for (final entry in countryCodeMap.entries) {
      if (cleanedNumber.startsWith(entry.key)) {
        countryCode = entry.value;
        numberOnly = cleanedNumber.replaceFirst(entry.key, '').trim();
        break;
      }
    }

    return {
      'countryCode': countryCode,
      'number': numberOnly,
    };
  }

  Future<void> fetchDoctorProfile({bool forceRefresh = false}) async {
    try {
      debugPrint('===== fetchDoctorProfile START =====');
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      final response = await editViewModel.getSignleDocResponse();
      debugPrint("SINGLE DOCTOR RES: $response");
      debugPrint("Response success: ${response['success']}");
      debugPrint("Response data: ${response['data']}");

      if (response['success'] == true && response['data'] != null) {
        _populateFormFields(response['data']);
        debugPrint("✅ Form fields populated successfully");
      } else {
        errorMessage = 'Failed to load doctor profile';
        debugPrint("❌ Error fetching doctor - success: ${response['success']}, data: ${response['data']}");
      }
    } catch (e, stackTrace) {
      errorMessage = 'Error loading profile: ${e.toString()}';
      debugPrint("❌ Exception in fetchDoctorProfile: $e");
      debugPrint("Stack trace: $stackTrace");
    } finally {
      debugPrint('===== Setting isLoading = false =====');
      isLoading = false;
      notifyListeners();
      debugPrint('===== fetchDoctorProfile END =====');
    }
  }

  void _populateFormFields(dynamic data) {
    try {
      if (data is Map<String, dynamic>) {
        debugPrint('📝 Starting to populate form fields...');
        debugPrint('📊 Data received: $data');

        final doc = Doctor.fromJson(data);
        debugPrint('✅ Doctor model created: ${doc.firstName} ${doc.lastName}');

        firstNameController.text = doc.firstName ?? '';
        lastNameController.text = doc.lastName ?? '';
        emailController.text = doc.email ?? '';
        debugPrint('✅ Basic info set: ${firstNameController.text} ${lastNameController.text}, ${emailController.text}');

        // Parse phone number
        String? phoneNum = doc.phoneNumber;
        debugPrint('📞 Phone number from API: $phoneNum');

        if (phoneNum != null && phoneNum.isNotEmpty) {
          final parsedPhone = _parsePhoneNumber(phoneNum);
          _countryCode = parsedPhone['countryCode']!;
          _initialPhoneNumber = parsedPhone['number'];
          _phoneNumber = phoneNum;
          _phoneFieldKey++; // Increment to force rebuild

          debugPrint('📞 Set country code: $_countryCode');
          debugPrint('📞 Set initial phone: $_initialPhoneNumber');
          debugPrint('📞 Phone field key incremented to: $_phoneFieldKey');
        } else {
          debugPrint('📞 Phone number is null or empty');
        }

        licenseNumberController.text = doc.licenseNumber ?? '';
        yearsExperienceController.text = doc.yearsOfExperience?.toString() ?? '';
        licenseAuthorityController.text = doc.licenseIssuingAuthority ?? '';

        gender = doc.gender == 'M'
            ? 'Male'
            : doc.gender == 'F'
            ? 'Female'
            : 'Other';

        selectedDate = doc.dob ?? DateTime(1992, 1, 8);
        selectedSpecialization = doc.specialization;
        selectedLicenseType = doc.licenseType;

        licenseDocumentUrl = doc.licenseDocument;
        idDocumentUrl = doc.IdDocuments;

        debugPrint('Form fields populated successfully');

        _initializeChangeTracking();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error populating form fields: $e');
    }
  }

  String get countryCode => _countryCode;
  String? get initialPhoneNumber => _initialPhoneNumber;
  int get phoneFieldKey => _phoneFieldKey;

  void updatePhoneNumber(PhoneNumber? phoneNumber) {
    if (phoneNumber != null) {
      _phoneNumber = phoneNumber.completeNumber;
      _countryCode = phoneNumber.countryISOCode ?? 'US';
      _checkForChanges();
    } else {
      _phoneNumber = null;
    }
  }

  void updateGender(String? value) {
    gender = value;
    _checkForChanges();
    notifyListeners();
  }

  void updateDateOfBirth(DateTime? date) {
    selectedDate = date;
    _checkForChanges();
    notifyListeners();
  }

  void updateSpecialization(String? value) {
    selectedSpecialization = value;
    _checkForChanges();
    notifyListeners();
  }

  void updateLicenseType(String? value) {
    selectedLicenseType = value;
    _checkForChanges();
    notifyListeners();
  }

  String? validateFirstName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'First name is required';
    }
    if (!RegExp(r'^[a-zA-Z]+$').hasMatch(value.trim())) {
      return 'Only alphabets allowed';
    }
    return null;
  }

  String? validateLastName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Last name is required';
    }
    if (!RegExp(r'^[a-zA-Z]+$').hasMatch(value.trim())) {
      return 'Only alphabets allowed';
    }
    return null;
  }

  String? validatePhoneNumber(String? value) {
    if (_phoneNumber == null || _phoneNumber!.isEmpty) {
      return 'Phone number is required';
    }
    return null;
  }

  String? validateLicenseNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'License number is required';
    }
    return null;
  }

  String? validateYearsExperience(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Years of experience required';
    }
    final intValue = int.tryParse(value.trim());
    if (intValue == null || intValue <= 0 || intValue > 99) {
      return 'Enter value between 1 and 99';
    }
    return null;
  }

  String? validateLicenseAuthority(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'License authority is required';
    }
    return null;
  }

  String? validateGender(String? value) {
    if (value == null || value.isEmpty) {
      return 'Gender is required';
    }
    return null;
  }

  String? validateDateOfBirth(String? value) {
    if (selectedDate == null) {
      return 'Date of birth is required';
    }
    return null;
  }

  String? validateSpecialization(String? value) {
    if (value == null || value.isEmpty) {
      return 'Specialization is required';
    }
    return null;
  }

  String? validateLicenseType(String? value) {
    if (value == null || value.isEmpty) {
      return 'License type is required';
    }
    return null;
  }

  void moveToNextPage() {
    if (formKeyPage1.currentState!.validate()) {
      currentStep = 2;
      errorMessage = null;
      notifyListeners();
    }
  }

  void moveBackToPreviousPage() {
    currentStep = 1;
    errorMessage = null;
    notifyListeners();
  }

  Future<void> submitProfile() async {
    // Validate all fields
    if (!formKeyPage2.currentState!.validate()) {
      return;
    }

    // Ensure all required fields are filled
    if (_phoneNumber == null || _phoneNumber!.isEmpty) {
      errorMessage = 'Please enter a valid phone number';
      notifyListeners();
      return;
    }

    if (selectedLicenseType == null || selectedSpecialization == null || gender == null || selectedDate == null) {
      errorMessage = 'Please complete all required fields';
      notifyListeners();
      return;
    }

    isSubmitting = true;
    errorMessage = null;
    successMessage = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('user_email') ?? emailController.text;

      editViewModel.updateDoctorInstanceFromControllers(
        firstName: firstNameController.text,
        lastName: lastNameController.text,
        email: email,
        phoneNumber: _phoneNumber ?? '',
        licenseNumber: licenseNumberController.text,
        licenseType: selectedLicenseType,
        specialization: selectedSpecialization,
        yearsExperience: yearsExperienceController.text,
        licenseAuthority: licenseAuthorityController.text,
        gender: gender,
        dob: selectedDate,
      );

      debugPrint('Doctor instance before update: ${editViewModel.doctorInstance}');

      final response = await editViewModel.updateDoctorInfo();

      debugPrint('=== UPDATE DOCTOR RESPONSE ===');
      debugPrint('Full Response: $response');
      debugPrint('Success: ${response['success']}');
      debugPrint('Message: ${response['message']}');
      debugPrint('Data: ${response['data']}');
      debugPrint('Status Code: ${response['code']}');
      debugPrint('=============================');

      if (response['success'] == true) {
        final firstName = response['data']['first_name'];
        final lastName = response['data']['last_name'];

        // Update shared preferences
        await prefs.setString('user_first_name', firstName);
        await prefs.setString('user_last_name', lastName);

        successMessage = 'Doctor profile updated successfully';
        _shouldNavigateToHome = true;
        notifyListeners();
      } else {
        final errorMsg = response['message'] ?? "Something went wrong. Please try again.";
        errorMessage = errorMsg;
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error updating doctor: $e");
      debugPrint("Stack trace: ${StackTrace.current}");
      errorMessage = "Something went wrong. Please try again.";
      notifyListeners();
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }

  void resetNavigation() {
    _shouldNavigateToHome = false;
  }

  Future<void> uploadLicenseDocument(File file) async {
    try {
      debugPrint('📤 Uploading license document...');

      // Store the file immediately for UI update
      licenseDocumentFile = file;
      notifyListeners();

      isLoading = true;
      errorMessage = null;
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token') ?? '';
      final doctorId = prefs.getString('doctor_id') ?? '';

      if (doctorId.isEmpty) {
        errorMessage = 'Doctor ID not found';
        return;
      }

      final uri = Uri.parse('${AppConfig.baseUrl}doc/doctors/$doctorId/');
      final request = http.MultipartRequest('PATCH', uri);

      request.headers['Authorization'] = 'Bearer $accessToken';
      request.files.add(
        await http.MultipartFile.fromPath('license_document', file.path),
      );

      debugPrint('📤 Sending license document to: $uri');

      final client = ChuckerHttpClient(http.Client());
      final response = await client.send(request);
      final responseBody = await response.stream.bytesToString();

      debugPrint('📥 License upload response: ${response.statusCode}');
      debugPrint('📥 Response body: $responseBody');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        debugPrint('✅ License document uploaded successfully');
        final jsonResponse = jsonDecode(responseBody);
        if (jsonResponse['data'] != null) {
          licenseDocumentUrl = jsonResponse['data']['license_document'];
        }
      } else {
        errorMessage = 'Failed to upload license document';
        debugPrint('❌ Upload failed with status: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      errorMessage = 'Error uploading license document: ${e.toString()}';
      debugPrint('❌ Exception in uploadLicenseDocument: $e');
      debugPrint('Stack trace: $stackTrace');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> uploadIdDocument(File file) async {
    try {
      debugPrint('📤 Uploading ID document...');

      // Store the file immediately for UI update
      idDocumentFile = file;
      notifyListeners();

      isLoading = true;
      errorMessage = null;
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token') ?? '';
      final doctorId = prefs.getString('doctor_id') ?? '';

      if (doctorId.isEmpty) {
        errorMessage = 'Doctor ID not found';
        return;
      }

      final uri = Uri.parse('${AppConfig.baseUrl}doc/doctors/$doctorId/');
      final request = http.MultipartRequest('PATCH', uri);

      request.headers['Authorization'] = 'Bearer $accessToken';
      request.files.add(
        await http.MultipartFile.fromPath('id_document', file.path),
      );

      debugPrint('📤 Sending ID document to: $uri');

      final client = ChuckerHttpClient(http.Client());
      final response = await client.send(request);
      final responseBody = await response.stream.bytesToString();

      debugPrint('📥 ID upload response: ${response.statusCode}');
      debugPrint('📥 Response body: $responseBody');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        debugPrint('✅ ID document uploaded successfully');
        final jsonResponse = jsonDecode(responseBody);
        if (jsonResponse['data'] != null) {
          idDocumentUrl = jsonResponse['data']['id_document'];
        }
      } else {
        errorMessage = 'Failed to upload ID document';
        debugPrint('❌ Upload failed with status: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      errorMessage = 'Error uploading ID document: ${e.toString()}';
      debugPrint('❌ Exception in uploadIdDocument: $e');
      debugPrint('Stack trace: $stackTrace');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    phoneNumberController.dispose();
    licenseNumberController.dispose();
    yearsExperienceController.dispose();
    licenseAuthorityController.dispose();
    super.dispose();
  }
}
