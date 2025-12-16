// import 'package:haticare/features/doctor/models/updated_doctor_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class SharedPrefsHelper {
  static const _refreshTokenKey = 'refresh_token';

  static Future<void> saveRefreshToken(String refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_refreshTokenKey, refreshToken);
  }

  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }

  static Future<void> clearRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_refreshTokenKey);
  }
}
class SaveLoginResponse {
  static const String _loginKey = 'login_model';

  static Map<String, dynamic>? loginData;

  static Future<void> saveLoginModel(Map<String, dynamic>? loggedInModel) async {
    loginData = loggedInModel;
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(loggedInModel);
    await prefs.setString(_loginKey, jsonString);
  }

  static Future<void> loadLoginModel() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_loginKey);
    if (jsonString != null) {
      loginData = jsonDecode(jsonString);
    }
  }
}

// class SaveDoctorResponse {
//   static const String _doctorKey = 'doctor_model';

//   static Doctor? doctorInstance;

//   static Future<void> saveDoctorModel(Map<String, dynamic> doctorData) async {
//     doctorInstance = Doctor.fromJson(doctorData);
//     final prefs = await SharedPreferences.getInstance();
//     final jsonString = jsonEncode(doctorData);
//     await prefs.setString(_doctorKey, jsonString);
//   }

//   static Future<void> loadDoctorModel() async {
//     final prefs = await SharedPreferences.getInstance();
//     final jsonString = prefs.getString(_doctorKey);
//     if (jsonString != null) {
//       final data = jsonDecode(jsonString);
//       doctorInstance = Doctor.fromJson(data);
//     }
//   }
// }

