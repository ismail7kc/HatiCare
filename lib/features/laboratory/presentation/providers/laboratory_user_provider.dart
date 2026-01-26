import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:chucker_flutter/chucker_flutter.dart';
import '../../../../core/config/app_config.dart';
import '../../../common/shared_prefs_helper.dart';

class LaboratoryUserProvider extends ChangeNotifier {
  String _laboratoryName = '';
  String _profilePictureUrl = '';
  String _contactPerson = '';
  String _licenseNumber = '';
  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _testRequests = [];
  List<dynamic> _completedTestRequests = []; // Backward compatibility
  bool _testRequestsLoading = false;
  bool _isVerifying = false; // Backward compatibility
  String _verifiedRxCode = ''; // Backward compatibility
  bool _isApproved = false;
  String _approvalMessage = '';

  String get laboratoryName => _laboratoryName;
  String get profilePictureUrl => _profilePictureUrl;
  String get contactPerson => _contactPerson;
  String get licenseNumber => _licenseNumber;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<dynamic> get testRequests => _testRequests;
  List<dynamic> get prescriptions => _testRequests; // Backward compatibility
  List<dynamic> get completedTestRequests => _completedTestRequests; // Backward compatibility
  bool get testRequestsLoading => _testRequestsLoading;
  bool get prescriptionsLoading => _testRequestsLoading; // Backward compatibility
  bool get isVerifying => _isVerifying; // Backward compatibility
  String get verifiedRxCode => _verifiedRxCode; // Backward compatibility
  bool get isApproved => _isApproved;
  String get approvalMessage => _approvalMessage;

  LaboratoryUserProvider() {
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      await SaveLoginResponse.loadLoginModel();
      _laboratoryName = SaveLoginResponse.loginData?['laboratory_name'] ?? '';
      notifyListeners();
      fetchProfile();
    } catch (e) {
      // Error loading initial data handled silently
    }
  }

  Future<void> fetchProfile({bool forceRefresh = false}) async {
    try {
      if (forceRefresh) {
        _isLoading = true;
        notifyListeners();
      }

      final prefs = await SharedPreferences.getInstance();
      final laboratoryId = SaveLoginResponse.loginData?['id'] ?? '';
      final accessToken = prefs.getString('access_token') ?? '';

      if (laboratoryId.toString().isEmpty) {
        _isLoading = false;
        notifyListeners();
        return;
      }

      final uri = Uri.parse('${AppConfig.baseUrl}lab/laboratories/$laboratoryId/');
      final cacheBuster = forceRefresh
          ? '?t=${DateTime.now().millisecondsSinceEpoch}'
          : '';
      final finalUri = Uri.parse('$uri$cacheBuster');

      final client = ChuckerHttpClient(http.Client());
      final response = await client
          .get(
            finalUri,
            headers: {
              'Authorization': 'Bearer $accessToken',
              'Content-Type': 'application/json',
              'Cache-Control': 'no-cache',
              'Pragma': 'no-cache',
            },
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final jsonResponse = jsonDecode(response.body);
        dynamic data;
        if (jsonResponse is Map<String, dynamic> &&
            jsonResponse.containsKey('data')) {
          data = jsonResponse['data'];
        } else {
          data = jsonResponse;
        }

        if (data is Map<String, dynamic>) {
          _laboratoryName = data['laboratory_name'] ?? '';
          _profilePictureUrl = data['profile_picture'] ?? '';
          _contactPerson = data['contact_person'] ?? '';
          _licenseNumber = data['license_number'] ?? '';

          _isApproved = (data['is_approved'] == true);

          // Store approval message if present
          if (data.containsKey('approval_message')) {
            _approvalMessage = data['approval_message'] ?? '';
          } else if (data.containsKey('status_message')) {
            _approvalMessage = data['status_message'] ?? '';
          } else if (!_isApproved) {
            _approvalMessage = "Waiting For Admin's Approval";
          } else {
            _approvalMessage = '';
          }

          _errorMessage = null;

          // Update SaveLoginResponse and SharedPreferences
          if (_laboratoryName.isNotEmpty) {
            SaveLoginResponse.loginData?['laboratory_name'] = _laboratoryName;
          }

          if (_profilePictureUrl.isNotEmpty) {
            SaveLoginResponse.loginData?['profile_picture'] = _profilePictureUrl;
          }

          SaveLoginResponse.loginData?['is_approved'] = _isApproved;

          // Save approval status to preferences for offline checking
          await prefs.setBool('laboratory_is_approved', _isApproved);
          await prefs.setString('laboratory_approval_message', _approvalMessage);
        }
      } else {
        _errorMessage = 'Failed to load profile: ${response.statusCode}';
      }
    } catch (e) {
      _errorMessage = 'Error loading profile: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchTestRequests() async {
    try {
      _testRequestsLoading = true;
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token') ?? '';

      if (accessToken.isEmpty) {
        _errorMessage = 'No authentication token found';
        _testRequestsLoading = false;
        notifyListeners();
        return;
      }

      final uri = Uri.parse('${AppConfig.baseUrl}prescriptions/laboratory/list/');
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
        
        if (jsonResponse['results'] != null && 
            jsonResponse['results']['data'] != null) {
          _testRequests = jsonResponse['results']['data'] as List<dynamic>;
        } else if (jsonResponse['data'] != null) {
          _testRequests = jsonResponse['data'] as List<dynamic>;
        } else if (jsonResponse['results'] != null) {
          _testRequests = jsonResponse['results'] as List<dynamic>;
        } else if (jsonResponse['items'] != null) {
          _testRequests = jsonResponse['items'] as List<dynamic>;
        } else if (jsonResponse['test_requests'] != null) {
          _testRequests = jsonResponse['test_requests'] as List<dynamic>;
        } else {
          _testRequests = [];
        }
        
        _errorMessage = null;
      } else {
        _testRequests = [];
        _errorMessage = 'Failed to load test requests: ${response.statusCode}';
      }
    } catch (e) {
      _testRequests = [];
      _errorMessage = 'Error loading test requests: $e';
    } finally {
      _testRequestsLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchPrescriptions() async {
    // Backward compatibility - just call fetchTestRequests
    await fetchTestRequests();
  }

  Future<void> fetchAssignedPrescriptions() async {
    await fetchTestRequests();
  }

  void updateProfilePicture(String newUrl) {
    _profilePictureUrl = newUrl;
    SaveLoginResponse.loginData?['profile_picture'] = newUrl;
    notifyListeners();
  }

  void updateLaboratoryName(String laboratoryName) {
    _laboratoryName = laboratoryName;
    SaveLoginResponse.loginData?['laboratory_name'] = laboratoryName;
    notifyListeners();
  }

  void updateContactPerson(String contactPerson) {
    _contactPerson = contactPerson;
    SaveLoginResponse.loginData?['contact_person'] = contactPerson;
    notifyListeners();
  }

  void clearSearch() {
    _errorMessage = null;
    fetchTestRequests();
  }

  // Backward compatibility methods
  Future<void> acceptPrescription(String statusId) async {
    // Empty implementation for backward compatibility
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> updateTestAvailability(String prescriptionId, bool isAvailable) async {
    // Empty implementation for backward compatibility
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> verifyRxCode(String rxCode) async {
    // Empty implementation for backward compatibility
    _isVerifying = false;
    _errorMessage = null;
    notifyListeners();
  }
}
