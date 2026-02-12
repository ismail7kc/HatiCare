import 'package:flutter/material.dart';
import 'package:haticare/features/common/global_alert.dart';
import 'package:haticare/features/common/shared_prefs_helper.dart';
import 'package:haticare/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  static bool _isLoggingOut = false;

  static Future<void> forceLogout(String message) async {
    if (_isLoggingOut) return;
    _isLoggingOut = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      SharedPrefsHelper.clearRefreshToken();
      SaveLoginResponse.loginData = null;
      final context = navigatorKey.currentContext;
      if (context == null) return;
      GlobalAlert.show(
        message.isNotEmpty ? message : "Your account has been deactivated",
        onOk: () {
          navigatorKey.currentState?.pushNamedAndRemoveUntil(
            '/login',
            (route) => false,
          );
          _isLoggingOut = false;
        },
      );
    } catch (e) {
      debugPrint("Error during forceLogout: $e");
      _isLoggingOut = false;
    }
  }
}

