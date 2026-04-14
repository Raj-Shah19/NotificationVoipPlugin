package com.example.notification_voip_plugin.models

data class CallState(
    val callId: String,
    var status: String = "ringing", // ringing, connected, onHold, ended
    var isMuted: Boolean = false,
    var isSpeakerOn: Boolean = false,
    var isCameraOn: Boolean = false,
    var connectedAt: Long? = null
) {
    fun toMap(): Map<String, Any?> = mutableMapOf<String, Any?>(
        "callId" to callId,
        "status" to status,
        "isMuted" to isMuted,
        "isSpeakerOn" to isSpeakerOn,
        "isCameraOn" to isCameraOn
    ).also {
        if (connectedAt != null) it["connectedAt"] = connectedAt
    }
}
