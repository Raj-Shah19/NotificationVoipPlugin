package com.example.notification_voip_plugin.handlers

import android.Manifest
import android.app.Activity
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.media.AudioManager
import android.telecom.PhoneAccount
import android.telecom.PhoneAccountHandle
import android.telecom.TelecomManager
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import com.example.notification_voip_plugin.CallConnectionService
import com.example.notification_voip_plugin.models.CallState
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry
import android.net.Uri
import android.os.Bundle

class CallHandler(private val context: Context) : PluginRegistry.RequestPermissionsResultListener {
    companion object {
        private const val REQUEST_PHONE_PERMISSION = 2202
    }

    var activity: Activity? = null
    var voipEventSink: EventChannel.EventSink? = null
    var callStateSink: EventChannel.EventSink? = null
    private var pendingResult: MethodChannel.Result? = null
    private var phoneAccountId: String = "NvpVoipAccount"
    private var phoneAccountLabel: String = "VoIP Calls"

    private val activeCalls = mutableMapOf<String, CallState>()
    private val callerInfo = mutableMapOf<String, Map<String, Any>>()
    private val audioManager: AudioManager by lazy {
        context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
    }

    fun configure(config: Map<String, Any>?) {
        config?.let {
            phoneAccountId = it["phoneAccountId"] as? String ?: "NvpVoipAccount"
            phoneAccountLabel = it["appName"] as? String ?: "VoIP Calls"
        }
        registerPhoneAccount()
    }

    private fun registerPhoneAccount() {
        try {
            val telecomManager = context.getSystemService(Context.TELECOM_SERVICE) as TelecomManager
            val handle = PhoneAccountHandle(
                ComponentName(context, CallConnectionService::class.java), phoneAccountId
            )
            val account = PhoneAccount.builder(handle, phoneAccountLabel)
                .setCapabilities(PhoneAccount.CAPABILITY_CALL_PROVIDER)
                .build()
            telecomManager.registerPhoneAccount(account)
        } catch (e: Exception) {
            android.util.Log.e("NVP", "registerPhoneAccount: $e")
        }
    }

    fun showIncomingCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            val args = call.arguments as? Map<*, *> ?: emptyMap<String, Any>()
            val callId = args["callId"] as? String ?: ""
            val callerName = args["callerName"] as? String ?: "Unknown"
            val isVideo = args["isVideo"] as? Boolean ?: false
            val useNativeScreen = args["useNativeScreen"] as? Boolean ?: true
            val duration = args["duration"] as? Int

            val state = CallState(callId = callId, status = "ringing", isCameraOn = isVideo)
            activeCalls[callId] = state
            callerInfo[callId] = mapOf("callerName" to callerName, "isVideo" to isVideo)
            emitCallState(state)

            if (useNativeScreen) {
                // Ensure phone account is registered before attempting the call
                registerPhoneAccount()

                val telecomManager = context.getSystemService(Context.TELECOM_SERVICE) as TelecomManager
                val handle = PhoneAccountHandle(
                    ComponentName(context, CallConnectionService::class.java), phoneAccountId
                )

                val extras = Bundle().apply {
                    val uri = Uri.fromParts("tel", callId, null)
                    putParcelable(TelecomManager.EXTRA_INCOMING_CALL_ADDRESS, uri)
                    putString("callerId", callId)
                    putString("callerName", callerName)
                    putBoolean("isVideo", isVideo)
                }
                telecomManager.addNewIncomingCall(handle, extras)
            } else {
                // Custom screen mode: emit the event with full caller info
                // so Flutter can show its own UI. All lifecycle (accept, reject,
                // end, timeout) still works through CallHandler.
                onCallAction("incoming", callId, mapOf(
                    "callerName" to callerName,
                    "isVideo" to isVideo
                ))
            }

            // Auto-end the call after the specified duration if still ringing
            if (duration != null && duration > 0) {
                android.os.Handler(android.os.Looper.getMainLooper()).postDelayed({
                    val currentState = activeCalls[callId]
                    if (currentState != null && currentState.status == "ringing") {
                        currentState.status = "ended"
                        emitCallState(currentState)
                        activeCalls.remove(callId)
                        CallConnectionService.endCall(callId)
                        onCallAction("ended", callId)
                    }
                }, duration.toLong() * 1000)
            }

            result.success(null)
        } catch (e: SecurityException) {
            result.error(
                "PHONE_ACCOUNT_NOT_ENABLED",
                "The VoIP phone account is not enabled. Please enable it in Settings → Phone → Calling accounts.",
                null
            )
        } catch (e: Exception) {
            val msg = e.message ?: ""
            if (msg.contains("PhoneAccountHandle") && msg.contains("not enabled")) {
                result.error(
                    "PHONE_ACCOUNT_NOT_ENABLED",
                    "The VoIP phone account is not enabled. Please enable it in Settings → Phone → Calling accounts.",
                    null
                )
            } else {
                result.error("CALL_ERROR", msg, null)
            }
        }
    }

    fun showOutgoingCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            val args = call.arguments as? Map<*, *> ?: emptyMap<String, Any>()
            val callId = args["callId"] as? String ?: ""
            val isVideo = args["isVideo"] as? Boolean ?: false

            val state = CallState(callId = callId, status = "ringing", isCameraOn = isVideo)
            activeCalls[callId] = state
            emitCallState(state)
            result.success(null)
        } catch (e: Exception) {
            result.error("CALL_ERROR", e.message, null)
        }
    }

    fun acceptCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            val callId = call.argument<String>("callId") ?: ""
            val state = activeCalls[callId]
            if (state != null) {
                state.status = "connected"
                state.connectedAt = System.currentTimeMillis()
                emitCallState(state)
            }
            onCallAction("accept", callId)
            result.success(null)
        } catch (e: Exception) {
            result.error("CALL_ERROR", e.message, null)
        }
    }

    fun rejectCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            val callId = call.argument<String>("callId") ?: ""
            val state = activeCalls[callId]
            if (state != null) {
                state.status = "ended"
                emitCallState(state)
                activeCalls.remove(callId)
            }
            CallConnectionService.endCall(callId)
            onCallAction("decline", callId)
            result.success(null)
        } catch (e: Exception) {
            result.error("CALL_ERROR", e.message, null)
        }
    }

    fun endCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            val callId = call.argument<String>("callId") ?: ""
            val state = activeCalls[callId]
            if (state != null) {
                state.status = "ended"
                emitCallState(state)
                activeCalls.remove(callId)
            }

            // End via ConnectionService stored connections
            CallConnectionService.endCall(callId)
            result.success(null)
        } catch (e: Exception) {
            result.error("CALL_ERROR", e.message, null)
        }
    }

    fun endAllCalls(result: MethodChannel.Result) {
        try {
            val entries = activeCalls.entries.toList() // snapshot to avoid ConcurrentModificationException
            for ((_, state) in entries) {
                state.status = "ended"
                emitCallState(state)
            }
            activeCalls.clear()
            callerInfo.clear()
            CallConnectionService.endAllCalls()
            result.success(null)
        } catch (e: Exception) {
            result.error("CALL_ERROR", e.message, null)
        }
    }

    fun setCallConnected(call: MethodCall, result: MethodChannel.Result) {
        try {
            val callId = call.argument<String>("callId") ?: ""
            val state = activeCalls[callId]
            if (state != null) {
                state.status = "connected"
                state.connectedAt = System.currentTimeMillis()
                emitCallState(state)
            }
            result.success(null)
        } catch (e: Exception) {
            result.error("CALL_ERROR", e.message, null)
        }
    }

    fun getActiveCallIds(result: MethodChannel.Result) {
        result.success(ArrayList(activeCalls.keys))
    }

    fun toggleMute(call: MethodCall, result: MethodChannel.Result) {
        val callId = call.argument<String>("callId") ?: ""
        val state = activeCalls[callId]
        if (state != null) {
            state.isMuted = !state.isMuted
            audioManager.isMicrophoneMute = state.isMuted
            emitCallState(state)
        }
        result.success(null)
    }

    fun toggleSpeaker(call: MethodCall, result: MethodChannel.Result) {
        val callId = call.argument<String>("callId") ?: ""
        val state = activeCalls[callId]
        if (state != null) {
            state.isSpeakerOn = !state.isSpeakerOn
            audioManager.isSpeakerphoneOn = state.isSpeakerOn
            emitCallState(state)
        }
        result.success(null)
    }

    fun toggleCamera(call: MethodCall, result: MethodChannel.Result) {
        val callId = call.argument<String>("callId") ?: ""
        val state = activeCalls[callId]
        if (state != null) {
            state.isCameraOn = !state.isCameraOn
            emitCallState(state)
        }
        result.success(null)
    }

    fun isPhoneAccountEnabled(result: MethodChannel.Result) {
        if (ContextCompat.checkSelfPermission(context, Manifest.permission.READ_PHONE_NUMBERS)
            != PackageManager.PERMISSION_GRANTED
        ) {
            pendingResult = result
            activity?.let {
                ActivityCompat.requestPermissions(
                    it, arrayOf(Manifest.permission.READ_PHONE_NUMBERS), REQUEST_PHONE_PERMISSION
                )
            } ?: result.error("NO_ACTIVITY", "Activity is null", null)
            return
        }
        checkPhoneAccountEnabled(result)
    }

    private fun checkPhoneAccountEnabled(result: MethodChannel.Result) {
        try {
            val telecomManager = context.getSystemService(Context.TELECOM_SERVICE) as TelecomManager
            val handle = PhoneAccountHandle(
                ComponentName(context, CallConnectionService::class.java), phoneAccountId
            )
            val account = telecomManager.getPhoneAccount(handle)
            result.success(account?.isEnabled ?: false)
        } catch (e: SecurityException) {
            result.error("SECURITY_ERROR", e.message, null)
        }
    }

    fun openPhoneAccountSettings(result: MethodChannel.Result) {
        val intent = Intent(TelecomManager.ACTION_CHANGE_PHONE_ACCOUNTS)
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        context.startActivity(intent)
        result.success(null)
    }

    fun onCallAction(action: String, callId: String, payload: Map<String, Any> = emptyMap()) {
        // Merge stored caller info into the event so Flutter always has it
        val info = callerInfo[callId] ?: emptyMap()
        val mergedPayload = info + payload

        voipEventSink?.success(mapOf(
            "action" to action,
            "callId" to callId,
            "callerName" to (mergedPayload["callerName"] ?: ""),
            "isVideo" to (mergedPayload["isVideo"] ?: false),
            "payload" to mergedPayload
        ))

        when (action) {
            "accept" -> {
                activeCalls[callId]?.let {
                    it.status = "connected"
                    it.connectedAt = System.currentTimeMillis()
                    emitCallState(it)
                }
            }
            "decline", "ended" -> {
                activeCalls[callId]?.let {
                    it.status = "ended"
                    emitCallState(it)
                }
                activeCalls.remove(callId)
                callerInfo.remove(callId)
            }
        }
    }

    fun hasActiveCall(callId: String): Boolean {
        return activeCalls.containsKey(callId)
    }

    private fun emitCallState(state: CallState) {
        callStateSink?.success(state.toMap())
    }

    fun dispose() {
        activeCalls.clear()
        callerInfo.clear()
    }

    override fun onRequestPermissionsResult(
        requestCode: Int, permissions: Array<out String>, grantResults: IntArray
    ): Boolean {
        if (requestCode == REQUEST_PHONE_PERMISSION) {
            val granted = grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED
            if (granted) {
                pendingResult?.let { checkPhoneAccountEnabled(it) }
            } else {
                pendingResult?.success(false)
            }
            pendingResult = null
            return true
        }
        return false
    }
}
