package app.mursa.blocker

import android.content.Context
import android.os.SystemClock
import android.provider.Settings

/**
 * Monotonny cas zariadenia. Odomknutia sa meraju cez [elapsedRealtime],
 * takze zmena systemoveho casu (rucna, NTP, casove pasmo) ich neovplyvni.
 * [elapsedRealtime] sa po restarte nuluje, preto sa uklada aj [bootCount].
 */
interface DeviceTime {
    /** Milisekundy od startu zariadenia vratane spanku. */
    fun elapsedRealtime(): Long

    /** Pocet startov zariadenia, -1 ak nie je k dispozicii. */
    fun bootCount(): Int

    /** Nastenny cas (len pre UsageStatsManager, nikdy pre odomknutia). */
    fun currentTimeMillis(): Long
}

class SystemDeviceTime(context: Context) : DeviceTime {
    private val resolver = context.applicationContext.contentResolver

    override fun elapsedRealtime(): Long = SystemClock.elapsedRealtime()

    override fun bootCount(): Int =
        Settings.Global.getInt(resolver, Settings.Global.BOOT_COUNT, -1)

    override fun currentTimeMillis(): Long = System.currentTimeMillis()
}
