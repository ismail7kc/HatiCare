import AVFoundation
import Flutter
import TwilioVoice
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, CallDelegate, FlutterStreamHandler {

  private let callChannelName = "twilio_call"
  private let audioRouteChannelName = "audio_route"
  private let callEventsChannelName = "twilio_call_events"

  private var callChannel: FlutterMethodChannel?
  private var audioRouteChannel: FlutterMethodChannel?
  private var callEventsChannel: FlutterEventChannel?

  private var activeCall: Call?
  private var eventSink: FlutterEventSink?
  private var speakerEnabled = false

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    if let controller = window?.rootViewController as? FlutterViewController {
      let messenger = controller.binaryMessenger
      registerCallChannel(messenger: messenger)
      registerAudioRouteChannel(messenger: messenger)
      registerCallEventsChannel(messenger: messenger)
    } else {
      NSLog("TWILIO: root view controller is not a FlutterViewController, call channels not registered")
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // MARK: - Channels

  private func registerCallChannel(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: callChannelName, binaryMessenger: messenger)
    callChannel = channel

    channel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else {
        result(FlutterError(code: "UNAVAILABLE", message: "App delegate was deallocated", details: nil))
        return
      }

      switch call.method {
      case "startCall":
        self.handleStartCall(call, result: result)

      case "endCall":
        // Works while connecting as well: the SDK cancels the pending call.
        self.activeCall?.disconnect()
        self.activeCall = nil
        result("Call Ended")

      case "setMuted":
        let arguments = call.arguments as? [String: Any]
        let muted = arguments?["muted"] as? Bool ?? false
        self.activeCall?.isMuted = muted
        result(nil)

      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func registerAudioRouteChannel(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: audioRouteChannelName, binaryMessenger: messenger)
    audioRouteChannel = channel

    channel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else {
        result(FlutterError(code: "UNAVAILABLE", message: "App delegate was deallocated", details: nil))
        return
      }

      switch call.method {
      case "setSpeaker":
        let arguments = call.arguments as? [String: Any]
        let enabled = arguments?["enabled"] as? Bool ?? false
        self.setSpeaker(enabled)
        result(nil)

      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func registerCallEventsChannel(messenger: FlutterBinaryMessenger) {
    let channel = FlutterEventChannel(name: callEventsChannelName, binaryMessenger: messenger)
    callEventsChannel = channel
    channel.setStreamHandler(self)
  }

  // MARK: - FlutterStreamHandler

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    eventSink = events
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    eventSink = nil
    return nil
  }

  // MARK: - Outgoing calls

  private func handleStartCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    let arguments = call.arguments as? [String: Any]
    let visitId = arguments?["visitId"] as? Int

    guard let token = arguments?["token"] as? String, !token.isEmpty,
      let to = arguments?["to"] as? String, !to.isEmpty
    else {
      let message = "Missing token or number"
      emitCallEvent("failed", message: message)
      result(FlutterError(code: "INVALID", message: message, details: nil))
      return
    }

    let connectOptions = ConnectOptions(accessToken: token) { builder in
      builder.params = [:]

      // Custom connect parameter: Twilio forwards this to the TwiML app voice
      // URL, so /calls/app-dial/ can read visit_id instead of guessing it.
      builder.params["To"] = to
      if let visitId = visitId {
        builder.params["visit_id"] = String(visitId)
        NSLog("TWILIO: Connecting with visit_id=\(visitId)")
      } else {
        NSLog("TWILIO: Connecting without visit_id")
      }
    }

    activeCall = TwilioVoiceSDK.connect(options: connectOptions, delegate: self)
    result("Calling Started")
  }

  private func setSpeaker(_ enabled: Bool) {
    speakerEnabled = enabled
    applySpeakerRoute()
  }

  private func applySpeakerRoute() {
    let session = AVAudioSession.sharedInstance()
    do {
      try session.overrideOutputAudioPort(speakerEnabled ? .speaker : .none)
      NSLog("AUDIO_ROUTE: Speaker \(speakerEnabled ? "ON" : "OFF")")
    } catch {
      NSLog("AUDIO_ROUTE: Unable to change audio route: \(error.localizedDescription)")
    }
  }

  // MARK: - Call state reporting

  /// Sends call state to Flutter so the UI can follow what Twilio is actually doing
  /// (ringing, connected, reconnecting) and report connect failures instead of
  /// assuming every call connected successfully.
  private func emitCallEvent(_ event: String, message: String? = nil, code: Int? = nil) {
    NSLog("TWILIO: Call event=\(event) message=\(message ?? "-") code=\(code.map(String.init) ?? "-")")

    guard let sink = eventSink else { return }

    var payload: [String: Any] = ["event": event]
    if let message = message, !message.isEmpty {
      payload["message"] = message
    }
    if let code = code {
      payload["code"] = code
    }

    DispatchQueue.main.async { sink(payload) }
  }

  // MARK: - CallDelegate

  func callDidStartRinging(call: Call) {
    emitCallEvent("ringing")
  }

  func callDidConnect(call: Call) {
    applySpeakerRoute()
    emitCallEvent("connected")
  }

  func callIsReconnecting(call: Call, error: Error) {
    emitCallEvent("reconnecting", message: error.localizedDescription)
  }

  func callDidReconnect(call: Call) {
    emitCallEvent("reconnected")
  }

  func callDidFailToConnect(call: Call, error: Error) {
    activeCall = nil
    emitCallEvent("failed", message: error.localizedDescription, code: (error as NSError).code)
  }

  func callDidDisconnect(call: Call, error: Error?) {
    activeCall = nil

    guard let error = error else {
      // Somebody hung up normally.
      emitCallEvent("disconnected")
      return
    }

    // An error (no answer, busy, network drop) is passed to Flutter which decides
    // whether the call ever connected.
    emitCallEvent("disconnected", message: error.localizedDescription, code: (error as NSError).code)
  }
}
