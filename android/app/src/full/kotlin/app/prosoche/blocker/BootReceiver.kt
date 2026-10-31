package app.prosoche.blocker

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

/**
 * Po restarte (a po update appky) znova spusti [BlockerService], ak je
 * blokovanie zapnute a usage access stale udeleny. specialUse FGS sa z
 * BOOT_COMPLETED spustit smie (docs/08 B).
 */
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action !in ACTIONS) return
        if (!BlockerPrefs(context).enabled) return
        if (!Permissions(context).usageAccess()) return
        try {
            BlockerService.start(context)
        } catch (e: RuntimeException) {
            // ForegroundServiceStartNotAllowedException a pod.: brana sa
            // obnovi pri dalsom otvoreni appky.
            Log.w(GateLauncher.TAG, "boot start failed: ${e.javaClass.simpleName}")
        }
    }

    companion object {
        val ACTIONS = setOf(Intent.ACTION_BOOT_COMPLETED, Intent.ACTION_MY_PACKAGE_REPLACED)
    }
}
