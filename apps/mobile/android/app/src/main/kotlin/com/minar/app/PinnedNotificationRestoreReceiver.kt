package com.minar.app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class PinnedNotificationRestoreReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        val bytes = MainActivity.lastTableBytes
        val compact = MainActivity.lastCompactBytes
        val expanded = MainActivity.lastExpandedBytes
        if (bytes != null || compact != null || expanded != null) {
            MainActivity.postTableNotification(context, bytes, compact, expanded)
        }
    }
}
