package app.prosoche.blocker

import android.content.Context
import android.content.SharedPreferences

/**
 * `packageName -> unlockedUntil` (TECHNICKY_PLAN 9.1). Zapisuje Flutter cez
 * Pigeon `unlockFor`, cita BlockerService kazdy tick.
 *
 * Hodnota je `bootCount:untilElapsed:minutes`. Odomknutie plati, len ak:
 * - je z rovnakeho startu zariadenia (elapsedRealtime sa po restarte nuluje),
 * - `now < untilElapsed`,
 * - zostavajuci cas nie je dlhsi ako povodne udelene minuty (poistka, ked
 *   boot count nie je dostupny a hodnota je z predosleho startu).
 * Nastenny cas sa nepouziva, takze posun systemoveho casu nic nezmeni.
 */
class UnlockStore(
    private val prefs: SharedPreferences,
    private val time: DeviceTime,
) {
    constructor(context: Context, time: DeviceTime = SystemDeviceTime(context)) : this(
        context.applicationContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE),
        time,
    )

    /** Odomkne [ref] na [minutes] minut od teraz. Prepise predosle odomknutie. */
    fun unlockFor(ref: String, minutes: Int) {
        require(minutes in MIN_MINUTES..MAX_MINUTES) { "minutes out of range" }
        val until = time.elapsedRealtime() + minutes * MINUTE_MS
        prefs.edit().putString(ref, "${time.bootCount()}:$until:$minutes").apply()
    }

    /** Zostavajuci cas odomknutia v ms, 0 ak [ref] nie je odomknuta. */
    fun remainingMs(ref: String): Long {
        val raw = prefs.getString(ref, null) ?: return 0
        val parts = raw.split(':')
        if (parts.size != 3) return 0
        val boot = parts[0].toIntOrNull() ?: return 0
        val until = parts[1].toLongOrNull() ?: return 0
        val minutes = parts[2].toIntOrNull() ?: return 0
        if (boot != time.bootCount()) return 0
        val remaining = until - time.elapsedRealtime()
        if (remaining <= 0 || remaining > minutes * MINUTE_MS) return 0
        return remaining
    }

    fun isUnlocked(ref: String): Boolean = remainingMs(ref) > 0

    fun clear(ref: String) {
        prefs.edit().remove(ref).apply()
    }

    /** Zmaze vsetky odomknutia (Pigeon `clearUnlocks`, zmazanie dat). */
    fun clearAll() {
        prefs.edit().clear().apply()
    }

    /** Zmaze vyprsane a neplatne zaznamy (volane pri starte sluzby). */
    fun purgeExpired() {
        val stale = prefs.all.keys.filter { remainingMs(it) == 0L }
        if (stale.isEmpty()) return
        val editor = prefs.edit()
        stale.forEach { editor.remove(it) }
        editor.apply()
    }

    companion object {
        const val PREFS = "prosoche_blocker_unlocks"
        const val MIN_MINUTES = 1
        const val MAX_MINUTES = 24 * 60
        private const val MINUTE_MS = 60_000L
    }
}
