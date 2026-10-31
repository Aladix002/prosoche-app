package app.prosoche.blocker

import android.content.Context
import android.content.pm.ApplicationInfo
import android.util.Log

/**
 * Diagnosticke logy monitora, len v debuggable buildoch (tag `ProsocheGateDbg`).
 * Obsahuju nazvy balikov, preto v release nikdy (docs/06 C.5).
 */
fun debugLogger(context: Context): ((String) -> Unit)? {
    val debuggable = context.applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE != 0
    return if (debuggable) { msg -> Log.d(DEBUG_TAG, msg) } else null
}

const val DEBUG_TAG = "ProsocheGateDbg"
