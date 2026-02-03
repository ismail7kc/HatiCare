import 'package:twilio_voice/twilio_voice.dart';

class TwilioCallService {
  static Future<void> startCall({
    required String token,
    required String patientNumber,
  }) async {
    // await TwilioVoice.instance.connect(
    //   accessToken: token,
    //   params: {
    //     "To": patientNumber,
    //   },
    // );
  }

  static Future<void> endCall() async {
    // await TwilioVoice.instance.disconnect();
  }
}

