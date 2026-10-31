package app.prosoche.blocker

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class ForegroundAppMonitorTest {
    private class FakeScheduler : TickScheduler {
        var pending: Runnable? = null
        var lastDelay: Long = -1

        override fun schedule(delayMs: Long, task: Runnable) {
            pending = task
            lastDelay = delayMs
        }

        override fun cancel(task: Runnable) {
            if (pending === task) pending = null
        }

        fun runPending() {
            val task = pending ?: error("nothing scheduled")
            pending = null
            task.run()
        }
    }

    private val scheduler = FakeScheduler()
    private var now = 1_800_000_000_000L
    private val queries = mutableListOf<Pair<Long, Long>>()
    private var nextResumed: String? = null
    private val gates = mutableListOf<String>()
    private val unlocked = mutableSetOf<String>()

    private val monitor = ForegroundAppMonitor(
        events = { begin, end ->
            queries += begin to end
            nextResumed.also { nextResumed = null }
        },
        decider = GateDecider(OWN),
        snapshot = { BlockerSnapshot(true, setOf(IG), { it in unlocked }) },
        showGate = { gates += it },
        wallClock = { now },
        scheduler = scheduler,
    )

    private fun tick(resumed: String? = null) {
        nextResumed = resumed
        now += ForegroundAppMonitor.INTERVAL_MS
        scheduler.runPending()
    }

    @Test
    fun `opening blocked app launches gate on next tick`() {
        monitor.start(screenInteractive = true)
        assertEquals(0L, scheduler.lastDelay)
        tick(IG)
        assertEquals(listOf(IG), gates)
        assertEquals(ForegroundAppMonitor.INTERVAL_MS, scheduler.lastDelay)
    }

    @Test
    fun `foreground persists between ticks without events`() {
        monitor.start(true)
        tick(IG)
        tick()
        tick()
        assertEquals(IG, monitor.foreground)
        assertEquals(listOf(IG), gates)
    }

    @Test
    fun `query windows are contiguous with overlap`() {
        monitor.start(true)
        tick()
        tick()
        val (b1, e1) = queries[0]
        val (b2, e2) = queries[1]
        assertEquals(ForegroundAppMonitor.LOOKBACK_MS, e1 - b1)
        assertEquals(e1 - ForegroundAppMonitor.OVERLAP_MS, b2)
        assertTrue(e2 > e1)
    }

    @Test
    fun `wall clock jumping back resets window`() {
        monitor.start(true)
        tick()
        now -= 3_600_000L
        tick()
        val (b, e) = queries[1]
        assertEquals(ForegroundAppMonitor.LOOKBACK_MS, e - b)
    }

    @Test
    fun `screen off pauses polling, screen on resumes`() {
        monitor.start(true)
        tick(IG)
        monitor.onScreenOff()
        assertFalse(monitor.isPolling)
        assertNull(scheduler.pending)

        monitor.onScreenOn()
        assertTrue(monitor.isPolling)
        assertEquals(0L, scheduler.lastDelay)
        tick()
        assertEquals(2, queries.size)
    }

    @Test
    fun `started with screen off does not poll`() {
        monitor.start(screenInteractive = false)
        assertNull(scheduler.pending)
        assertTrue(queries.isEmpty())
    }

    @Test
    fun `stop cancels ticks and stale tick does nothing`() {
        monitor.start(true)
        val task = scheduler.pending!!
        monitor.stop()
        assertNull(scheduler.pending)
        task.run()
        assertTrue(queries.isEmpty())
    }

    @Test
    fun `unlock expiry while in app shows gate again`() {
        monitor.start(true)
        unlocked += IG
        tick(IG)
        assertTrue(gates.isEmpty())
        unlocked -= IG
        tick()
        assertEquals(listOf(IG), gates)
    }

    @Test
    fun `debug log explains skipped gate for unlocked app`() {
        val log = mutableListOf<String>()
        val m = ForegroundAppMonitor(
            events = { _, _ -> IG },
            decider = GateDecider(OWN),
            snapshot = { BlockerSnapshot(true, setOf(IG), { it in unlocked }) },
            showGate = { gates += it },
            wallClock = { now },
            scheduler = scheduler,
            debugLog = { log += it },
        )
        unlocked += IG
        m.start(true)
        scheduler.runPending()
        assertTrue(gates.isEmpty())
        assertTrue(log.any { "UNLOCKED" in it && IG in it })
        unlocked.clear()
        scheduler.runPending()
        assertEquals(listOf(IG), gates)
        assertTrue(log.last().contains("ShowGate"))
    }

    @Test
    fun `exception in event source keeps polling`() {
        var fail = true
        val errors = mutableListOf<RuntimeException>()
        val m = ForegroundAppMonitor(
            events = { _, _ -> if (fail) throw SecurityException("no access") else IG },
            decider = GateDecider(OWN),
            snapshot = { BlockerSnapshot(true, setOf(IG), { false }) },
            showGate = { gates += it },
            wallClock = { now },
            scheduler = scheduler,
            onError = { errors += it },
        )
        m.start(true)
        scheduler.runPending()
        assertTrue(errors.single() is SecurityException)
        assertEquals(ForegroundAppMonitor.INTERVAL_MS, scheduler.lastDelay)
        fail = false
        scheduler.runPending()
        assertEquals(listOf(IG), gates)
    }

    private companion object {
        const val OWN = "app.prosoche.dev"
        const val IG = "com.instagram.android"
    }
}
