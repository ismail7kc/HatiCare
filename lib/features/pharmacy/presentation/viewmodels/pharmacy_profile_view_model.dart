import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
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

  final String pharmacyId;
  final bool openedFromSettings;
  final GlobalKey<FormState> formKeyPage1 = GlobalKey<FormState>();
  final GlobalKey<FormState> formKeyPage2 = GlobalKey<FormState>();

  PharmacyProfileViewModel({
    required this.pharmacyId,
    this.openedFromSettings = false,
  }) {
    _initializeProfile();
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

        // Don't set phoneNumberController.text, let IntlPhoneField handle formatting
        _initialPhoneNumber = numberOnly;
        _phoneNumber = phoneNumber;
        _countryCode = countryCode;
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading pharmacy data: $e');
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

    // Remove all formatting characters (spaces, parentheses, hyphens, etc.) except + and digits
    String cleanedNumber = phoneNumber.replaceAll(RegExp(r'[^+\d]'), '');

    for (final entry in countryCodeMap.entries) {
      if (cleanedNumber.startsWith(entry.key)) {
        countryCode = entry.value;
        // Remove country code and keep only digits
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

        final city = data['city'] ?? '';
        cityController.text = city;
        debugPrint('city: $city');

        final state = data['state'] ?? '';
        stateController.text = state;
        debugPrint('state: $state');

        final zipCode = data['zip_code'] ?? '';
        zipCodeController.text = zipCode;
        debugPrint('zip_code: $zipCode');

        final country = data['country'] ?? '';
        countryController.text = country;
        debugPrint('country: $country');

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

  String? validateCity(String? value) {
    if (value == null || value.isEmpty) {
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
    if (!formKeyPage2.currentState!.validate()) {
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
