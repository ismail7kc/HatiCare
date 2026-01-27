import 'package:flutter/material.dart';

import 'package:haticare/core/services/device_id_provider.dart';
import 'package:haticare/features/auth/domain/exceptions/auth_exceptions.dart';
import 'package:haticare/features/auth/domain/repositories/auth_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:haticare/features/common/shared_prefs_helper.dart';

class LoginViewModel extends ChangeNotifier {
  LoginViewModel(this._repository) {
    _loadSavedCredentials();
    _setupErrorClearingListeners();
  }

  final AuthRepository _repository;

  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool rememberMe = false;
  bool isSubmitting = false;
  bool isProfileCompleted = false;
  String? errorMessage;
  String? dialogMessage;
  Map<String, dynamic>? lastResponse;
  bool _shouldNavigate = false;
  bool _shouldAutovalidate = false;
  String? pharmacyId;
  String? laboratoryId;

  Future<void> _loadSavedCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedEmail = prefs.getString('saved_email');
      final savedPassword = prefs.getString('saved_password');
      final savedRememberMe = prefs.getBool('remember_me') ?? false;

      if (savedRememberMe && savedEmail != null && savedPassword != null) {
        emailController.text = savedEmail;
        passwordController.text = savedPassword;
        rememberMe = true;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading saved credentials: $e');
    }
  }

  Future<void> _saveCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (rememberMe) {
        await prefs.setString('saved_email', emailController.text.trim());
        await prefs.setString('saved_password', passwordController.text.trim());
        await prefs.setBool('remember_me', true);
      } else {
        await prefs.remove('saved_email');
        await prefs.remove('saved_password');
        await prefs.setBool('remember_me', false);
      }
    } catch (e) {
      debugPrint('Error saving credentials: $e');
    }
  }

  void markNavigationHandled() {
    if (_shouldNavigate) {
      _shouldNavigate = false;
      notifyListeners();
    }
  }

  void toggleRememberMe(bool? value) {
    rememberMe = value ?? false;
    notifyListeners();
  }

  void _setupErrorClearingListeners() {
    emailController.addListener(_clearErrorOnChange);
    passwordController.addListener(_clearErrorOnChange);
  }

  void _clearErrorOnChange() {
    if (errorMessage != null) {
      errorMessage = null;
      notifyListeners();
    }
  }

  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    final emailRegex = RegExp(r'^\S+@\S+\.\S+$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    return null;
  }

  Future<void> submit() async {
    _shouldAutovalidate = true;
    notifyListeners();

    if (!formKey.currentState!.validate()) {
      return;
    }

    isSubmitting = true;
    errorMessage = null;
    dialogMessage = null;
    lastResponse = null;
    _shouldNavigate = false;
    notifyListeners();

    try {
      final deviceId = await DeviceIdProvider().getDeviceId();

      final response = await _repository.login(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
        deviceId: deviceId,
      );

      lastResponse = response;
      _shouldNavigate = true;

      // Save credentials if remember me is checked
      await _saveCredentials();

      // Save tokens
      final prefs = await SharedPreferences.getInstance();

      /// Not Corrected way to do all stuff below 😅

      // Try to get access token from different possible locations
      String? accessToken;
      String? refreshToken;

      // Check in response object
      final responseObj = response['response'];
      if (responseObj is Map<String, dynamic>) {
        accessToken = responseObj['access_token'] ?? responseObj['access'];
        refreshToken = responseObj['refresh_token'] ?? responseObj['refresh'];
      }

      if (response['success'] == true) {
        // Extract ID based on role
        final id = response['data']['id'];
        final role = roleFromResponse;

        if (id != null) {
          if (role == 'laboratory') {
            laboratoryId = id.toString();
            await prefs.setString('laboratory_id', laboratoryId!);
            debugPrint('Laboratory ID saved: $laboratoryId');
          } else {
            pharmacyId = id.toString();
            await prefs.setString('pharmacy_id', pharmacyId!);
            debugPrint('Pharmacy ID saved: $pharmacyId');
          }
        }

        isProfileCompleted = (response['data']['is_profile_complete'] == true);

        // For doctors, check verification status per doctor ID
        if (role == 'doctor') {
          final doctorId = response['data']['id']?.toString() ?? '';
          if (doctorId.isNotEmpty) {
            final verificationCompleted =
                prefs.getBool('doctor_verification_completed_$doctorId') ??
                false;
            if (verificationCompleted && !isProfileCompleted) {
              // Local verification flag exists but server hasn't updated yet
              isProfileCompleted = true;
            }
          }
        }

        debugPrint('is CompletedProfile is $isProfileCompleted');

        if (role == 'laboratory') {
          await prefs.setBool(
            'laboratory_profile_completed',
            isProfileCompleted,
          );

          // Save Access Toekn
          final accessToken = response['data']['access_token'];
          await prefs.setString('access_token', accessToken);

        } else if (role == 'pharmacy') {
          await prefs.setBool('pharmacy_profile_completed', isProfileCompleted);
        }
      }

      if (response['success'] == true && response['data'] != null) {
        final responseData = response['data'] as Map<String, dynamic>;
        lastResponse = responseData;
        await SaveLoginResponse.saveLoginModel(lastResponse);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('doctorId', responseData['id'].toString());

        if (roleFromResponse == 'doctor') {
          final currentDoctorId = responseData['id']?.toString() ?? '';
          final lastDoctorId =
              prefs.getString('last_logged_in_doctor_id') ?? '';

          if (currentDoctorId.isNotEmpty &&
              lastDoctorId.isNotEmpty &&
              currentDoctorId != lastDoctorId) {
            await prefs.remove('idCardChecked_$lastDoctorId');
            await prefs.remove('selfieChecked_$lastDoctorId');
            await prefs.remove('licenseChecked_$lastDoctorId');
            await prefs.remove('isRequiredInfoFilled_$lastDoctorId');

            await prefs.remove('licenseNumber_$lastDoctorId');
            await prefs.remove('yearsExperience_$lastDoctorId');
            await prefs.remove('licenseAuthority_$lastDoctorId');
            await prefs.remove('licenseType_$lastDoctorId');
            await prefs.remove('specialization_$lastDoctorId');

            // Clear global profile completion flags
            await prefs.remove('is_profile_completed');
            await prefs.remove('doctor_verification_completed_$lastDoctorId');

            debugPrint(
              'Cleared previous doctor data including profile completion flags',
            );
          }

          if (currentDoctorId.isNotEmpty) {
            await prefs.setString('last_logged_in_doctor_id', currentDoctorId);
          }
        }
        SaveLoginResponse.loginData = responseData;
      }

      accessToken ??= response['access_token'] ?? response['access'];
      refreshToken ??= response['refresh_token'] ?? response['refresh'];

      final data = response['data'];
      if (data is Map<String, dynamic>) {
        accessToken ??= data['access_token'] ?? data['access'];
        refreshToken ??= data['refresh_token'] ?? data['refresh'];
      }

      if (accessToken != null && accessToken.isNotEmpty) {
        await prefs.setString('access_token', accessToken);
        debugPrint('access_token token is: $accessToken');
      } else {
        debugPrint('No access token found in response');
      }

      if (refreshToken != null && refreshToken.isNotEmpty) {
        await SharedPrefsHelper.saveRefreshToken(refreshToken);
        debugPrint('refresh token is: $refreshToken');
      } else {
        debugPrint('No refresh token found in response');
      }

      final userType = roleFromResponse;
      if (userType != null) {
        await prefs.setString('user_type', userType);
      }

      String? firstName;
      String? lastName;
      String? phoneNumber;
      if (response['first_name'] is String) {
        firstName = response['first_name'] as String;
      }
      if (response['last_name'] is String) {
        lastName = response['last_name'] as String;
      }
      if (response['phone_number'] is String) {
        phoneNumber = response['phone_number'] as String;
      }
      final responseObj2 = response['response'];
      if (responseObj2 is Map<String, dynamic>) {
        if (responseObj2['first_name'] is String &&
            (firstName == null || firstName.isEmpty)) {
          firstName = responseObj2['first_name'] as String;
        }
        if (responseObj2['last_name'] is String &&
            (lastName == null || lastName.isEmpty)) {
          lastName = responseObj2['last_name'] as String;
        }
        if (responseObj2['phone_number'] is String &&
            (phoneNumber == null || phoneNumber.isEmpty)) {
          phoneNumber = responseObj2['phone_number'] as String;
        }
      }
      final dataObj = response['data'];
      if (dataObj is Map<String, dynamic>) {
        if (dataObj['first_name'] is String &&
            (firstName == null || firstName.isEmpty)) {
          firstName = dataObj['first_name'] as String;
        }
        if (dataObj['last_name'] is String &&
            (lastName == null || lastName.isEmpty)) {
          lastName = dataObj['last_name'] as String;
        }
        if (dataObj['phone_number'] is String &&
            (phoneNumber == null || phoneNumber.isEmpty)) {
          phoneNumber = dataObj['phone_number'] as String;
        }
      }
      if (firstName != null && firstName.isNotEmpty) {
        await prefs.setString('user_first_name', firstName);
      }
      if (lastName != null && lastName.isNotEmpty) {
        await prefs.setString('user_last_name', lastName);
      }
      if (phoneNumber != null && phoneNumber.isNotEmpty) {
        await prefs.setString('user_phone_number', phoneNumber);
      }

      if (dataObj is Map<String, dynamic>) {
        if (roleFromResponse == 'laboratory') {
          final laboratoryName = dataObj['laboratory_name'] ?? dataObj['name'];
          if (laboratoryName is String && laboratoryName.isNotEmpty) {
            await prefs.setString('laboratory_name', laboratoryName);
          }

          final profilePicture = dataObj['profile_picture'];
          if (profilePicture is String && profilePicture.isNotEmpty) {
            await prefs.setString('profile_picture_url', profilePicture);
          }

          final email = dataObj['email'];
          if (email is String && email.isNotEmpty) {
            await prefs.setString('email', email);
          }
        } else if (roleFromResponse == 'pharmacy') {
          final pharmacyName = dataObj['pharmacy_name'] ?? dataObj['name'];
          if (pharmacyName is String && pharmacyName.isNotEmpty) {
            await prefs.setString('pharmacy_name', pharmacyName);
          }

          final profilePicture = dataObj['profile_picture'];
          if (profilePicture is String && profilePicture.isNotEmpty) {
            await prefs.setString('profile_picture_url', profilePicture);
          }

          final email = dataObj['email'];
          if (email is String && email.isNotEmpty) {
            await prefs.setString('email', email);
          }
        }
      }

      await prefs.setBool('is_logged_in', true);
      await prefs.setString('user_email', emailController.text.trim());
    } on AuthApiException catch (error) {
      debugPrint('AuthApiException: ${error.message}');
      debugPrint('Status code: ${error.statusCode}');

      final errorMsg = error.message.toLowerCase();

      if (errorMsg.contains('deactivated') || errorMsg.contains('inactive')) {
        dialogMessage = error.message;
      } else if (errorMsg.contains('not found') ||
          errorMsg.contains('does not exist') ||
          errorMsg.contains('no account found') ||
          errorMsg.contains('user not found')) {
        dialogMessage =
            'No account found with this email. Please try with correct email or register a new account.';
      } else if (errorMsg.contains('password') ||
          errorMsg.contains('incorrect') ||
          errorMsg.contains('invalid credentials') ||
          errorMsg.contains('wrong password')) {
        dialogMessage =
            'Incorrect password. Please check your password and try again.';
      } else if (errorMsg.contains('email') && errorMsg.contains('invalid')) {
        dialogMessage = 'Invalid email address. Please enter a valid email.';
      } else {
        dialogMessage = error.message.isNotEmpty
            ? error.message
            : 'Invalid login credentials. Please try again.';
      }

      errorMessage = null;
      _shouldNavigate = false;
      lastResponse = null;
    } catch (e) {
      dialogMessage = 'Login failed. Please try again.';
      _shouldNavigate = false;
      lastResponse = null;
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }

  bool get shouldNavigate => _shouldNavigate;
  bool get shouldAutovalidate => _shouldAutovalidate;

  String? get roleFromResponse {
    final response = lastResponse;
    if (response == null) return null;

    final userType = response['user_type'];
    if (userType is String) return userType.toLowerCase();

    final responseObj = response['response'];
    if (responseObj is Map<String, dynamic>) {
      final type = responseObj['user_type'];
      if (type is String) return type.toLowerCase();
    }

    final data = response['data'];
    if (data is Map<String, dynamic>) {
      final type = data['user_type'] ?? data['role'] ?? data['type'];
      if (type is String) return type.toLowerCase();
    }

    final role = response['role'] ?? response['user_role'] ?? response['type'];
    return role is String ? role.toLowerCase() : null;
  }

  void clearDialogMessage() {
    if (dialogMessage != null) {
      dialogMessage = null;
      notifyListeners();
    }
  }

  void resetAutovalidate() {
    if (_shouldAutovalidate) {
      _shouldAutovalidate = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
