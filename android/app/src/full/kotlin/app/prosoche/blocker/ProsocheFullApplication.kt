package app.prosoche.blocker

import android.app.Application
import android.os.Handler
import android.os.Looper
import android.util.Log
import io.flutter.embedding.android.FlutterEngineConfigurator
import io.flutter.embedding.engine.FlutterEngine

/**
 * Application edicie `full` (manifest overlay `tools:replace="android:name"`).
 *
 * - [configureFlutterEngine]: MainActivity (src/main) ho vola pre engine
 *   hlavnej appky a tu sa registruje [BlockerHostApi]. V `lite` Application
 *   toto rozhranie nema, takze MainActivity nic nerobi.
 * - [warmGateEngine]: predhriaty engine brany (ADR-16), vola ho
 *   [BlockerService] pri starte.
 */
class ProsocheFullApplication : Application(), FlutterEngineConfigurator {
    private val main = Handler(Looper.getMainLooper())

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        BlockerHostApi.setUp(flutterEngine.dartExecutor.binaryMessenger, BlockerHostApiImpl(this))
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        BlockerHostApi.setUp(flutterEngine.dartExecutor.binaryMessenger, null)
    }

    /**
     * Spusti engine brany na hlavnom vlakne po aktualnej sprave, aby
     * nezdrzal `startForeground` sluzby. Chyba nesmie zhodit sluzbu:
     * GateActivity si engine pri potrebe vytvori sama (studeny start).
     */
    fun warmGateEngine() {
        main.post {
            try {
                GateEngine.warmUp(this)
            } catch (e: RuntimeException) {
                Log.w(GateLauncher.TAG, "gate engine warm up failed: ${e.javaClass.simpleName}")
            }
        }
    }
}
