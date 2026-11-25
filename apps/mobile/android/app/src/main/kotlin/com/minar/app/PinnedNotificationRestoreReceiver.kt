package com.minar.app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class PinnedNotificationRestoreReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        val bytes = MainActivity.lastTableBytes
        if (bytes != null) {
            MainActivity.postTableNotification(context, bytes)
        }
    }
}
