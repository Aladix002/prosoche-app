package app.mursa.blocker

import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import java.io.ByteArrayOutputStream
import java.util.Locale

/**
 * Spustitelne appky cez `<queries>` s intentom MAIN/LAUNCHER, bez
 * QUERY_ALL_PACKAGES (TECHNICKY_PLAN 9.1, docs/08 A).
 */
class InstalledAppsProvider(context: Context) {
    private val context = context.applicationContext
    private val pm = this.context.packageManager

    fun launchableApps(): List<InstalledApp> {
        val launcher = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER)
        @Suppress("DEPRECATION")
        val activities = pm.queryIntentActivities(launcher, 0)
        return activities
            .map { it.activityInfo.applicationInfo }
            .filter { it.packageName != context.packageName }
            .distinctBy { it.packageName }
            .map { InstalledApp(ref = it.packageName, label = it.loadLabel(pm).toString()) }
            .sortedBy { it.label.lowercase(Locale.ROOT) }
    }

    /** PNG ikona [ref] v rozmere [sizePx], null ak appka nie je viditelna. */
    fun iconPng(ref: String, sizePx: Int = ICON_PX): ByteArray? {
        val drawable = try {
            pm.getApplicationIcon(ref)
        } catch (e: PackageManager.NameNotFoundException) {
            return null
        }
        val bitmap = Bitmap.createBitmap(sizePx, sizePx, Bitmap.Config.ARGB_8888)
        drawable.setBounds(0, 0, sizePx, sizePx)
        drawable.draw(Canvas(bitmap))
        return ByteArrayOutputStream().use { out ->
            bitmap.compress(Bitmap.CompressFormat.PNG, 100, out)
            bitmap.recycle()
            out.toByteArray()
        }
    }

    companion object {
        const val ICON_PX = 96
    }
}
