package app.prosoche

import android.content.Intent
import android.net.Uri
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.android.FlutterEngineConfigurator
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Hlavna aktivita. Nativne API edicie `full` (Pigeon blocker, B-01/B-02)
 * registruje Application cez [FlutterEngineConfigurator]; v `lite` ho
 * Application neimplementuje a nic sa nedeje.
 *
 * Kanal [SYSTEM_CHANNEL] otvori systemove nastavenia appky (zamietnute
 * notifikacie v onboardingu a nastaveniach), v oboch ediciach.
 */
class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SYSTEM_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "openAppSettings" -> {
                        val intent = Intent(
                            Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                            Uri.fromParts("package", packageName, null),
                        ).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        startActivity(intent)
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
        (application as? FlutterEngineConfigurator)?.configureFlutterEngine(flutterEngine)
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        (application as? FlutterEngineConfigurator)?.cleanUpFlutterEngine(flutterEngine)
        super.cleanUpFlutterEngine(flutterEngine)
    }

    companion object {
        const val SYSTEM_CHANNEL = "app.prosoche/system"
    }
}
