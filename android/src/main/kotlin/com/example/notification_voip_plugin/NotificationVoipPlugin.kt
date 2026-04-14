package com.example.notification_voip_plugin

import android.app.Activity
import android.content.Context
import android.content.Intent
import com.example.notification_voip_plugin.handlers.CallHandler
import com.example.notification_voip_plugin.handlers.NotificationHandler
import com.example.notification_voip_plugin.handlers.PermissionHandler
import com.example.notification_voip_plugin.handlers.TokenHandler
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry

class NotificationVoipPlugin : FlutterPlugin, MethodChannel.MethodCallHandler, ActivityAware, PluginRegistry.NewIntentListener {

    private lateinit var context: Context
    private lateinit var channel: MethodChannel
    private lateinit var inappEventChannel: EventChannel
    private lateinit var voipEventChannel: EventChannel
    private lateinit var callStateChannel: EventChannel
    private lateinit var tokenRefreshChannel: EventChannel

    private lateinit var notificationHandler: NotificationHandler
    private lateinit var permissionHandler: PermissionHandler
    private lateinit var tokenHandler: TokenHandler

    /// Pending notification tap events buffered before the Dart sink is ready.
    private val pendingNotificationTapEvents = mutableListOf<Map<String, Any>>()

    companion object {
        var callHandler: CallHandler? = null
            private set

        fun setCallHandler(handler: CallHandler?) {
            callHandler = handler
        }
    }

    private var permissionListenerRegistered = false

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext

        // Handlers
        notificationHandler = NotificationHandler(context)
        permissionHandler = PermissionHandler(context)
        tokenHandler = TokenHandler()
        setCallHandler(CallHandler(context))

        // MethodChannel
        channel = MethodChannel(binding.binaryMessenger, "notification_voip_plugin")
        channel.setMethodCallHandler(this)

        // EventChannels with dedicated sinks
        inappEventChannel = EventChannel(binding.binaryMessenger, "notification_voip_plugin/inapp_events")
        inappEventChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                notificationHandler.inappEventSink = events
                // Drain any events buffered before the sink was ready
                if (events != null && pendingNotificationTapEvents.isNotEmpty()) {
                    for (event in pendingNotificationTapEvents) {
                        events.success(event)
                    }
                    pendingNotificationTapEvents.clear()
                }
            }
            override fun onCancel(arguments: Any?) {
                notificationHandler.inappEventSink = null
            }
        })

        voipEventChannel = EventChannel(binding.binaryMessenger, "notification_voip_plugin/voip_events")
        voipEventChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                callHandler?.voipEventSink = events
            }
            override fun onCancel(arguments: Any?) {
                callHandler?.voipEventSink = null
            }
        })

        callStateChannel = EventChannel(binding.binaryMessenger, "notification_voip_plugin/call_state")
        callStateChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                callHandler?.callStateSink = events
            }
            override fun onCancel(arguments: Any?) {
                callHandler?.callStateSink = null
            }
        })

        tokenRefreshChannel = EventChannel(binding.binaryMessenger, "notification_voip_plugin/token_refresh")
        tokenRefreshChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                tokenHandler.tokenRefreshSink = events
            }
            override fun onCancel(arguments: Any?) {
                tokenHandler.tokenRefreshSink = null
            }
        })
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        inappEventChannel.setStreamHandler(null)
        voipEventChannel.setStreamHandler(null)
        callStateChannel.setStreamHandler(null)
        tokenRefreshChannel.setStreamHandler(null)
        setCallHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        val activity = binding.activity
        notificationHandler.activity = activity
        permissionHandler.activity = activity
        callHandler?.activity = activity
        if (!permissionListenerRegistered) {
            binding.addRequestPermissionsResultListener(permissionHandler)
            binding.addRequestPermissionsResultListener(callHandler!!)
            permissionListenerRegistered = true
        }
        binding.addOnNewIntentListener(this)
        // Check if the activity was launched from a notification tap
        handleNotificationIntent(activity.intent)
    }

    override fun onDetachedFromActivity() {
        notificationHandler.activity = null
        permissionHandler.activity = null
        callHandler?.activity = null
        permissionListenerRegistered = false
    }

    override fun onDetachedFromActivityForConfigChanges() {
        notificationHandler.activity = null
        permissionHandler.activity = null
        callHandler?.activity = null
        permissionListenerRegistered = false
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        val activity = binding.activity
        notificationHandler.activity = activity
        permissionHandler.activity = activity
        callHandler?.activity = activity
        if (!permissionListenerRegistered) {
            binding.addRequestPermissionsResultListener(permissionHandler)
            binding.addRequestPermissionsResultListener(callHandler!!)
            permissionListenerRegistered = true
        }
        binding.addOnNewIntentListener(this)
    }

    override fun onNewIntent(intent: Intent): Boolean {
        handleNotificationIntent(intent)
        return false
    }

    private fun handleNotificationIntent(intent: Intent?) {
        if (intent == null) return
        val isNotificationTap = intent.getStringExtra("notification_tap") == "true"
        val isNotificationAction = intent.getStringExtra("notification_action") == "true"
        if (!isNotificationTap && !isNotificationAction) return

        val extras = intent.extras ?: return
        val eventData = mutableMapOf<String, Any>()
        for (key in extras.keySet()) {
            // Skip internal Android keys
            if (key.startsWith("android.") || key == "notification_tap" || key == "notification_action") continue
            val value = extras.getString(key)
            if (value != null) eventData[key] = value
        }
        if (isNotificationAction) {
            val actionId = intent.getStringExtra("action_id")
            if (actionId != null) eventData["actionId"] = actionId
            // Check for inline reply text
            val remoteInput = androidx.core.app.RemoteInput.getResultsFromIntent(intent)
            if (remoteInput != null && actionId != null) {
                val replyText = remoteInput.getCharSequence(actionId)?.toString()
                if (replyText != null) eventData["replyText"] = replyText
            }
        }

        if (eventData.isNotEmpty()) {
            val sink = notificationHandler.inappEventSink
            if (sink != null) {
                sink.success(eventData)
            } else {
                pendingNotificationTapEvents.add(eventData)
            }
        }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "init" -> {
                val config = call.arguments as? Map<String, Any>
                notificationHandler.configure(config)
                callHandler?.configure(config)
                result.success(null)
            }
            // Tokens
            "getPushToken", "getFCMToken" -> tokenHandler.getFCMToken(result)
            "getAPNsToken" -> tokenHandler.getAPNsToken(result)
            "getVoIPToken" -> tokenHandler.getVoIPToken(result)
            // Permissions
            "requestPermission" -> permissionHandler.requestNotificationPermission(result)
            "isPermissionGranted" -> permissionHandler.isPermissionGranted(result)
            "openSettings" -> permissionHandler.openSettings(result)
            // Notifications
            "showNotification" -> notificationHandler.showNotification(call, result)
            "showInAppNotification" -> notificationHandler.showInAppNotification(call, result)
            "clearAll" -> notificationHandler.clearAll(result)
            "cancelNotification" -> notificationHandler.cancelNotification(call, result)
            "suppressNextForegroundNotification" -> result.success(null) // iOS-only, no-op on Android
            "setBadgeCount" -> notificationHandler.setBadgeCount(call, result)
            "getBadgeCount" -> notificationHandler.getBadgeCount(result)
            // Calls
            "showIncomingCall" -> callHandler?.showIncomingCall(call, result) ?: result.error("NO_HANDLER", "CallHandler not initialized", null)
            "showOutgoingCall" -> callHandler?.showOutgoingCall(call, result) ?: result.error("NO_HANDLER", "CallHandler not initialized", null)
            "acceptCall" -> callHandler?.acceptCall(call, result) ?: result.error("NO_HANDLER", "CallHandler not initialized", null)
            "rejectCall" -> callHandler?.rejectCall(call, result) ?: result.error("NO_HANDLER", "CallHandler not initialized", null)
            "endCall" -> callHandler?.endCall(call, result) ?: result.error("NO_HANDLER", "CallHandler not initialized", null)
            "endAllCalls" -> callHandler?.endAllCalls(result) ?: result.success(null)
            "setCallConnected" -> callHandler?.setCallConnected(call, result) ?: result.success(null)
            "getActiveCallIds" -> callHandler?.getActiveCallIds(result) ?: result.success(emptyList<String>())
            "toggleMute" -> callHandler?.toggleMute(call, result) ?: result.success(null)
            "toggleSpeaker" -> callHandler?.toggleSpeaker(call, result) ?: result.success(null)
            "toggleCamera" -> callHandler?.toggleCamera(call, result) ?: result.success(null)
            "isPhoneAccountEnabled" -> callHandler?.isPhoneAccountEnabled(result) ?: result.success(false)
            "openPhoneAccountSettings" -> callHandler?.openPhoneAccountSettings(result) ?: result.success(null)
            // Lifecycle
            "dispose" -> {
                callHandler?.dispose()
                CallConnectionService.endAllCalls()
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }
}
