import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:haticare/features/common/session_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:chucker_flutter/chucker_flutter.dart';
import '../../../../core/config/app_config.dart';
import '../../../common/shared_prefs_helper.dart';

class DoctorUserProvider extends ChangeNotifier {
  String _doctorName = '';
  String _profilePictureUrl = '';
  String _specialty = '';
  String _licenseNumber = '';
  String _email = '';
  bool _isLoading = true;
  String? _errorMessage;
  bool? _isApproved;
  String _approvalMessage = '';

  String get doctorName => _doctorName;
  String get profilePictureUrl => _profilePictureUrl;
  String get specialty => _specialty;
  String get licenseNumber => _licenseNumber;
  String get email => _email;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool? get isApproved => _isApproved;
  String get approvalMessage => _approvalMessage;

  DoctorUserProvider() {
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      await SaveLoginResponse.loadLoginModel();
      final firstName = SaveLoginResponse.loginData?['first_name'] ?? '';
      final lastName = SaveLoginResponse.loginData?['last_name'] ?? '';
      _doctorName = '$firstName $lastName'.trim();
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
      final doctorId = SaveLoginResponse.loginData?['id'] ?? '';
      final accessToken = prefs.getString('access_token') ?? '';

      if (doctorId.toString().isEmpty) {
        _isLoading = false;
        notifyListeners();
        return;
      }

      final uri = Uri.parse('${AppConfig.baseUrl}doc/doctors/$doctorId/');
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

      try {
        final decoded = jsonDecode(response.body);
        if (response.statusCode == 403 &&
            (decoded['user_is_active'] == false ||
                decoded['error'] == 'ACCOUNT_DEACTIVATED')) {
          await SessionManager.forceLogout(
            decoded['message'] ?? "Your account has been deactivated",
          );
          return;
        }
      } catch (_) {
        // If response is not JSON, ignore force logout
      }

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
          final firstName = data['first_name'] ?? '';
          final lastName = data['last_name'] ?? '';
          _doctorName = '$firstName $lastName'.trim();
          _profilePictureUrl = data['profile_picture'] ?? '';
          _specialty = data['specialization'] ?? '';
          _licenseNumber = data['license_number'] ?? '';
          _email = data['email'] ?? '';

          _isApproved = (data['is_approved'] == true);

          // Store approval message if present
          if (data.containsKey('approval_message')) {
            _approvalMessage = data['approval_message'] ?? '';
          } else if (data.containsKey('status_message')) {
            _approvalMessage = data['status_message'] ?? '';
          } else if (_isApproved != true) {
            _approvalMessage = "Waiting For Admin's Approval";
          } else {
            _approvalMessage = '';
          }

          _errorMessage = null;

          // Update SaveLoginResponse and SharedPreferences
          if (_doctorName.isNotEmpty) {
            SaveLoginResponse.loginData?['first_name'] = firstName;
            SaveLoginResponse.loginData?['last_name'] = lastName;
          }

          if (_profilePictureUrl.isNotEmpty) {
            SaveLoginResponse.loginData?['profile_picture'] =
                _profilePictureUrl;
          }

          SaveLoginResponse.loginData?['is_approved'] = _isApproved;

          // Save approval status to preferences for offline checking
          await prefs.setBool('doctor_is_approved', _isApproved ?? false);
          await prefs.setString('doctor_approval_message', _approvalMessage);
        }
      } else {
        _errorMessage = 'Failed to load profile: ${response.statusCode}';
      }
    } catch (e) {
      _errorMessage = 'Error loading profile: $e';
      debugPrint('Error fetching doctor profile: $e');
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

  void updateDoctorName(String firstName, String lastName) {
    _doctorName = '$firstName $lastName'.trim();
    SaveLoginResponse.loginData?['first_name'] = firstName;
    SaveLoginResponse.loginData?['last_name'] = lastName;
    notifyListeners();
  }
}
