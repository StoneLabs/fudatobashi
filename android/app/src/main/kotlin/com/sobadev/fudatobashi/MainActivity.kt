package com.sobadev.fudatobashi

import android.Manifest
import android.content.pm.PackageManager
import android.media.AudioManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var permissionResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        // Celebration sounds stay quiet while the ringer is on silent or vibrate.
        MethodChannel(messenger, "fudatobashi/ringer").setMethodCallHandler { call, result ->
            if (call.method == "isSilenced") {
                val audio = getSystemService(AUDIO_SERVICE) as AudioManager
                result.success(audio.ringerMode != AudioManager.RINGER_MODE_NORMAL)
            } else {
                result.notImplemented()
            }
        }
        MethodChannel(messenger, "fudatobashi/match_timer").setMethodCallHandler { call, result ->
            when (call.method) {
                "start" -> runCatching { MatchTimerService.start(this, call.arguments as Map<*, *>) }.report(result)
                "stop" -> runCatching { MatchTimerService.stop(this) }.report(result)
                "needsNotificationPermission" -> result.success(needsNotificationPermission())
                "askNotificationPermission" -> askNotificationPermission(result)
                else -> result.notImplemented()
            }
        }
    }

    private fun needsNotificationPermission() = Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
        checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED

    private fun askNotificationPermission(result: MethodChannel.Result) {
        if (!needsNotificationPermission() || permissionResult != null) {
            result.success(!needsNotificationPermission())
            return
        }
        permissionResult = result
        requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), NOTIFICATION_REQUEST)
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != NOTIFICATION_REQUEST) return
        permissionResult?.success(grantResults.firstOrNull() == PackageManager.PERMISSION_GRANTED)
        permissionResult = null
    }

    private fun Result<Unit>.report(result: MethodChannel.Result) =
        fold({ result.success(null) }, { result.error("match_timer", it.message, null) })

    private companion object {
        const val NOTIFICATION_REQUEST = 1
    }
}
