package app.mursa.blocker

import android.app.AlertDialog
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.util.Log
import app.mursa.R
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch

/**
 * Brana nad blokovanou appkou (ADR-16): FlutterActivity nad predhriatym
 * enginom [GateEngine] (`gateMain`) z `FlutterEngineCache`. Ak engine v
 * cache nie je (sluzba ho este nestihla vytvorit, OEM zabil proces), vytvori
 * sa tu a do prveho frame je vidiet nativny splash (`GateLaunchTheme`).
 *
 * Ciel brany ide do Dartu cez `BlockerFlutterApi.onGateRequested(ref)`,
 * nie cez initial route (engine uz bezi). Ak Dart poziadavku do
 * [FALLBACK_MS] nepotvrdi, ukaze sa nativny fallback "Continue" / "Go
 * back" (brana nikdy neuvazni, docs/01 5.3, D5).
 *
 * Back riesi Flutter `PopScope` (targetSdk 36 nevola onBackPressed).
 */
class GateActivity : FlutterActivity(), GateHost {
    override val gateTarget: String?
        get() = intent?.getStringExtra(EXTRA_APP)?.takeIf(::isValidPackageName)

    private val main = Handler(Looper.getMainLooper())
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)
    private var request: Job? = null
    private var requestAcked = false
    private var fallback: AlertDialog? = null
    private val showFallback = Runnable { onGateStuck() }

    override fun onCreate(savedInstanceState: Bundle?) {
        // Engine musi byt v cache skor, nez si ho FlutterActivity vyziada.
        GateEngine.warmUp(applicationContext)
        super.onCreate(savedInstanceState)
        if (gateTarget == null) {
            finishGate(openTarget = false)
            return
        }
        main.postDelayed(showFallback, FALLBACK_MS)
    }

    override fun getCachedEngineId(): String = GateEngine.ENGINE_ID

    // Engine prezije aktivitu, dalsia brana ho znova pouzije.
    override fun shouldDestroyEngineWithHost(): Boolean = false

    // Ciel ide z extras cez onGateRequested, nie z intent data.
    override fun shouldHandleDeeplinking(): Boolean = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        BlockerHostApi.setUp(
            flutterEngine.dartExecutor.binaryMessenger,
            BlockerHostApiImpl(applicationContext, gateHost = this),
        )
        requestGate(flutterEngine)
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        BlockerHostApi.setUp(flutterEngine.dartExecutor.binaryMessenger, null)
        super.cleanUpFlutterEngine(flutterEngine)
    }

    /** Brana uz bezi (singleTask) a prisla poziadavka na inu appku. */
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        flutterEngine?.let(::requestGate)
    }

    override fun onFlutterUiDisplayed() {
        super.onFlutterUiDisplayed()
        // Cas pre meranie latencie (bez nazvu balika, docs/06 C.5).
        Log.i(GateLauncher.TAG, "gate ui displayed t=${SystemClock.elapsedRealtime()}")
    }

    override fun onDestroy() {
        main.removeCallbacks(showFallback)
        scope.cancel()
        fallback?.dismiss()
        fallback = null
        super.onDestroy()
    }

    /** Posle ciel do Dartu; sprava pocka v kanali, kym Dart nezaregistruje handler. */
    private fun requestGate(engine: FlutterEngine) {
        val target = gateTarget ?: return
        requestAcked = false
        request?.cancel()
        request = scope.launch {
            try {
                BlockerFlutterApi(engine.dartExecutor.binaryMessenger).onGateRequested(target)
                requestAcked = true
                main.removeCallbacks(showFallback)
                Log.i(GateLauncher.TAG, "gate request delivered t=${SystemClock.elapsedRealtime()}")
            } catch (e: FlutterError) {
                Log.w(GateLauncher.TAG, "gate request failed: ${e.code}")
            }
        }
    }

    /** Dart nepotvrdil branu do [FALLBACK_MS]: nativna volba bez Flutteru. */
    private fun onGateStuck() {
        if (requestAcked || isFinishing || fallback != null) return
        Log.w(GateLauncher.TAG, "gate fallback shown")
        fallback = AlertDialog.Builder(this)
            .setTitle(R.string.gate_fallback_title)
            .setMessage(R.string.gate_fallback_body)
            .setCancelable(false)
            .setPositiveButton(R.string.gate_fallback_continue) { _, _ -> finishGate(openTarget = true) }
            .setNegativeButton(R.string.gate_fallback_back) { _, _ -> finishGate(openTarget = false) }
            .show()
    }

    override fun finishGate(openTarget: Boolean) {
        main.removeCallbacks(showFallback)
        val target = gateTarget
        val launch = if (openTarget && target != null) {
            // "Continue" bez unlockFor (napr. chyba v brane) nesmie skoncit
            // dalsou branou o sekundu neskor: kratky prechod.
            val unlocks = UnlockStore(applicationContext)
            if (!unlocks.isUnlocked(target)) unlocks.unlockFor(target, PASS_THROUGH_MINUTES)
            packageManager.getLaunchIntentForPackage(target)
        } else {
            null
        }
        val next = (launch ?: homeIntent()).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        try {
            startActivity(next)
        } catch (e: RuntimeException) {
            startActivity(homeIntent())
        }
        finishAndRemoveTask()
    }

    companion object {
        const val EXTRA_APP = "app.mursa.gate.APP"
        const val EXTRA_SRC = "app.mursa.gate.SRC"
        const val SOURCE_MONITOR = "monitor"
        val SOURCES = setOf("monitor", "notif", "test", "error")

        /** Odomknutie pri "Continue" bez predchadzajuceho unlockFor. */
        const val PASS_THROUGH_MINUTES = 1

        /** Flutter musi potvrdit branu do 5 s (docs/01 5.3). */
        const val FALLBACK_MS = 5_000L

        /** Intent na branu nad predhriatym enginom (`withCachedEngine`). */
        fun intent(context: Context, ref: String, source: String = SOURCE_MONITOR): Intent =
            CachedEngineIntentBuilder(GateActivity::class.java, GateEngine.ENGINE_ID)
                .destroyEngineWithActivity(false)
                .build(context)
                .putExtra(EXTRA_APP, ref)
                .putExtra(EXTRA_SRC, source.takeIf { it in SOURCES } ?: SOURCE_MONITOR)

        fun homeIntent(): Intent =
            Intent(Intent.ACTION_MAIN)
                .addCategory(Intent.CATEGORY_HOME)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
    }
}

/** Activita brany, ktoru vie zavriet `closeGate`. */
interface GateHost {
    val gateTarget: String?

    fun finishGate(openTarget: Boolean)
}
