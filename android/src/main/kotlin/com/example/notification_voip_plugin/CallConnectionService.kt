package com.example.notification_voip_plugin

import android.telecom.Connection
import android.telecom.ConnectionRequest
import android.telecom.ConnectionService
import android.telecom.DisconnectCause
import android.telecom.PhoneAccountHandle
import android.telecom.TelecomManager
import android.util.Log

class CallConnectionService : ConnectionService() {

    override fun onCreateIncomingConnection(
        connectionManagerPhoneAccount: PhoneAccountHandle,
        request: ConnectionRequest
    ): Connection {
        val callerName = request.extras.getString("callerName", "VOIP Call")
        val connection = object : Connection() {
            override fun onAnswer() {
                setActive()
                NotificationVoipPlugin.callActionEventSink?.success(mapOf("event" to "callAnswered"))
                setDisconnected(android.telecom.DisconnectCause(android.telecom.DisconnectCause.LOCAL))
                destroy()
            }
            override fun onReject() {
                setDisconnected(DisconnectCause(DisconnectCause.REJECTED))
                destroy()
                NotificationVoipPlugin.callActionEventSink?.success(mapOf("event" to "callDeclined"))
            }
        }
        connection.setAddress(request.address, TelecomManager.PRESENTATION_ALLOWED)
        connection.setCallerDisplayName(callerName, TelecomManager.PRESENTATION_ALLOWED)
        connection.setInitializing()
        connection.setRinging()
        return connection
    }


    override fun onCreateOutgoingConnection(
        connectionManagerPhoneAccount: PhoneAccountHandle,
        request: ConnectionRequest
    ): Connection {
        val connection = object : Connection() {
            override fun onDisconnect() {
                setDisconnected(DisconnectCause(DisconnectCause.LOCAL))
                destroy()
            }
        }
        connection.setAddress(request.address, TelecomManager.PRESENTATION_ALLOWED)
        connection.setInitializing()
        connection.setActive()
        return connection
    }
}
