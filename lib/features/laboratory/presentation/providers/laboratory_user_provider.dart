import 'package:flutter/material.dart';
import 'package:haticare/features/laboratory/domain/entities/test_request.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LaboratoryUserProvider extends ChangeNotifier {
  bool _isLoading = true;
  String _laboratoryName = '';
  String _email = '';
  String _profilePictureUrl = '';
  String _laboratoryId = '';
  bool _profileCompleted = false;
  List<TestRequest> _testRequests = [];
  List<TestRequest> _completedTestRequests = [];

  bool get isLoading => _isLoading;
  String get laboratoryName => _laboratoryName;
  String get email => _email;
  String get profilePictureUrl => _profilePictureUrl;
  String get laboratoryId => _laboratoryId;
  bool get profileCompleted => _profileCompleted;
  List<TestRequest> get testRequests => _testRequests;
  List<TestRequest> get completedTestRequests => _completedTestRequests;

  LaboratoryUserProvider() {
    initializeData();
  }

  Future<void> initializeData() async {
    try {
      _isLoading = true;
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      
      // Get laboratory data from SharedPreferences
      _laboratoryName = prefs.getString('laboratory_name') ?? 'Laboratory';
      _email = prefs.getString('email') ?? '';
      _profilePictureUrl = prefs.getString('profile_picture_url') ?? '';
      _laboratoryId = prefs.getString('laboratory_id') ?? '';
      _profileCompleted = prefs.getBool('laboratory_profile_completed') ?? false;

      // Load dummy test requests
      _testRequests = TestRequest.getDummyTestRequests();
      _completedTestRequests = TestRequest.getDummyCompletedTestRequests();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateProfilePicture(String url) async {
    _profilePictureUrl = url;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_picture_url', url);
    notifyListeners();
  }

  Future<void> updateLaboratoryName(String name) async {
    _laboratoryName = name;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('laboratory_name', name);
    notifyListeners();
  }
}
