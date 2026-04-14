package com.example.notification_voip_plugin

import android.telecom.Connection
import android.telecom.ConnectionRequest
import android.telecom.ConnectionService
import android.telecom.DisconnectCause
import android.telecom.PhoneAccountHandle
import android.telecom.TelecomManager

class CallConnectionService : ConnectionService() {

    companion object {
        private val activeConnections = mutableMapOf<String, Connection>()

        fun endCall(callId: String) {
            activeConnections[callId]?.let { connection ->
                connection.setDisconnected(DisconnectCause(DisconnectCause.LOCAL))
                connection.destroy()
                activeConnections.remove(callId)
            }
        }

        fun endAllCalls() {
            activeConnections.values.forEach { connection ->
                connection.setDisconnected(DisconnectCause(DisconnectCause.LOCAL))
                connection.destroy()
            }
            activeConnections.clear()
        }
    }

    override fun onCreateIncomingConnection(
        connectionManagerPhoneAccount: PhoneAccountHandle,
        request: ConnectionRequest
    ): Connection {
        val callerName = request.extras.getString("callerName", "VoIP Call")
        val callerId = request.extras.getString("callerId", "")
        val isVideo = request.extras.getBoolean("isVideo", false)

        val connection = object : Connection() {
            override fun onAnswer() {
                setActive()
                NotificationVoipPlugin.callHandler?.onCallAction("accept", callerId, mapOf(
                    "callerName" to callerName,
                    "isVideo" to isVideo
                ))
            }

            override fun onReject() {
                setDisconnected(DisconnectCause(DisconnectCause.REJECTED))
                destroy()
                activeConnections.remove(callerId)
                NotificationVoipPlugin.callHandler?.onCallAction("decline", callerId, mapOf(
                    "callerName" to callerName,
                    "isVideo" to isVideo
                ))
            }

            override fun onDisconnect() {
                setDisconnected(DisconnectCause(DisconnectCause.LOCAL))
                destroy()
                activeConnections.remove(callerId)
                NotificationVoipPlugin.callHandler?.onCallAction("ended", callerId, mapOf(
                    "callerName" to callerName,
                    "isVideo" to isVideo
                ))
            }
        }

        connection.setAddress(request.address, TelecomManager.PRESENTATION_ALLOWED)
        connection.setCallerDisplayName(callerName, TelecomManager.PRESENTATION_ALLOWED)
        connection.setInitializing()
        connection.setRinging()

        activeConnections[callerId] = connection
        return connection
    }

    override fun onCreateOutgoingConnection(
        connectionManagerPhoneAccount: PhoneAccountHandle,
        request: ConnectionRequest
    ): Connection {
        val callerId = request.extras.getString("callerId", "")

        val connection = object : Connection() {
            override fun onDisconnect() {
                setDisconnected(DisconnectCause(DisconnectCause.LOCAL))
                destroy()
                activeConnections.remove(callerId)
                NotificationVoipPlugin.callHandler?.onCallAction("ended", callerId)
            }
        }

        connection.setAddress(request.address, TelecomManager.PRESENTATION_ALLOWED)
        connection.setInitializing()
        connection.setActive()

        activeConnections[callerId] = connection
        return connection
    }
}
