package app.mursa.blocker

import android.content.Context
import android.os.Looper
import android.os.SystemClock
import android.util.Log
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.dart.DartExecutor

/**
 * Predhriaty FlutterEngine brany (ADR-16, Z3): entrypoint `gateMain`
 * z `lib/gate_main.dart`, ulozeny vo [FlutterEngineCache]. Startuje sa so
 * [BlockerService], takze pri otvoreni blokovanej appky uz Dart bezi a ma
 * otvorenu content.db aj user.db. [GateActivity] sa k nemu len pripoji.
 *
 * Vsetko len na hlavnom vlakne (FlutterEngine to vyzaduje).
 */
object GateEngine {
    const val ENGINE_ID = "mursa_gate"
    const val ENTRYPOINT_LIBRARY = "package:sakina/gate_main.dart"
    const val ENTRYPOINT = "gateMain"

    val isWarm: Boolean
        get() = FlutterEngineCache.getInstance().contains(ENGINE_ID)

    /** Vrati engine z cache, alebo ho vytvori a spusti `gateMain`. */
    fun warmUp(context: Context): FlutterEngine {
        check(Looper.myLooper() == Looper.getMainLooper()) { "GateEngine on main thread only" }
        FlutterEngineCache.getInstance().get(ENGINE_ID)?.let { return it }
        val started = SystemClock.elapsedRealtime()
        val app = context.applicationContext
        val engine = FlutterEngine(app)
        val loader = FlutterInjector.instance().flutterLoader()
        engine.dartExecutor.executeDartEntrypoint(
            DartExecutor.DartEntrypoint(loader.findAppBundlePath(), ENTRYPOINT_LIBRARY, ENTRYPOINT),
        )
        FlutterEngineCache.getInstance().put(ENGINE_ID, engine)
        Log.i(GateLauncher.TAG, "gate engine warm ms=${SystemClock.elapsedRealtime() - started}")
        return engine
    }

    /** Uvolni pamat, ked sa brana vypne (BlockerService.onDestroy). */
    fun destroy() {
        val cache = FlutterEngineCache.getInstance()
        val engine = cache.get(ENGINE_ID) ?: return
        cache.remove(ENGINE_ID)
        engine.destroy()
    }
}
