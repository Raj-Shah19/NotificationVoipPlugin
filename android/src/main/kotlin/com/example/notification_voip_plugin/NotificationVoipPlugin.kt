package com.example.notification_voip_plugin

import android.Manifest
import android.app.Activity
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.view.Gravity
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.FrameLayout
import android.widget.ImageView
import android.widget.TextView
import android.widget.Toast
import androidx.annotation.NonNull
import androidx.core.app.ActivityCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import com.google.firebase.messaging.FirebaseMessaging
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.*
import java.io.InputStream
import java.net.HttpURLConnection
import java.net.URL
import java.util.concurrent.Executors
import android.telecom.TelecomManager
import android.telecom.PhoneAccount
import android.telecom.PhoneAccountHandle
import android.content.ComponentName
import android.content.Context

class NotificationVoipPlugin : FlutterPlugin, MethodChannel.MethodCallHandler,
    ActivityAware, PluginRegistry.RequestPermissionsResultListener,
    EventChannel.StreamHandler {

    private lateinit var context: Context
    private lateinit var channel: MethodChannel
    private lateinit var eventChannel: EventChannel

    private var activity: Activity? = null
    private var notificationManager: NotificationManager? = null
    private var pendingResult: MethodChannel.Result? = null
    private var eventSink: EventChannel.EventSink? = null

    // ✅ Added for overlay management
    private var currentOverlay: View? = null

    companion object {
        private const val CHANNEL_ID = "foreground_notifications"
        private const val CHANNEL_NAME = "Foreground Notifications"
        private const val REQUEST_NOTIFICATION_PERMISSION = 1001
        private const val REQUEST_ANSWER_CALLS_PERMISSION = 2203
        private val REQUEST_PHONE_PERMISSION = 2202
        var callActionEventSink: EventChannel.EventSink? = null
    }

    private var answerCallPermissionResult: MethodChannel.Result? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        notificationManager =
            ContextCompat.getSystemService(context, NotificationManager::class.java)

        channel = MethodChannel(binding.binaryMessenger, "notification_voip_plugin")
        eventChannel =
            EventChannel(binding.binaryMessenger, "notification_voip_plugin/inapp_events")

        channel.setMethodCallHandler(this)
        eventChannel.setStreamHandler(this)

        createNotificationChannel()
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        // ✅ Clean up overlay
        removeCurrentOverlay()
        channel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        binding.addRequestPermissionsResultListener(this)
    }

    override fun onDetachedFromActivity() {
        // ✅ Clean up overlay when activity detaches
        removeCurrentOverlay()
        activity = null
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
        binding.addRequestPermissionsResultListener(this)
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
        callActionEventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
        callActionEventSink = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {

            "getPlatformVersion" -> {
                val version = "Android ${android.os.Build.VERSION.RELEASE}"
                result.success(version)
            }

            "getFCMToken" -> {
                FirebaseMessaging.getInstance().token
                    .addOnSuccessListener { token ->
                        result.success(token)
                    }
                    .addOnFailureListener { exception ->
                        result.error("TOKEN_ERROR", exception.message, null)
                    }
            }

            "getAPNsToken", "getVoIPToken" -> {
                result.success(null)
            }

            "requestNotificationPermissions" -> {
                requestNotificationPermissions(result)
            }

            "areNotificationsEnabled" -> {
                result.success(areNotificationsEnabled())
            }

            "openNotificationSettings" -> {
                openNotificationSettings()
                result.success(null)
            }

            "showInAppNotification" -> {
                try {
                    val args = call.arguments as? Map<*, *> ?: emptyMap<String, Any>()
                    val title = args["title"] as? String ?: "Notification"
                    val body = args["body"] as? String ?: ""
                    val data = args["data"] as? Map<*, *> ?: emptyMap<String, Any>()
                    val imageUrl = args["imageUrl"] as? String
                    val sound = args["sound"] as? String

                    showInAppNotification(title, body, data, imageUrl, sound)
                    result.success(null)
                } catch (e: Exception) {
                    result.error("NOTIFICATION_ERROR", e.message, null)
                }
            }

            "showBackgroundNotification" -> {
                try {
                    val args = call.arguments as? Map<*, *> ?: emptyMap<String, Any>()
                    val title = args["title"] as? String ?: "Notification"
                    val body = args["body"] as? String ?: ""
                    val data = args["data"] as? Map<*, *> ?: emptyMap<String, Any>()
                    val imageUrl = args["imageUrl"] as? String
                    val sound = args["sound"] as? String
                    val channelId = args["channelId"] as? String ?: "background_notifications"
                    val channelName = args["channelName"] as? String ?: "Background Notifications"

                    showBackgroundNotification(
                        title,
                        body,
                        data,
                        imageUrl,
                        sound,
                        channelId,
                        channelName
                    )
                    result.success(null)
                } catch (e: Exception) {
                    result.error("NOTIFICATION_ERROR", e.message, null)
                }
            }

            "clearAllNotifications" -> {
                notificationManager?.cancelAll()
                removeCurrentOverlay() // ✅ Also clear in-app notification
                result.success(null)
            }

            "registerPhoneAccount" -> {
                CallUtils(context).registerPhoneAccount()
                result.success(true)
            }

            "addIncomingCall" -> {
                val callerId = call.argument<String>("callerId") ?: ""
                val callerName = call.argument<String>("callerName") ?: "Unknown"
                CallUtils(context).addIncomingCall(callerId, callerName)
                result.success(true)
            }

            "endCall" -> {
                endNativeCall()
                result.success(true)
            }

            "openPhoneAccountSettings" -> {
                openPhoneAccountSettings(context)
                result.success(true)
            }

            "isPhoneAccountEnabled" -> {
                isVoipPhoneAccountEnabled(context, activity, result)
            }

            "launchAppFromBackground" -> {
                launchAppFromBackground(context)
                result.success(true)
            }
            "requestAnswerPhoneCallsPermission" -> {
                requestAnswerPhoneCallsPermission(result)
            }

            else -> {
                result.notImplemented()
            }
        }
    }

    fun requestAnswerPhoneCallsPermission(result: MethodChannel.Result) {
        if (ContextCompat.checkSelfPermission(context, Manifest.permission.ANSWER_PHONE_CALLS)
            == PackageManager.PERMISSION_GRANTED) {
            result.success(true)
            return
        }
        answerCallPermissionResult = result
        activity?.let {
            ActivityCompat.requestPermissions(
                it,
                arrayOf(Manifest.permission.ANSWER_PHONE_CALLS),
                REQUEST_ANSWER_CALLS_PERMISSION
            )
        } ?: result.error("NO_ACTIVITY", "Activity is null", null)
    }

    fun endNativeCall() {
        if (ContextCompat.checkSelfPermission(context, Manifest.permission.ANSWER_PHONE_CALLS)
            != PackageManager.PERMISSION_GRANTED) {
            // You may chain to requestAnswerPhoneCallsPermission here, but it's best to have caller control permission flow.
            android.util.Log.e("NotificationVoipPlugin", "Missing ANSWER_PHONE_CALLS permission")
            return
        }
        try {
            val telecomManager = context.getSystemService(Context.TELECOM_SERVICE) as TelecomManager
            telecomManager.endCall()
        } catch (e: Exception) {
            android.util.Log.e("NotificationVoipPlugin Error", "endNativeCall: $e")
        }
    }
    fun isVoipPhoneAccountEnabled(
        context: Context,
        activity: Activity?,
        result: MethodChannel.Result
    ) {
        if (ContextCompat.checkSelfPermission(context, Manifest.permission.READ_PHONE_NUMBERS)
            != PackageManager.PERMISSION_GRANTED
        ) {

            // Ask for permission at runtime
            pendingResult = result
            activity?.let {
                ActivityCompat.requestPermissions(
                    it,
                    arrayOf(Manifest.permission.READ_PHONE_NUMBERS),
                    REQUEST_PHONE_PERMISSION
                )
            } ?: result.error("NO_ACTIVITY", "Activity is null", null)
            return
        }
        try {
            val telecomManager = context.getSystemService(Context.TELECOM_SERVICE) as TelecomManager
            val handle = PhoneAccountHandle(
                ComponentName(context, CallConnectionService::class.java), "VoipAccountId"
            )
            val account = telecomManager.getPhoneAccount(handle)
            result.success(account?.isEnabled ?: false)
        } catch (e: SecurityException) {
            result.error("SECURITY_ERROR", e.message, null)
        }
    }

    fun launchAppFromBackground(context: Context) {
        val intent = context.packageManager.getLaunchIntentForPackage(context.packageName)
        intent?.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
        context.startActivity(intent)
    }

    fun openPhoneAccountSettings(context: Context) {
        val intent = Intent(TelecomManager.ACTION_CHANGE_PHONE_ACCOUNTS)
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        context.startActivity(intent)
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                CHANNEL_NAME,
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Notifications shown when app is in foreground"
                enableLights(true)
                enableVibration(true)
                setShowBadge(true)
            }
            notificationManager?.createNotificationChannel(channel)
        }
    }

    private fun requestNotificationPermissions(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            val granted = ContextCompat.checkSelfPermission(
                context, Manifest.permission.POST_NOTIFICATIONS
            ) == PackageManager.PERMISSION_GRANTED

            if (granted) {
                result.success(true)
            } else {
                pendingResult = result
                activity?.let {
                    ActivityCompat.requestPermissions(
                        it,
                        arrayOf(Manifest.permission.POST_NOTIFICATIONS),
                        REQUEST_NOTIFICATION_PERMISSION
                    )
                } ?: result.error("NO_ACTIVITY", "Activity is null", null)
            }
        } else {
            result.success(true)
        }
    }



    override fun onRequestPermissionsResult(
        requestCode: Int, permissions: Array<out String>, grantResults: IntArray
    ): Boolean {
        if (requestCode == REQUEST_PHONE_PERMISSION) {
            val granted =
                grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED
            if (granted) {
                // Permission now granted, check again
                isVoipPhoneAccountEnabled(context, activity, pendingResult!!)
            } else {
                pendingResult?.success(false) // Permission denied, treat as not enabled
            }
            pendingResult = null
            return true
        }
        if (requestCode == REQUEST_ANSWER_CALLS_PERMISSION) {
            val granted = grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED
            answerCallPermissionResult?.success(granted)
            answerCallPermissionResult = null
            return true
        }
        return false
    }


    private fun areNotificationsEnabled(): Boolean {
        return NotificationManagerCompat.from(context).areNotificationsEnabled()
    }

    private fun openNotificationSettings() {
        val intent = Intent().apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                action = Settings.ACTION_APP_NOTIFICATION_SETTINGS
                putExtra(Settings.EXTRA_APP_PACKAGE, context.packageName)
            } else {
                action = Settings.ACTION_APPLICATION_DETAILS_SETTINGS
                data = Uri.parse("package:${context.packageName}")
            }
        }
        context.startActivity(intent)
    }

    // ✅ UPDATED: Window Overlay Approach (No Dialog)
    private fun showInAppNotification(
        title: String,
        body: String,
        data: Map<*, *>,
        imageUrl: String? = null,
        sound: String? = null
    ) {
        activity?.runOnUiThread {
            try {
                // Remove any existing overlay
                removeCurrentOverlay()

                val inflater = LayoutInflater.from(activity)
                val notificationView = inflater.inflate(
                    getLayoutResourceId("in_app_notification"),
                    null
                )

                // Set up views
                val titleView =
                    notificationView.findViewById<TextView>(getResourceId("notification_title"))
                val bodyView =
                    notificationView.findViewById<TextView>(getResourceId("notification_body"))
                val avatarView =
                    notificationView.findViewById<ImageView>(getResourceId("notification_avatar"))
                val closeButton =
                    notificationView.findViewById<View>(getResourceId("notification_close"))

                titleView.text = title
                bodyView.text = body

                // Load image if provided
                if (imageUrl != null && avatarView != null) {
                    loadImageIntoView(imageUrl, avatarView)
                }

                // Get the activity's root view
                val rootView = activity!!.findViewById<ViewGroup>(android.R.id.content)

                // Create container with proper layout params
                val container = FrameLayout(activity!!).apply {
                    layoutParams = FrameLayout.LayoutParams(
                        FrameLayout.LayoutParams.MATCH_PARENT,
                        FrameLayout.LayoutParams.WRAP_CONTENT
                    ).apply {
                        topMargin = getStatusBarHeight()
                        gravity = Gravity.TOP
                    }
                    setPadding(16, 8, 16, 8)
                }

                // Add notification view to container
                container.addView(notificationView)

                // ✅ Handle tap on notification (sends data to Flutter)
                notificationView.setOnClickListener {
                    removeCurrentOverlay()
                    eventSink?.success(data.mapKeys { it.key.toString() })
                }

                // ✅ Handle close button
                closeButton?.setOnClickListener {
                    removeCurrentOverlay()
                }

                // Add container to root view
                rootView.addView(container)
                currentOverlay = container

                // ✅ Animate slide in from top
                container.translationY = -200f
                container.animate()
                    .translationY(0f)
                    .setDuration(300)
                    .setInterpolator(android.view.animation.DecelerateInterpolator())
                    .start()

                // ✅ Auto-dismiss after 5 seconds (changed from 2 seconds)
                Handler(Looper.getMainLooper()).postDelayed({
                    removeCurrentOverlay()
                }, 5000)

            } catch (e: Exception) {
                showSimpleInAppNotification(title, body, data)
            }
        }
    }


    // ✅ NEW: Method to remove overlay with animation
    private fun removeCurrentOverlay() {
        currentOverlay?.let { overlay ->
            overlay.animate()
                .translationY(-200f)
                .setDuration(250)
                .withEndAction {
                    try {
                        (overlay.parent as? ViewGroup)?.removeView(overlay)
                    } catch (e: Exception) {
                        // Handle case where view is already removed
                    }
                    currentOverlay = null
                }
                .start()
        }
    }

    private fun showBackgroundNotification(
        title: String,
        body: String,
        data: Map<*, *>,
        imageUrl: String? = null,
        sound: String? = null,
        channelId: String,
        channelName: String
    ) {
        // Create notification channel for background notifications
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                channelId,
                channelName,
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Notifications shown when app is in background"
                enableLights(true)
                enableVibration(true)
                setShowBadge(true)
            }
            notificationManager?.createNotificationChannel(channel)
        }

        val notificationId = System.currentTimeMillis().toInt()

        // Create intent to open app when notification is tapped
        val intent = context.packageManager.getLaunchIntentForPackage(context.packageName)?.apply {
            addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_NEW_TASK)
            // Add data as extras for handling tap
            data.forEach { (key, value) ->
                putExtra(key.toString(), value.toString())
            }
            putExtra("notification_tap", "true")
            putExtra("notification_data", data.toString())
        }

        val pendingIntent = PendingIntent.getActivity(
            context,
            notificationId,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // Build notification
        val notificationBuilder = NotificationCompat.Builder(context, channelId)
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setContentTitle(title)
            .setContentText(body)
            .setAutoCancel(true)
            .setContentIntent(pendingIntent)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(NotificationCompat.CATEGORY_MESSAGE)
            .setDefaults(NotificationCompat.DEFAULT_ALL)

        // Set custom sound if provided
        sound?.let { soundName ->
            val soundUri = Uri.parse("android.resource://${context.packageName}/raw/$soundName")
            notificationBuilder.setSound(soundUri)
        }

        // Big text style for longer messages
        if (body.length > 50) {
            notificationBuilder.setStyle(NotificationCompat.BigTextStyle().bigText(body))
        }

        // Load and set large icon/image if provided
        if (imageUrl != null) {
            Executors.newSingleThreadExecutor().execute {
                val bitmap = getBitmapFromUrl(imageUrl)
                bitmap?.let {
                    notificationBuilder.setLargeIcon(it)
                    notificationBuilder.setStyle(
                        NotificationCompat.BigPictureStyle()
                            .bigPicture(it)
                            .bigLargeIcon(null as Bitmap?)
                    )
                }
                notificationManager?.notify(notificationId, notificationBuilder.build())
            }
        } else {
            notificationManager?.notify(notificationId, notificationBuilder.build())
        }
    }

    private fun showSimpleInAppNotification(title: String, body: String, data: Map<*, *>) {
        activity?.runOnUiThread {
            val toast = Toast.makeText(activity, "$title\n$body", Toast.LENGTH_LONG)
            toast.setGravity(Gravity.TOP or Gravity.FILL_HORIZONTAL, 0, getStatusBarHeight())
            toast.show()

            Handler(Looper.getMainLooper()).postDelayed({
                toast.cancel()
            }, 5000) // ✅ Changed to 5 seconds for consistency
        }
    }

    private fun loadImageIntoView(imageUrl: String, imageView: ImageView) {
        Executors.newSingleThreadExecutor().execute {
            try {
                val bitmap = getBitmapFromUrl(imageUrl)
                activity?.runOnUiThread {
                    if (bitmap != null) {
                        imageView.setImageBitmap(bitmap)
                    } else {
                        imageView.setImageResource(android.R.drawable.ic_dialog_info)
                    }
                }
            } catch (e: Exception) {
                activity?.runOnUiThread {
                    imageView.setImageResource(android.R.drawable.ic_dialog_info)
                }
            }
        }
    }

    private fun getBitmapFromUrl(url: String): Bitmap? {
        return try {
            val connection = URL(url).openConnection() as HttpURLConnection
            connection.doInput = true
            connection.connectTimeout = 5000
            connection.readTimeout = 10000
            connection.connect()
            val input: InputStream = connection.inputStream
            BitmapFactory.decodeStream(input)
        } catch (e: Exception) {
            null
        }
    }

    private fun getLayoutResourceId(name: String): Int {
        return context.resources.getIdentifier(name, "layout", context.packageName)
    }

    private fun getResourceId(name: String): Int {
        return context.resources.getIdentifier(name, "id", context.packageName)
    }

    private fun getStatusBarHeight(): Int {
        var result = 0
        val resourceId = context.resources.getIdentifier("status_bar_height", "dimen", "android")
        if (resourceId > 0) {
            result = context.resources.getDimensionPixelSize(resourceId)

        }
        return result + 20 // Add some padding
    }
}


//--------------------------------------------------------------------------------------------------

//package com.example.notification_voip_plugin
//
//import android.Manifest
//import android.app.Activity
//import android.app.NotificationChannel
//import android.app.NotificationManager
//import android.content.Context
//import android.content.Intent
//import android.content.pm.PackageManager
//import android.graphics.Bitmap
//import android.graphics.BitmapFactory
//import android.net.Uri
//import android.os.Build
//import android.os.Handler
//import android.os.Looper
//import android.provider.Settings
//import android.view.Gravity
//import android.view.LayoutInflater
//import android.view.View
//import android.widget.ImageView
//import android.widget.TextView
//import android.widget.Toast
//import androidx.annotation.NonNull
//import androidx.core.app.ActivityCompat
//import androidx.core.app.NotificationManagerCompat
//import androidx.core.content.ContextCompat
//import com.google.firebase.messaging.FirebaseMessaging
//import io.flutter.embedding.engine.plugins.FlutterPlugin
//import io.flutter.embedding.engine.plugins.activity.ActivityAware
//import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
//import io.flutter.plugin.common.*
//import java.io.InputStream
//import java.net.HttpURLConnection
//import java.net.URL
//import java.util.concurrent.Executors
//
//class NotificationVoipPlugin : FlutterPlugin, MethodChannel.MethodCallHandler,
//    ActivityAware, PluginRegistry.RequestPermissionsResultListener,
//    EventChannel.StreamHandler {
//
//    private lateinit var context: Context
//    private lateinit var channel: MethodChannel
//    private lateinit var eventChannel: EventChannel
//
//    private var activity: Activity? = null
//    private var notificationManager: NotificationManager? = null
//    private var pendingResult: MethodChannel.Result? = null
//    private var eventSink: EventChannel.EventSink? = null
//
//    companion object {
//        private const val CHANNEL_ID = "foreground_notifications"
//        private const val CHANNEL_NAME = "Foreground Notifications"
//        private const val REQUEST_NOTIFICATION_PERMISSION = 1001
//    }
//
//    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
//        context = binding.applicationContext
//        notificationManager = ContextCompat.getSystemService(context, NotificationManager::class.java)
//
//        channel = MethodChannel(binding.binaryMessenger, "notification_voip_plugin")
//        eventChannel = EventChannel(binding.binaryMessenger, "notification_voip_plugin/inapp_events")
//
//        channel.setMethodCallHandler(this)
//        eventChannel.setStreamHandler(this)
//
//        createNotificationChannel()
//    }
//
//    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
//        channel.setMethodCallHandler(null)
//        eventChannel.setStreamHandler(null)
//    }
//
//    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
//        activity = binding.activity
//        binding.addRequestPermissionsResultListener(this)
//    }
//
//    override fun onDetachedFromActivity() {
//        activity = null
//    }
//
//    override fun onDetachedFromActivityForConfigChanges() {
//        activity = null
//    }
//
//    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
//        activity = binding.activity
//        binding.addRequestPermissionsResultListener(this)
//    }
//
//    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
//        eventSink = events
//    }
//
//    override fun onCancel(arguments: Any?) {
//        eventSink = null
//    }
//
//    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
//        when (call.method) {
//            "getFCMToken" -> {
//                FirebaseMessaging.getInstance().token
//                    .addOnSuccessListener { token ->
//                        result.success(token)
//                    }
//                    .addOnFailureListener { exception ->
//                        result.error("TOKEN_ERROR", exception.message, null)
//                    }
//            }
//
//            "getAPNsToken", "getVoIPToken" -> {
//                result.success(null)
//            }
//
//            "requestNotificationPermissions" -> {
//                requestNotificationPermissions(result)
//            }
//
//            "areNotificationsEnabled" -> {
//                result.success(areNotificationsEnabled())
//            }
//
//            "openNotificationSettings" -> {
//                openNotificationSettings()
//                result.success(null)
//            }
//
//            "showInAppNotification" -> {
//                try {
//                    val args = call.arguments as? Map<*, *> ?: emptyMap<String, Any>()
//                    val title = args["title"] as? String ?: "Notification"
//                    val body = args["body"] as? String ?: ""
//                    val data = args["data"] as? Map<*, *> ?: emptyMap<String, Any>()
//                    val imageUrl = args["imageUrl"] as? String
//                    val sound = args["sound"] as? String
//
//                    showInAppNotification(title, body, data, imageUrl, sound)
//                    result.success(null)
//                } catch (e: Exception) {
//                    result.error("NOTIFICATION_ERROR", e.message, null)
//                }
//            }
//
//            "clearAllNotifications" -> {
//                notificationManager?.cancelAll()
//                result.success(null)
//            }
//
//            else -> {
//                result.notImplemented()
//            }
//        }
//    }
//
//    private fun createNotificationChannel() {
//        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
//            val channel = NotificationChannel(
//                CHANNEL_ID,
//                CHANNEL_NAME,
//                NotificationManager.IMPORTANCE_HIGH
//            ).apply {
//                description = "Notifications shown when app is in foreground"
//                enableLights(true)
//                enableVibration(true)
//                setShowBadge(true)
//            }
//            notificationManager?.createNotificationChannel(channel)
//        }
//    }
//
//    private fun requestNotificationPermissions(result: MethodChannel.Result) {
//        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
//            val granted = ContextCompat.checkSelfPermission(
//                context, Manifest.permission.POST_NOTIFICATIONS
//            ) == PackageManager.PERMISSION_GRANTED
//
//            if (granted) {
//                result.success(true)
//            } else {
//                pendingResult = result
//                activity?.let {
//                    ActivityCompat.requestPermissions(
//                        it,
//                        arrayOf(Manifest.permission.POST_NOTIFICATIONS),
//                        REQUEST_NOTIFICATION_PERMISSION
//                    )
//                } ?: result.error("NO_ACTIVITY", "Activity is null", null)
//            }
//        } else {
//            result.success(true)
//        }
//    }
//
//    override fun onRequestPermissionsResult(
//        requestCode: Int, permissions: Array<out String>, grantResults: IntArray
//    ): Boolean {
//        if (requestCode == REQUEST_NOTIFICATION_PERMISSION) {
//            val granted = grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED
//            pendingResult?.success(granted)
//            pendingResult = null
//            return true
//        }
//        return false
//    }
//
//    private fun areNotificationsEnabled(): Boolean {
//        return NotificationManagerCompat.from(context).areNotificationsEnabled()
//    }
//
//    private fun openNotificationSettings() {
//        val intent = Intent().apply {
//            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
//            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
//                action = Settings.ACTION_APP_NOTIFICATION_SETTINGS
//                putExtra(Settings.EXTRA_APP_PACKAGE, context.packageName)
//            } else {
//                action = Settings.ACTION_APPLICATION_DETAILS_SETTINGS
//                data = Uri.parse("package:${context.packageName}")
//            }
//        }
//        context.startActivity(intent)
//    }
//
//    private fun showInAppNotification(
//        title: String,
//        body: String,
//        data: Map<*, *>,
//        imageUrl: String? = null,
//        sound: String? = null
//    ) {
//        activity?.runOnUiThread {
//            try {
//                val inflater = LayoutInflater.from(activity)
//                val notificationView = inflater.inflate(
//                    getLayoutResourceId("in_app_notification"),
//                    null
//                )
//
//                val titleView = notificationView.findViewById<TextView>(getResourceId("notification_title"))
//                val bodyView = notificationView.findViewById<TextView>(getResourceId("notification_body"))
//                val avatarView = notificationView.findViewById<ImageView>(getResourceId("notification_avatar"))
//                val closeButton = notificationView.findViewById<View>(getResourceId("notification_close"))
//
//                titleView.text = title
//                bodyView.text = body
//
//                if (imageUrl != null && avatarView != null) {
//                    loadImageIntoView(imageUrl, avatarView)
//                }
//
//                val dialog = android.app.Dialog(activity!!)
//                dialog.setContentView(notificationView)
//                dialog.window?.setBackgroundDrawableResource(android.R.color.transparent)
//                dialog.window?.setGravity(Gravity.TOP)
//                dialog.setCancelable(true)
//
//                // Handle tap
//                notificationView.setOnClickListener {
//                    dialog.dismiss()
//                    eventSink?.success(data.mapKeys { it.key.toString() })
//                }
//
//                // Handle close
//                closeButton?.setOnClickListener {
//                    dialog.dismiss()
//                }
//
//                dialog.show()
//
//                Handler(Looper.getMainLooper()).postDelayed({
//                    dialog.dismiss()
//                }, 2000)
//
//            } catch (e: Exception) {
//                showSimpleInAppNotification(title, body, data)
//            }
//        }
//    }
////    private fun showInAppNotification(
////        title: String,
////        body: String,
////        data: Map<*, *>, // Added missing parameter name
////        imageUrl: String? = null,
////        sound: String? = null
////    ) {
////        activity?.runOnUiThread {
////            try {
////                val inflater = LayoutInflater.from(activity)
////                val notificationView = inflater.inflate(
////                    getLayoutResourceId("in_app_notification"),
////                    null
////                )
////
////                // Set title and body
////                val titleView = notificationView.findViewById<TextView>(getResourceId("notification_title"))
////                val bodyView = notificationView.findViewById<TextView>(getResourceId("notification_body"))
////                val avatarView = notificationView.findViewById<ImageView>(getResourceId("notification_avatar"))
////                val closeButton = notificationView.findViewById<View>(getResourceId("notification_close"))
////
////                titleView.text = title
////                bodyView.text = body
////
////                // Load image if provided
////                if (imageUrl != null && avatarView != null) {
////                    loadImageIntoView(imageUrl, avatarView)
////                }
////
////                val toast = Toast(activity)
////                toast.view = notificationView
////                toast.duration = Toast.LENGTH_LONG
////                toast.setGravity(Gravity.TOP or Gravity.FILL_HORIZONTAL, 0, getStatusBarHeight())
////
////                // Handle tap on notification
////                notificationView.setOnClickListener {
////                    toast.cancel()
////                    eventSink?.success(data.mapKeys { it.key.toString() })
////                }
////
////                // Handle close button
////                closeButton?.setOnClickListener {
////                    toast.cancel()
////                }
////
////                // Show toast
////                toast.show()
////
////                // Auto-dismiss after 5 seconds
////                Handler(Looper.getMainLooper()).postDelayed({
////                    toast.cancel()
////                }, 5000)
////
////            } catch (e: Exception) {
////                // Fallback to simple notification if custom layout fails
////                showSimpleInAppNotification(title, body, data)
////            }
////        }
////    }
//
//    private fun showSimpleInAppNotification(title: String, body: String, data: Map<*, *>) { // Added missing parameter name
//        activity?.runOnUiThread {
//            val toast = Toast.makeText(activity, "$title\n$body", Toast.LENGTH_LONG)
//            toast.setGravity(Gravity.TOP or Gravity.FILL_HORIZONTAL, 0, getStatusBarHeight())
//            toast.show()
//
//            Handler(Looper.getMainLooper()).postDelayed({
//                toast.cancel()
//            }, 2000)
//        }
//    }
//
//    private fun loadImageIntoView(imageUrl: String, imageView: ImageView) {
//        Executors.newSingleThreadExecutor().execute {
//            try {
//                val bitmap = getBitmapFromUrl(imageUrl)
//                activity?.runOnUiThread {
//                    if (bitmap != null) {
//                        imageView.setImageBitmap(bitmap)
//                    } else {
//                        imageView.setImageResource(android.R.drawable.ic_dialog_info)
//                    }
//                }
//            } catch (e: Exception) {
//                activity?.runOnUiThread {
//                    imageView.setImageResource(android.R.drawable.ic_dialog_info)
//                }
//            }
//        }
//    }
//
//    private fun getBitmapFromUrl(url: String): Bitmap? {
//        return try {
//            val connection = URL(url).openConnection() as HttpURLConnection
//            connection.doInput = true
//            connection.connectTimeout = 5000
//            connection.readTimeout = 10000
//            connection.connect()
//            val input: InputStream = connection.inputStream
//            BitmapFactory.decodeStream(input)
//        } catch (e: Exception) {
//            null
//        }
//    }
//
//    private fun getLayoutResourceId(name: String): Int {
//        return context.resources.getIdentifier(name, "layout", context.packageName)
//    }
//
//    private fun getResourceId(name: String): Int {
//        return context.resources.getIdentifier(name, "id", context.packageName)
//    }
//
//    private fun getStatusBarHeight(): Int {
//        var result = 0
//        val resourceId = context.resources.getIdentifier("status_bar_height", "dimen", "android")
//        if (resourceId > 0) {
//            result = context.resources.getDimensionPixelSize(resourceId)
//        }
//        return result + 20 // Add some padding
//    }
//}
