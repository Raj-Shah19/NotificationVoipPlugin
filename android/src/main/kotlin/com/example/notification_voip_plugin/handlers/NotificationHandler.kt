package com.example.notification_voip_plugin.handlers

import android.app.Activity
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.view.Gravity
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.FrameLayout
import android.widget.ImageView
import android.widget.TextView
import android.content.res.Configuration
import android.graphics.Color
import android.graphics.drawable.GradientDrawable
import androidx.cardview.widget.CardView
import androidx.core.app.NotificationCompat
import androidx.core.app.RemoteInput
import androidx.core.content.ContextCompat
import androidx.core.graphics.ColorUtils
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import me.leolin.shortcutbadger.ShortcutBadger
import java.io.InputStream
import java.net.HttpURLConnection
import java.net.URL
import java.util.concurrent.Executors

class NotificationHandler(private val context: Context) {
    var activity: Activity? = null
    var inappEventSink: EventChannel.EventSink? = null
    private var notificationManager: NotificationManager? =
        ContextCompat.getSystemService(context, NotificationManager::class.java)
    private var currentOverlay: View? = null
    private var bannerDuration: Long = 5000
    private var defaultChannelId: String = "default_channel"
    private var defaultChannelName: String = "Default Channel"

    // Track group notification counts for summary
    private val groupCounts = mutableMapOf<String, Int>()

    // Track badge count
    private var badgeCount: Int = 0
    private val BADGE_NOTIFICATION_ID = 0x42424242

    companion object {
        // In-app banner defaults, per system light/dark mode
        private val DEFAULT_BANNER_BG_LIGHT = Color.WHITE
        private val DEFAULT_BANNER_BG_DARK = 0xFF2C2C2E.toInt()
        private val DEFAULT_BANNER_TEXT_LIGHT = Color.BLACK
        private val DEFAULT_BANNER_TEXT_DARK = Color.WHITE
    }

    fun configure(config: Map<String, Any>?) {
        config?.let {
            bannerDuration = (it["bannerDuration"] as? Number)?.toLong() ?: 5000
            defaultChannelId = it["channelId"] as? String ?: "default_channel"
            defaultChannelName = it["channelName"] as? String ?: "Default Channel"
        }
        createNotificationChannel(defaultChannelId, defaultChannelName)

        // Restore persisted badge count
        val prefs = context.getSharedPreferences("nvp_prefs", Context.MODE_PRIVATE)
        badgeCount = prefs.getInt("badge_count", 0)
    }

    fun showNotification(call: MethodCall, result: MethodChannel.Result) {
        try {
            val args = call.arguments as? Map<*, *> ?: emptyMap<String, Any>()
            val notification = args["notification"] as? Map<*, *> ?: emptyMap<String, Any>()
            val template = args["template"] as? Map<*, *>

            val title = notification["title"] as? String ?: "Notification"
            val body = notification["body"] as? String ?: ""
            val imageUrl = notification["imageUrl"] as? String
                ?: template?.get("imageUrl") as? String
            val groupKey = notification["groupKey"] as? String
            val channelId = notification["channelId"] as? String ?: defaultChannelId
            val channelName = notification["channelName"] as? String ?: defaultChannelName
            val data = notification["data"] as? Map<*, *> ?: emptyMap<String, Any>()
            val tag = notification["tag"] as? String
            val templateType = template?.get("type") as? String ?: "normal"

            createNotificationChannel(channelId, channelName)
            // Use tag hashCode for stable ID when tag is provided (enables in-place updates).
            // Combine with a prefix to reduce collision risk with group summary IDs.
            val notificationId = if (tag != null) {
                0x4E565000 xor tag.hashCode() // 'NVP' prefix XOR to avoid collisions with groupKey.hashCode()
            } else {
                System.currentTimeMillis().toInt()
            }

            val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)?.apply {
                addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_NEW_TASK)
                data.forEach { (key, value) -> putExtra(key.toString(), value.toString()) }
                putExtra("notification_tap", "true")
            }
            val pendingIntent = PendingIntent.getActivity(
                context, notificationId, launchIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            val builder = NotificationCompat.Builder(context, channelId)
                .setSmallIcon(android.R.drawable.ic_dialog_info)
                .setContentTitle(title)
                .setContentText(body)
                .setAutoCancel(true)
                .setContentIntent(pendingIntent)
                .setPriority(NotificationCompat.PRIORITY_HIGH)
                .setCategory(NotificationCompat.CATEGORY_MESSAGE)

            // Custom sound support
            val soundName = notification["sound"] as? String
            if (!soundName.isNullOrEmpty()) {
                val soundUri = android.net.Uri.parse(
                    "android.resource://${context.packageName}/raw/$soundName"
                )
                builder.setSound(soundUri)
                builder.setDefaults(NotificationCompat.DEFAULT_VIBRATE or NotificationCompat.DEFAULT_LIGHTS)
            } else {
                builder.setDefaults(NotificationCompat.DEFAULT_ALL)
            }

            // Apply grouping
            if (groupKey != null) {
                builder.setGroup(groupKey)
                val count = (groupCounts[groupKey] ?: 0) + 1
                groupCounts[groupKey] = count
            }

            // Apply template
            when (templateType) {
                "bigText" -> {
                    val expandedText = template?.get("expandedText") as? String ?: body
                    builder.setStyle(NotificationCompat.BigTextStyle().bigText(expandedText))
                }
                "bigPicture" -> {
                    if (imageUrl != null) {
                        Executors.newSingleThreadExecutor().execute {
                            val bitmap = getBitmapFromUrl(imageUrl)
                            bitmap?.let {
                                builder.setLargeIcon(it)
                                builder.setStyle(
                                    NotificationCompat.BigPictureStyle()
                                        .bigPicture(it)
                                        .bigLargeIcon(null as Bitmap?)
                                )
                            }
                            notifyWithGroupSummary(notificationId, builder, groupKey)
                        }
                        result.success(true)
                        return
                    }
                }
                "bigBanner" -> {
                    val expandedText = template?.get("expandedText") as? String ?: body
                    if (imageUrl != null) {
                        Executors.newSingleThreadExecutor().execute {
                            val bitmap = getBitmapFromUrl(imageUrl)
                            bitmap?.let {
                                builder.setLargeIcon(it)
                                builder.setStyle(
                                    NotificationCompat.BigPictureStyle()
                                        .bigPicture(it)
                                        .setSummaryText(expandedText)
                                        .bigLargeIcon(null as Bitmap?)
                                )
                            } ?: run {
                                builder.setStyle(NotificationCompat.BigTextStyle().bigText(expandedText))
                            }
                            notifyWithGroupSummary(notificationId, builder, groupKey)
                        }
                        result.success(true)
                        return
                    } else {
                        builder.setStyle(NotificationCompat.BigTextStyle().bigText(expandedText))
                    }
                }
                "richText" -> {
                    val expandedText = template?.get("expandedText") as? String ?: body
                    val styledText = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                        android.text.Html.fromHtml(expandedText, android.text.Html.FROM_HTML_MODE_COMPACT)
                    } else {
                        @Suppress("DEPRECATION")
                        android.text.Html.fromHtml(expandedText)
                    }
                    builder.setStyle(NotificationCompat.BigTextStyle().bigText(styledText))
                }
                "progress" -> {
                    val progressValue = (template?.get("progressValue") as? Number)?.toInt() ?: 0
                    val progressMax = (template?.get("progressMax") as? Number)?.toInt() ?: 100
                    val indeterminate = template?.get("progressIndeterminate") as? Boolean ?: false
                    builder.setProgress(progressMax, progressValue, indeterminate)
                    // Progress notifications should be silent and not auto-cancel
                    builder.setSilent(true)
                        .setAutoCancel(false)
                        .setOnlyAlertOnce(true)
                        .setDefaults(0)
                }
                "interactive" -> {
                    val actions = template?.get("actions") as? List<*>
                    actions?.forEach { actionMap ->
                        val action = actionMap as? Map<*, *> ?: return@forEach
                        val actionId = action["id"] as? String ?: return@forEach
                        val actionTitle = action["title"] as? String ?: return@forEach
                        val isTextInput = action["isTextInput"] as? Boolean ?: false
                        val placeholder = action["textInputPlaceholder"] as? String ?: "Type..."

                        val actionIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)?.apply {
                            addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_NEW_TASK)
                            putExtra("action_id", actionId)
                            putExtra("notification_action", "true")
                        }
                        val actionPendingIntent = PendingIntent.getActivity(
                            context, (System.currentTimeMillis() + actionId.hashCode()).toInt(),
                            actionIntent,
                            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
                        )

                        if (isTextInput) {
                            val remoteInput = RemoteInput.Builder(actionId)
                                .setLabel(placeholder)
                                .build()
                            val replyAction = NotificationCompat.Action.Builder(
                                android.R.drawable.ic_menu_send, actionTitle, actionPendingIntent
                            ).addRemoteInput(remoteInput).build()
                            builder.addAction(replyAction)
                        } else {
                            builder.addAction(0, actionTitle, actionPendingIntent)
                        }
                    }
                }
                // "normal" and "custom" fall through to default
            }

            // Set badge number
            val unreadCount = notification["unreadMessageCount"] as? Int
            if (unreadCount != null) {
                builder.setNumber(unreadCount)
            }

            notifyWithGroupSummary(notificationId, builder, groupKey)
            result.success(true)
        } catch (e: Exception) {
            result.error("NOTIFICATION_ERROR", e.message, null)
        }
    }

    private fun notifyWithGroupSummary(
        notificationId: Int,
        builder: NotificationCompat.Builder,
        groupKey: String?
    ) {
        notificationManager?.notify(notificationId, builder.build())

        // Create group summary if needed
        if (groupKey != null) {
            val count = groupCounts[groupKey] ?: 1
            if (count >= 2) {
                val summaryBuilder = NotificationCompat.Builder(context, defaultChannelId)
                    .setSmallIcon(android.R.drawable.ic_dialog_info)
                    .setGroup(groupKey)
                    .setGroupSummary(true)
                    .setAutoCancel(true)
                    .setStyle(
                        NotificationCompat.InboxStyle()
                            .setSummaryText("$count new messages")
                    )
                notificationManager?.notify(groupKey.hashCode(), summaryBuilder.build())
            }
        }
    }

    fun showInAppNotification(call: MethodCall, result: MethodChannel.Result) {
        try {
            val args = call.arguments as? Map<*, *> ?: emptyMap<String, Any>()
            val notification = args["notification"] as? Map<*, *> ?: emptyMap<String, Any>()
            val title = notification["title"] as? String ?: "Notification"
            val body = notification["body"] as? String ?: ""
            val data = notification["data"] as? Map<*, *> ?: emptyMap<String, Any>()
            val imageUrl = notification["imageUrl"] as? String

            val style = args["style"] as? Map<*, *>
            val backgroundColor = (style?.get("backgroundColor") as? Number)?.toLong()?.toInt()
            val textColor = (style?.get("textColor") as? Number)?.toLong()?.toInt()

            showOverlayBanner(title, body, data, imageUrl, backgroundColor, textColor)
            result.success(true)
        } catch (e: Exception) {
            result.error("NOTIFICATION_ERROR", e.message, null)
        }
    }

    private fun showOverlayBanner(
        title: String, body: String, data: Map<*, *>, imageUrl: String?,
        backgroundColor: Int? = null, textColor: Int? = null
    ) {
        activity?.runOnUiThread {
            try {
                removeCurrentOverlay()
                val inflater = LayoutInflater.from(activity)
                val layoutId = context.resources.getIdentifier("in_app_notification", "layout", context.packageName)

                val notificationView = if (layoutId != 0) {
                    inflater.inflate(layoutId, null)
                } else {
                    createFallbackBanner(title, body, data)
                    return@runOnUiThread
                }

                val isDarkMode = ((activity ?: context).resources.configuration.uiMode and
                    Configuration.UI_MODE_NIGHT_MASK) == Configuration.UI_MODE_NIGHT_YES
                val bgColor = backgroundColor
                    ?: if (isDarkMode) DEFAULT_BANNER_BG_DARK else DEFAULT_BANNER_BG_LIGHT
                val txtColor = textColor
                    ?: if (isDarkMode) DEFAULT_BANNER_TEXT_DARK else DEFAULT_BANNER_TEXT_LIGHT

                val titleId = context.resources.getIdentifier("notification_title", "id", context.packageName)
                val bodyId = context.resources.getIdentifier("notification_body", "id", context.packageName)
                val avatarId = context.resources.getIdentifier("notification_avatar", "id", context.packageName)
                val closeId = context.resources.getIdentifier("notification_close", "id", context.packageName)

                if (notificationView is CardView) {
                    notificationView.setCardBackgroundColor(bgColor)
                    // Clear the content row's own background so the card color shows.
                    (notificationView as? ViewGroup)?.getChildAt(0)?.background = null
                } else {
                    val density = context.resources.displayMetrics.density
                    notificationView.background = GradientDrawable().apply {
                        cornerRadius = 12 * density
                        setColor(bgColor)
                    }
                }

                notificationView.findViewById<TextView>(titleId)?.apply {
                    text = title
                    setTextColor(txtColor)
                }
                notificationView.findViewById<TextView>(bodyId)?.apply {
                    text = body
                    setTextColor(ColorUtils.setAlphaComponent(txtColor, (0.7f * 255).toInt()))
                }
                (notificationView.findViewById<View>(closeId) as? ImageView)
                    ?.setColorFilter(ColorUtils.setAlphaComponent(txtColor, (0.6f * 255).toInt()))

                val avatarView = notificationView.findViewById<ImageView>(avatarId)
                if (imageUrl != null && avatarView != null) {
                    loadImageIntoView(imageUrl, avatarView)
                }

                notificationView.findViewById<View>(closeId)?.setOnClickListener {
                    removeCurrentOverlay()
                }

                notificationView.setOnClickListener {
                    removeCurrentOverlay()
                    inappEventSink?.success(data.mapKeys { it.key.toString() })
                }

                val rootView = activity!!.findViewById<ViewGroup>(android.R.id.content)
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
                container.addView(notificationView)
                rootView.addView(container)
                currentOverlay = container

                container.translationY = -200f
                container.animate()
                    .translationY(0f)
                    .setDuration(300)
                    .setInterpolator(android.view.animation.DecelerateInterpolator())
                    .start()

                Handler(Looper.getMainLooper()).postDelayed({ removeCurrentOverlay() }, bannerDuration)
            } catch (e: Exception) {
                createFallbackBanner(title, body, data)
            }
        }
    }

    private fun createFallbackBanner(title: String, body: String, data: Map<*, *>) {
        activity?.runOnUiThread {
            android.widget.Toast.makeText(activity, "$title\n$body", android.widget.Toast.LENGTH_LONG).show()
        }
    }

    fun clearAll(result: MethodChannel.Result) {
        notificationManager?.cancelAll()
        removeCurrentOverlay()
        groupCounts.clear()
        badgeCount = 0
        context.getSharedPreferences("nvp_prefs", Context.MODE_PRIVATE)
            .edit().putInt("badge_count", 0).apply()
        try { ShortcutBadger.removeCount(context) } catch (_: Exception) {}
        result.success(null)
    }

    fun cancelNotification(call: MethodCall, result: MethodChannel.Result) {
        val tag = call.argument<String>("tag") ?: ""
        if (tag.isNotEmpty()) {
            notificationManager?.cancel(0x4E565000 xor tag.hashCode())
        }
        result.success(null)
    }

    fun setBadgeCount(call: MethodCall, result: MethodChannel.Result) {
        val count = call.argument<Int>("count") ?: 0
        badgeCount = count

        // Persist badge count so it survives app restart
        context.getSharedPreferences("nvp_prefs", Context.MODE_PRIVATE)
            .edit().putInt("badge_count", count).apply()

        if (count == 0) {
            // Remove the badge notification and clear badge
            notificationManager?.cancel(BADGE_NOTIFICATION_ID)
            try { ShortcutBadger.removeCount(context) } catch (_: Exception) {}
            result.success(null)
            return
        }

        // Check POST_NOTIFICATIONS permission on Android 13+ before posting
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            val hasPermission = androidx.core.content.ContextCompat.checkSelfPermission(
                context, android.Manifest.permission.POST_NOTIFICATIONS
            ) == android.content.pm.PackageManager.PERMISSION_GRANTED
            if (!hasPermission) {
                // Still try ShortcutBadger even without notification permission
                try { ShortcutBadger.applyCount(context, count) } catch (_: Exception) {}
                result.success(null)
                return
            }
        }

        // On Android 8+, post a silent notification with the badge number
        // This is required for stock Android launchers (Pixel, AOSP) to show badge dots
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val badgeChannelId = "nvp_badge_channel"
            val badgeChannel = NotificationChannel(
                badgeChannelId, "Badge",
                NotificationManager.IMPORTANCE_MIN
            ).apply {
                description = "Used to display app badge count"
                setShowBadge(true)
                enableLights(false)
                enableVibration(false)
                setSound(null, null)
            }
            notificationManager?.createNotificationChannel(badgeChannel)

            val builder = NotificationCompat.Builder(context, badgeChannelId)
                .setSmallIcon(android.R.drawable.ic_dialog_info)
                .setContentTitle("")
                .setContentText("")
                .setNumber(count)
                .setBadgeIconType(NotificationCompat.BADGE_ICON_SMALL)
                .setPriority(NotificationCompat.PRIORITY_MIN)
                .setSilent(true)
                .setAutoCancel(false)
                .setOngoing(false)
            notificationManager?.notify(BADGE_NOTIFICATION_ID, builder.build())
        }

        // ShortcutBadger for Samsung, Huawei, LG, Sony, HTC, Xiaomi, etc.
        try { ShortcutBadger.applyCount(context, count) } catch (_: Exception) {}

        result.success(null)
    }

    fun getBadgeCount(result: MethodChannel.Result) {
        result.success(badgeCount)
    }

    private fun removeCurrentOverlay() {
        currentOverlay?.let { overlay ->
            overlay.animate()
                .translationY(-200f)
                .setDuration(250)
                .withEndAction {
                    try { (overlay.parent as? ViewGroup)?.removeView(overlay) } catch (_: Exception) {}
                    currentOverlay = null
                }
                .start()
        }
    }

    private fun createNotificationChannel(channelId: String, channelName: String) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(channelId, channelName, NotificationManager.IMPORTANCE_HIGH).apply {
                description = "Notification channel for $channelName"
                enableLights(true)
                enableVibration(true)
                setShowBadge(true)
            }
            notificationManager?.createNotificationChannel(channel)
        }
    }

    private fun loadImageIntoView(imageUrl: String, imageView: ImageView) {
        Executors.newSingleThreadExecutor().execute {
            try {
                val bitmap = getBitmapFromUrl(imageUrl)
                activity?.runOnUiThread {
                    imageView.setImageBitmap(bitmap ?: return@runOnUiThread)
                }
            } catch (_: Exception) {}
        }
    }

    private fun getBitmapFromUrl(url: String): Bitmap? {
        var connection: HttpURLConnection? = null
        var input: InputStream? = null
        return try {
            connection = URL(url).openConnection() as HttpURLConnection
            connection.doInput = true
            connection.connectTimeout = 5000
            connection.readTimeout = 10000
            connection.connect()
            input = connection.inputStream
            BitmapFactory.decodeStream(input)
        } catch (_: Exception) { null }
        finally {
            try { input?.close() } catch (_: Exception) {}
            try { connection?.disconnect() } catch (_: Exception) {}
        }
    }

    private fun getStatusBarHeight(): Int {
        var result = 0
        val resourceId = context.resources.getIdentifier("status_bar_height", "dimen", "android")
        if (resourceId > 0) result = context.resources.getDimensionPixelSize(resourceId)
        return result + 20
    }
}
