import 'package:flutter/material.dart';
import 'package:haticare/features/doctor/AuthRepository/authD_repository.dart';
import 'package:haticare/core/services/device_id_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:haticare/features/common/shared_prefs_helper.dart';

class AuthDViewModel extends ChangeNotifier {
  final AuthDRepository _repository;

  AuthDViewModel(this._repository);
  bool logoutSuccess = false;

  Future<bool> logout() async {
    notifyListeners();
    debugPrint(await DeviceIdProvider().getDeviceId());
    try {
      final deviceId = await DeviceIdProvider().getDeviceId();
      final token = await SharedPrefsHelper.getRefreshToken();
      final result = await _repository.logout(deviceId, token);
      debugPrint('Logout Success: $result');

      logoutSuccess = true;

      // Clear all login data
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('access_token');
      await prefs.remove('device_id');
      await prefs.remove('user_type');
      await prefs.remove('user_email');
      await prefs.setBool('is_logged_in', false);

      SharedPrefsHelper.clearRefreshToken();

      // Don't remove saved credentials if remember me was checked
      // Only clear login state

      return true;
    } catch (error) {
      debugPrint('Logout Error: $error');
      return false;
    } finally {
      notifyListeners();
    }
  }
}
