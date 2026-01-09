import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:chucker_flutter/chucker_flutter.dart';
import '../../../../core/config/app_config.dart';

class LaboratoryUserProvider extends ChangeNotifier {
  String _laboratoryName = '';
  String _profilePictureUrl = '';
  String _contactPerson = '';
  String _licenseNumber = '';
  String _email = '';
  bool _isLoading = true;
  String? _errorMessage;
  bool _profileCompleted = false;
  List<dynamic> _testRequests = [];
  List<dynamic> _completedTestRequests = [];
  List<dynamic> _filteredTestRequests = [];
  List<dynamic> _prescriptions = [];
  bool _prescriptionsLoading = false;
  String _verifiedRxCode = '';
  bool _isVerifying = false;
  bool _isApproved = true;
  String _approvalMessage = '';

  bool get isLoading => _isLoading;
  String get laboratoryName => _laboratoryName;
  String get email => _email;
  String get profilePictureUrl => _profilePictureUrl;
  String get contactPerson => _contactPerson;
  String get licenseNumber => _licenseNumber;
  bool get profileCompleted => _profileCompleted;
  List<dynamic> get testRequests => _verifiedRxCode.isNotEmpty ? _filteredTestRequests : _testRequests;
  List<dynamic> get completedTestRequests => _completedTestRequests;
  List<dynamic> get prescriptions => _prescriptions;
  bool get prescriptionsLoading => _prescriptionsLoading;
  String? get errorMessage => _errorMessage;
  String get verifiedRxCode => _verifiedRxCode;
  bool get isVerifying => _isVerifying;
  bool get isApproved => _isApproved;
  String get approvalMessage => _approvalMessage;

  LaboratoryUserProvider() {
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _laboratoryName = prefs.getString('user_first_name') ?? '';
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
      final laboratoryId = prefs.getString('laboratory_id') ?? '';
      final accessToken = prefs.getString('access_token') ?? '';

      if (laboratoryId.isEmpty) {
        _isLoading = false;
        notifyListeners();
        return;
      }

      final uri = Uri.parse('${AppConfig.baseUrl}lab/laboratories/$laboratoryId/');
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
          _laboratoryName = data['laboratory_name'] ?? '';
          _profilePictureUrl = data['profile_picture'] ?? '';
          _contactPerson = data['contact_person'] ?? '';
          _licenseNumber = data['license_number'] ?? '';
          _email = data['email'] ?? '';
          _profileCompleted = data['is_profile_complete'] ?? false;

          _isApproved = (data['is_approved'] == true ||
                        data['approved'] == true ||
                        data['is_approved_by_admin'] == true ||
                        data['laboratory_approved'] == true);

          if (data.containsKey('approval_message')) {
            _approvalMessage = data['approval_message'] ?? '';
          } else if (data.containsKey('status_message')) {
            _approvalMessage = data['status_message'] ?? '';
          } else if (!_isApproved) {
            _approvalMessage = 'Your laboratory account is not approved';
          } else {
            _approvalMessage = '';
          }

          _errorMessage = null;

          if (_laboratoryName.isNotEmpty) {
            await prefs.setString('user_first_name', _laboratoryName);
          }

          if (_profilePictureUrl.isNotEmpty) {
            await prefs.setString('profile_picture_url', _profilePictureUrl);
          }

          if (_email.isNotEmpty) {
            await prefs.setString('email', _email);
          }

          await prefs.setBool('laboratory_profile_completed', _profileCompleted);

          await prefs.setBool('laboratory_is_approved', _isApproved);
          await prefs.setString('laboratory_approval_message', _approvalMessage);
        }
      } else {
        _errorMessage = 'Failed to load profile: ${response.statusCode}';
      }
    } catch (e) {
      _errorMessage = 'Error loading profile: $e';
      debugPrint('Error fetching laboratory profile: $e');
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

      // Check if laboratory is approved
      final isApproved = prefs.getBool('laboratory_is_approved') ?? false;
      if (!isApproved) {
        _prescriptions = [];
        _prescriptionsLoading = false;
        _approvalMessage = prefs.getString('laboratory_approval_message') ?? 'Your laboratory account is not approved';
        notifyListeners();
        return;
      }

      final uri = Uri.parse('${AppConfig.baseUrl}prescriptions/laboratory/list');
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
            // Handle actual API response structure: results.data
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

  Future<void> fetchAssignedPrescriptions() async {
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

      // Check if laboratory is approved
      final isApproved = prefs.getBool('laboratory_is_approved') ?? false;
      if (!isApproved) {
        _prescriptions = [];
        _prescriptionsLoading = false;
        _approvalMessage = prefs.getString('laboratory_approval_message') ?? 'Your laboratory account is not approved';
        notifyListeners();
        return;
      }

      final uri = Uri.parse('${AppConfig.baseUrl}prescriptions/laboratory/assigned/');
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
            // Handle actual API response structure: results.data
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
        _errorMessage = 'Failed to load assigned prescriptions: ${response.statusCode}';
      }
    } catch (e) {
      _prescriptions = [];
      _errorMessage = 'Error loading assigned prescriptions: $e';
      debugPrint('Error fetching assigned prescriptions: $e');
    } finally {
      _prescriptionsLoading = false;
      notifyListeners();
    }
  }

  Future<void> acceptPrescription(String statusId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token') ?? '';

      if (accessToken.isEmpty) {
        _errorMessage = 'No authentication token found';
        notifyListeners();
        return;
      }

      final uri = Uri.parse('${AppConfig.baseUrl}prescriptions/laboratory/$statusId/accept/');
      final client = ChuckerHttpClient(http.Client());
      final response = await client.post(
        uri,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        _errorMessage = null;
        // Show success message
        debugPrint('Prescription accepted successfully');
      } else {
        _errorMessage = 'Failed to accept prescription: ${response.statusCode}';
      }
    } catch (e) {
      _errorMessage = 'Error accepting prescription: $e';
      debugPrint('Error accepting prescription: $e');
    } finally {
      notifyListeners();
    }
  }

  Future<void> updateTestAvailability(String prescriptionId, bool isAvailable) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token') ?? '';

      if (accessToken.isEmpty) {
        _errorMessage = 'No authentication token found';
        notifyListeners();
        return;
      }

      final uri = Uri.parse('${AppConfig.baseUrl}prescriptions/laboratory/$prescriptionId/availability/');
      final client = ChuckerHttpClient(http.Client());
      final response = await client.patch(
        uri,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'is_available': isAvailable,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Update local state
        final prescriptionIndex = _prescriptions.indexWhere(
          (p) => p['prescription_id']?.toString() == prescriptionId
        );
        if (prescriptionIndex != -1) {
          _prescriptions[prescriptionIndex]['is_available'] = isAvailable;
        }
        _errorMessage = null;
      } else {
        _errorMessage = 'Failed to update test availability: ${response.statusCode}';
      }
    } catch (e) {
      _errorMessage = 'Error updating test availability: $e';
      debugPrint('Error updating test availability: $e');
    } finally {
      notifyListeners();
    }
  }

  Future<void> verifyRxCode(String rxCode) async {
    try {
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

      final isApproved = prefs.getBool('laboratory_is_approved') ?? false;
      if (!isApproved) {
        _errorMessage = 'Your laboratory account is not approved';
        _isVerifying = false;
        notifyListeners();
        return;
      }

      final uri = Uri.parse('${AppConfig.baseUrl}lab/test-requests/verify/');
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
            _filteredTestRequests = [jsonResponse['data']];
            _verifiedRxCode = rxCode;
            _errorMessage = null;
          } else if (jsonResponse.containsKey('data') && jsonResponse['data'] is List) {
            final dataList = jsonResponse['data'] as List<dynamic>;
            if (dataList.isNotEmpty) {
              _filteredTestRequests = dataList;
              _verifiedRxCode = rxCode;
              _errorMessage = null;
            } else {
              _filteredTestRequests = [];
              _verifiedRxCode = '';
              _errorMessage = 'No test request found for this RX code';
            }
          } else if (jsonResponse.containsKey('detail')) {
            _filteredTestRequests = [];
            _verifiedRxCode = '';
            final errorMessage = jsonResponse['detail']?.toString() ?? 'RX Code not found';

            if (errorMessage.toLowerCase().contains('approved') ||
                errorMessage.toLowerCase().contains('approval') ||
                errorMessage.toLowerCase().contains('only approved')) {
              _isApproved = false;
              _approvalMessage = errorMessage;
              await prefs.setBool('laboratory_is_approved', false);
              await prefs.setString('laboratory_approval_message', errorMessage);
            }

            _errorMessage = errorMessage;
          } else {
            _filteredTestRequests = [jsonResponse];
            _verifiedRxCode = rxCode;
            _errorMessage = null;
          }
        } else if (jsonResponse is List) {
          final dataList = jsonResponse as List<dynamic>;
          if (dataList.isNotEmpty) {
            _filteredTestRequests = dataList;
            _verifiedRxCode = rxCode;
            _errorMessage = null;
          } else {
            _filteredTestRequests = [];
            _verifiedRxCode = '';
            _errorMessage = 'No test request found for this RX code';
          }
        } else {
          _filteredTestRequests = [];
          _verifiedRxCode = '';
          _errorMessage = 'Invalid response format';
        }
      } else {
        _filteredTestRequests = [];
        _verifiedRxCode = '';
        if (response.statusCode == 404) {
          _errorMessage = 'RX Code not found';
        } else {
          _errorMessage = 'Error: ${response.statusCode}';
        }
      }
    } catch (e) {
      _filteredTestRequests = [];
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
    _filteredTestRequests = [];
    _errorMessage = null;
    notifyListeners();
  }
}
