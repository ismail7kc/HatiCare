import 'package:flutter/material.dart';
import 'package:haticare/main.dart';

class GlobalAlert {
  static void show(
    String message, {
    String title = 'Error',
    VoidCallback? onOk,
    bool barrierDismissible = false,
  }) {
    final context = navigatorKey.currentState?.overlay?.context;
    if (context == null) return;

    showDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
             if (onOk != null) onOk();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
