package com.example.notification_voip_plugin

import android.content.ComponentName
import android.content.Context
import android.net.Uri
import android.os.Bundle
import android.telecom.PhoneAccount
import android.telecom.PhoneAccountHandle
import android.telecom.TelecomManager

class CallUtils(private val context: Context) {
    private val telecomManager = context.getSystemService(Context.TELECOM_SERVICE) as TelecomManager

    fun registerPhoneAccount() {
        val handle = PhoneAccountHandle(
            ComponentName(context, CallConnectionService::class.java),
            "VoipAccountId"
        )
        val account = PhoneAccount.builder(handle, "VoIP Call Permission")
            .setCapabilities(PhoneAccount.CAPABILITY_CALL_PROVIDER)
            .build()
        telecomManager.registerPhoneAccount(account)
    }

    fun addIncomingCall(callerId: String, callerName: String) {
        val handle = PhoneAccountHandle(
            ComponentName(context, CallConnectionService::class.java), "VoipAccountId"
        )
        val extras = Bundle().apply {
            val uri = Uri.fromParts("tel", callerId, null)
            putParcelable(TelecomManager.EXTRA_INCOMING_CALL_ADDRESS, uri)
            putString("callerId", callerId)
            putString("callerName", callerName)
        }
        telecomManager.addNewIncomingCall(handle, extras)
    }
}
