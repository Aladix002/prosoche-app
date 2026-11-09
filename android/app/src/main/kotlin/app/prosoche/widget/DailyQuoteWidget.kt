package app.prosoche.widget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.util.SizeF
import android.view.View
import android.widget.RemoteViews
import app.prosoche.MainActivity
import app.prosoche.R
import java.io.File
import java.time.LocalDate
import org.json.JSONArray
import org.json.JSONObject

/**
 * W-01: widget na ploche s citatom dna.
 *
 * Dart (`lib/features/home_widget/`) vyberie citat dna deterministicky
 * podla datumu z content.db a posle ho cez kanal `app.prosoche/widget`
 * na [DAYS_AHEAD] dni dopredu. Widget si pri kazdom prekresleni vyberie
 * zaznam pre dnesny lokalny datum, takze po polnoci (updatePeriodMillis,
 * zmena casu/zony) ukaze novy citat bez spustenia Fluttera. Ziadne
 * povolenia, ziadne alarmy.
 */
class DailyQuoteWidget : AppWidgetProvider() {

    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        render(context, manager, ids)
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        manager: AppWidgetManager,
        id: Int,
        newOptions: Bundle,
    ) {
        render(context, manager, intArrayOf(id))
    }

    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            Intent.ACTION_TIME_CHANGED, Intent.ACTION_TIMEZONE_CHANGED -> updateAll(context)
            else -> super.onReceive(context, intent)
        }
    }

    /** Velkost widgetu. */
    enum class Size { SMALL, LARGE, LARGE_TALL }

    companion object {
        /** Kolko dni dopredu posiela Dart (len informacne, rozhoduje Dart). */
        const val DAYS_AHEAD = 45

        /** Od tejto sirky (dp) je widget "velky" (4x2). */
        private const val LARGE_MIN_WIDTH_DP = 260f

        /** Od tejto vysky (dp) sa zmesti aj riadok "Translated by". */
        private const val TALL_MIN_HEIGHT_DP = 150f

        private const val FILE = "widget/daily_quote.json"

        /** Prekresli vsetky instancie widgetu. */
        fun updateAll(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(ComponentName(context, DailyQuoteWidget::class.java))
            if (ids.isNotEmpty()) render(context, manager, ids)
        }

        /**
         * Ulozi data z Dartu. Ak uz widget ma citat pre dnesok, ostane
         * (citat dna sa nemeni ani po aktualizacii obsahu pocas dna).
         */
        fun save(context: Context, json: String) {
            val incoming = JSONObject(json)
            val today = LocalDate.now().toString()
            val old = load(context)?.let { entryFor(it, today) }
            if (old != null && old.optString("date") == today) {
                val days = incoming.optJSONArray("days") ?: JSONArray()
                for (i in 0 until days.length()) {
                    if (days.getJSONObject(i).optString("date") == today) {
                        days.put(i, old)
                    }
                }
            }
            val file = File(context.noBackupFilesDir, FILE)
            file.parentFile?.mkdirs()
            val tmp = File(file.parentFile, "${file.name}.tmp")
            tmp.writeText(incoming.toString())
            if (!tmp.renameTo(file)) {
                file.writeText(incoming.toString())
                tmp.delete()
            }
        }

        private fun load(context: Context): JSONObject? = try {
            val file = File(context.noBackupFilesDir, FILE)
            if (file.exists()) JSONObject(file.readText()) else null
        } catch (e: Exception) {
            null
        }

        /**
         * Zaznam pre [today]; ked chyba (appka dlho nebezala), striedaju sa
         * ulozene zaznamy podla datumu, aby bol citat stale rovnaky cely den.
         */
        internal fun entryFor(data: JSONObject, today: String): JSONObject? {
            val days = data.optJSONArray("days") ?: return null
            if (days.length() == 0) return null
            for (i in 0 until days.length()) {
                val d = days.optJSONObject(i) ?: continue
                if (d.optString("date") == today) return d
            }
            val epochDay = LocalDate.parse(today).toEpochDay()
            return days.optJSONObject(Math.floorMod(epochDay, days.length().toLong()).toInt())
        }

        private fun render(context: Context, manager: AppWidgetManager, ids: IntArray) {
            val data = load(context)
            val entry = data?.let { entryFor(it, LocalDate.now().toString()) }
            val labels = data?.optJSONObject("labels")
            for (id in ids) {
                val views = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    RemoteViews(
                        mapOf(
                            SizeF(100f, 100f) to build(context, id, entry, labels, Size.SMALL),
                            SizeF(LARGE_MIN_WIDTH_DP, 100f) to
                                build(context, id, entry, labels, Size.LARGE),
                            SizeF(LARGE_MIN_WIDTH_DP, TALL_MIN_HEIGHT_DP) to
                                build(context, id, entry, labels, Size.LARGE_TALL),
                        ),
                    )
                } else {
                    build(context, id, entry, labels, legacySize(manager.getAppWidgetOptions(id)))
                }
                manager.updateAppWidget(id, views)
            }
        }

        /** Pred Androidom 12: velkost z options (portret = min. sirka, max. vyska). */
        private fun legacySize(options: Bundle): Size {
            val w = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH).toFloat()
            val h = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT).toFloat()
            return when {
                w < LARGE_MIN_WIDTH_DP -> Size.SMALL
                h >= TALL_MIN_HEIGHT_DP -> Size.LARGE_TALL
                else -> Size.LARGE
            }
        }

        private fun build(
            context: Context,
            widgetId: Int,
            entry: JSONObject?,
            labels: JSONObject?,
            size: Size,
        ): RemoteViews {
            val small = size == Size.SMALL
            val views = RemoteViews(
                context.packageName,
                if (small) R.layout.widget_quote_small else R.layout.widget_quote_large,
            )
            val link = entry?.optString("link")?.takeIf { it.startsWith("prosoche://") }
                ?: "prosoche://today"
            views.setOnClickPendingIntent(android.R.id.background, openIntent(context, widgetId, link))

            if (entry == null) {
                views.setTextViewText(R.id.widget_text, context.getString(R.string.widget_quote_empty))
                views.setViewVisibility(R.id.widget_reference, View.GONE)
                if (!small) {
                    views.setViewVisibility(R.id.widget_translator, View.GONE)
                    views.setViewVisibility(R.id.widget_read, View.GONE)
                    views.setTextViewText(R.id.widget_eyebrow, context.getString(R.string.app_name))
                }
                return views
            }

            val text = entry.optString("text")
            // Cely citat (Dart vybera len kratke, do 140 znakov); autosize
            // ho zmesti aj do 2x2, nikdy sa nekrati uprostred vety.
            views.setTextViewText(R.id.widget_text, text)
            val reference = entry.optString("reference")
            val author = entry.optString("author")
            val refLine = when {
                small -> reference
                author.isNotEmpty() && reference.isNotEmpty() -> "$reference · $author"
                else -> reference.ifEmpty { author }
            }
            views.setTextViewText(R.id.widget_reference, refLine)
            views.setViewVisibility(R.id.widget_reference, View.VISIBLE)
            val description = listOf(text, reference, author).filter { it.isNotEmpty() }
                .joinToString(", ")
            views.setContentDescription(android.R.id.background, description)

            if (!small) {
                labels?.optString("eyebrow")?.takeIf { it.isNotEmpty() }?.let {
                    views.setTextViewText(R.id.widget_eyebrow, it.uppercase())
                }
                val translator = entry.optString("translatedBy")
                    .takeIf { !entry.isNull("translatedBy") && it.isNotEmpty() }
                val showTranslator = size == Size.LARGE_TALL && translator != null
                views.setTextViewText(R.id.widget_translator, translator ?: "")
                views.setViewVisibility(
                    R.id.widget_translator,
                    if (showTranslator) View.VISIBLE else View.GONE,
                )
                val read = labels?.optString("readInContext").orEmpty()
                views.setTextViewText(R.id.widget_read, read)
                views.setViewVisibility(
                    R.id.widget_read,
                    if (size == Size.LARGE_TALL && read.isNotEmpty()) View.VISIBLE else View.GONE,
                )
            }
            return views
        }

        private fun openIntent(context: Context, widgetId: Int, link: String): PendingIntent {
            val intent = Intent(Intent.ACTION_VIEW, Uri.parse(link))
                .setClass(context, MainActivity::class.java)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
            return PendingIntent.getActivity(
                context,
                widgetId,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
        }
    }
}
