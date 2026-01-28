import 'package:flutter/material.dart';

class ProfileNotifier {
  static final ValueNotifier<String?> profileImageUrl = ValueNotifier(null);
  static final ValueNotifier<String?> doctorName = ValueNotifier(null);
}
