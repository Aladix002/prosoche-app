package app.mursa.blocker

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.Handler
import android.os.HandlerThread
import android.os.IBinder
import android.os.PowerManager
import android.util.Log
import app.mursa.R

/**
 * Foreground service `specialUse` (TECHNICKY_PLAN 9.1, docs/08 A, B): drzi
 * [ForegroundAppMonitor] a spusta branu cez [GateLauncher].
 *
 * Spusta sa len z popredia (Flutter `setEnabled`) alebo z [BootReceiver],
 * nikdy z pozadia cez SAW vynimku. Nie `dataSync` (limit 6 h, zakaz z boot).
 */
class BlockerService : Service() {
    private lateinit var thread: HandlerThread
    private lateinit var monitor: ForegroundAppMonitor
    private lateinit var handler: Handler

    private val screenReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            when (intent.action) {
                Intent.ACTION_SCREEN_OFF -> handler.post { monitor.onScreenOff() }
                Intent.ACTION_SCREEN_ON -> handler.post { monitor.onScreenOn() }
            }
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        startInForeground()
        val prefs = BlockerPrefs(this)
        val unlocks = UnlockStore(this)
        unlocks.purgeExpired()
        val launcher = GateLauncher(this)
        thread = HandlerThread("MursaBlockerMonitor").apply { start() }
        handler = Handler(thread.looper)
        val debugLog = debugLogger(this)
        monitor = ForegroundAppMonitor(
            events = UsageStatsEventSource(this, debugLog),
            decider = GateDecider(packageName),
            snapshot = { BlockerSnapshot(prefs.enabled, prefs.blockedRefs(), unlocks::isUnlocked) },
            showGate = { ref -> launcher.launch(ref) },
            wallClock = System::currentTimeMillis,
            scheduler = HandlerTickScheduler(handler),
            onError = { e -> Log.w(GateLauncher.TAG, "monitor tick failed: ${e.javaClass.simpleName}") },
            debugLog = debugLog,
        )
        val filter = IntentFilter().apply {
            addAction(Intent.ACTION_SCREEN_OFF)
            addAction(Intent.ACTION_SCREEN_ON)
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(screenReceiver, filter, RECEIVER_NOT_EXPORTED)
        } else {
            registerReceiver(screenReceiver, filter)
        }
        val interactive = getSystemService(PowerManager::class.java)?.isInteractive ?: true
        handler.post { monitor.start(interactive) }
        isRunning = true
        // Predhriaty engine brany (ADR-16): brana sa potom ukaze bez
        // studeneho startu Flutteru.
        (application as? MursaFullApplication)?.warmGateEngine()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        // startForeground musi prist aj pri okamzitom stopSelf.
        startInForeground()
        if (!BlockerPrefs(this).enabled) {
            stopSelf()
            return START_NOT_STICKY
        }
        return START_STICKY
    }

    override fun onDestroy() {
        isRunning = false
        unregisterReceiver(screenReceiver)
        handler.post { monitor.stop() }
        thread.quitSafely()
        // Brana vypnuta: uvolnit pamat enginu brany.
        GateEngine.destroy()
        super.onDestroy()
    }

    private fun startInForeground() {
        val nm = getSystemService(NotificationManager::class.java)
        nm.createNotificationChannel(
            NotificationChannel(
                CHANNEL_ID,
                getString(R.string.blocker_channel_name),
                NotificationManager.IMPORTANCE_MIN,
            ).apply {
                setShowBadge(false)
                description = getString(R.string.blocker_channel_description)
            },
        )
        val open = packageManager.getLaunchIntentForPackage(packageName)?.let {
            PendingIntent.getActivity(this, 0, it, PendingIntent.FLAG_IMMUTABLE)
        }
        val notification = Notification.Builder(this, CHANNEL_ID)
            .setSmallIcon(applicationInfo.icon)
            .setContentTitle(getString(R.string.blocker_notification_title))
            .setContentText(getString(R.string.blocker_notification_text))
            .setOngoing(true)
            .setShowWhen(false)
            .setContentIntent(open)
            .build()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            startForeground(NOTIFICATION_ID, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE)
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }
    }

    companion object {
        /** Kanal trvalej tichej notifikacie (TECHNICKY_PLAN 9.1). */
        const val CHANNEL_ID = "gate_service"
        private const val NOTIFICATION_ID = 4101

        @Volatile
        var isRunning: Boolean = false
            private set

        /** Volat len z popredia alebo z BOOT_COMPLETED. */
        fun start(context: Context) {
            context.startForegroundService(Intent(context, BlockerService::class.java))
        }

        fun stop(context: Context) {
            context.stopService(Intent(context, BlockerService::class.java))
        }
    }
}
