package app.prosoche

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.android.FlutterEngineConfigurator
import io.flutter.embedding.engine.FlutterEngine

/**
 * Hlavna aktivita. Nativne API edicie `full` (Pigeon blocker, B-01/B-02)
 * registruje Application cez [FlutterEngineConfigurator]; v `lite` ho
 * Application neimplementuje a nic sa nedeje.
 */
class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        (application as? FlutterEngineConfigurator)?.configureFlutterEngine(flutterEngine)
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        (application as? FlutterEngineConfigurator)?.cleanUpFlutterEngine(flutterEngine)
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
