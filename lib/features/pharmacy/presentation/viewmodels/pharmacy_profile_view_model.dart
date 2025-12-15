import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl_phone_field/phone_number.dart';
import 'package:chucker_flutter/chucker_flutter.dart';

import '../../../../core/config/app_config.dart';

class PharmacyProfileViewModel extends ChangeNotifier {
  final pharmacyNameController = TextEditingController();
  final addressLine1Controller = TextEditingController();
  final cityController = TextEditingController();
  final stateController = TextEditingController();
  final zipCodeController = TextEditingController();
  final countryController = TextEditingController();

  final contactPersonController = TextEditingController();
  final emailController = TextEditingController();
  final phoneNumberController = TextEditingController();
  String? _phoneNumber;
  String _countryCode = 'US';
  String? _initialPhoneNumber; // Store initial phone for IntlPhoneField

  final taxIdController = TextEditingController();
  final licenseNumberController = TextEditingController();

  File? profilePicture;
  File? licenseDocument1;
  File? licenseDocument2;

  String? profilePictureUrl;
  String? licenseDocument1Url;
  String? licenseDocument2Url;

  int currentStep = 1;
  bool isSubmitting = false;
  bool isLoading = true;
  String? errorMessage;
  String? successMessage;
  bool _shouldNavigateToHome = false;
  bool _attemptedSubmit = false;

  final String pharmacyId;
  final bool openedFromSettings;
  final GlobalKey<FormState> formKeyPage1 = GlobalKey<FormState>();
  final GlobalKey<FormState> formKeyPage2 = GlobalKey<FormState>();

  // Country/State/City data
  List<Map<String, dynamic>> countries = [];
  List<Map<String, dynamic>> states = [];
  List<String> cities = [];
  bool isCountriesLoading = true;
  
  String? selectedCountry;
  String? selectedState;
  String? selectedCity;
  
  // Validation error management
  final Map<String, String?> _validationErrors = {};

  // Change tracking
  late Map<String, String> _initialValues;
  bool _hasChanges = false;

  bool get hasChanges => _hasChanges;
  bool get attemptedSubmit => _attemptedSubmit;

  PharmacyProfileViewModel({
    required this.pharmacyId,
    this.openedFromSettings = false,
  }) {
    isLoading = openedFromSettings; // Only show loader if opened from settings
    _addTextControllerListeners();
    _initialize();
  }

  void _addTextControllerListeners() {
    pharmacyNameController.addListener(_checkForChanges);
    addressLine1Controller.addListener(_checkForChanges);
    cityController.addListener(_checkForChanges);
    stateController.addListener(_checkForChanges);
    zipCodeController.addListener(_checkForChanges);
    countryController.addListener(_checkForChanges);
    taxIdController.addListener(_checkForChanges);
    licenseNumberController.addListener(_checkForChanges);
  }

  Future<void> _initialize() async {
    await _loadCountriesData();
    await _initializeProfile();
  }

  Future<void> _loadCountriesData() async {
    try {
      final jsonString = await rootBundle.loadString('assets/json/countries.json');
      final jsonData = jsonDecode(jsonString) as List;
      countries = List<Map<String, dynamic>>.from(jsonData);
      debugPrint('Loaded ${countries.length} countries');
    } catch (e) {
      debugPrint('Error loading countries data: $e');
    } finally {
      isCountriesLoading = false;
      notifyListeners();
    }
  }

  Future<void> _initializeProfile() async {
    await _loadPharmacyData();
    if (openedFromSettings) {
      await fetchPharmacyProfile();
    } else {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadPharmacyData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final firstName = prefs.getString('user_first_name') ?? '';
      final userEmail = prefs.getString('user_email') ?? '';
      final phoneNumber = prefs.getString('user_phone_number') ?? '';

      contactPersonController.text = firstName;
      emailController.text = userEmail;

      if (phoneNumber.isNotEmpty) {
        final parsedPhone = _parsePhoneNumber(phoneNumber);
        final countryCode = parsedPhone['countryCode'] ?? 'US';
        final numberOnly = parsedPhone['number'] ?? '';

        _initialPhoneNumber = numberOnly;
        _phoneNumber = phoneNumber;
        _countryCode = countryCode;
      }

      // Initialize change tracking after loading data
      _initializeChangeTracking();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading pharmacy data: $e');
    }
  }

  void _initializeChangeTracking() {
    _initialValues = {
      'pharmacyName': pharmacyNameController.text,
      'addressLine1': addressLine1Controller.text,
      'city': cityController.text,
      'state': stateController.text,
      'zipCode': zipCodeController.text,
      'country': countryController.text,
      'contactPerson': contactPersonController.text,
      'email': emailController.text,
      'phoneNumber': _phoneNumber ?? '',
      'taxId': taxIdController.text,
      'licenseNumber': licenseNumberController.text,
    };
    _hasChanges = false;
  }

  void _checkForChanges() {
    final currentValues = {
      'pharmacyName': pharmacyNameController.text,
      'addressLine1': addressLine1Controller.text,
      'city': cityController.text,
      'state': stateController.text,
      'zipCode': zipCodeController.text,
      'country': countryController.text,
      'contactPerson': contactPersonController.text,
      'email': emailController.text,
      'phoneNumber': _phoneNumber ?? '',
      'taxId': taxIdController.text,
      'licenseNumber': licenseNumberController.text,
    };

    _hasChanges = currentValues != _initialValues;
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

    debugPrint('Parsed Phone - Country: $countryCode, Number: $numberOnly, Original: $phoneNumber');

    return {
      'countryCode': countryCode,
      'number': numberOnly,
    };
  }

  Future<void> fetchPharmacyProfile({bool forceRefresh = false}) async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token') ?? '';

      String finalPharmacyId = pharmacyId;
      if (pharmacyId.isEmpty) {
        finalPharmacyId = prefs.getString('pharmacy_id') ?? '';
      }

      if (finalPharmacyId.isEmpty) {
        errorMessage = 'Pharmacy ID not found. Please login again.';
        isLoading = false;
        notifyListeners();
        return;
      }

      final uri = Uri.parse('${AppConfig.baseUrl}phar/pharmacies/$finalPharmacyId/');

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
    } on TimeoutException {
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

        final pharmacyName = data['pharmacy_name'] ?? '';
        pharmacyNameController.text = pharmacyName;
        debugPrint('pharmacy_name: $pharmacyName');

        final addressLine1 = data['address_line1'] ?? '';
        addressLine1Controller.text = addressLine1;
        debugPrint('address_line1: $addressLine1');

        final country = data['country'] ?? '';
        if (country.isNotEmpty) {
          // Check if country exists in the list
          final countryExists = countries.any((c) => c['Country_name'] == country);
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

        // Populate contact person from API response
        final contactPerson = data['contact_person'] ?? '';
        if (contactPerson.isNotEmpty) {
          contactPersonController.text = contactPerson;
          debugPrint('contact_person: $contactPerson');
        }

        // Populate email from API response
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
          
          // Don't set phoneNumberController.text, let IntlPhoneField handle formatting
          _initialPhoneNumber = numberOnly;
          _phoneNumber = phoneNumber; // Keep full number with code
          _countryCode = countryCode; // Store country code for IntlPhoneField
          
          debugPrint('phone_number: $phoneNumber');
          debugPrint('Parsed - Country: $countryCode, Number: $numberOnly');
        }

        // Populate Page 2 fields
        final taxId = data['tax_identification_number'] ?? '';
        taxIdController.text = taxId;
        debugPrint('tax_identification_number: $taxId');

        final licenseNumber = data['license_number'] ?? '';
        licenseNumberController.text = licenseNumber;
        debugPrint('license_number: $licenseNumber');

        // Load profile picture URL (if available)
        final profilePictureUrlValue = data['profile_picture'];
        if (profilePictureUrlValue != null && profilePictureUrlValue.toString().isNotEmpty) {
          profilePictureUrl = profilePictureUrlValue.toString();
          debugPrint('profile_picture URL: $profilePictureUrl');
        }

        // Load license documents URLs (if available)
        final licenseDoc1UrlValue = data['license_document'];
        if (licenseDoc1UrlValue != null && licenseDoc1UrlValue.toString().isNotEmpty) {
          licenseDocument1Url = licenseDoc1UrlValue.toString();
          debugPrint('license_document URL: $licenseDocument1Url');
        }

        final licenseDoc2UrlValue = data['license_document_2'];
        if (licenseDoc2UrlValue != null && licenseDoc2UrlValue.toString().isNotEmpty) {
          licenseDocument2Url = licenseDoc2UrlValue.toString();
          debugPrint('license_document_2 URL: $licenseDocument2Url');
        }

        debugPrint('Form fields populated successfully');
        
        // Reinitialize change tracking after populating all fields
        _initializeChangeTracking();
        notifyListeners(); // Notify listeners after populating fields
      } else {
        debugPrint('Data is not a Map: ${data.runtimeType}');
      }
    } catch (e) {
      debugPrint('Error populating form fields: $e');
    }
  }

  void setProfilePicture(File? file) {
    profilePicture = file;
    notifyListeners();
  }

  void setLicenseDocument1(File? file) {
    licenseDocument1 = file;
    notifyListeners();
  }

  void setLicenseDocument2(File? file) {
    licenseDocument2 = file;
    notifyListeners();
  }

  void selectCountry(String? countryName) {
    if (countryName == null) return;
    
    selectedCountry = countryName;
    selectedState = null;
    selectedCity = null;
    states = [];
    cities = [];
    
    // Find the country and load its states
    final country = countries.firstWhere(
      (c) => c['Country_name'] == countryName,
      orElse: () => {},
    );
    
    if (country.isNotEmpty && country['states'] != null) {
      states = List<Map<String, dynamic>>.from(country['states']);
    }
    
    countryController.text = countryName;
    
    // If no states available, auto-populate state with country name
    if (states.isEmpty) {
      selectedState = countryName;
      stateController.text = countryName;
      cityController.text = countryName;
    } else {
      stateController.clear();
      cityController.clear();
    }
    
    notifyListeners();
  }

  void selectState(String? stateName) {
    if (stateName == null || selectedCountry == null) return;
    
    selectedState = stateName;
    selectedCity = null;
    cities = [];
    
    // Find the state and load its cities
    final state = states.firstWhere(
      (s) => s['state_name'] == stateName,
      orElse: () => {},
    );
    
    if (state.isNotEmpty && state['cities'] != null) {
      final citiesList = state['cities'] as List<dynamic>;
      cities = citiesList.map((c) => c.toString()).toList();
    }
    
    stateController.text = stateName;
    
    // If no cities available, auto-populate city with state name
    if (cities.isEmpty) {
      selectedCity = stateName;
      cityController.text = stateName;
    } else {
      cityController.clear();
    }
    
    notifyListeners();
  }

  void selectCity(String? cityName) {
    if (cityName == null) return;
    
    selectedCity = cityName;
    cityController.text = cityName;
    notifyListeners();
  }

  List<String> getCountryNames() {
    return countries.map((c) => c['Country_name'] as String).toList();
  }

  List<String> getStateNames() {
    return states.map((s) => s['state_name'] as String).toList();
  }

  List<String> getCityNames() {
    return cities;
  }

  String? validatePharmacyName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Pharmacy name is required';
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
      return 'Please select a city';
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

  /// Get the current country code for IntlPhoneField
  String get countryCode => _countryCode;

  /// Get the initial phone number for IntlPhoneField
  String? get initialPhoneNumber => _initialPhoneNumber;

  void updatePhoneNumber(PhoneNumber? phoneNumber) {
    if (phoneNumber != null) {
      _phoneNumber = phoneNumber.completeNumber;
      _countryCode = phoneNumber.countryISOCode ?? 'US';
    } else {
      _phoneNumber = null;
    }
  }

  String? validatePhoneNumber(String? value) {
    if (_phoneNumber == null || _phoneNumber!.isEmpty) {
      return 'Phone number is required';
    }
    // You can add more specific validation if needed
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
    _attemptedSubmit = true;
    notifyListeners();
    
    // Validate all fields and show errors if any
    if (!validateAllFields()) {
      return;
    }
    
    if (!formKeyPage2.currentState!.validate()) {
      return;
    }

    // Check if profile picture exists (either newly uploaded or from API)
    if (profilePicture == null && (profilePictureUrl == null || profilePictureUrl!.isEmpty)) {
      errorMessage = 'Profile picture is required';
      notifyListeners();
      return;
    }

    // Check if license document exists (either newly uploaded or from API)
    if (licenseDocument1 == null && (licenseDocument1Url == null || licenseDocument1Url!.isEmpty)) {
      errorMessage = 'License document is required';
      notifyListeners();
      return;
    }

    isSubmitting = true;
    errorMessage = null;
    successMessage = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token') ?? '';

      // Get pharmacyId from SharedPreferences if empty
      String finalPharmacyId = pharmacyId;
      if (pharmacyId.isEmpty) {
        finalPharmacyId = prefs.getString('pharmacy_id') ?? '';
      }
      

      if (finalPharmacyId.isEmpty) {
        errorMessage = 'Pharmacy ID not found. Please login again.';
        notifyListeners();
        return;
      }
      
      final uri = Uri.parse('${AppConfig.baseUrl}phar/pharmacies/$finalPharmacyId/');
      final request = http.MultipartRequest('PATCH', uri);

      // Add headers
      request.headers['Authorization'] = 'Bearer $accessToken';

      // Add form fields
      request.fields['pharmacy_name'] = pharmacyNameController.text;
      request.fields['address_line1'] = addressLine1Controller.text;
      request.fields['city'] = cityController.text;
      request.fields['state'] = stateController.text;
      request.fields['zip_code'] = zipCodeController.text;
      request.fields['country'] = countryController.text;
      request.fields['phone_number'] = _phoneNumber ?? phoneNumberController.text;
      request.fields['tax_identification_number'] = taxIdController.text;
      request.fields['license_number'] = licenseNumberController.text;
      // Mark profile as completed
      request.fields['is_profile_complete'] = 'true';
      request.fields['profile_completed'] = 'true';
      request.fields['profile_complete'] = 'true';

      // Add files
      if (profilePicture != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'profile_picture',
            profilePicture!.path,
          ),
        );
      }

      if (licenseDocument1 != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'license_document',
            licenseDocument1!.path,
          ),
        );
      }

      if (licenseDocument2 != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'license_document_2',
            licenseDocument2!.path,
          ),
        );
      }

      debugPrint('Sending request to: ${uri.toString()}');
      debugPrint('Headers: ${request.headers}');
      debugPrint('Fields: ${request.fields}');
      
      // Use ChuckerHttpClient to intercept the request
      final client = ChuckerHttpClient(http.Client());
      
      try {
        final response = await client.send(request).timeout(const Duration(seconds: 30));
        final responseBody = await response.stream.bytesToString();
        
        debugPrint('Response status: ${response.statusCode}');
        debugPrint('Response body: $responseBody');

        if (response.statusCode >= 200 && response.statusCode < 300) {
          successMessage = 'Profile updated successfully';
          _shouldNavigateToHome = true;
          await prefs.setBool('pharmacy_profile_completed', true);
        } else {
          errorMessage = 'Failed to update profile: ${response.statusCode}\n$responseBody';
        }
      } on SocketException catch (e) {
        errorMessage = 'Network error: ${e.message}. Please check your internet connection and try again.';
        debugPrint('SocketException: $e');
      } on TimeoutException {
        errorMessage = 'Request timed out. The server is taking too long to respond.';
      } catch (e) {
        errorMessage = 'An unexpected error occurred: $e';
        debugPrint('Unexpected error: $e');
      }
    } catch (e) {
      errorMessage = 'Error updating profile: ${e.toString()}';
      debugPrint('Exception: $e');
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }

  bool get shouldNavigateToHome => _shouldNavigateToHome;

  void resetNavigation() {
    _shouldNavigateToHome = false;
  }

  // Validation error management methods
  void setValidationError(String field, String? error) {
    _validationErrors[field] = error;
    notifyListeners();
  }

  void clearValidationError(String field) {
    if (_validationErrors.containsKey(field)) {
      _validationErrors[field] = null;
      notifyListeners();
    }
  }

  String? getValidationError(String field) {
    return _validationErrors[field];
  }

  void clearAllValidationErrors() {
    _validationErrors.clear();
    notifyListeners();
  }

  // Validate all fields and set errors
  bool validateAllFields() {
    clearAllValidationErrors();
    bool hasErrors = false;

    // Validate country
    final countryError = validateCountry(countryController.text);
    if (countryError != null) {
      setValidationError('country', countryError);
      hasErrors = true;
    }

    // Validate state
    final stateError = validateState(stateController.text);
    if (stateError != null) {
      setValidationError('state', stateError);
      hasErrors = true;
    }

    // Validate city
    final cityError = validateCity(cityController.text);
    if (cityError != null) {
      setValidationError('city', cityError);
      hasErrors = true;
    }

    // Validate other required fields
    if (pharmacyNameController.text.isEmpty) {
      setValidationError('pharmacyName', 'Pharmacy name is required');
      hasErrors = true;
    }

    if (addressLine1Controller.text.isEmpty) {
      setValidationError('address', 'Address is required');
      hasErrors = true;
    }

    if (zipCodeController.text.isEmpty) {
      setValidationError('zipCode', 'Zip code is required');
      hasErrors = true;
    }

    return !hasErrors;
  }

  @override
  void dispose() {
    pharmacyNameController.dispose();
    addressLine1Controller.dispose();
    cityController.dispose();
    stateController.dispose();
    zipCodeController.dispose();
    countryController.dispose();
    contactPersonController.dispose();
    emailController.dispose();
    phoneNumberController.dispose();
    taxIdController.dispose();
    super.dispose();
  }
}
