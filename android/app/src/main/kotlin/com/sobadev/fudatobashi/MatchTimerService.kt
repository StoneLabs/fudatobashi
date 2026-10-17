package com.sobadev.fudatobashi

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.PowerManager

/**
 * Keeps the app awake while the match timer runs: a foreground service with an
 * ongoing notification that counts down to the end by itself, and a partial wake
 * lock so the timer's ticks, and the sounds they play, keep coming with the
 * screen off. Wake locks of a foreground service also hold in Doze. It stops
 * itself at the release time it was given, so nothing outlives the timer.
 */
class MatchTimerService : Service() {
    private val handler = Handler(Looper.getMainLooper())
    private val release = Runnable { stopSelf() }
    private val wakeLock by lazy {
        (getSystemService(POWER_SERVICE) as PowerManager)
            .newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, WAKE_LOCK_TAG)
            .apply { setReferenceCounted(false) }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent == null || intent.action == ACTION_STOP) {
            stopSelf()
            return START_NOT_STICKY
        }
        val notification = notification(intent)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            startForeground(NOTIFICATION_ID, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE)
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }
        val holdFor = (intent.getLongExtra(RELEASE_AT, 0) - System.currentTimeMillis()).coerceAtLeast(0)
        wakeLock.acquire(holdFor)
        handler.removeCallbacks(release)
        handler.postDelayed(release, holdFor)
        return START_NOT_STICKY
    }

    override fun onDestroy() {
        handler.removeCallbacks(release)
        if (wakeLock.isHeld) wakeLock.release()
        super.onDestroy()
    }

    private fun notification(intent: Intent): Notification {
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            // Silent: the timer plays its own sounds.
            val channel = NotificationChannel(CHANNEL_ID, intent.getStringExtra(CHANNEL), NotificationManager.IMPORTANCE_DEFAULT)
                .apply {
                    setSound(null, null)
                    enableVibration(false)
                }
            getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
            Notification.Builder(this, CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            builder.setForegroundServiceBehavior(Notification.FOREGROUND_SERVICE_IMMEDIATE)
        }
        val open = PendingIntent.getActivity(
            this, 0, packageManager.getLaunchIntentForPackage(packageName),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
        return builder
            .setSmallIcon(R.drawable.ic_launcher_monochrome)
            .setContentTitle(intent.getStringExtra(TITLE))
            .setContentText(intent.getStringExtra(TEXT))
            .setWhen(intent.getLongExtra(ENDS_AT, 0))
            .setShowWhen(true)
            .setUsesChronometer(true)
            .setChronometerCountDown(true)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setContentIntent(open)
            .build()
    }

    companion object {
        private const val CHANNEL_ID = "match_timer"
        private const val NOTIFICATION_ID = 1
        private const val WAKE_LOCK_TAG = "fudatobashi:matchTimer"
        private const val ENDS_AT = "endsAt"
        private const val RELEASE_AT = "releaseAt"
        private const val TITLE = "title"
        private const val TEXT = "text"
        private const val CHANNEL = "channel"
        private const val ACTION_STOP = "stop"

        /** Starts or updates the service from the timer channel's `start` arguments. */
        fun start(context: Context, args: Map<*, *>) {
            val intent = Intent(context, MatchTimerService::class.java)
                .putExtra(ENDS_AT, (args[ENDS_AT] as Number).toLong())
                .putExtra(RELEASE_AT, (args[RELEASE_AT] as Number).toLong())
                .putExtra(TITLE, args[TITLE] as String)
                .putExtra(TEXT, args[TEXT] as String)
                .putExtra(CHANNEL, args[CHANNEL] as String)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }

        /**
         * Stops the service through its own queue: stopping it from outside before
         * it reached startForeground would crash the app.
         */
        fun stop(context: Context) {
            context.startService(Intent(context, MatchTimerService::class.java).setAction(ACTION_STOP))
        }
    }
}
