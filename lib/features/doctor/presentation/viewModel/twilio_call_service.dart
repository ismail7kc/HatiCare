import 'package:flutter/services.dart';

class TwilioCallService {
  static const MethodChannel _channel =
      MethodChannel("twilio_call");

  static Future<void> startCall({
    required String token,
    required String patientNumber,
  }) async {
    await _channel.invokeMethod("startCall", {
      "token": token,
      "to": patientNumber,
    });
  }

  static Future<void> endCall() async {
    await _channel.invokeMethod("endCall");
  }
}
