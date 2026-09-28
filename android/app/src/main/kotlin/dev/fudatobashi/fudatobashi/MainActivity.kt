package dev.fudatobashi.fudatobashi

import android.media.AudioManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Celebration sounds stay quiet while the ringer is on silent or vibrate.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "fudatobashi/ringer").setMethodCallHandler { call, result ->
            if (call.method == "isSilenced") {
                val audio = getSystemService(AUDIO_SERVICE) as AudioManager
                result.success(audio.ringerMode != AudioManager.RINGER_MODE_NORMAL)
            } else {
                result.notImplemented()
            }
        }
    }
}
