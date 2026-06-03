import 'package:flutter/services.dart';

class TwilioCallService {
  static const MethodChannel _channel = MethodChannel("twilio_call");

  static Future<void> startCall({
    required String token,
    required String patientNumber,
  }) async {
    await _channel.invokeMethod("startCall", {
      "token": token,
      "to": patientNumber,
    });
  }

  static Future<void> setMuted(bool muted) async {
    await _channel.invokeMethod("setMuted", { "muted": muted, });
  }

  static Future<void> endCall() async {
    await _channel.invokeMethod("endCall");
  }
}

class AudioRouteService {
  static const _channel = MethodChannel('audio_route');

  static Future<void> setSpeaker(bool enabled) async {
    await _channel.invokeMethod('setSpeaker', {
      'enabled': enabled,
    });
  }
}
