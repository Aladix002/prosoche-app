package app.prosoche.blocker

import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.Context
import android.os.Build
import android.os.Handler

/** Zdroj udalosti "appka presla do popredia". */
fun interface ForegroundEventSource {
    /** Package poslednej appky, ktora presla do popredia v [beginMs, endMs], alebo null. */
    fun lastResumed(beginMs: Long, endMs: Long): String?
}

/** Planovanie tickov (Handler v sluzbe, fake v testoch). */
interface TickScheduler {
    fun schedule(delayMs: Long, task: Runnable)

    fun cancel(task: Runnable)
}

class HandlerTickScheduler(private val handler: Handler) : TickScheduler {
    override fun schedule(delayMs: Long, task: Runnable) {
        handler.postDelayed(task, delayMs)
    }

    override fun cancel(task: Runnable) {
        handler.removeCallbacks(task)
    }
}

class UsageStatsEventSource(
    context: Context,
    private val debugLog: ((String) -> Unit)? = null,
) : ForegroundEventSource {
    private val usm = context.getSystemService(UsageStatsManager::class.java)

    override fun lastResumed(beginMs: Long, endMs: Long): String? {
        val events = usm?.queryEvents(beginMs, endMs)
        if (events == null) {
            debugLog?.invoke("queryEvents null")
            return null
        }
        val event = UsageEvents.Event()
        var last: String? = null
        val types = if (debugLog != null) mutableMapOf<Int, Int>() else null
        while (events.hasNextEvent()) {
            events.getNextEvent(event)
            types?.merge(event.eventType, 1, Int::plus)
            if (event.eventType == RESUMED) last = event.packageName
        }
        debugLog?.invoke("events [${endMs - beginMs} ms] types=$types resumed=$last")
        return last
    }

    private companion object {
        @Suppress("DEPRECATION")
        val RESUMED =
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                UsageEvents.Event.ACTIVITY_RESUMED
            } else {
                UsageEvents.Event.MOVE_TO_FOREGROUND
            }
    }
}

/**
 * Pri zapnutej obrazovke kazdu ~1 s vola [ForegroundEventSource] za okno od
 * posledneho dotazu (ADR-07) a rozhodnutie prenecha [GateDecider]. Pri
 * vypnutej obrazovke sa pozastavi ([onScreenOff]/[onScreenOn]).
 */
class ForegroundAppMonitor(
    private val events: ForegroundEventSource,
    private val decider: GateDecider,
    private val snapshot: () -> BlockerSnapshot,
    private val showGate: (String) -> Unit,
    private val wallClock: () -> Long,
    private val scheduler: TickScheduler,
    private val intervalMs: Long = INTERVAL_MS,
    private val onError: (RuntimeException) -> Unit = {},
    private val debugLog: ((String) -> Unit)? = null,
) {
    private var running = false
    private var screenOn = false
    private var lastQueryEnd = 0L

    /** Posledna znama appka v popredi. */
    var foreground: String? = null
        private set

    private val tickTask = Runnable { tick() }

    fun start(screenInteractive: Boolean) {
        debugLog?.invoke("start interactive=$screenInteractive")
        running = true
        screenOn = screenInteractive
        reschedule(0)
    }

    fun stop() {
        running = false
        scheduler.cancel(tickTask)
    }

    fun onScreenOff() {
        screenOn = false
        scheduler.cancel(tickTask)
    }

    fun onScreenOn() {
        screenOn = true
        reschedule(0)
    }

    val isPolling: Boolean get() = running && screenOn

    internal fun tick() {
        if (!isPolling) return
        try {
            val now = wallClock()
            // Prvy dotaz alebo posun systemoveho casu dozadu: kratke okno dozadu.
            val begin =
                if (lastQueryEnd == 0L || now < lastQueryEnd) {
                    now - LOOKBACK_MS
                } else {
                    lastQueryEnd - OVERLAP_MS
                }
            events.lastResumed(begin, now)?.let { foreground = it }
            lastQueryEnd = now
            val decision = decider.decide(foreground, snapshot())
            debugLog?.invoke("tick fg=$foreground decision=$decision")
            if (decision is GateDecision.ShowGate) showGate(decision.ref)
        } catch (e: RuntimeException) {
            // Napr. SecurityException po odobrati usage access: sluzba nesmie
            // spadnut, dalsi tick to skusi znova.
            onError(e)
        } finally {
            reschedule(intervalMs)
        }
    }

    private fun reschedule(delayMs: Long) {
        scheduler.cancel(tickTask)
        if (isPolling) scheduler.schedule(delayMs, tickTask)
    }

    companion object {
        const val INTERVAL_MS = 1_000L
        const val OVERLAP_MS = 1_500L
        const val LOOKBACK_MS = 5_000L
    }
}
