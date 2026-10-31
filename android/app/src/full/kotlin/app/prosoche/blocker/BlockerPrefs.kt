package app.prosoche.blocker

import android.content.Context
import android.content.SharedPreferences
import org.json.JSONArray
import org.json.JSONObject

/**
 * Nastavenia blockeru, ktore potrebuje sluzba aj bez Flutteru (BootReceiver,
 * monitor): zapnute/vypnute, blokovane appky, okna modlitieb.
 * Zdroj pravdy je user.db vo Flutteri, sem sa zrkadli cez Pigeon.
 */
class BlockerPrefs(private val prefs: SharedPreferences) {
    constructor(context: Context) : this(
        context.applicationContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE),
    )

    var enabled: Boolean
        get() = prefs.getBoolean(KEY_ENABLED, false)
        set(value) {
            prefs.edit().putBoolean(KEY_ENABLED, value).apply()
        }

    /** Package names blokovanych appiek (cita monitor kazdy tick). */
    fun blockedRefs(): Set<String> = prefs.getStringSet(KEY_REFS, emptySet()) ?: emptySet()

    fun targets(): List<BlockedTarget> {
        val raw = prefs.getString(KEY_TARGETS, null) ?: return emptyList()
        return try {
            val array = JSONArray(raw)
            (0 until array.length()).map { i ->
                val o = array.getJSONObject(i)
                BlockedTarget(
                    ref = o.getString("ref"),
                    label = if (o.has("label")) o.getString("label") else null,
                    cardsRequired = o.getLong("cards"),
                    unlockMinutes = o.getLong("minutes"),
                )
            }
        } catch (e: org.json.JSONException) {
            emptyList()
        }
    }

    /** Ulozi ciele bez ikon (ikony sa citaju z PackageManager). */
    fun setTargets(targets: List<BlockedTarget>) {
        val array = JSONArray()
        targets.forEach { t ->
            array.put(
                JSONObject()
                    .put("ref", t.ref)
                    .put("cards", t.cardsRequired)
                    .put("minutes", t.unlockMinutes)
                    .apply { t.label?.let { put("label", it) } },
            )
        }
        prefs.edit()
            .putString(KEY_TARGETS, array.toString())
            .putStringSet(KEY_REFS, targets.map { it.ref }.toSet())
            .apply()
    }

    /** Okna modlitieb (epoch ms zaciatkov, trvanie v minutach). */
    fun prayerLocks(): Pair<List<Long>, Int> {
        val starts = prefs.getString(KEY_PRAYER_STARTS, "")!!
            .split(',')
            .mapNotNull { it.toLongOrNull() }
        return starts to prefs.getInt(KEY_PRAYER_MINUTES, 0)
    }

    fun setPrayerLocks(startEpochMs: List<Long>, durationMinutes: Int) {
        prefs.edit()
            .putString(KEY_PRAYER_STARTS, startEpochMs.joinToString(","))
            .putInt(KEY_PRAYER_MINUTES, durationMinutes)
            .apply()
    }

    companion object {
        const val PREFS = "prosoche_blocker"
        private const val KEY_ENABLED = "enabled"
        private const val KEY_REFS = "blocked_refs"
        private const val KEY_TARGETS = "targets_json"
        private const val KEY_PRAYER_STARTS = "prayer_starts"
        private const val KEY_PRAYER_MINUTES = "prayer_minutes"
    }
}

/** Validny Android package name (rovnaky regex ako `GateParams.parseApp`). */
fun isValidPackageName(ref: String): Boolean = ref.length <= 255 && PACKAGE_RE.matches(ref)

private val PACKAGE_RE = Regex("^[a-zA-Z][a-zA-Z0-9_]*(\\.[a-zA-Z][a-zA-Z0-9_]*)+$")
