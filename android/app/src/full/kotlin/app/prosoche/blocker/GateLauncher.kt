package app.prosoche.blocker

import android.content.Context
import android.content.Intent
import android.os.SystemClock
import android.util.Log

/**
 * Spusti [GateActivity] nad blokovanou appkou. Volane zo sluzby priamo cez
 * `startActivity` s `FLAG_ACTIVITY_NEW_TASK`, nie cez PendingIntent ani
 * IntentSender (Android 14/15/17 BAL, docs/08 A). Vynimku zo zakazu
 * spustat aktivity z pozadia dava udelene SYSTEM_ALERT_WINDOW.
 */
class GateLauncher(private val context: Context) {
    /** Vrati false, ak start zlyhal (brana nikdy neuvazni: appka ostane otvorena). */
    fun launch(ref: String, source: String = GateActivity.SOURCE_MONITOR): Boolean {
        if (!isValidPackageName(ref)) return false
        val intent = GateActivity.intent(context, ref, source)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        return try {
            // Bez nazvu balika v logu (docs/06 C.5), cas pre meranie latencie.
            Log.i(TAG, "gate launch t=${SystemClock.elapsedRealtime()}")
            context.startActivity(intent)
            true
        } catch (e: RuntimeException) {
            Log.w(TAG, "gate launch failed: ${e.javaClass.simpleName}")
            false
        }
    }

    companion object {
        const val TAG = "ProsocheGate"
    }
}
