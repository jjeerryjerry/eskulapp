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

    fun schedule(ctx: Context, talkId: Long, title: String, subtitle: String?, triggerAt: Long) =
        enqueue(ctx, "reminder_$talkId", triggerAt, workDataOf("title" to title, "subtitle" to (subtitle ?: "")))

    /** Przypomnienie o calej sesji (niezalezne od przypomnien o jej podwykladach). */
    fun scheduleSession(ctx: Context, sessionId: Long, title: String, subtitle: String?, triggerAt: Long) =
        enqueue(ctx, "session_$sessionId", triggerAt, workDataOf(
            "title" to title, "headline" to "Za 10 minut sesja: $title", "subtitle" to (subtitle ?: "")))

    fun cancelSession(ctx: Context, sessionId: Long) {
        WorkManager.getInstance(ctx).cancelUniqueWork("session_$sessionId")
    }

    private fun enqueue(ctx: Context, name: String, triggerAt: Long, data: Data) {
        val delay = triggerAt - System.currentTimeMillis()
        if (delay <= 0) return // pozycja juz minela: zapamietujemy stan, ale nie budzimy
        val req = OneTimeWorkRequestBuilder<ReminderWorker>()
            .setInitialDelay(delay, TimeUnit.MILLISECONDS)
            .setInputData(data)
            .addTag("reminder")
            .build()
        WorkManager.getInstance(ctx).enqueueUniqueWork(name, ExistingWorkPolicy.REPLACE, req)
    }

    /** Przypomnienie "Oceń wykład" w chwili otwarcia okna ocen (SPEC-OCENY §5, opcja). */
    fun scheduleRate(ctx: Context, talkId: Long, title: String, triggerAt: Long) {
        val delay = triggerAt - System.currentTimeMillis()
        if (delay <= 0) return
        val req = OneTimeWorkRequestBuilder<ReminderWorker>()
            .setInitialDelay(delay, TimeUnit.MILLISECONDS)
            .setInputData(workDataOf("title" to title, "headline" to "Oceń wykład: $title",
                "subtitle" to "Ocenianie jest już otwarte. Odpowiedz na 3 krótkie pytania."))
            .addTag("reminder")
            .build()
        WorkManager.getInstance(ctx).enqueueUniqueWork("rate_$talkId", ExistingWorkPolicy.REPLACE, req)
    }

    fun cancel(ctx: Context, talkId: Long) {
        WorkManager.getInstance(ctx).cancelUniqueWork("reminder_$talkId")
        WorkManager.getInstance(ctx).cancelUniqueWork("rate_$talkId")
    }
}
