package app.prosoche.blocker

import android.content.Context
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment

/** Intent brany nad predhriatym enginom (B-02, ADR-16). */
@RunWith(RobolectricTestRunner::class)
class GateActivityIntentTest {
    private val context: Context get() = RuntimeEnvironment.getApplication()

    @Test
    fun `intent uses the cached gate engine`() {
        val intent = GateActivity.intent(context, "com.instagram.android")
        assertEquals(GateActivity::class.java.name, intent.component?.className)
        assertEquals(GateEngine.ENGINE_ID, intent.getStringExtra("cached_engine_id"))
        assertFalse(intent.getBooleanExtra("destroy_engine_with_activity", true))
        assertEquals("com.instagram.android", intent.getStringExtra(GateActivity.EXTRA_APP))
        assertEquals(GateActivity.SOURCE_MONITOR, intent.getStringExtra(GateActivity.EXTRA_SRC))
    }

    @Test
    fun `source is kept when known and normalized otherwise`() {
        val error = GateActivity.intent(context, "com.instagram.android", "error")
        assertEquals("error", error.getStringExtra(GateActivity.EXTRA_SRC))
        val unknown = GateActivity.intent(context, "com.instagram.android", "bogus")
        assertEquals(GateActivity.SOURCE_MONITOR, unknown.getStringExtra(GateActivity.EXTRA_SRC))
    }

    @Test
    fun `practice intent is an explicit deep link into this app`() {
        val intent = GateActivity.practiceIntent("app.prosoche.dev")
        assertEquals(android.content.Intent.ACTION_VIEW, intent.action)
        assertEquals("prosoche://practice", intent.dataString)
        assertEquals("app.prosoche.dev", intent.`package`)
        assertTrue(intent.flags and android.content.Intent.FLAG_ACTIVITY_NEW_TASK != 0)
    }

    @Test
    fun `sources match the Dart GateParams`() {
        assertEquals(setOf("monitor", "notif", "test", "error"), GateActivity.SOURCES)
        assertTrue(GateActivity.FALLBACK_MS in 3_000L..10_000L)
    }
}
