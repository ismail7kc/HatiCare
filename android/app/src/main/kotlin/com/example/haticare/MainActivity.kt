package com.example.haticare

import android.util.Log
import com.twilio.voice.Call
import com.twilio.voice.CallException
import com.twilio.voice.ConnectOptions
import com.twilio.voice.Voice

import android.media.AudioManager
import android.content.Context

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "twilio_call"
    private val EVENTS_CHANNEL = "twilio_call_events"

    private val AUDIO_CHANNEL = "audio_route"
    private lateinit var audioManager: AudioManager

    private var activeCall: Call? = null
    private var eventSink: EventChannel.EventSink? = null


    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENTS_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                }

                override fun onCancel(arguments: Any?) {
                    eventSink = null
                }
            })

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        .setMethodCallHandler { call, result ->
            when (call.method) {
                "startCall" -> {
                    val token = call.argument<String>("token")
                    val to = call.argument<String>("to")
                    val visitId = call.argument<Int>("visitId")

                    if (token.isNullOrEmpty() || to.isNullOrEmpty()) {
                        emitCallEvent("failed", "Missing token or number")
                        result.error("INVALID", "Missing token or number", null)
                        return@setMethodCallHandler
                    }

                    try {
                        startTwilioCall(token, to, visitId)
                        result.success("Calling Started")
                    } catch (e: Exception) {
                        Log.e("TWILIO", "Unable to start call", e)
                        emitCallEvent("failed", e.message ?: "Unable to start call")
                        result.error("CALL_FAILED", e.message, null)
                    }
                }

                "endCall" -> {
                    activeCall?.disconnect()
                    activeCall = null
                    result.success("Call Ended")
                }

                "setMuted" -> {
                    val muted = call.argument<Boolean>("muted") ?: false
                    activeCall?.mute(muted)
                    result.success(null)
                }

                else -> result.notImplemented()
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, AUDIO_CHANNEL)
        .setMethodCallHandler { call, result ->
            when (call.method) {
                "setSpeaker" -> {
                    val enabled = call.argument<Boolean>("enabled") ?: false
                    setSpeakerphone(enabled)
                    result.success(null)
                }

                else -> result.notImplemented()
            }
        }
    }

    private fun setSpeakerphone(enabled: Boolean) {
        audioManager.mode = AudioManager.MODE_IN_COMMUNICATION
        audioManager.isSpeakerphoneOn = enabled
        Log.d("AUDIO_ROUTE", "Speaker ${if (enabled) "ON" else "OFF"}")
    }

    /**
     * Sends call state to Flutter so the UI can follow what Twilio is actually doing
     * (ringing, connected, reconnecting) and report connect failures instead of
     * assuming every call connected successfully.
     */
    private fun emitCallEvent(event: String, message: String? = null, code: Int? = null) {
        Log.d("TWILIO", "Call event: $event message=${message ?: "-"} code=${code ?: -1}")

        val sink = eventSink ?: return

        val payload = HashMap<String, Any?>()
        payload["event"] = event
        if (message != null) payload["message"] = message
        if (code != null) payload["code"] = code

        runOnUiThread { sink.success(payload) }
    }

    private fun startTwilioCall(token: String, to: String, visitId: Int?) {

        val params = HashMap<String, String>()
        params["To"] = to

        // Custom connect parameter: Twilio forwards this to the TwiML app voice
        // URL, so /calls/app-dial/ can read visit_id instead of guessing it.
        if (visitId != null) {
            params["visit_id"] = visitId.toString()
            Log.d("TWILIO", "Connecting with visit_id=$visitId")
        } else {
            Log.w("TWILIO", "Connecting without visit_id")
        }

        val connectOptions = ConnectOptions.Builder(token)
            .params(params)
            .build()

        activeCall = Voice.connect(
            this,
            connectOptions,
            object : Call.Listener {

                override fun onConnected(call: Call) {
                    Log.d("TWILIO", "Call Connected")
                    emitCallEvent("connected")
                }

                override fun onRinging(call: Call) {
                    Log.d("TWILIO", "Call Ringing")
                    emitCallEvent("ringing")
                }

                override fun onReconnecting(call: Call, error: CallException) {
                    Log.w("TWILIO", "Call Reconnecting: ${error.message}")
                    emitCallEvent("reconnecting", error.message)
                }

                override fun onReconnected(call: Call) {
                    Log.d("TWILIO", "Call Reconnected")
                    emitCallEvent("reconnected")
                }

                override fun onDisconnected(call: Call, error: CallException?) {
                    Log.d(
                        "TWILIO",
                        "Call Disconnected: ${error?.message ?: "no error"}"
                    )
                    activeCall = null
                    // No error means somebody hung up normally; an error (no answer,
                    // busy, network drop) is passed to Flutter which decides whether
                    // the call ever connected.
                    emitCallEvent("disconnected", error?.message, error?.errorCode)
                }

                override fun onConnectFailure(call: Call, error: CallException) {
                    Log.e("TWILIO", "Call Failed: ${error.message}")
                    activeCall = null
                    emitCallEvent("failed", error.message, error.errorCode)
                }
            }
        )
    }
}
