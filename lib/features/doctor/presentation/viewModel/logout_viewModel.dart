import 'package:flutter/material.dart';
import 'package:haticare/features/doctor/AuthRepository/authD_repository.dart';
import 'package:haticare/core/services/device_id_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthDViewModel extends ChangeNotifier {
  final AuthDRepository _repository;

  AuthDViewModel(this._repository);
  bool logoutSuccess = false;

  Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('refresh_token');
  }

  Future<bool> logout() async {
    notifyListeners();
    debugPrint(await DeviceIdProvider().getDeviceId());
    try {
      final deviceId = await DeviceIdProvider().getDeviceId();
      final token = await getRefreshToken();
      final result = await _repository.logout(deviceId, token);
      debugPrint('Logout Success: $result');

      logoutSuccess = true;

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('refresh_token');
      await prefs.remove('device_id');
      return true;
    } catch (e) {
      debugPrint('Logout Error: $e');
       return false;
    } finally {
      notifyListeners();
    }
  }

  
}
