package app.prosoche.blocker

import android.content.Context
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Assert.fail
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment

@RunWith(RobolectricTestRunner::class)
class BlockerHostApiImplTest {
    private class FakePermissions(context: Context) : Permissions(context) {
        var usage = true
        var overlayGranted = true

        override fun usageAccess() = usage

        override fun overlay() = overlayGranted
    }

    private class FakeService : ServiceControl {
        var running = false
        var startError: RuntimeException? = null

        override fun start(context: Context) {
            startError?.let { throw it }
            running = true
        }

        override fun stop(context: Context) {
            running = false
        }

        override fun isRunning() = running
    }

    private class FakeGate : GateHost {
        var closed: Boolean? = null
        override val gateTarget: String? = IG

        var practice = 0

        override fun finishGate(openTarget: Boolean) {
            closed = openTarget
        }

        override fun openPractice() {
            practice++
        }
    }

    private val context: Context get() = RuntimeEnvironment.getApplication()
    private lateinit var time: FakeDeviceTime
    private lateinit var prefs: BlockerPrefs
    private lateinit var unlocks: UnlockStore
    private lateinit var permissions: FakePermissions
    private lateinit var service: FakeService
    private lateinit var api: BlockerHostApiImpl

    @Before
    fun setUp() {
        time = FakeDeviceTime()
        prefs = BlockerPrefs(context)
        unlocks = UnlockStore(context, time)
        permissions = FakePermissions(context)
        service = FakeService()
        api = BlockerHostApiImpl(context, null, prefs, unlocks, permissions, service)
    }

    private fun expectError(code: String, block: () -> Unit) {
        try {
            block()
            fail("expected FlutterError $code")
        } catch (e: FlutterError) {
            assertEquals(code, e.code)
            assertFalse("no package name in message", e.message.orEmpty().contains(IG))
        }
    }

    @Test
    fun `status reports version, enabled, permission and service`() {
        permissions.usage = false
        val s = api.status()
        assertEquals(BLOCKER_API_VERSION, s.apiVersion)
        assertFalse(s.enabled)
        assertEquals(BlockerPermission.DENIED, s.permission)
        assertFalse(s.serviceRunning)
    }

    @Test
    fun `setEnabled requires usage access then overlay`() {
        permissions.usage = false
        expectError("permission_missing") { api.setEnabled(true) }
        permissions.usage = true
        permissions.overlayGranted = false
        expectError("overlay_denied") { api.setEnabled(true) }
        assertFalse(prefs.enabled)
        assertFalse(service.running)
    }

    @Test
    fun `setEnabled starts and stops service`() {
        api.setEnabled(true)
        assertTrue(prefs.enabled)
        assertTrue(api.status().serviceRunning)
        assertEquals(BlockerPermission.GRANTED, api.status().permission)
        api.setEnabled(false)
        assertFalse(prefs.enabled)
        assertFalse(service.running)
    }

    @Test
    fun `turning the gate on clears stale unlocks`() {
        api.unlockFor(IG, 10)
        api.setEnabled(true)
        assertFalse(unlocks.isUnlocked(IG))
        // Opakovane zapnutie (Fix, restart sluzby) odomknutia nemaze.
        api.unlockFor(IG, 10)
        api.setEnabled(true)
        assertTrue(unlocks.isUnlocked(IG))
    }

    @Test
    fun `clearUnlocks removes all unlocks`() {
        api.unlockFor(IG, 10)
        api.unlockFor(YT, 5)
        api.clearUnlocks()
        assertFalse(unlocks.isUnlocked(IG))
        assertFalse(unlocks.isUnlocked(YT))
    }

    @Test
    fun `deviceManufacturer is lowercase`() {
        val m = api.deviceManufacturer()
        assertEquals(m.lowercase(), m)
    }

    @Test
    fun `failed service start rolls back enabled`() {
        service.startError = IllegalStateException("bg start")
        expectError("internal") { api.setEnabled(true) }
        assertFalse(prefs.enabled)
    }

    @Test
    fun `unlockFor writes unlock store and validates input`() {
        api.unlockFor(IG, 5)
        assertEquals(5 * 60_000L, unlocks.remainingMs(IG))
        expectError("invalid_target") { api.unlockFor("not a package", 5) }
        expectError("invalid_target") { api.unlockFor(IG, 0) }
        expectError("invalid_target") { api.unlockFor(IG, 1441) }
    }

    @Test
    fun `setTargets persists refs for monitor`() {
        api.setTargets(
            listOf(
                BlockedTarget(ref = IG, label = "Instagram", cardsRequired = 3, unlockMinutes = 15),
                BlockedTarget(ref = YT, cardsRequired = 2, unlockMinutes = 10),
            ),
        )
        assertEquals(setOf(IG, YT), prefs.blockedRefs())
        val stored = BlockerPrefs(context).targets()
        assertEquals("Instagram", stored[0].label)
        assertNull(stored[1].label)
        assertEquals(10L, stored[1].unlockMinutes)
        expectError("invalid_target") {
            api.setTargets(listOf(BlockedTarget(ref = "x", cardsRequired = 1, unlockMinutes = 1)))
        }
    }

    @Test
    fun `closeGate goes to gate host, no-op in main engine`() {
        api.closeGate(true) // bez brany nic
        val gate = FakeGate()
        BlockerHostApiImpl(context, gate, prefs, unlocks, permissions, service).closeGate(false)
        assertEquals(false, gate.closed)
    }

    @Test
    fun `openPractice goes to gate host, no-op in main engine`() {
        api.openPractice() // bez brany nic
        val gate = FakeGate()
        BlockerHostApiImpl(context, gate, prefs, unlocks, permissions, service).openPractice()
        assertEquals(1, gate.practice)
        assertNull(gate.closed)
    }

    @Test
    fun `pickTargets is unsupported on android`() {
        expectError("os_unsupported") { kotlinx.coroutines.runBlocking { api.pickTargets() } }
    }

    @Test
    fun `corrupted targets json reads as empty`() {
        context.getSharedPreferences(BlockerPrefs.PREFS, Context.MODE_PRIVATE)
            .edit().putString("targets_json", "{").apply()
        assertTrue(prefs.targets().isEmpty())
    }

    private companion object {
        const val IG = "com.instagram.android"
        const val YT = "com.google.android.youtube"
    }
}
