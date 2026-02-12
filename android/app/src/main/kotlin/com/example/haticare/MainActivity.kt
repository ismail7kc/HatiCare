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
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "twilio_call"
    private var activeCall: Call? = null

    private val AUDIO_CHANNEL = "audio_route"
    private lateinit var audioManager: AudioManager


    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        .setMethodCallHandler { call, result ->
            when (call.method) {
                "startCall" -> {
                    val token = call.argument<String>("token")
                    val to = call.argument<String>("to")

                    if (token.isNullOrEmpty() || to.isNullOrEmpty()) {
                        result.error("INVALID", "Missing token or number", null)
                        return@setMethodCallHandler
                    }

                    startTwilioCall(token, to)
                    result.success("Calling Started")
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

    private fun startTwilioCall(token: String, to: String) {

        val params = HashMap<String, String>()
        params["To"] = to

        val connectOptions = ConnectOptions.Builder(token)
            .params(params)
            .build()

        activeCall = Voice.connect(
            this,
            connectOptions,
            object : Call.Listener {

                override fun onConnected(call: Call) {
                    Log.d("TWILIO", "Call Connected")
                }

                override fun onRinging(call: Call) {
                    Log.d("TWILIO", "Call Ringing")
                }

                override fun onReconnecting(call: Call, error: CallException) {
                    Log.w("TWILIO", "Call Reconnecting: ${error.message}")
                }

                override fun onReconnected(call: Call) {
                    Log.d("TWILIO", "Call Reconnected")
                }

                override fun onDisconnected(call: Call, error: CallException?) {
                    Log.d(
                        "TWILIO",
                        "Call Disconnected: ${error?.message ?: "no error"}"
                    )
                }

                override fun onConnectFailure(call: Call, error: CallException) {
                    Log.e("TWILIO", "Call Failed: ${error.message}")
                }
            }
        )
    }
}
