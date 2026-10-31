package app.prosoche.blocker

import android.content.Context
import android.os.Build
import java.util.Locale
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

/** Verzia nativnej strany Pigeon API (ADR-10), Dart: `blockerApiVersion`. */
const val BLOCKER_API_VERSION = 1L

/**
 * Implementacia [BlockerHostApi] (TECHNICKY_PLAN 11). Chybove kody podla
 * docs/06 C.5; do message nikdy nejde nazov balika ani data pouzivatela.
 *
 * [gateHost] je null v hlavnom engine (MainActivity), vtedy `closeGate`
 * nic nerobi.
 */
class BlockerHostApiImpl(
    context: Context,
    private val gateHost: GateHost? = null,
    private val prefs: BlockerPrefs = BlockerPrefs(context),
    private val unlocks: UnlockStore = UnlockStore(context),
    private val permissions: Permissions = Permissions(context),
    private val service: ServiceControl = ServiceControl.Default,
) : BlockerHostApi {
    private val context = context.applicationContext

    override fun status(): BlockerStatus =
        BlockerStatus(
            apiVersion = BLOCKER_API_VERSION,
            enabled = prefs.enabled,
            permission = if (permissions.usageAccess()) BlockerPermission.GRANTED else BlockerPermission.DENIED,
            serviceRunning = service.isRunning(),
        )

    override fun permissionsDetail(): PermissionsDetail = permissions.detail()

    override suspend fun requestPermission(): BlockerPermission {
        if (permissions.usageAccess()) return BlockerPermission.GRANTED
        SystemSettingsIntents.open(context, SystemSettingsKind.USAGE_ACCESS)
        return BlockerPermission.DENIED
    }

    override fun openSystemSettings(kind: SystemSettingsKind) {
        if (!SystemSettingsIntents.open(context, kind)) {
            throw FlutterError("os_unsupported", "settings screen not available", null)
        }
    }

    override suspend fun pickTargets(): List<BlockedTarget> =
        throw FlutterError("os_unsupported", "android uses installedApps", null)

    override suspend fun installedApps(): List<InstalledApp> =
        withContext(Dispatchers.IO) { InstalledAppsProvider(context).launchableApps() }

    override suspend fun appIcon(ref: String): ByteArray? {
        requireRef(ref)
        return withContext(Dispatchers.IO) { InstalledAppsProvider(context).iconPng(ref) }
    }

    override fun setTargets(targets: List<BlockedTarget>) {
        targets.forEach { requireRef(it.ref) }
        prefs.setTargets(targets)
    }

    override fun setEnabled(enabled: Boolean) {
        if (!enabled) {
            prefs.enabled = false
            service.stop(context)
            return
        }
        if (!permissions.usageAccess()) {
            throw FlutterError("permission_missing", "usage access not granted", null)
        }
        if (!permissions.overlay()) {
            throw FlutterError("overlay_denied", "overlay not granted", null)
        }
        // Zapnutie brany zacina nanovo: stare odomknutie (napr. z brany
        // otvorenej pred vypnutim) by inak branu potichu preskocilo
        // (I-02: monitor "nespustil" branu, appka bola odomknuta).
        if (!prefs.enabled) unlocks.clearAll()
        prefs.enabled = true
        try {
            service.start(context)
        } catch (e: RuntimeException) {
            // ForegroundServiceStartNotAllowedException (appka nie je v popredi) a pod.
            prefs.enabled = false
            throw FlutterError("internal", e.javaClass.simpleName, null)
        }
    }

    override fun unlockFor(ref: String, minutes: Long) {
        requireRef(ref)
        if (minutes !in UnlockStore.MIN_MINUTES..UnlockStore.MAX_MINUTES) {
            throw FlutterError("invalid_target", "minutes out of range", null)
        }
        unlocks.unlockFor(ref, minutes.toInt())
    }

    override fun closeGate(openTarget: Boolean) {
        gateHost?.finishGate(openTarget)
    }

    override fun clearUnlocks() {
        unlocks.clearAll()
    }

    override fun deviceManufacturer(): String = Build.MANUFACTURER.orEmpty().lowercase(Locale.ROOT)

    private fun requireRef(ref: String) {
        if (!isValidPackageName(ref)) throw FlutterError("invalid_target", "invalid ref", null)
    }
}

/** Ovladanie BlockerService (fake v testoch). */
interface ServiceControl {
    fun start(context: Context)

    fun stop(context: Context)

    fun isRunning(): Boolean

    object Default : ServiceControl {
        override fun start(context: Context) = BlockerService.start(context)

        override fun stop(context: Context) = BlockerService.stop(context)

        override fun isRunning(): Boolean = BlockerService.isRunning
    }
}
