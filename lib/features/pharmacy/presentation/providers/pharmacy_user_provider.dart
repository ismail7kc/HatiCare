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

  String get pharmacyName => _pharmacyName;
  String get profilePictureUrl => _profilePictureUrl;
  String get contactPerson => _contactPerson;
  String get licenseNumber => _licenseNumber;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  PharmacyUserProvider() {
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _pharmacyName = prefs.getString('user_first_name') ?? '';
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
          _errorMessage = null;
          
          if (_pharmacyName.isNotEmpty) {
             await prefs.setString('user_first_name', _pharmacyName);
          }
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
}
