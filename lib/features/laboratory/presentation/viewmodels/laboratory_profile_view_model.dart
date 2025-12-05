import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:chucker_flutter/chucker_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:haticare/core/config/app_config.dart';
import 'package:haticare/core/utils/file_utils.dart';
import 'package:haticare/core/utils/phone_utils.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/phone_number.dart';

class LaboratoryProfileViewModel extends ChangeNotifier {
  LaboratoryProfileViewModel({
    required this.laboratoryId,
    this.openedFromSettings = false,
  }) {
    _initializeProfile();
  }

  final String laboratoryId;
  final bool openedFromSettings;
  BuildContext? _context;

  void setContext(BuildContext context) {
    _context = context;
  }

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
  PhoneNumber? _phoneMeta;
  String _countryCode = '+1';

  // Profile picture
  File? _profilePictureFile;
  String? _profilePicturePath;
  String? _profilePictureName;

  // License documents
  File? _licenseDocumentFile;
  String? _licenseDocumentPath;
  String? _licenseDocumentName;

  // State variables
  bool isLoading = false;
  bool isSubmitting = false;
  String? errorMessage;
  String? successMessage;

  // Getters
  String? get phoneNumber => _phoneNumber;
  String get countryCode => _countryCode;
  File? get profilePictureFile => _profilePictureFile;
  String? get profilePicturePath => _profilePicturePath;
  String? get profilePictureName => _profilePictureName;
  File? get licenseDocumentFile => _licenseDocumentFile;
  String? get licenseDocumentPath => _licenseDocumentPath;
  String? get licenseDocumentName => _licenseDocumentName;

  Future<void> _initializeProfile() async {
    isLoading = true;
    notifyListeners();

    try {
      // Load cached data first
      await _loadCachedData();
      
      // If opened from settings, fetch fresh data
      if (openedFromSettings) {
        await fetchLaboratoryProfile();
      }
    } catch (e) {
      errorMessage = 'Failed to load profile data';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadCachedData() async {
    final prefs = await SharedPreferences.getInstance();
    contactPersonController.text = prefs.getString('laboratory_contact_person') ?? '';
    emailController.text = prefs.getString('laboratory_email') ?? '';
    laboratoryNameController.text = prefs.getString('laboratory_name') ?? '';
    phoneNumberController.text = prefs.getString('laboratory_phone') ?? '';
    addressLine1Controller.text = prefs.getString('laboratory_address_line1') ?? '';
    cityController.text = prefs.getString('laboratory_city') ?? '';
    stateController.text = prefs.getString('laboratory_state') ?? '';
    zipCodeController.text = prefs.getString('laboratory_zip_code') ?? '';
    countryController.text = prefs.getString('laboratory_country') ?? '';
    taxIdentificationNumberController.text = prefs.getString('laboratory_tax_id') ?? '';
    licenseNumberController.text = prefs.getString('laboratory_license_number') ?? '';
    _profilePicturePath = prefs.getString('laboratory_profile_picture_path');
    _licenseDocumentPath = prefs.getString('laboratory_license_document_path');
  }

  Future<void> fetchLaboratoryProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';

    final client = ChuckerHttpClient(http.Client());
    final uri = Uri.parse('${AppConfig.baseUrl}lab/laboratories/$laboratoryId/');

    try {
      final response = await client.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);
        if (decoded['data'] != null) {
          await _populateFormFields(decoded['data']);
        }
      } else {
        throw Exception('Failed to fetch laboratory profile');
      }
    } catch (e) {
      errorMessage = 'Failed to fetch laboratory profile: $e';
      notifyListeners();
    }
  }

  Future<void> _populateFormFields(Map<String, dynamic> data) async {
    contactPersonController.text = data['contact_person'] ?? '';
    emailController.text = data['email'] ?? '';
    laboratoryNameController.text = data['laboratory_name'] ?? '';
    
    // Parse phone number
    if (data['phone_number'] != null) {
      final phoneData = PhoneUtils.parsePhoneNumber(data['phone_number']);
      phoneNumberController.text = phoneData['number'] ?? '';
      _countryCode = phoneData['countryCode'] ?? '+1';
      _phoneNumber = data['phone_number'];
    }

    addressLine1Controller.text = data['address_line1'] ?? '';
    cityController.text = data['city'] ?? '';
    stateController.text = data['state'] ?? '';
    zipCodeController.text = data['zip_code'] ?? '';
    countryController.text = data['country'] ?? '';
    taxIdentificationNumberController.text = data['tax_identification_number'] ?? '';
    licenseNumberController.text = data['license_number'] ?? '';
    
    _profilePicturePath = data['profile_picture'];
    _licenseDocumentPath = data['license_document'];

    // Cache the data
    await _cacheFormData();
  }

  Future<void> _cacheFormData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('laboratory_contact_person', contactPersonController.text);
    await prefs.setString('laboratory_email', emailController.text);
    await prefs.setString('laboratory_name', laboratoryNameController.text);
    await prefs.setString('laboratory_phone', phoneNumberController.text);
    await prefs.setString('laboratory_address_line1', addressLine1Controller.text);
    await prefs.setString('laboratory_city', cityController.text);
    await prefs.setString('laboratory_state', stateController.text);
    await prefs.setString('laboratory_zip_code', zipCodeController.text);
    await prefs.setString('laboratory_country', countryController.text);
    await prefs.setString('laboratory_tax_id', taxIdentificationNumberController.text);
    await prefs.setString('laboratory_license_number', licenseNumberController.text);
    if (_profilePicturePath != null) {
      await prefs.setString('laboratory_profile_picture_path', _profilePicturePath!);
    }
    if (_licenseDocumentPath != null) {
      await prefs.setString('laboratory_license_document_path', _licenseDocumentPath!);
    }
  }

  void updatePhone(PhoneNumber? phone) {
    _phoneMeta = phone;
    if (phone != null) {
      _countryCode = phone.countryCode;
      _phoneNumber = PhoneUtils.normalizePhoneNumber(phone);
    }
    notifyListeners();
  }

  void updateCountryCode(String countryCode) {
    _countryCode = PhoneUtils.normalizeCountryCodeString(countryCode);
    notifyListeners();
  }

  Future<void> pickProfilePicture(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: source, imageQuality: 80);
      
      if (pickedFile != null) {
        _profilePictureFile = File(pickedFile.path);
        _profilePictureName = pickedFile.name;
        notifyListeners();
      }
    } catch (e) {
      errorMessage = 'Failed to pick profile picture: $e';
      notifyListeners();
    }
  }

  Future<void> pickLicenseDocument(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: source, imageQuality: 80);
      
      if (pickedFile != null) {
        _licenseDocumentFile = File(pickedFile.path);
        _licenseDocumentName = pickedFile.name;
        notifyListeners();
      }
    } catch (e) {
      errorMessage = 'Failed to pick license document: $e';
      notifyListeners();
    }
  }

  Future<void> submitProfile() async {
    if (!_validateForm()) return;

    isSubmitting = true;
    errorMessage = null;
    successMessage = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';

      // Create multipart request
      final request = http.MultipartRequest(
        'PATCH',
        Uri.parse('${AppConfig.baseUrl}lab/laboratories/$laboratoryId/'),
      );

      // Add headers
      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Content-Type': 'multipart/form-data',
      });

      // Add form fields
      request.fields['contact_person'] = contactPersonController.text;
      request.fields['email'] = emailController.text;
      request.fields['laboratory_name'] = laboratoryNameController.text;
      request.fields['phone_number'] = _phoneNumber ?? phoneNumberController.text;
      request.fields['address_line1'] = addressLine1Controller.text;
      request.fields['city'] = cityController.text;
      request.fields['state'] = stateController.text;
      request.fields['zip_code'] = zipCodeController.text;
      request.fields['country'] = countryController.text;
      request.fields['tax_identification_number'] = taxIdentificationNumberController.text;
      request.fields['license_number'] = licenseNumberController.text;

      // Add profile picture if selected
      if (_profilePictureFile != null) {
        final profilePicture = await http.MultipartFile.fromPath(
          'profile_picture',
          _profilePictureFile!.path,
          filename: _profilePictureName ?? 'profile_picture.jpg',
        );
        request.files.add(profilePicture);
      }

      // Add license document if selected
      if (_licenseDocumentFile != null) {
        final licenseDocument = await http.MultipartFile.fromPath(
          'license_document',
          _licenseDocumentFile!.path,
          filename: _licenseDocumentName ?? 'license_document.jpg',
        );
        request.files.add(licenseDocument);
      }

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        successMessage = 'Laboratory profile updated successfully!';
        
        // Mark profile as completed
        await prefs.setBool('laboratory_profile_completed', true);
        
        // Cache updated data
        await _cacheFormData();
        
        // Navigate based on context
        if (openedFromSettings) {
          Navigator.pop(_context!);
        } else {
          Navigator.pushReplacementNamed(_context!, '/laboratoryHome');
        }
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to update profile');
      }
    } catch (e) {
      errorMessage = 'Failed to update profile: $e';
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }

  bool _validateForm() {
    if (contactPersonController.text.trim().isEmpty) {
      errorMessage = 'Please enter contact person name';
      notifyListeners();
      return false;
    }

    if (laboratoryNameController.text.trim().isEmpty) {
      errorMessage = 'Please enter laboratory name';
      notifyListeners();
      return false;
    }

    if (phoneNumberController.text.trim().isEmpty) {
      errorMessage = 'Please enter phone number';
      notifyListeners();
      return false;
    }

    if (addressLine1Controller.text.trim().isEmpty) {
      errorMessage = 'Please enter address';
      notifyListeners();
      return false;
    }

    if (cityController.text.trim().isEmpty) {
      errorMessage = 'Please enter city';
      notifyListeners();
      return false;
    }

    if (stateController.text.trim().isEmpty) {
      errorMessage = 'Please enter state';
      notifyListeners();
      return false;
    }

    if (zipCodeController.text.trim().isEmpty) {
      errorMessage = 'Please enter ZIP code';
      notifyListeners();
      return false;
    }

    if (countryController.text.trim().isEmpty) {
      errorMessage = 'Please enter country';
      notifyListeners();
      return false;
    }

    if (taxIdentificationNumberController.text.trim().isEmpty) {
      errorMessage = 'Please enter tax identification number';
      notifyListeners();
      return false;
    }

    if (licenseNumberController.text.trim().isEmpty) {
      errorMessage = 'Please enter license number';
      notifyListeners();
      return false;
    }

    return true;
  }

  void clearError() {
    if (errorMessage != null) {
      errorMessage = null;
      notifyListeners();
    }
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
