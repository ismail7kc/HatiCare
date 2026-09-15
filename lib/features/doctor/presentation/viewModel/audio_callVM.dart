import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../../../../core/config/app_config.dart';
import 'twilio_call_service.dart';

class AudioCallVM extends ChangeNotifier {
  AudioCallVM() {
    _eventSubscription = TwilioCallService.callEvents.listen(
      _onCallEvent,
      onError: (Object error) => _fail(_describeFailure(error.toString(), null)),
    );
  }

  /// Give up if Twilio never reports a terminal state for the call.
  static const Duration _connectTimeout = Duration(seconds: 60);

  bool isCalling = false;
  bool isConnected = false;
  bool speakerOn = false;
  bool micMuted = false;

  /// The call could not be established (token failure, no answer, network drop
  /// before the call connected). The UI shows [errorMessage] and leaves.
  bool callFailed = false;

  /// A connected call ended remotely.
  bool callEnded = false;

  /// Reason shown to the user when the call could not be completed.
  String? errorMessage;

  String callStatus = "Initializing...";
  String duration = "00:00";

  Timer? _timer;
  Timer? _connectTimer;
  StreamSubscription<TwilioCallEvent>? _eventSubscription;
  bool _hasConnected = false;
  int seconds = 0;

  Future<void> toggleSpeaker() async {
    speakerOn = !speakerOn;
    await AudioRouteService.setSpeaker(speakerOn);
    notifyListeners();
  }

  Future<void> toggleMute() async {
    micMuted = !micMuted;
    await TwilioCallService.setMuted(micMuted);
    notifyListeners();
  }

  Future<void> startCall({
    required int visitId,
    required String authToken,
  }) async {
    _hasConnected = false;
    isCalling = true;
    callFailed = false;
    callEnded = false;
    errorMessage = null;
    callStatus = "Requesting token...";
    notifyListeners();

    try {
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

      // Only the native SDK knows whether the call really connects, so the
      // "Connected" state is driven by [callEvents], not by this call returning.
      await TwilioCallService.startCall(
        token: token,
        patientNumber: patientNumber,
        visitId: visitId,
      );

      callStatus = "Calling...";
      _startConnectTimeout();
      notifyListeners();
    } catch (e) {
      _fail(_describeFailure(_rawErrorMessage(e), _errorCode(e)));
      notifyListeners();
    }
  }

  Future<void> endCall() async {
    _cancelTimers();

    isCalling = false;
    isConnected = false;
    callStatus = "Call Ended";

    try {
      await TwilioCallService.endCall();
    } catch (e) {
      debugPrint("END CALL ERROR: $e");
    }

    notifyListeners();
  }

  void _onCallEvent(TwilioCallEvent event) {
    switch (event.type) {
      case TwilioCallEventType.ringing:
        callStatus = "Ringing...";
        break;

      case TwilioCallEventType.connected:
        _connectTimer?.cancel();
        _hasConnected = true;
        isCalling = false;
        isConnected = true;
        callStatus = "Connected";
        _startTimer();
        break;

      case TwilioCallEventType.reconnecting:
        callStatus = "Reconnecting...";
        break;

      case TwilioCallEventType.reconnected:
        callStatus = "Connected";
        break;

      case TwilioCallEventType.failed:
        _fail(_describeFailure(event.message, event.code));
        break;

      case TwilioCallEventType.disconnected:
        _handleDisconnected(event);
        break;

      case TwilioCallEventType.unknown:
        return;
    }

    notifyListeners();
  }

  void _handleDisconnected(TwilioCallEvent event) {
    _cancelTimers();

    isCalling = false;
    isConnected = false;

    final hasError = event.message != null && event.message!.trim().isNotEmpty;

    if (!_hasConnected) {
      // Twilio disconnects the caller when the dialled party never answers,
      // so a disconnect before the first "connected" is a failed call.
      callFailed = true;
      errorMessage = _describeFailure(event.message, event.code);
      callStatus = "Call Failed";
      return;
    }

    callEnded = true;
    callStatus = "Call Ended";

    if (hasError) {
      errorMessage = _describeFailure(event.message, event.code);
    }
  }

  void _fail(String message) {
    _cancelTimers();

    isCalling = false;
    isConnected = false;
    callFailed = true;
    errorMessage = message;
    callStatus = "Call Failed";
  }

  void _startConnectTimeout() {
    _connectTimer?.cancel();
    _connectTimer = Timer(_connectTimeout, () async {
      if (isConnected || callFailed || callEnded) return;

      _fail("The call could not be connected. Please try again.");
      notifyListeners();

      try {
        await TwilioCallService.endCall();
      } catch (e) {
        debugPrint("END CALL ERROR: $e");
      }
    });
  }

  String _rawErrorMessage(Object error) {
    if (error is PlatformException) {
      return error.message ?? error.code;
    }
    if (error is MissingPluginException) {
      return "Audio calling is not supported on this device.";
    }
    return error.toString().replaceFirst("Exception: ", "");
  }

  int? _errorCode(Object error) =>
      error is PlatformException && error.details is int
          ? error.details as int
          : null;

  /// Turns Twilio error codes/messages into something a doctor can act on.
  String _describeFailure(String? rawMessage, int? code) {
    switch (code) {
      case 20101:
      case 20104:
      case 20105:
      case 20106:
        return "Your session has expired. Please log in again.";
      case 31005:
      case 31009:
      case 53001:
      case 53405:
        return "Network problem. Check your internet connection and try again.";
      case 31480:
      case 31503:
        return "Calling is temporarily unavailable. Please try again.";
      case 31484:
        return "The patient's phone number is not valid.";
      case 31486:
        return "The patient's line is busy. Please try again.";
      case 31487:
      case 31603:
        return "The patient did not answer.";
      case 31604:
        return "The patient's phone number does not exist.";
      case 21218:
        return "Calling is not configured correctly. Please contact support.";
    }

    final message = rawMessage?.trim() ?? '';
    if (message.isEmpty) {
      return "The call could not be connected. Please try again.";
    }

    final lower = message.toLowerCase();

    if (lower.contains("access token")) {
      return "Your session has expired. Please log in again.";
    }
    if (lower.contains("no answer") || lower.contains("not answer")) {
      return "The patient did not answer.";
    }
    if (lower.contains("busy")) {
      return "The patient's line is busy. Please try again.";
    }
    if (lower.contains("declin")) {
      return "The patient declined the call.";
    }
    if (lower.contains("timeout") || lower.contains("timed out")) {
      return "The call timed out. Please try again.";
    }
    if (lower.contains("network") ||
        lower.contains("connection") ||
        lower.contains("transport") ||
        lower.contains("signaling")) {
      return "Network problem. Check your internet connection and try again.";
    }
    if (lower.contains("application ") || lower.contains("not found")) {
      return "Calling is not configured correctly. Please contact support.";
    }
    if (lower.contains("patient phone missing") ||
        lower.contains("twilio token missing")) {
      return "This patient can't be called: phone number missing.";
    }
    if (lower.contains("socketexception") ||
        lower.contains("failed host lookup") ||
        lower.contains("connection refused")) {
      return "Network problem. Check your internet connection and try again.";
    }

    return message;
  }

  void _startTimer() {
    if (_timer != null) return;

    seconds = 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      seconds++;

      final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
      final secs = (seconds % 60).toString().padLeft(2, '0');

      duration = "$minutes:$secs";
      notifyListeners();
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
    seconds = 0;
    duration = "00:00";
  }

  void _cancelTimers() {
    _connectTimer?.cancel();
    _connectTimer = null;
    _stopTimer();
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    _eventSubscription = null;
    _cancelTimers();
    super.dispose();
  }
}
