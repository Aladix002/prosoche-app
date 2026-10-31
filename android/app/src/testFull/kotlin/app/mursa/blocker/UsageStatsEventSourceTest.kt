package app.mursa.blocker

import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.Shadows.shadowOf
import org.robolectric.shadows.ShadowUsageStatsManager.EventBuilder

/** Vyber appky v popredi z UsageEvents (Android 10+: ACTIVITY_RESUMED). */
@RunWith(RobolectricTestRunner::class)
class UsageStatsEventSourceTest {
    private val context = RuntimeEnvironment.getApplication()
    private val usm = context.getSystemService(UsageStatsManager::class.java)

    private fun add(pkg: String, type: Int, ts: Long) {
        shadowOf(usm).addEvent(
            EventBuilder.buildEvent().setPackage(pkg).setTimeStamp(ts).setEventType(type).build(),
        )
    }

    @Test
    fun `last resumed activity wins, pause and stop are ignored`() {
        add(LAUNCHER, UsageEvents.Event.ACTIVITY_RESUMED, 1_000)
        add(LAUNCHER, UsageEvents.Event.ACTIVITY_PAUSED, 1_100)
        add(CONTACTS, UsageEvents.Event.ACTIVITY_RESUMED, 1_200)
        add(LAUNCHER, UsageEvents.Event.ACTIVITY_STOPPED, 1_300)
        val log = mutableListOf<String>()
        val source = UsageStatsEventSource(context) { log += it }
        assertEquals(CONTACTS, source.lastResumed(0, 2_000))
        assertEquals(1, log.size)
    }

    @Test
    fun `window without resume returns null`() {
        add(CONTACTS, UsageEvents.Event.ACTIVITY_RESUMED, 1_000)
        add(CONTACTS, UsageEvents.Event.ACTIVITY_PAUSED, 3_000)
        assertNull(UsageStatsEventSource(context).lastResumed(2_000, 4_000))
    }

    private companion object {
        const val LAUNCHER = "com.google.android.apps.nexuslauncher"
        const val CONTACTS = "com.google.android.contacts"
    }
}
