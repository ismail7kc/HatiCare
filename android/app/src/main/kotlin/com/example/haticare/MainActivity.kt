package com.example.haticare

import android.util.Log
import com.twilio.voice.Call
import com.twilio.voice.ConnectOptions
import com.twilio.voice.Voice

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "twilio_call"
    private var activeCall: Call? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->

            when (call.method) {

                "startCall" -> {
                    val token = call.argument<String>("token")
                    val to = call.argument<String>("to")

                    if (token == null || to == null) {
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

                else -> result.notImplemented()
            }
        }
    }

    private fun startTwilioCall(token: String, to: String) {

        val params = HashMap<String, String>()
        params["To"] = to

        val connectOptions = ConnectOptions.Builder(token)
            .params(params)
            .build()

        activeCall = Voice.connect(this, connectOptions, object : Call.Listener {

            override fun onConnected(call: Call) {
                Log.d("TWILIO", "Call Connected")
            }

            override fun onDisconnected(call: Call, error: Call.Exception?) {
                Log.d("TWILIO", "Call Disconnected")
            }

            override fun onConnectFailure(call: Call, error: Call.Exception) {
                Log.e("TWILIO", "Call Failed: ${error.message}")
            }
        })
    }
}
