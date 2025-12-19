import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl_phone_field/phone_number.dart';
import 'package:chucker_flutter/chucker_flutter.dart';
import '../../../../../core/config/app_config.dart';

class LaboratoryProfileViewModel extends ChangeNotifier {
  LaboratoryProfileViewModel({
    required this.laboratoryId,
    this.openedFromSettings = false,
  }) {
    _addTextControllerListeners();
    _initialize();
  }

  final String laboratoryId;
  final bool openedFromSettings;

  // Form controllers
  final contactPersonController = TextEditingController();
  final emailController = TextEditingController();
  final laboratoryNameController = TextEditingController();
  final phoneNumberController = TextEditingController();
  final addressLine1Controller = TextEditingController();
  final cityController = TextEditingController();
  final stateController = TextEditingController();
  final zipCodeController = TextEditingController();
  final countryController = TextEditingController();
  final taxIdentificationNumberController = TextEditingController();
  final licenseNumberController = TextEditingController();

  // Phone number handling
  String? _phoneNumber;
  String _countryCode = 'US';
  String? _initialPhoneNumber;

  // Profile picture and documents
  File? profilePictureFile;
  File? licenseDocumentFile;
  String? profilePictureUrl;
  String? licenseDocumentUrl;
  
  // Aliases for compatibility with pharmacy profile screen
  File? get profilePicture => profilePictureFile;
  File? get licenseDocument1 => licenseDocumentFile;
  String? get licenseDocument1Url => licenseDocumentUrl;

  // State variables
  bool isLoading = true;
  bool isSubmitting = false;
  String? errorMessage;
  String? successMessage;
  bool _shouldNavigateToHome = false;
  int _currentStep = 1;
  bool _attemptedSubmit = false;

  // Change tracking
  late Map<String, String> _initialValues;
  bool _hasChanges = false;
  
  // Form keys
  final formKeyPage1 = GlobalKey<FormState>();
  final formKeyPage2 = GlobalKey<FormState>();
  
  // Validation errors
  final Map<String, String> _validationErrors = {};
  
  // Country/State/City selection
  String? selectedCountry;
  String? selectedState;
  String? selectedCity;
  List<String> countries = [];
  List<String> states = [];
  List<String> cities = [];

  bool get hasChanges => _hasChanges;
  bool get shouldNavigateToHome => _shouldNavigateToHome;
  int get currentStep => _currentStep;
  bool get attemptedSubmit => _attemptedSubmit;
  
  String? get taxIdController => taxIdentificationNumberController.text;
  set taxIdController(String? value) {
    if (value != null) {
      taxIdentificationNumberController.text = value;
    }
  }

  void _addTextControllerListeners() {
    laboratoryNameController.addListener(_checkForChanges);
    addressLine1Controller.addListener(_checkForChanges);
    cityController.addListener(_checkForChanges);
    stateController.addListener(_checkForChanges);
    zipCodeController.addListener(_checkForChanges);
    countryController.addListener(_checkForChanges);
    taxIdentificationNumberController.addListener(_checkForChanges);
    licenseNumberController.addListener(_checkForChanges);
  }

  Future<void> _initialize() async {
    await _loadCountriesData();
    await _loadCachedData();
    if (openedFromSettings) {
      await fetchLaboratoryProfile();
    } else {
      isLoading = false;
      notifyListeners();
    }
  }

  // Cache for all countries data
  late List<dynamic> _countriesJsonData;
  bool _jsonDataLoaded = false;

  Future<void> _loadCountriesData() async {
    try {
      final jsonString = await rootBundle.loadString('assets/json/countries.json');
      final List<dynamic> jsonData = jsonDecode(jsonString);
      
      _countriesJsonData = jsonData;
      _jsonDataLoaded = true;
      countries = jsonData.map((item) => item['Country_name'] as String).toList();
      
      debugPrint('Loaded ${countries.length} countries');
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading countries data: $e');
      countries = [];
      _jsonDataLoaded = false;
      notifyListeners();
    }
  }

  Future<void> _loadCachedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      contactPersonController.text = prefs.getString('user_first_name') ?? '';
      emailController.text = prefs.getString('user_email') ?? '';
      
      final phoneNumber = prefs.getString('user_phone_number') ?? '';
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
      debugPrint('Error loading cached data: $e');
    }
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

  void _initializeChangeTracking() {
    _initialValues = {
      'laboratoryName': laboratoryNameController.text,
      'addressLine1': addressLine1Controller.text,
      'city': cityController.text,
      'state': stateController.text,
      'zipCode': zipCodeController.text,
      'country': countryController.text,
      'contactPerson': contactPersonController.text,
      'email': emailController.text,
      'phoneNumber': _phoneNumber ?? '',
      'taxId': taxIdentificationNumberController.text,
      'licenseNumber': licenseNumberController.text,
    };
    _hasChanges = false;
  }

  void _checkForChanges() {
    final currentValues = {
      'laboratoryName': laboratoryNameController.text,
      'addressLine1': addressLine1Controller.text,
      'city': cityController.text,
      'state': stateController.text,
      'zipCode': zipCodeController.text,
      'country': countryController.text,
      'contactPerson': contactPersonController.text,
      'email': emailController.text,
      'phoneNumber': _phoneNumber ?? '',
      'taxId': taxIdentificationNumberController.text,
      'licenseNumber': licenseNumberController.text,
    };

    _hasChanges = currentValues != _initialValues;
    notifyListeners();
  }

  Future<void> fetchLaboratoryProfile() async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token') ?? '';

      if (accessToken.isEmpty) {
        errorMessage = 'No authentication token found';
        isLoading = false;
        notifyListeners();
        return;
      }

      String finalLaboratoryId = laboratoryId;
      if (laboratoryId.isEmpty) {
        finalLaboratoryId = prefs.getString('laboratory_id') ?? '';
      }

      if (finalLaboratoryId.isEmpty) {
        errorMessage = 'Laboratory ID not found. Please login again.';
        isLoading = false;
        notifyListeners();
        return;
      }

      final uri = Uri.parse('${AppConfig.baseUrl}lab/laboratories/$finalLaboratoryId/');
      final client = ChuckerHttpClient(http.Client());
      final response = await client.get(
        uri,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      debugPrint('Fetch Profile Response Status: ${response.statusCode}');
      debugPrint('Fetch Profile Response Body: ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final jsonResponse = jsonDecode(response.body);
        debugPrint('Full API Response: $jsonResponse');

        dynamic data;
        if (jsonResponse is Map<String, dynamic> && jsonResponse.containsKey('data')) {
          data = jsonResponse['data'];
        } else {
          data = jsonResponse;
        }

        debugPrint('Extracted Data: $data');
        _populateFormFields(data);
        successMessage = null;
      } else {
        final responseBody = response.body;
        errorMessage = 'Failed to load profile: ${response.statusCode}';
        debugPrint('Error response: $responseBody');
      }
    } on SocketException catch (e) {
      errorMessage = 'Network error: ${e.message}. Please check your internet connection.';
      debugPrint('SocketException: $e');
    } on TimeoutException catch (e) {
      errorMessage = 'Request timed out. Please try again.';
    } catch (e) {
      errorMessage = 'Error loading profile: ${e.toString()}';
      debugPrint('Exception: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void _populateFormFields(dynamic data) {
    try {
      if (data is Map<String, dynamic>) {
        debugPrint('Starting to populate form fields...');

        final laboratoryName = data['laboratory_name'] ?? '';
        laboratoryNameController.text = laboratoryName;
        debugPrint('laboratory_name: $laboratoryName');

        final addressLine1 = data['address_line1'] ?? '';
        addressLine1Controller.text = addressLine1;
        debugPrint('address_line1: $addressLine1');

        final country = data['country'] ?? '';
        if (country.isNotEmpty) {
          // Check if country exists in the list
          final countryExists = countries.any((c) => c == country);
          if (countryExists) {
            selectCountry(country);
            debugPrint('Country selected: $country');
          } else {
            // If country doesn't exist in list, just set the text
            countryController.text = country;
            selectedCountry = country;
            debugPrint('Country not found in list, set as text: $country');
          }
        }
        debugPrint('country: $country');

        final state = data['state'] ?? '';
        if (state.isNotEmpty) {
          // First ensure country is selected
          if (selectedCountry != null && selectedCountry!.isNotEmpty) {
            selectState(state);
            debugPrint('State selected: $state');
          } else {
            // If country not selected, just set the text
            stateController.text = state;
            selectedState = state;
            debugPrint('State not selected due to missing country, set as text: $state');
          }
        }
        debugPrint('state: $state');

        final city = data['city'] ?? '';
        if (city.isNotEmpty) {
          selectCity(city);
          debugPrint('City selected: $city');
        }
        debugPrint('city: $city');

        final zipCode = data['zip_code'] ?? '';
        zipCodeController.text = zipCode;
        debugPrint('zip_code: $zipCode');

        final contactPerson = data['contact_person'] ?? '';
        if (contactPerson.isNotEmpty) {
          contactPersonController.text = contactPerson;
          debugPrint('contact_person: $contactPerson');
        }

        final email = data['email'] ?? '';
        if (email.isNotEmpty) {
          emailController.text = email;
          debugPrint('email: $email');
        }
        
        final phoneNumber = data['phone_number'] ?? '';
        if (phoneNumber.isNotEmpty) {
          final parsedPhone = _parsePhoneNumber(phoneNumber);
          final countryCode = parsedPhone['countryCode'] ?? 'US';
          final numberOnly = parsedPhone['number'] ?? '';
          
          _initialPhoneNumber = numberOnly;
          _phoneNumber = phoneNumber;
          _countryCode = countryCode;
          
          debugPrint('phone_number: $phoneNumber');
          debugPrint('Parsed - Country: $countryCode, Number: $numberOnly');
        }

        final taxId = data['tax_identification_number'] ?? '';
        taxIdentificationNumberController.text = taxId;
        debugPrint('tax_identification_number: $taxId');

        final licenseNumber = data['license_number'] ?? '';
        licenseNumberController.text = licenseNumber;
        debugPrint('license_number: $licenseNumber');

        final profilePictureUrlValue = data['profile_picture'];
        if (profilePictureUrlValue != null && profilePictureUrlValue.toString().isNotEmpty) {
          profilePictureUrl = profilePictureUrlValue.toString();
          debugPrint('profile_picture URL: $profilePictureUrl');
        }

        final licenseDocUrlValue = data['license_document'];
        if (licenseDocUrlValue != null && licenseDocUrlValue.toString().isNotEmpty) {
          licenseDocumentUrl = licenseDocUrlValue.toString();
          debugPrint('license_document URL: $licenseDocumentUrl');
        }

        debugPrint('Form fields populated successfully');
        
        _initializeChangeTracking();
        notifyListeners();
      } else {
        debugPrint('Data is not a Map: ${data.runtimeType}');
      }
    } catch (e) {
      debugPrint('Error populating form fields: $e');
    }
  }

  void setProfilePicture(File? file) {
    profilePictureFile = file;
    notifyListeners();
  }

  void setLicenseDocument(File? file) {
    licenseDocumentFile = file;
    notifyListeners();
  }

  void updatePhoneNumber(PhoneNumber? phoneNumber) {
    if (phoneNumber != null) {
      _phoneNumber = phoneNumber.completeNumber;
      _countryCode = phoneNumber.countryISOCode ?? 'US';
    } else {
      _phoneNumber = null;
    }
    _checkForChanges();
  }

  String? validateContactPerson(String? value) {
    if (value == null || value.isEmpty) {
      return 'Contact person name is required';
    }
    return null;
  }

  String? validateLaboratoryName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Laboratory name is required';
    }
    return null;
  }

  String? validateAddress(String? value) {
    if (value == null || value.isEmpty) {
      return 'Address is required';
    }
    return null;
  }

  String? validateCity(String value) {
    if (value.isEmpty) {
      return 'City is required';
    }
    return null;
  }

  String? validateState(String? value) {
    if (value == null || value.isEmpty) {
      return 'State is required';
    }
    return null;
  }

  String? validateZipCode(String? value) {
    if (value == null || value.isEmpty) {
      return 'Zip code is required';
    }
    return null;
  }

  String? validateCountry(String? value) {
    if (value == null || value.isEmpty) {
      return 'Country is required';
    }
    return null;
  }

  String? validatePhoneNumber(String? value) {
    if (_phoneNumber == null || _phoneNumber!.isEmpty) {
      return 'Phone number is required';
    }
    return null;
  }

  String? validateTaxId(String? value) {
    if (value == null || value.isEmpty) {
      return 'Tax identification number is required';
    }
    return null;
  }

  String? validateLicenseNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'License number is required';
    }
    return null;
  }

  Future<void> submitProfile() async {
    _attemptedSubmit = true;
    errorMessage = null;
    successMessage = null;
    notifyListeners();

    // Validate basic forms if available
    if (formKeyPage1.currentState != null && !formKeyPage1.currentState!.validate()) {
      return;
    }
    if (formKeyPage2.currentState != null && !formKeyPage2.currentState!.validate()) {
      return;
    }

    // Require profile picture
    if (profilePictureFile == null && (profilePictureUrl == null || profilePictureUrl!.isEmpty)) {
      errorMessage = 'Profile picture is required';
      notifyListeners();
      return;
    }

    // Require license document (either newly uploaded or existing)
    if (licenseDocumentFile == null && (licenseDocumentUrl == null || licenseDocumentUrl!.isEmpty)) {
      errorMessage = 'License document is required';
      notifyListeners();
      return;
    }

    isSubmitting = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token') ?? '';

      String finalLaboratoryId = laboratoryId;
      if (laboratoryId.isEmpty) {
        finalLaboratoryId = prefs.getString('laboratory_id') ?? '';
      }

      if (finalLaboratoryId.isEmpty) {
        errorMessage = 'Laboratory ID not found. Please login again.';
        isSubmitting = false;
        notifyListeners();
        return;
      }

      final request = http.MultipartRequest(
        'PATCH',
        Uri.parse('${AppConfig.baseUrl}lab/laboratories/$finalLaboratoryId/'),
      );

      request.headers.addAll({
        'Authorization': 'Bearer $accessToken',
      });

      request.fields['contact_person'] = contactPersonController.text;
      request.fields['laboratory_name'] = laboratoryNameController.text;
      request.fields['address_line1'] = addressLine1Controller.text;
      request.fields['city'] = selectedCity ?? cityController.text;
      request.fields['state'] = selectedState ?? stateController.text;
      request.fields['zip_code'] = zipCodeController.text;
      request.fields['country'] = selectedCountry ?? countryController.text;
      request.fields['phone_number'] = _phoneNumber ?? '';
      request.fields['tax_identification_number'] = taxIdentificationNumberController.text;
      request.fields['license_number'] = licenseNumberController.text;
      request.fields['is_profile_complete'] = 'true';
      request.fields['profile_completed'] = 'true';
      request.fields['profile_complete'] = 'true';

      if (profilePictureFile != null) {
        final profilePicture = await http.MultipartFile.fromPath(
          'profile_picture',
          profilePictureFile!.path,
        );
        request.files.add(profilePicture);
      }

      if (licenseDocumentFile != null) {
        final licenseDoc = await http.MultipartFile.fromPath(
          'license_document',
          licenseDocumentFile!.path,
        );
        request.files.add(licenseDoc);
      }

      debugPrint('Sending LAB PATCH: ${request.method} ${request.url}');
      debugPrint('Headers: ${request.headers}');
      debugPrint('Fields: ${request.fields}');

      final client = ChuckerHttpClient(http.Client());
      final streamedResponse = await client.send(request).timeout(const Duration(seconds: 30));
      final responseBody = await streamedResponse.stream.bytesToString();

      debugPrint('LAB PATCH status: ${streamedResponse.statusCode}');
      debugPrint('LAB PATCH body: $responseBody');

      if (streamedResponse.statusCode >= 200 && streamedResponse.statusCode < 300) {
        successMessage = 'Laboratory profile updated successfully!';
        await prefs.setBool('laboratory_profile_completed', true);
        _shouldNavigateToHome = true;
        _initializeChangeTracking();
      } else {
        dynamic decoded;
        try {
          decoded = jsonDecode(responseBody);
        } catch (_) {
          decoded = null;
        }
        final msg = (decoded is Map<String, dynamic>)
            ? (decoded['message']?.toString() ?? decoded['detail']?.toString())
            : null;
        throw Exception(msg ?? 'Failed to update profile: ${streamedResponse.statusCode}');
      }
    } catch (e) {
      errorMessage = 'Error updating profile: $e';
      debugPrint('Error submitting profile: $e');
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }

  void resetNavigation() {
    _shouldNavigateToHome = false;
  }

  String get countryCode => _countryCode;
  String? get initialPhoneNumber => _initialPhoneNumber;

  void updatePhone(String phone) {
    _phoneNumber = phone;
    _checkForChanges();
  }

  void updateCountryCode(String countryCode) {
    _countryCode = countryCode;
    _checkForChanges();
  }

  Future<void> pickProfilePicture(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 80);
    if (pickedFile != null) {
      setProfilePicture(File(pickedFile.path));
    }
  }

  Future<void> pickLicenseDocument(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 80);
    if (pickedFile != null) {
      setLicenseDocument(File(pickedFile.path));
    }
  }

  bool validatePage1() {
    bool isValid = true;
    
    // Validate Laboratory Name
    if (laboratoryNameController.text.isEmpty) {
      setValidationError('laboratoryName', 'Laboratory name is required');
      isValid = false;
    }
    
    // Validate Phone Number
    if (_phoneNumber == null || _phoneNumber!.isEmpty) {
      setValidationError('phoneNumber', 'Phone number is required');
      isValid = false;
    }
    
    // Validate Address
    if (addressLine1Controller.text.isEmpty) {
      setValidationError('address', 'Address is required');
      isValid = false;
    }
    
    // Validate Country
    if (countryController.text.isEmpty) {
      setValidationError('country', 'Country is required');
      isValid = false;
    }
    
    // Validate State
    if (stateController.text.isEmpty) {
      setValidationError('state', 'State is required');
      isValid = false;
    }
    
    // Validate City
    if (cityController.text.isEmpty) {
      setValidationError('city', 'City is required');
      isValid = false;
    }
    
    // Validate Zip Code
    if (zipCodeController.text.isEmpty) {
      setValidationError('zipCode', 'Zip code is required');
      isValid = false;
    }
    
    notifyListeners();
    return isValid;
  }

  void moveToNextPage() {
    if (_currentStep < 2 && validatePage1()) {
      _currentStep++;
      notifyListeners();
    }
  }

  void moveBackToPreviousPage() {
    if (_currentStep > 1) {
      _currentStep--;
      notifyListeners();
    }
  }

  String? getValidationError(String fieldName) {
    return _validationErrors[fieldName];
  }

  void clearValidationError(String fieldName) {
    _validationErrors.remove(fieldName);
    notifyListeners();
  }

  void setValidationError(String fieldName, String error) {
    _validationErrors[fieldName] = error;
    notifyListeners();
  }

  void selectCountry(String? country) {
    selectedCountry = country;
    countryController.text = country ?? '';
    selectedState = null;
    selectedCity = null;
    states = [];
    cities = [];

    if (country != null && country.isNotEmpty) {
      _loadStatesForCountry(country);
      
      // If no states available, auto-populate state with country name
      if (states.isEmpty) {
        selectedState = country;
        stateController.text = country;
        cityController.text = country;
      } else {
        stateController.text = '';
        cityController.text = '';
      }
    } else {
      stateController.text = '';
      cityController.text = '';
    }

    _checkForChanges();
    notifyListeners();
  }

  void selectState(String? state) {
    selectedState = state;
    stateController.text = state ?? '';
    selectedCity = null;
    cities = [];

    if (state != null && state.isNotEmpty && selectedCountry != null) {
      _loadCitiesForState(selectedCountry!, state);
      
      // If no cities available, auto-populate city with state name
      if (cities.isEmpty) {
        selectedCity = state;
        cityController.text = state;
      } else {
        cityController.text = '';
      }
    } else {
      cityController.text = '';
    }

    _checkForChanges();
    notifyListeners();
  }

  void selectCity(String? city) {
    selectedCity = city;
    cityController.text = city ?? '';
    _checkForChanges();
    notifyListeners();
  }

  void _loadStatesForCountry(String countryName) {
    if (!_jsonDataLoaded) {
      debugPrint('JSON data not loaded yet');
      states = [];
      notifyListeners();
      return;
    }

    try {
      List<String> loadedStates = [];
      for (var country in _countriesJsonData) {
        if (country['Country_name'] == countryName) {
          final countryStates = country['states'] as List<dynamic>;
          loadedStates = countryStates.map((s) => s['state_name'] as String).toList();
          break;
        }
      }
      
      states = loadedStates;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading states: $e');
      states = [];
      notifyListeners();
    }
  }

  void _loadCitiesForState(String countryName, String stateName) {
    if (!_jsonDataLoaded) {
      debugPrint('JSON data not loaded yet');
      cities = [];
      notifyListeners();
      return;
    }

    try {
      List<String> loadedCities = [];
      for (var country in _countriesJsonData) {
        if (country['Country_name'] == countryName) {
          final countryStates = country['states'] as List<dynamic>;
          for (var state in countryStates) {
            if (state['state_name'] == stateName) {
              final stateCities = state['cities'] as List<dynamic>;
              loadedCities = stateCities.map((c) => c.toString()).toList();
              break;
            }
          }
          break;
        }
      }
      
      cities = loadedCities;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading cities: $e');
      cities = [];
      notifyListeners();
    }
  }

  List<String> getCountryNames() {
    return countries;
  }

  List<String> getStateNames() {
    return states;
  }

  List<String> getCityNames() {
    return cities;
  }

  void setLicenseDocument1(File file) {
    licenseDocumentFile = file;
    _checkForChanges();
    notifyListeners();
  }

  void setLicenseDocument2(File file) {
    _checkForChanges();
    notifyListeners();
  }

  @override
  void dispose() {
    contactPersonController.dispose();
    emailController.dispose();
    laboratoryNameController.dispose();
    phoneNumberController.dispose();
    addressLine1Controller.dispose();
    cityController.dispose();
    stateController.dispose();
    zipCodeController.dispose();
    countryController.dispose();
    taxIdentificationNumberController.dispose();
    licenseNumberController.dispose();
    super.dispose();
  }
}
