package pl.eskulapp.mobile.ratings

import android.content.Context
import androidx.work.BackoffPolicy
import androidx.work.Constraints
import androidx.work.CoroutineWorker
import androidx.work.ExistingWorkPolicy
import androidx.work.NetworkType
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.WorkerParameters
import pl.eskulapp.mobile.data.ApiClient
import pl.eskulapp.mobile.data.Repo
import java.util.concurrent.TimeUnit
import kotlin.coroutines.cancellation.CancellationException

/**
 * Wysylka glosow offline-first: glos lezy w Room jako "pending", worker wysyla go od razu
 * albo po odzyskaniu sieci (constraint CONNECTED, backoff przy 429/5xx). Glos oddany offline
 * w oknie, ale doslany po zamknieciu okna, serwer odrzuci (409): zapisujemy "rejected"
 * z kodem bledu, a ekran prelekcji pokazuje "Nie udało się zapisać, okno oceniania zamknięte."
 */
class RatingSyncWorker(ctx: Context, params: WorkerParameters) : CoroutineWorker(ctx, params) {
    override suspend fun doWork(): Result {
        val dao = Repo.get(applicationContext).dao
        val installId = InstallId.get(applicationContext)
        var retry = false
        for (r in dao.pendingRatings()) {
            val res = try {
                ApiClient.postRating(r.eventCode, r.talkId, installId, r.score)
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                RatingResult.Retry
            }
            when (res) {
                // updatedAt w warunku: jesli user zmienil ocene w trakcie wysylki, nowa wersja
                // zostaje "pending" i poleci w kolejnym przebiegu (APPEND w enqueue).
                is RatingResult.Saved -> dao.setRatingStatus(r.talkId, r.updatedAt, RatingStatus.SYNCED, null)
                is RatingResult.Rejected -> dao.setRatingStatus(r.talkId, r.updatedAt, RatingStatus.REJECTED, res.error)
                RatingResult.Retry -> retry = true
            }
        }
        return if (retry) Result.retry() else Result.success()
    }

    companion object {
        private const val WORK = "ratings_sync"

        fun enqueue(context: Context) {
            val req = OneTimeWorkRequestBuilder<RatingSyncWorker>()
                .setConstraints(Constraints.Builder().setRequiredNetworkType(NetworkType.CONNECTED).build())
                .setBackoffCriteria(BackoffPolicy.EXPONENTIAL, 30, TimeUnit.SECONDS)
                .addTag("ratings")
                .build()
            WorkManager.getInstance(context)
                .enqueueUniqueWork(WORK, ExistingWorkPolicy.APPEND_OR_REPLACE, req)
        }
    }
}
