package com.example.notification_voip_plugin.handlers

import com.google.firebase.messaging.FirebaseMessaging
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class TokenHandler {
    var tokenRefreshSink: EventChannel.EventSink? = null

    fun getFCMToken(result: MethodChannel.Result) {
        FirebaseMessaging.getInstance().token
            .addOnSuccessListener { token -> result.success(token) }
            .addOnFailureListener { e -> result.error("TOKEN_ERROR", e.message, null) }
    }

    fun getAPNsToken(result: MethodChannel.Result) = result.success(null)
    fun getVoIPToken(result: MethodChannel.Result) = result.success(null)

    fun onTokenRefresh(token: String) {
        tokenRefreshSink?.success(token)
    }
}
