package pl.eskulapp.mobile.reminders

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import androidx.work.*
import java.time.LocalDateTime
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import java.util.concurrent.TimeUnit

object Reminders {
    const val CHANNEL = "eskulapp_talks"
    private val FMT = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss")

    fun ensureChannel(ctx: Context) {
        val nm = ctx.getSystemService(NotificationManager::class.java)
        if (nm.getNotificationChannel(CHANNEL) == null) {
            nm.createNotificationChannel(
                NotificationChannel(CHANNEL, "Przypomnienia o prelekcjach", NotificationManager.IMPORTANCE_HIGH)
            )
        }
    }

    /** Zwraca planowany czas (ms) lub null gdy nie da sie sparsowac. */
    fun triggerAt(startsAt: String?): Long? {
        if (startsAt == null || startsAt.length < 19) return null
        return try {
            LocalDateTime.parse(startsAt, FMT).atZone(ZoneId.systemDefault()).toInstant().toEpochMilli() - 10 * 60_000L
        } catch (e: Exception) { null }
    }

    fun schedule(ctx: Context, talkId: Long, title: String, subtitle: String?, triggerAt: Long) {
        val delay = triggerAt - System.currentTimeMillis()
        if (delay <= 0) return // prelekcja juz minela: zapamietujemy stan, ale nie budzimy
        val req = OneTimeWorkRequestBuilder<ReminderWorker>()
            .setInitialDelay(delay, TimeUnit.MILLISECONDS)
            .setInputData(workDataOf("title" to title, "subtitle" to (subtitle ?: "")))
            .addTag("reminder")
            .build()
        WorkManager.getInstance(ctx).enqueueUniqueWork("reminder_$talkId", ExistingWorkPolicy.REPLACE, req)
    }

    fun cancel(ctx: Context, talkId: Long) {
        WorkManager.getInstance(ctx).cancelUniqueWork("reminder_$talkId")
    }
}
