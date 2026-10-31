package app.mursa.blocker

import org.junit.Assert.assertEquals
import org.junit.Test

class GateDeciderTest {
    private val unlocked = mutableSetOf<String>()
    private var enabled = true
    private val decider = GateDecider(OWN)

    private fun snapshot() = BlockerSnapshot(enabled, setOf(IG, YT), { it in unlocked })

    private fun decide(fg: String?) = decider.decide(fg, snapshot())

    private fun skip(reason: SkipReason) = GateDecision.Skip(reason)

    @Test
    fun `blocked app opens gate`() {
        assertEquals(GateDecision.ShowGate(IG), decide(IG))
    }

    @Test
    fun `disabled blocker never gates`() {
        enabled = false
        assertEquals(skip(SkipReason.DISABLED), decide(IG))
    }

    @Test
    fun `unknown foreground is skipped`() {
        assertEquals(skip(SkipReason.UNKNOWN_FOREGROUND), decide(null))
    }

    @Test
    fun `own app and not blocked apps are skipped`() {
        assertEquals(skip(SkipReason.OWN_APP), decide(OWN))
        assertEquals(skip(SkipReason.NOT_BLOCKED), decide(LAUNCHER))
    }

    @Test
    fun `unlocked app is skipped`() {
        unlocked += IG
        assertEquals(skip(SkipReason.UNLOCKED), decide(IG))
    }

    @Test
    fun `gate is launched once per foreground session (no spam when launch fails)`() {
        assertEquals(GateDecision.ShowGate(IG), decide(IG))
        repeat(5) { assertEquals(skip(SkipReason.ALREADY_GATED), decide(IG)) }
    }

    @Test
    fun `returning from gate via recents without unlock gates again`() {
        decide(IG)
        decide(OWN) // brana v popredi
        assertEquals(GateDecision.ShowGate(IG), decide(IG))
    }

    @Test
    fun `leaving to home and reopening gates again`() {
        decide(IG)
        decide(LAUNCHER)
        assertEquals(GateDecision.ShowGate(IG), decide(IG))
    }

    @Test
    fun `continue after cards opens target without second gate`() {
        decide(IG)
        decide(OWN)
        unlocked += IG // Flutter unlockFor pred closeGate(true)
        assertEquals(skip(SkipReason.UNLOCKED), decide(IG))
    }

    @Test
    fun `unlock expiring while app is in use gates again`() {
        decide(IG)
        unlocked += IG
        decide(IG)
        unlocked -= IG
        assertEquals(GateDecision.ShowGate(IG), decide(IG))
        assertEquals(skip(SkipReason.ALREADY_GATED), decide(IG))
    }

    @Test
    fun `switching directly between two blocked apps gates each`() {
        assertEquals(GateDecision.ShowGate(IG), decide(IG))
        assertEquals(GateDecision.ShowGate(YT), decide(YT))
    }

    @Test
    fun `re-enabling resets state`() {
        decide(IG)
        enabled = false
        decide(IG)
        enabled = true
        assertEquals(GateDecision.ShowGate(IG), decide(IG))
    }

    private companion object {
        const val OWN = "app.mursa.dev"
        const val IG = "com.instagram.android"
        const val YT = "com.google.android.youtube"
        const val LAUNCHER = "com.google.android.apps.nexuslauncher"
    }
}
