package app.prosoche.blocker

import android.content.Context
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment

class FakeDeviceTime(
    var elapsed: Long = 1_000_000L,
    var boot: Int = 7,
    var wall: Long = 1_800_000_000_000L,
) : DeviceTime {
    override fun elapsedRealtime(): Long = elapsed

    override fun bootCount(): Int = boot

    override fun currentTimeMillis(): Long = wall
}

@RunWith(RobolectricTestRunner::class)
class UnlockStoreTest {
    private lateinit var time: FakeDeviceTime
    private lateinit var store: UnlockStore
    private val context: Context get() = RuntimeEnvironment.getApplication()

    @Before
    fun setUp() {
        time = FakeDeviceTime()
        store = UnlockStore(context, time)
    }

    @Test
    fun `locked by default`() {
        assertFalse(store.isUnlocked(IG))
        assertEquals(0L, store.remainingMs(IG))
    }

    @Test
    fun `unlock lasts exactly the granted minutes`() {
        store.unlockFor(IG, 5)
        assertTrue(store.isUnlocked(IG))
        assertEquals(5 * MIN, store.remainingMs(IG))

        time.elapsed += 5 * MIN - 1
        assertTrue(store.isUnlocked(IG))
        assertEquals(1L, store.remainingMs(IG))

        time.elapsed += 1
        assertFalse(store.isUnlocked(IG))
    }

    @Test
    fun `unlock is per package`() {
        store.unlockFor(IG, 10)
        assertTrue(store.isUnlocked(IG))
        assertFalse(store.isUnlocked(YT))
    }

    @Test
    fun `wall clock moved forward does not expire unlock`() {
        store.unlockFor(IG, 10)
        time.wall += 24 * 60 * MIN
        assertTrue(store.isUnlocked(IG))
        assertEquals(10 * MIN, store.remainingMs(IG))
    }

    @Test
    fun `wall clock moved backward does not extend unlock`() {
        store.unlockFor(IG, 10)
        time.wall -= 24 * 60 * MIN
        time.elapsed += 10 * MIN
        assertFalse(store.isUnlocked(IG))
    }

    @Test
    fun `real system time change does not matter`() {
        // Ziadny zavisly vypocet na System.currentTimeMillis(): rovnaky
        // vysledok pre lubovolny nastenny cas.
        store.unlockFor(IG, 3)
        listOf(0L, 1L, Long.MAX_VALUE / 2, 1_700_000_000_000L).forEach {
            time.wall = it
            assertEquals(3 * MIN, store.remainingMs(IG))
        }
    }

    @Test
    fun `reboot invalidates unlock even when elapsed looks valid`() {
        store.unlockFor(IG, 30)
        time.boot += 1
        time.elapsed = 10
        assertFalse(store.isUnlocked(IG))
    }

    @Test
    fun `reboot without boot count is caught by remaining bigger than granted`() {
        time.boot = -1
        time.elapsed = 5 * 60 * MIN
        store.unlockFor(IG, 5)
        // Restart: elapsed znova od nuly, boot count nedostupny.
        time.elapsed = 1_000
        assertFalse(store.isUnlocked(IG))
    }

    @Test
    fun `new unlock replaces older one`() {
        store.unlockFor(IG, 30)
        store.unlockFor(IG, 5)
        assertEquals(5 * MIN, store.remainingMs(IG))
    }

    @Test
    fun `clear removes unlock`() {
        store.unlockFor(IG, 30)
        store.clear(IG)
        assertFalse(store.isUnlocked(IG))
    }

    @Test
    fun `persists across instances (service reads what Flutter wrote)`() {
        store.unlockFor(IG, 15)
        val other = UnlockStore(context, time)
        assertEquals(15 * MIN, other.remainingMs(IG))
    }

    @Test(expected = IllegalArgumentException::class)
    fun `zero minutes rejected`() {
        store.unlockFor(IG, 0)
    }

    @Test(expected = IllegalArgumentException::class)
    fun `more than a day rejected`() {
        store.unlockFor(IG, UnlockStore.MAX_MINUTES + 1)
    }

    @Test
    fun `corrupted value is treated as locked`() {
        prefs().edit().putString(IG, "garbage").putString(YT, "1:x:5").apply()
        assertFalse(store.isUnlocked(IG))
        assertFalse(store.isUnlocked(YT))
    }

    @Test
    fun `purgeExpired keeps only active unlocks`() {
        store.unlockFor(IG, 1)
        store.unlockFor(YT, 10)
        time.elapsed += 2 * MIN
        store.purgeExpired()
        assertEquals(setOf(YT), prefs().all.keys)
    }

    private fun prefs() = context.getSharedPreferences(UnlockStore.PREFS, Context.MODE_PRIVATE)

    private companion object {
        const val IG = "com.instagram.android"
        const val YT = "com.google.android.youtube"
        const val MIN = 60_000L
    }
}
