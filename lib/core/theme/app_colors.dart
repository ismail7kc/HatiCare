import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  static const Color primaryDark = Color(0xFF07498A);
  static const Color primaryLight = Color(0xFF54DCDF);

  static const Color primary = primaryDark;
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF1F1F39);
  static const Color textSecondary = Color(0xFF6E6E8C);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryLight, primaryDark],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}
