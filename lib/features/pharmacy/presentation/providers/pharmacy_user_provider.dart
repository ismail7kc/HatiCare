import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:chucker_flutter/chucker_flutter.dart';
import '../../../../core/config/app_config.dart';
import '../../../common/shared_prefs_helper.dart';

class PharmacyUserProvider extends ChangeNotifier {
  String _pharmacyName = '';
  String _profilePictureUrl = '';
  String _contactPerson = '';
  String _licenseNumber = '';
  String _userId = '';
  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _prescriptions = [];
  List<dynamic> _assignedRequests = [];
  List<dynamic> _historyRequests = [];
  bool _prescriptionsLoading = false;
  bool _assignedLoading = false;
  bool _historyLoading = false;
  bool _isApproved = false;
  String _approvalMessage = '';

  String get pharmacyName => _pharmacyName;
  String get profilePictureUrl => _profilePictureUrl;
  String get contactPerson => _contactPerson;
  String get licenseNumber => _licenseNumber;
  String get userId => _userId;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<dynamic> get prescriptions => _prescriptions;
  List<dynamic> get assignedRequests => _assignedRequests;
  List<dynamic> get historyRequests => _historyRequests;
  bool get prescriptionsLoading => _prescriptionsLoading;
  bool get assignedLoading => _assignedLoading;
  bool get historyLoading => _historyLoading;
  bool get isApproved => _isApproved;
  String get approvalMessage => _approvalMessage;

  PharmacyUserProvider() {
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
      await SaveLoginResponse.loadLoginModel();
      _pharmacyName = SaveLoginResponse.loginData?['pharmacy_name'] ?? '';
      
      // Load user ID from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      _userId = prefs.getString('pharmacy_id') ?? '';
      
      notifyListeners();
      fetchProfile();
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

      final uri = Uri.parse('${AppConfig.baseUrl}prescriptions/pharmacy/list/');
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
          _prescriptions = jsonResponse['results']['data'] as List<dynamic>;
        } else if (jsonResponse['data'] != null) {
          _prescriptions = jsonResponse['data'] as List<dynamic>;
        } else if (jsonResponse['results'] != null) {
          _prescriptions = jsonResponse['results'] as List<dynamic>;
        } else if (jsonResponse['items'] != null) {
          _prescriptions = jsonResponse['items'] as List<dynamic>;
        } else if (jsonResponse['prescriptions'] != null) {
          _prescriptions = jsonResponse['prescriptions'] as List<dynamic>;
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
    } finally {
      _prescriptionsLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchAssignedPrescriptions() async {
    try {
      _assignedLoading = true;
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token') ?? '';

      if (accessToken.isEmpty) {
        _assignedLoading = false;
        notifyListeners();
        return;
      }

      final uri = Uri.parse('${AppConfig.baseUrl}prescriptions/pharmacy/assigned/?status=assigned');
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
          _assignedRequests = jsonResponse['results']['data'] as List<dynamic>;
        } else if (jsonResponse['data'] != null) {
          _assignedRequests = jsonResponse['data'] as List<dynamic>;
        } else {
          _assignedRequests = [];
        }
      } else {
        _assignedRequests = [];
      }
    } catch (e) {
      _assignedRequests = [];
    } finally {
      _assignedLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchHistory() async {
    try {
      _historyLoading = true;
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token') ?? '';

      if (accessToken.isEmpty) {
        _historyLoading = false;
        notifyListeners();
        return;
      }

      final uri = Uri.parse('${AppConfig.baseUrl}prescriptions/pharmacy/history/?state=completed');
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
          _historyRequests = jsonResponse['results']['data'] as List<dynamic>;
        } else if (jsonResponse['data'] != null) {
          _historyRequests = jsonResponse['data'] as List<dynamic>;
        } else {
          _historyRequests = [];
        }
      } else {
        _historyRequests = [];
      }
    } catch (e) {
      _historyRequests = [];
    } finally {
      _historyLoading = false;
      notifyListeners();
    }
  }


  Future<void> fetchProfile({bool forceRefresh = false}) async {
    try {
      if (forceRefresh) {
        _isLoading = true;
        notifyListeners();
      }

      final prefs = await SharedPreferences.getInstance();
      final pharmacyId = SaveLoginResponse.loginData?['id'] ?? '';
      final accessToken = prefs.getString('access_token') ?? '';

      if (pharmacyId.toString().isEmpty) {
        _isLoading = false;
        notifyListeners();
        return;
      }

      final uri = Uri.parse('${AppConfig.baseUrl}phar/pharmacies/$pharmacyId/');
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
          _pharmacyName = data['pharmacy_name'] ?? '';
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
          if (_pharmacyName.isNotEmpty) {
            SaveLoginResponse.loginData?['pharmacy_name'] = _pharmacyName;
          }

          if (_profilePictureUrl.isNotEmpty) {
            SaveLoginResponse.loginData?['profile_picture'] = _profilePictureUrl;
          }

          SaveLoginResponse.loginData?['is_approved'] = _isApproved;

          // Save approval status to preferences for offline checking
          await prefs.setBool('pharmacy_is_approved', _isApproved);
          await prefs.setString('pharmacy_approval_message', _approvalMessage);
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


  void updateProfilePicture(String newUrl) {
    _profilePictureUrl = newUrl;
    SaveLoginResponse.loginData?['profile_picture'] = newUrl;
    notifyListeners();
  }

  void updatePharmacyName(String pharmacyName) {
    _pharmacyName = pharmacyName;
    SaveLoginResponse.loginData?['pharmacy_name'] = pharmacyName;
    notifyListeners();
  }

  void updateContactPerson(String contactPerson) {
    _contactPerson = contactPerson;
    SaveLoginResponse.loginData?['contact_person'] = contactPerson;
    notifyListeners();
  }

  void clearSearch() {
    _errorMessage = null;
    fetchPrescriptions();
  }

  /// Handle WebSocket updates by directly updating the prescription list
  /// This avoids unnecessary API calls and provides instant UI updates
  void handleWebSocketUpdate(Map<String, dynamic> wsData) {
    try {
      final type = wsData['type'] as String?;
      final data = wsData['data'] as List<dynamic>?;
      
      if (data == null || data.isEmpty) return;
      
      final newPrescription = data[0] as Map<String, dynamic>;
      final statusId = newPrescription['status_id'];
      
      if (type == 'initial_item') {
        // Initial items are already loaded, skip
        return;
      } else if (type == 'update_request') {
        // Find and update existing prescription, or add if new
        final index = _prescriptions.indexWhere(
          (p) => p is Map && p['status_id'] == statusId
        );
        
        if (index != -1) {
          _prescriptions[index] = newPrescription;
        } else {
          // New prescription, add to the beginning of the list
          _prescriptions.insert(0, newPrescription);
        }
        
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error handling WebSocket update: $e');
    }
  }
}
