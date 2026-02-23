import 'dart:convert';
import 'dart:io';
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
  String _userId = '';
  bool _isLoading = true;
  String? _errorMessage;

  List<dynamic> _newRequests = [];
  List<dynamic> _assignedRequests = []; 
  final List<dynamic> _testRequests = [];
  List<dynamic> _completedTestRequests = [];

  bool _newRequestsLoading = false;
  bool _assignedRequestsLoading = false;
  final bool _testRequestsLoading = false;

  bool _isVerifying = false; 
  final String _verifiedRxCode = '';
  bool _isApproved = false;
  String _approvalMessage = '';

  String get laboratoryName => _laboratoryName;
  String get profilePictureUrl => _profilePictureUrl;
  String get contactPerson => _contactPerson;
  String get licenseNumber => _licenseNumber;
  String get userId => _userId;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<dynamic> get newRequests => _newRequests;
  List<dynamic> get assignedRequests => _assignedRequests;
  bool get newRequestsLoading => _newRequestsLoading;
  bool get assignedRequestsLoading => _assignedRequestsLoading;

  List<dynamic> get testRequests => _testRequests;
  List<dynamic> get prescriptions => _newRequests;
  List<dynamic> get completedTestRequests => _completedTestRequests;
  bool get testRequestsLoading => _testRequestsLoading;
  bool get prescriptionsLoading => _newRequestsLoading; 
  bool get isVerifying => _isVerifying;
  String get verifiedRxCode => _verifiedRxCode;
  bool get isApproved => _isApproved;
  String get approvalMessage => _approvalMessage;

  LaboratoryUserProvider() {
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      await SaveLoginResponse.loadLoginModel();
      _laboratoryName = SaveLoginResponse.loginData?['laboratory_name'] ?? '';

      // Load user ID from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      _userId = prefs.getString('laboratory_id') ?? '';

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

      final uri = Uri.parse(
        '${AppConfig.baseUrl}lab/laboratories/$laboratoryId/',
      );
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
            SaveLoginResponse.loginData?['profile_picture'] =
                _profilePictureUrl;
          }

          SaveLoginResponse.loginData?['is_approved'] = _isApproved;

          // Save approval status to preferences for offline checking
          await prefs.setBool('laboratory_is_approved', _isApproved);
          await prefs.setString(
            'laboratory_approval_message',
            _approvalMessage,
          );
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

  Future<void> fetchNewRequests() async {
    try {
      _newRequestsLoading = true;
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token') ?? '';

      if (accessToken.isEmpty) {
        _errorMessage = 'No authentication token found';
        _newRequestsLoading = false;
        notifyListeners();
        return;
      }

      final uri = Uri.parse(
        '${AppConfig.baseUrl}prescriptions/laboratory/list/',
      );
      final client = ChuckerHttpClient(http.Client());
      final response = await client
          .get(
            uri,
            headers: {
              'Authorization': 'Bearer $accessToken',
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final jsonResponse = jsonDecode(response.body);

        if (jsonResponse['results'] != null &&
            jsonResponse['results']['data'] != null) {
          _newRequests = jsonResponse['results']['data'] as List<dynamic>;
        } else if (jsonResponse['data'] != null) {
          _newRequests = jsonResponse['data'] as List<dynamic>;
        } else if (jsonResponse['results'] != null) {
          _newRequests = jsonResponse['results'] as List<dynamic>;
        } else if (jsonResponse['items'] != null) {
          _newRequests = jsonResponse['items'] as List<dynamic>;
        } else if (jsonResponse['test_requests'] != null) {
          _newRequests = jsonResponse['test_requests'] as List<dynamic>;
        } else {
          _newRequests = [];
        }

        _errorMessage = null;
      } else {
        _newRequests = [];
        _errorMessage = 'Failed to load new requests: ${response.statusCode}';
      }
    } catch (e) {
      _newRequests = [];
      _errorMessage = 'Error loading new requests: $e';
    } finally {
      _newRequestsLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchTestRequests() async {
    // Backward compatibility - calls fetchNewRequests
    await fetchNewRequests();
  }

  Future<void> fetchPrescriptions() async {
    // Backward compatibility - calls fetchNewRequests
    await fetchNewRequests();
  }

  Future<void> fetchAssignedPrescriptions() async {
    try {
      _assignedRequestsLoading = true;
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token') ?? '';

      if (accessToken.isEmpty) {
        _errorMessage = 'No authentication token found';
        _assignedRequestsLoading = false;
        notifyListeners();
        return;
      }

      final uri = Uri.parse(
        '${AppConfig.baseUrl}prescriptions/laboratory/assigned/',
      );
      final client = ChuckerHttpClient(http.Client());
      final response = await client
          .get(
            uri,
            headers: {
              'Authorization': 'Bearer $accessToken',
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final jsonResponse = jsonDecode(response.body);
        final results = jsonResponse['results'];
        final data = results is Map<String, dynamic> ? results['data'] : null;

        if (data is List) {
          _assignedRequests = data
              .where((item) => item['lab_status'] != 'results_uploaded')
              .toList();
        } else {
          _assignedRequests = [];
        }

        debugPrint('This is Lab Test Result $assignedRequests');

        _errorMessage = null;
      } else {
        _assignedRequests = [];
        _errorMessage =
            'Failed to load assigned prescriptions: ${response.statusCode}';
      }
    } catch (e) {
      _assignedRequests = [];
      _errorMessage = 'Error loading assigned prescriptions: $e';
    } finally {
      _assignedRequestsLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchHistory() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token') ?? '';

      if (accessToken.isEmpty) {
        _errorMessage = 'No authentication token found';
        _isLoading = false;
        notifyListeners();
        return;
      }

      final uri = Uri.parse(
        '${AppConfig.baseUrl}prescriptions/laboratory/history/',
      );
      final client = ChuckerHttpClient(http.Client());
      final response = await client
          .get(
            uri,
            headers: {
              'Authorization': 'Bearer $accessToken',
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final jsonResponse = jsonDecode(response.body);

        // Parse the response and extract the history data
        if (jsonResponse['results'] != null &&
            jsonResponse['results']['data'] != null) {
          _completedTestRequests =
              jsonResponse['results']['data'] as List<dynamic>;
        } else if (jsonResponse['data'] != null) {
          _completedTestRequests = jsonResponse['data'] as List<dynamic>;
        } else if (jsonResponse['results'] != null) {
          _completedTestRequests = jsonResponse['results'] as List<dynamic>;
        } else if (jsonResponse['items'] != null) {
          _completedTestRequests = jsonResponse['items'] as List<dynamic>;
        } else if (jsonResponse['history'] != null) {
          _completedTestRequests = jsonResponse['history'] as List<dynamic>;
        } else {
          _completedTestRequests = [];
        }

        _errorMessage = null;
      } else {
        _completedTestRequests = [];
        _errorMessage = 'Failed to load history: ${response.statusCode}';
      }
    } catch (e) {
      _completedTestRequests = [];
      _errorMessage = 'Error loading history: $e';
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
    try {
      _errorMessage = null;
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token') ?? '';

      if (accessToken.isEmpty) {
        _errorMessage = 'No authentication token found';
        notifyListeners();
        return;
      }

      final uri = Uri.parse(
        '${AppConfig.baseUrl}prescriptions/laboratory/status/$statusId/accept/',
      );
      final client = ChuckerHttpClient(http.Client());

      final response = await client
          .patch(
            uri,
            headers: {
              'Authorization': 'Bearer $accessToken',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'accept': true}),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        _errorMessage = null;
        // Refresh both lists after accepting
        await Future.wait([
          fetchNewRequests(), // Refresh home screen list
          fetchAssignedPrescriptions(), // Refresh inventory screen list
        ]);
      } else {
        final jsonResponse = jsonDecode(response.body);
        _errorMessage =
            jsonResponse['message'] ??
            'Failed to accept prescription: ${response.statusCode}';
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Error accepting prescription: $e';
      notifyListeners();
    }
  }

  Future<void> updateTestAvailability(
    String prescriptionId,
    bool isAvailable,
  ) async {
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

  Future<bool> uploadReport(
    String labStatusID,
    List<File> files, {
    Map<String, dynamic>? labResults,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token') ?? '';

      final uri = Uri.parse(
        '${AppConfig.baseUrl}prescriptions/laboratory/status/$labStatusID/upload_result/',
      );

      debugPrint('Upload Report URL is here $uri');

      final request = http.MultipartRequest('POST', uri);
      request.headers.addAll({
        'Authorization': 'Bearer $accessToken',
        'Accept': 'application/json',
      });

      if (labResults != null && labResults.isNotEmpty) {
        request.fields['lab_results'] = jsonEncode(labResults);
      }

      // Add files
      for (var file in files) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'files', // Field name for multiple file uploads
            file.path,
          ),
        );
      }

      // Add debug print
      debugPrint('Uploading to $uri');
      debugPrint(
        'Lab results: ${labResults != null ? jsonEncode(labResults) : 'none'}',
      );
      debugPrint('Files: ${files.length}');

      final client = ChuckerHttpClient(http.Client());
      final streamedResponse = await client.send(request);
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('Upload response: ${response.statusCode} ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        _isLoading = false;
        print('Response is here $response');
        notifyListeners();
        return true;
      } else {
        // Parse error message from response
        String errorMsg = 'Failed to upload report';
        try {
          final errorData = jsonDecode(response.body);
          if (errorData is Map) {
            // Try different error message fields
            errorMsg =
                errorData['detail']?.toString() ??
                errorData['message']?.toString() ??
                errorData['error']?.toString() ??
                'Failed to upload report: ${response.statusCode}';
          }
        } catch (e) {
          errorMsg = 'Failed to upload report: ${response.statusCode}';
        }

        _errorMessage = errorMsg;
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error uploading report: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void handleWebSocketUpdate(Map<String, dynamic> wsData) {
    try {
      final type = wsData['type'] as String?;
      final data = wsData['data'] as List<dynamic>?;

      if (data == null || data.isEmpty) return;

      final newRequest = data[0] as Map<String, dynamic>;
      final statusId = newRequest['status_id'];

      if (type == 'initial_item') {
        // Initial items are already loaded, skip
        return;
      } else if (type == 'update_request') {
        // Find and update existing request, or add if new
        final index = _newRequests.indexWhere(
          (p) => p is Map && p['status_id'] == statusId,
        );

        if (index != -1) {
          _newRequests[index] = newRequest;
        } else {
          // New request, add to the beginning of the list
          _newRequests.insert(0, newRequest);
        }

        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error handling WebSocket update: $e');
    }
  }
}
