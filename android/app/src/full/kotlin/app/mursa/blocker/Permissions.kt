package app.mursa.blocker

import android.app.AlarmManager
import android.app.AppOpsManager
import android.app.NotificationManager
import android.content.ActivityNotFoundException
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.os.Process
import android.provider.Settings

/** Stav povoleni pre O6 (docs/02 D14). Bez REQUEST_IGNORE_BATTERY_OPTIMIZATIONS. */
open class Permissions(context: Context) {
    private val context = context.applicationContext

    @Suppress("DEPRECATION") // unsafeCheckOpNoThrow (API 36), checkOpNoThrow (API 29)
    open fun usageAccess(): Boolean {
        val ops = context.getSystemService(AppOpsManager::class.java) ?: return false
        val mode =
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                ops.unsafeCheckOpNoThrow(AppOpsManager.OPSTR_GET_USAGE_STATS, Process.myUid(), context.packageName)
            } else {
                ops.checkOpNoThrow(AppOpsManager.OPSTR_GET_USAGE_STATS, Process.myUid(), context.packageName)
            }
        return mode == AppOpsManager.MODE_ALLOWED
    }

    open fun overlay(): Boolean = Settings.canDrawOverlays(context)

    fun notifications(): Boolean =
        context.getSystemService(NotificationManager::class.java)?.areNotificationsEnabled() ?: false

    fun exactAlarm(): Boolean =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            context.getSystemService(AlarmManager::class.java)?.canScheduleExactAlarms() ?: false
        } else {
            true
        }

    /** true = appka podlieha optimalizacii baterie. */
    fun batteryOptimized(): Boolean {
        val pm = context.getSystemService(PowerManager::class.java) ?: return true
        return !pm.isIgnoringBatteryOptimizations(context.packageName)
    }

    fun detail(): PermissionsDetail =
        PermissionsDetail(
            usageAccess = usageAccess(),
            overlay = overlay(),
            notifications = notifications(),
            exactAlarm = exactAlarm(),
            batteryOptimized = batteryOptimized(),
        )
}

/**
 * Intenty systemovych nastaveni (docs/08 A). Ak ciel na zariadeni nie je,
 * fallback je detail appky. Bateria: len zoznam
 * `ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS`, nikdy priama ziadost.
 */
object SystemSettingsIntents {
    fun candidates(kind: SystemSettingsKind, pkg: String, sdk: Int = Build.VERSION.SDK_INT): List<Intent> {
        val pkgUri = Uri.parse("package:$pkg")
        val primary = when (kind) {
            SystemSettingsKind.USAGE_ACCESS -> listOf(
                Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS, pkgUri),
                Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS),
            )
            SystemSettingsKind.OVERLAY -> listOf(Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION, pkgUri))
            SystemSettingsKind.EXACT_ALARM ->
                if (sdk >= Build.VERSION_CODES.S) {
                    listOf(Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM, pkgUri))
                } else {
                    emptyList()
                }
            SystemSettingsKind.BATTERY_OPTIMIZATION ->
                listOf(Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS))
            SystemSettingsKind.NOTIFICATIONS -> listOf(
                Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).putExtra(Settings.EXTRA_APP_PACKAGE, pkg),
            )
        }
        return primary + Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, pkgUri)
    }

    /** Otvori prvy dostupny ciel. Vrati false, ak nejde ziadny. */
    fun open(context: Context, kind: SystemSettingsKind): Boolean {
        for (intent in candidates(kind, context.packageName)) {
            try {
                context.startActivity(intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
                return true
            } catch (e: ActivityNotFoundException) {
                continue
            } catch (e: SecurityException) {
                continue
            }
        }
        return false
    }
}
