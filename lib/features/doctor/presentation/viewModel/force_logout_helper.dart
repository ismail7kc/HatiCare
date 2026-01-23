import 'package:flutter/material.dart';
import 'package:haticare/features/common/shared_prefs_helper.dart';
import 'package:haticare/main.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:haticare/features/auth/presentation/screens/login_screen.dart';

class ForceLogoutHelper {
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    SharedPrefsHelper.clearRefreshToken();

    final navigator = rootNavigatorKey.currentState;
    if (navigator == null) return;

    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  static Future<void> showInactiveAccountAlert(
    BuildContext context, {
    required String message,
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text("Account Inactive"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await logout();
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }
}


