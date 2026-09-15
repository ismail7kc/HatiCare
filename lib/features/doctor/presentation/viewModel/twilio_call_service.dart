import 'dart:async';
import 'package:flutter/services.dart';

/// The states the native Twilio SDK reports for an outgoing call.
enum TwilioCallEventType {
  ringing,
  connected,
  reconnecting,
  reconnected,

  /// The call ended. `message`/`code` are set when it ended because of an error
  /// (no answer, busy, network drop, ...).
  disconnected,

  /// The call could never be established.
  failed,

  unknown,
}

class TwilioCallEvent {
  final TwilioCallEventType type;
  final String? message;

  /// Twilio error code, when the SDK provided one (e.g. 31487 for "no answer").
  final int? code;

  const TwilioCallEvent({required this.type, this.message, this.code});

  bool get isTerminal =>
      type == TwilioCallEventType.failed || type == TwilioCallEventType.disconnected;

  factory TwilioCallEvent.fromMap(dynamic raw) {
    if (raw is! Map) {
      return TwilioCallEvent(
        type: TwilioCallEventType.unknown,
        message: raw?.toString(),
      );
    }

    return TwilioCallEvent(
      type: _typeFromName(raw['event'] as String?),
      message: raw['message'] as String?,
      code: raw['code'] as int?,
    );
  }

  static TwilioCallEventType _typeFromName(String? name) {
    switch (name) {
      case 'ringing':
        return TwilioCallEventType.ringing;
      case 'connected':
        return TwilioCallEventType.connected;
      case 'reconnecting':
        return TwilioCallEventType.reconnecting;
      case 'reconnected':
        return TwilioCallEventType.reconnected;
      case 'disconnected':
        return TwilioCallEventType.disconnected;
      case 'failed':
        return TwilioCallEventType.failed;
      default:
        return TwilioCallEventType.unknown;
    }
  }

  @override
  String toString() => 'TwilioCallEvent($type, message: $message, code: $code)';
}

class TwilioCallService {
  static const MethodChannel _channel = MethodChannel("twilio_call");
  static const EventChannel _eventsChannel = EventChannel("twilio_call_events");

  /// Call state reported by the native Twilio SDK.
  ///
  /// Stream errors are converted into [TwilioCallEventType.failed] events so a
  /// broken native channel can never leave the UI stuck on "Calling...".
  static Stream<TwilioCallEvent> get callEvents =>
      _eventsChannel.receiveBroadcastStream().transform(
        StreamTransformer<dynamic, TwilioCallEvent>.fromHandlers(
          handleData: (data, sink) => sink.add(TwilioCallEvent.fromMap(data)),
          handleError: (error, stackTrace, sink) => sink.add(
            TwilioCallEvent(
              type: TwilioCallEventType.failed,
              message: error is PlatformException
                  ? (error.message ?? error.code)
                  : error.toString(),
            ),
          ),
        ),
      );

  static Future<void> startCall({
    required String token,
    required String patientNumber,
    int? visitId,
  }) async {
    await _channel.invokeMethod("startCall", {
      "token": token,
      "to": patientNumber,
      // Sent to Twilio as a custom connect parameter so the TwiML app
      // (/calls/app-dial/) receives visit_id instead of resolving it by caller.
      if (visitId != null) "visitId": visitId,
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
