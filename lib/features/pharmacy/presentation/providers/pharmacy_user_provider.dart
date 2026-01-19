import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:chucker_flutter/chucker_flutter.dart';
import '../../../../core/config/app_config.dart';

class PharmacyUserProvider extends ChangeNotifier {
  String _pharmacyName = '';
  String _profilePictureUrl = '';
  String _contactPerson = '';
  String _licenseNumber = '';
  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _prescriptions = [];
  bool _prescriptionsLoading = false;
  List<dynamic> _filteredPrescriptions = [];
  String _verifiedRxCode = '';
  bool _isVerifying = false;
  bool _isApproved = false;
  String _approvalMessage = '';

  String get pharmacyName => _pharmacyName;
  String get profilePictureUrl => _profilePictureUrl;
  String get contactPerson => _contactPerson;
  String get licenseNumber => _licenseNumber;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<dynamic> get prescriptions => _verifiedRxCode.isNotEmpty ? _filteredPrescriptions : _prescriptions;
  bool get prescriptionsLoading => _prescriptionsLoading;
  String get verifiedRxCode => _verifiedRxCode;
  bool get isVerifying => _isVerifying;
  bool get isApproved => _isApproved;
  String get approvalMessage => _approvalMessage;

  PharmacyUserProvider() {
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _pharmacyName = prefs.getString('user_first_name') ?? '';
      _profilePictureUrl = prefs.getString('pharmacy_profile_picture_url') ?? '';
      notifyListeners();
      fetchProfile();
    } catch (e) {
      debugPrint('Error loading initial data: $e');
    }
  }

  Future<void> fetchProfile({bool forceRefresh = false}) async {
    try {
      if (forceRefresh) {
        _isLoading = true;
        notifyListeners();
      }

      final prefs = await SharedPreferences.getInstance();
      final pharmacyId = prefs.getString('pharmacy_id') ?? '';
      final accessToken = prefs.getString('access_token') ?? '';

      if (pharmacyId.isEmpty) {
        _isLoading = false;
        notifyListeners();
        return;
      }

      final uri = Uri.parse('${AppConfig.baseUrl}phar/pharmacies/$pharmacyId/');
      final cacheBuster = forceRefresh ? '?t=${DateTime.now().millisecondsSinceEpoch}' : '';
      final finalUri = Uri.parse('$uri$cacheBuster');

      final client = ChuckerHttpClient(http.Client());
      final response = await client.get(
        finalUri,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
          'Cache-Control': 'no-cache',
          'Pragma': 'no-cache',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final jsonResponse = jsonDecode(response.body);
        dynamic data;
        if (jsonResponse is Map<String, dynamic> && jsonResponse.containsKey('data')) {
          data = jsonResponse['data'];
        } else {
          data = jsonResponse;
        }

        if (data is Map<String, dynamic>) {
          _pharmacyName = data['pharmacy_name'] ?? '';
          _profilePictureUrl = data['profile_picture'] ?? '';
          _contactPerson = data['contact_person'] ?? '';
          _licenseNumber = data['license_number'] ?? '';
          
          // Save profile picture URL to SharedPreferences
          if (_profilePictureUrl.isNotEmpty) {
            await prefs.setString('pharmacy_profile_picture_url', _profilePictureUrl);
          }
          
          // Check approval status - multiple field names for compatibility
          _isApproved = (data['is_approved'] == true || 
                        data['approved'] == true || 
                        data['is_approved_by_admin'] == true ||
                        data['pharmacy_approved'] == true);
          
          // Store approval message if present
          if (data.containsKey('approval_message')) {
            _approvalMessage = data['approval_message'] ?? '';
          } else if (data.containsKey('status_message')) {
            _approvalMessage = data['status_message'] ?? '';
          } else if (!_isApproved) {
            _approvalMessage = 'Your pharmacy account is not approved';
          } else {
            _approvalMessage = '';
          }
          
          _errorMessage = null;
          
          if (_pharmacyName.isNotEmpty) {
             await prefs.setString('user_first_name', _pharmacyName);
          }
          
          await prefs.setBool('pharmacy_is_approved', _isApproved);
          await prefs.setString('pharmacy_approval_message', _approvalMessage);
        }
      } else {
        _errorMessage = 'Failed to load profile: ${response.statusCode}';
      }
    } catch (e) {
      _errorMessage = 'Error loading profile: $e';
      debugPrint('Error fetching pharmacy profile: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  void updateProfilePicture(String newUrl) {
    _profilePictureUrl = newUrl;
    notifyListeners();
  }

  Future<void> fetchPrescriptions() async {
    try {
      _prescriptionsLoading = true;
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token') ?? '';

      if (accessToken.isEmpty) {
        _errorMessage = 'No authentication token found';
        _prescriptionsLoading = false;
        notifyListeners();
        return;
      }

      // Check if pharmacy is approved
      final isApproved = prefs.getBool('pharmacy_is_approved') ?? false;
      if (!isApproved) {
        _prescriptions = [];
        _prescriptionsLoading = false;
        _approvalMessage = prefs.getString('pharmacy_approval_message') ?? 'Your pharmacy account is not approved';
        notifyListeners();
        return;
      }

      final uri = Uri.parse('${AppConfig.baseUrl}prescriptions/pharmacy/list');
      final client = ChuckerHttpClient(http.Client());
      final response = await client.get(
        uri,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final jsonResponse = jsonDecode(response.body);
        
        if (jsonResponse is Map<String, dynamic>) {
          if (jsonResponse.containsKey('results') && 
              jsonResponse['results'] is Map<String, dynamic> &&
              jsonResponse['results'].containsKey('data') && 
              jsonResponse['results']['data'] is List) {
            // Handle the actual API response structure: results.data
            _prescriptions = jsonResponse['results']['data'] as List<dynamic>;
          } else if (jsonResponse.containsKey('data') && jsonResponse['data'] is List) {
            _prescriptions = jsonResponse['data'] as List<dynamic>;
          } else if (jsonResponse.containsKey('results') && jsonResponse['results'] is List) {
            _prescriptions = jsonResponse['results'] as List<dynamic>;
          } else {
            _prescriptions = [];
          }
        } else if (jsonResponse is List) {
          _prescriptions = jsonResponse as List<dynamic>;
        } else {
          _prescriptions = [];
        }
        
        _errorMessage = null;
      } else {
        _prescriptions = [];
        _errorMessage = 'Failed to load prescriptions: ${response.statusCode}';
      }
    } catch (e) {
      _prescriptions = [];
      _errorMessage = 'Error loading prescriptions: $e';
      debugPrint('Error fetching prescriptions: $e');
    } finally {
      _prescriptionsLoading = false;
      notifyListeners();
    }
  }

  Future<void> verifyRxCode(String rxCode) async {
    try {
      // Validate RX code length before API call
      if (rxCode.isEmpty) {
        _errorMessage = 'Please enter an RX code';
        notifyListeners();
        return;
      }

      if (rxCode.length < 6) {
        _errorMessage = 'RX code must be at least 6 characters';
        notifyListeners();
        return;
      }

      _isVerifying = true;
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token') ?? '';

      if (accessToken.isEmpty) {
        _errorMessage = 'No authentication token found';
        _isVerifying = false;
        notifyListeners();
        return;
      }

      // Check if pharmacy is approved before verifying
      final isApproved = prefs.getBool('pharmacy_is_approved') ?? false;
      if (!isApproved) {
        _errorMessage = 'Your pharmacy account is not approved';
        _isVerifying = false;
        notifyListeners();
        return;
      }

      final uri = Uri.parse('${AppConfig.baseUrl}prescriptions/pharmacy/verify/');
      final client = ChuckerHttpClient(http.Client());
      final response = await client.post(
        uri,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'rex_code': rxCode}),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final jsonResponse = jsonDecode(response.body);
        
        if (jsonResponse is Map<String, dynamic>) {
          if (jsonResponse.containsKey('data') && jsonResponse['data'] is Map) {
            _filteredPrescriptions = [jsonResponse['data']];
            _verifiedRxCode = rxCode;
            _errorMessage = null;
          } else if (jsonResponse.containsKey('data') && jsonResponse['data'] is List) {
            final dataList = jsonResponse['data'] as List<dynamic>;
            if (dataList.isNotEmpty) {
              _filteredPrescriptions = dataList;
              _verifiedRxCode = rxCode;
              _errorMessage = null;
            } else {
              // Empty list - show all prescriptions
              _filteredPrescriptions = [];
              _verifiedRxCode = '';
              _errorMessage = 'No prescription found for this RX code';
            }
          } else if (jsonResponse.containsKey('detail')) {
            // API returned error message
            _filteredPrescriptions = [];
            _verifiedRxCode = '';
            final errorMessage = jsonResponse['detail']?.toString() ?? 'RX Code not found';
            
            // Check if it's an approval error and update approval status if needed
            if (errorMessage.toLowerCase().contains('approved') || 
                errorMessage.toLowerCase().contains('approval') ||
                errorMessage.toLowerCase().contains('only approved')) {
              _isApproved = false;
              _approvalMessage = errorMessage;
              await prefs.setBool('pharmacy_is_approved', false);
              await prefs.setString('pharmacy_approval_message', errorMessage);
            }
            
            _errorMessage = errorMessage;
          } else {
            _filteredPrescriptions = [jsonResponse];
            _verifiedRxCode = rxCode;
            _errorMessage = null;
          }
        } else if (jsonResponse is List) {
          final dataList = jsonResponse as List<dynamic>;
          if (dataList.isNotEmpty) {
            _filteredPrescriptions = dataList;
            _verifiedRxCode = rxCode;
            _errorMessage = null;
          } else {
            _filteredPrescriptions = [];
            _verifiedRxCode = '';
            _errorMessage = 'No prescription found for this RX code';
          }
        } else {
          _filteredPrescriptions = [];
          _verifiedRxCode = '';
          _errorMessage = 'Invalid response format';
        }
      } else {
        _filteredPrescriptions = [];
        _verifiedRxCode = '';
        if (response.statusCode == 404) {
          _errorMessage = 'RX Code not found';
        } else {
          _errorMessage = 'Error: ${response.statusCode}';
        }
      }
    } catch (e) {
      _filteredPrescriptions = [];
      _verifiedRxCode = '';
      _errorMessage = 'Error verifying RX code: $e';
      debugPrint('Error verifying RX code: $e');
    } finally {
      _isVerifying = false;
      notifyListeners();
    }
  }

  void clearSearch() {
    _verifiedRxCode = '';
    _filteredPrescriptions = [];
    _errorMessage = null;
    fetchPrescriptions();
  }
}
