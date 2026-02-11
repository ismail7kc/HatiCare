import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../../core/config/app_config.dart';
import 'twilio_call_service.dart';

class AudioCallVM extends ChangeNotifier {
  bool isCalling = false;
  bool isConnected = false;
  bool speakerOn = false;

  String callStatus = "Initializing...";
  String duration = "00:00";

  Timer? _timer;
  int seconds = 0;

  Future<void> toggleSpeaker() async {
    speakerOn = !speakerOn;
    await AudioRouteService.setSpeaker(speakerOn);
    notifyListeners();
  }

  Future<void> startCall({
    required int visitId,
    required String authToken,
  }) async {
    try {
      isCalling = true;
      callStatus = "Requesting token...";
      notifyListeners();

      final response = await http.get(
        Uri.parse("${AppConfig.baseUrl}calls/token/?visit_id=$visitId"),
        headers: {"Authorization": "Bearer $authToken"},
      );

      debugPrint("TOKEN API RESPONSE: ${response.body}");

      if (response.statusCode != 200) {
        throw Exception("Token API Failed: ${response.statusCode}");
      }

      final data = jsonDecode(response.body);

      final token = data["token"] as String?;
      final patientNumber = data["patient_phone"] as String?;

      if (token == null || token.isEmpty) {
        throw Exception("Twilio Token missing");
      }

      if (patientNumber == null || patientNumber.isEmpty) {
        throw Exception("Patient phone missing");
      }

      callStatus = "Connecting...";
      notifyListeners();

      await TwilioCallService.startCall(
        token: token,
        patientNumber: patientNumber,
      );

      callStatus = "Calling Patient...";
      isConnected = true;
      notifyListeners();
    } catch (e) {
      callStatus = "Call Failed: $e";
      isCalling = false;
      isConnected = false;
      notifyListeners();
    }
  }

  Future<void> endCall() async {
    await TwilioCallService.endCall();

    callStatus = "Call Ended";
    isCalling = false;
    isConnected = false;

    _stopTimer();
    notifyListeners();
  }

  // void _startTimer() {
  //   _seconds = 0;
  //   _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
  //     _seconds++;
  //     final minutes = (_seconds ~/ 60).toString().padLeft(2, '0');
  //     final seconds = (_seconds % 60).toString().padLeft(2, '0');
  //     duration = "$minutes:$seconds";
  //     notifyListeners();
  //   });
  // }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
    seconds = 0;
    duration = "00:00";
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }
}
