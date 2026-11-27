package com.minar.app

import android.Manifest
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.BitmapFactory
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.CancellationSignal
import android.os.Handler
import android.os.Looper
import android.widget.RemoteViews
import androidx.core.app.ActivityCompat
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private const val LOCATION_CHANNEL = "com.minar.app/location"
        private const val REQ_COARSE_LOCATION = 9101
        private const val NOTIFICATION_CHANNEL = "com.minar.app/pinned_notification"
        private const val PINNED_NOTIF_ID = 888
        private const val PINNED_CHANNEL_ID = "minar_pinned_v4"

        var lastTableBytes: ByteArray? = null
        var lastCompactBytes: ByteArray? = null
        var lastExpandedBytes: ByteArray? = null

        fun postTableNotification(
            context: Context,
            bytes: ByteArray? = null,
            compactBytes: ByteArray? = null,
            expandedBytes: ByteArray? = null
        ) {
            val effCompact = compactBytes ?: bytes ?: return
            val effExpanded = expandedBytes ?: bytes ?: effCompact

            lastCompactBytes = effCompact
            lastExpandedBytes = effExpanded
            lastTableBytes = effExpanded

            val compactBitmap = BitmapFactory.decodeByteArray(effCompact, 0, effCompact.size) ?: return
            val expandedBitmap = BitmapFactory.decodeByteArray(effExpanded, 0, effExpanded.size) ?: return
            val nm = NotificationManagerCompat.from(context)

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                // Delete previous high-importance channels to stop unwanted slide-down banners
                nm.deleteNotificationChannel("minar_pinned_v3")
                nm.deleteNotificationChannel("minar_pinned_v2")
                nm.deleteNotificationChannel("minar_pinned_channel")

                val channel = NotificationChannel(
                    PINNED_CHANNEL_ID,
                    "Pinned Prayer Schedule",
                    NotificationManager.IMPORTANCE_LOW
                ).apply {
                    description = "Shows current prayer times in the notification shade"
                    setSound(null, null)
                    enableVibration(false)
                    setShowBadge(false)
                }
                nm.createNotificationChannel(channel)
            }

            val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
            val pendingIntent = PendingIntent.getActivity(
                context,
                PINNED_NOTIF_ID,
                launchIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0)
            )

            val deleteIntent = Intent(context, PinnedNotificationRestoreReceiver::class.java)
            val deletePendingIntent = PendingIntent.getBroadcast(
                context,
                PINNED_NOTIF_ID,
                deleteIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0)
            )

            val compactView = RemoteViews(context.packageName, R.layout.notification_compact)
            compactView.setImageViewBitmap(R.id.notification_compact_image, compactBitmap)

            val expandedView = RemoteViews(context.packageName, R.layout.notification_expanded)
            expandedView.setImageViewBitmap(R.id.notification_expanded_image, expandedBitmap)

            val transparentLargeIcon = android.graphics.Bitmap.createBitmap(1, 1, android.graphics.Bitmap.Config.ARGB_8888)

            val builder = NotificationCompat.Builder(context, PINNED_CHANNEL_ID)
                .setSmallIcon(R.drawable.ic_notif_transparent)
                .setLargeIcon(transparentLargeIcon)
                .setCustomContentView(compactView)
                .setCustomBigContentView(expandedView)
                .setOngoing(true)
                .setAutoCancel(false)
                .setSilent(true)
                .setShowWhen(false)
                .setOnlyAlertOnce(true)
                .setPriority(NotificationCompat.PRIORITY_LOW)
                .setContentIntent(pendingIntent)
                .setDeleteIntent(deletePendingIntent)
                .setColor(0xFF0E1729.toInt())
                .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)

            val notif = builder.build()
            notif.flags = notif.flags or
                android.app.Notification.FLAG_ONGOING_EVENT or
                android.app.Notification.FLAG_NO_CLEAR

            try {
                nm.notify(PINNED_NOTIF_ID, notif)
            } catch (_: SecurityException) {}
        }

        fun cancelTableNotification(context: Context) {
            lastTableBytes = null
            lastCompactBytes = null
            lastExpandedBytes = null
            val nm = NotificationManagerCompat.from(context)
            nm.cancel(PINNED_NOTIF_ID)
        }
    }

    private var pendingLocationResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, LOCATION_CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "getCoarseLocation") {
                    if (pendingLocationResult != null) {
                        result.error("BUSY", "Location request already in progress.", null)
                        return@setMethodCallHandler
                    }
                    pendingLocationResult = result
                    handleCoarseLocationRequest()
                } else {
                    result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, NOTIFICATION_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "showPinnedTable" -> {
                        val bytes = call.argument<ByteArray>("bytes")
                        val compactBytes = call.argument<ByteArray>("compactBytes")
                        val expandedBytes = call.argument<ByteArray>("expandedBytes")
                        if (compactBytes != null || expandedBytes != null || bytes != null) {
                            postTableNotification(this, bytes, compactBytes, expandedBytes)
                            result.success(true)
                        } else {
                            result.error("INVALID_ARGS", "Missing image bytes", null)
                        }
                    }
                    "cancelPinnedTable" -> {
                        cancelTableNotification(this)
                        result.success(true)
                    }
                    "getLocalTimeZone" -> {
                        result.success(java.util.TimeZone.getDefault().id)
                    }
                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.minar.app/widget")
            .setMethodCallHandler { call, result ->
                if (call.method == "updateWidgets") {
                    @Suppress("UNCHECKED_CAST")
                    val arguments = call.arguments as? Map<String, Any?>
                    if (arguments != null) {
                        MinarWidgetHelper.saveAndBroadcastData(this, arguments)
                        result.success(true)
                    } else {
                        result.error("INVALID_ARGS", "Missing widget arguments", null)
                    }
                } else {
                    result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.minar.app/system")
            .setMethodCallHandler { call, result ->
                if (call.method == "openUrl") {
                    val url = call.argument<String>("url")
                    if (url != null) {
                        try {
                            val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url))
                            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("ACTIVITY_FAILED", e.message, null)
                        }
                    } else {
                        result.error("INVALID_ARGS", "Missing url", null)
                    }
                } else {
                    result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.minar.app/updater")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getCacheDir" -> {
                        result.success(cacheDir.absolutePath)
                    }
                    "canRequestPackageInstalls" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            result.success(packageManager.canRequestPackageInstalls())
                        } else {
                            result.success(true)
                        }
                    }
                    "openInstallPermissionSettings" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            try {
                                val intent = Intent(android.provider.Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES).apply {
                                    data = Uri.parse("package:$packageName")
                                }
                                startActivity(intent)
                                result.success(true)
                            } catch (e: Exception) {
                                result.error("SETTINGS_ERROR", e.message, null)
                            }
                        } else {
                            result.success(false)
                        }
                    }
                    "installApk" -> {
                        val filePath = call.argument<String>("filePath")
                        if (filePath != null) {
                            installApk(filePath, result)
                        } else {
                            result.error("INVALID_ARGS", "Missing filePath", null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun installApk(filePath: String, result: MethodChannel.Result) {
        try {
            val file = java.io.File(filePath)
            if (!file.exists()) {
                result.error("FILE_NOT_FOUND", "APK file does not exist", null)
                return
            }

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                if (!packageManager.canRequestPackageInstalls()) {
                    val intent = Intent(android.provider.Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES).apply {
                        data = Uri.parse("package:$packageName")
                    }
                    startActivity(intent)
                    result.success(false)
                    return
                }
            }

            val contentUri = androidx.core.content.FileProvider.getUriForFile(
                this,
                "$packageName.fileprovider",
                file
            )
            val intent = Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(contentUri, "application/vnd.android.package-archive")
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_GRANT_READ_URI_PERMISSION
            }
            startActivity(intent)
            result.success(true)
        } catch (e: Exception) {
            result.error("INSTALL_ERROR", e.message, null)
        }
    }

    private fun handleCoarseLocationRequest() {
        val hasPermission = ContextCompat.checkSelfPermission(
            this,
            Manifest.permission.ACCESS_COARSE_LOCATION
        ) == PackageManager.PERMISSION_GRANTED

        if (!hasPermission) {
            ActivityCompat.requestPermissions(
                this,
                arrayOf(Manifest.permission.ACCESS_COARSE_LOCATION),
                REQ_COARSE_LOCATION
            )
            return
        }

        fetchBatterySaverCoarseFix()
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == REQ_COARSE_LOCATION) {
            val granted = grantResults.isNotEmpty() &&
                grantResults[0] == PackageManager.PERMISSION_GRANTED
            if (granted) {
                fetchBatterySaverCoarseFix()
            } else {
                finishLocationError(
                    "PERMISSION_DENIED",
                    "Location access was denied. Enable it in Android settings or use IP mode."
                )
            }
        }
    }

    @Suppress("MissingPermission")
    private fun fetchBatterySaverCoarseFix() {
        val lm = getSystemService(Context.LOCATION_SERVICE) as? LocationManager
        if (lm == null) {
            finishLocationError("UNAVAILABLE", "Location service unavailable.")
            return
        }

        val networkEnabled = lm.isProviderEnabled(LocationManager.NETWORK_PROVIDER)
        val passiveEnabled = lm.isProviderEnabled(LocationManager.PASSIVE_PROVIDER)
        if (!networkEnabled && !passiveEnabled) {
            finishLocationError(
                "LOCATION_OFF",
                "Device location is turned off. Turn on Location or switch to Network IP mode."
            )
            return
        }

        val twentyMinutesMs = 20 * 60 * 1000L
        val now = System.currentTimeMillis()
        val cached = lm.getLastKnownLocation(LocationManager.NETWORK_PROVIDER)
            ?: lm.getLastKnownLocation(LocationManager.PASSIVE_PROVIDER)

        if (cached != null && (now - cached.time) < twentyMinutesMs) {
            finishLocationSuccess(cached)
            return
        }

        val provider = if (networkEnabled) {
            LocationManager.NETWORK_PROVIDER
        } else {
            LocationManager.PASSIVE_PROVIDER
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            val cancelSignal = CancellationSignal()
            val handler = Handler(Looper.getMainLooper())
            val timeoutRunnable = Runnable {
                cancelSignal.cancel()
                if (cached != null) {
                    finishLocationSuccess(cached)
                } else {
                    finishLocationError(
                        "TIMEOUT",
                        "Could not get coarse location quickly. Try Network IP mode."
                    )
                }
            }
            handler.postDelayed(timeoutRunnable, 8000L)

            try {
                lm.getCurrentLocation(
                    provider,
                    cancelSignal,
                    mainExecutor
                ) { location ->
                    handler.removeCallbacks(timeoutRunnable)
                    if (location != null) {
                        finishLocationSuccess(location)
                    } else if (cached != null) {
                        finishLocationSuccess(cached)
                    } else {
                        finishLocationError(
                            "NO_FIX",
                            "Could not determine coarse location. Use Network IP mode or pick a city."
                        )
                    }
                }
            } catch (e: Exception) {
                handler.removeCallbacks(timeoutRunnable)
                if (cached != null) {
                    finishLocationSuccess(cached)
                } else {
                    finishLocationError("ERROR", "Unable to read coarse location.")
                }
            }
        } else {
            val handler = Handler(Looper.getMainLooper())
            var listenerRef: LocationListener? = null
            val timeoutRunnable = Runnable {
                listenerRef?.let {
                    try { lm.removeUpdates(it) } catch (_: Exception) {}
                }
                if (cached != null) {
                    finishLocationSuccess(cached)
                } else {
                    finishLocationError(
                        "TIMEOUT",
                        "Could not get coarse location quickly. Try Network IP mode."
                    )
                }
            }
            val listener = object : LocationListener {
                override fun onLocationChanged(location: Location) {
                    handler.removeCallbacks(timeoutRunnable)
                    try { lm.removeUpdates(this) } catch (_: Exception) {}
                    finishLocationSuccess(location)
                }
                @Deprecated("Deprecated in Java")
                override fun onStatusChanged(p: String?, status: Int, extras: Bundle?) {}
                override fun onProviderEnabled(p: String) {}
                override fun onProviderDisabled(p: String) {}
            }
            listenerRef = listener
            handler.postDelayed(timeoutRunnable, 8000L)
            try {
                @Suppress("DEPRECATION")
                lm.requestSingleUpdate(provider, listener, Looper.getMainLooper())
            } catch (e: Exception) {
                handler.removeCallbacks(timeoutRunnable)
                if (cached != null) {
                    finishLocationSuccess(cached)
                } else {
                    finishLocationError("ERROR", "Unable to read coarse location.")
                }
            }
        }
    }

    private fun finishLocationSuccess(loc: Location) {
        val res = pendingLocationResult
        pendingLocationResult = null
        res?.success(
            mapOf(
                "latitude" to loc.latitude,
                "longitude" to loc.longitude
            )
        )
    }

    private fun finishLocationError(code: String, message: String) {
        val res = pendingLocationResult
        pendingLocationResult = null
        res?.error(code, message, null)
    }
}
