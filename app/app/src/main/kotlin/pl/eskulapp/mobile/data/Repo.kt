package pl.eskulapp.mobile.data

import android.content.Context
import androidx.room.withTransaction
import pl.eskulapp.mobile.data.local.*
import pl.eskulapp.mobile.data.model.BundleDto
import pl.eskulapp.mobile.ratings.InstallId
import pl.eskulapp.mobile.ratings.RatingStatus
import pl.eskulapp.mobile.ratings.RatingSyncWorker

class Repo(context: Context) {
    private val db = AppDatabase.get(context)
    private val appContext = context.applicationContext
    val dao = db.dao()

    // Wersja bundla per kod (z manifestu CDN), zeby nie pobierac gdy bez zmian.
    private val prefs = appContext.getSharedPreferences("eskulapp_cdn", Context.MODE_PRIVATE)
    private fun storedVersion(code: String): String? = prefs.getString("ver_${code.uppercase()}", null)
    private fun setVersion(code: String, v: String) = prefs.edit().putString("ver_${code.uppercase()}", v).apply()

    /** Dolaczenie kodem: CDN (manifest -> bundel), fallback na PHP; NotFound z PHP idzie do UI. */
    suspend fun addOrRefresh(code: String): EventEntity {
        val c = code.trim().uppercase()
        val b = fetchSmart(c)
        saveBundle(b)
        return dao.eventByCode(b.event.accessCode) ?: error("brak eventu po zapisie")
    }

    /** Odswiezenie: pobiera bundel tylko gdy wersja w manifescie sie zmienila. */
    suspend fun refresh(code: String): Boolean = try {
        val c = code.trim().uppercase()
        try {
            val m = ApiClient.fetchManifest(c)
            val exists = dao.eventByCode(c) != null
            if (exists && storedVersion(c) == m.version) {
                true // aktualne, nic nie pobieramy
            } else {
                saveBundle(ApiClient.fetchBundleAt(m.bundlePath)); setVersion(c, m.version); true
            }
        } catch (cdn: Exception) {
            saveBundle(ApiClient.fetchBundle(c)); true // fallback na PHP
        }
    } catch (e: Exception) { false }

    /** Odswiezenie wszystkich dodanych eventow (np. przy starcie apki). Bledy ignorowane. */
    suspend fun refreshAll() {
        for (c in dao.allCodes()) { runCatching { refresh(c) } }
    }

    /** CDN najpierw (manifest + wersjonowany bundel), a gdy niedostepny to PHP. */
    private suspend fun fetchSmart(code: String): BundleDto = try {
        val m = ApiClient.fetchManifest(code)
        val b = ApiClient.fetchBundleAt(m.bundlePath)
        setVersion(code, m.version)
        b
    } catch (cdn: Exception) {
        ApiClient.fetchBundle(code)
    }

    private suspend fun saveBundle(b: BundleDto) {
        val e = b.event.id
        db.withTransaction {
            // Zachowaj lokalny addedAt (kolejnosc listy) przy odswiezaniu z serwera.
            val existingAddedAt = dao.eventByCode(b.event.accessCode)?.addedAt
            dao.putEvent(
                EventEntity(
                    id = b.event.id, slug = b.event.slug, name = b.event.name,
                    accessCode = b.event.accessCode, isClosed = b.event.isClosed,
                    startsAt = b.event.startsAt, endsAt = b.event.endsAt,
                    venueName = b.event.venueName, city = b.event.city,
                    mapImageUrl = b.event.mapImageUrl, mapEmbed = b.event.mapEmbed,
                    mapEnabled = b.event.mapEnabled,
                    ratingsEnabled = b.event.ratingsEnabled,
                    ratingsOpenMin = b.event.ratingsOpenAfterStartMin,
                    ratingsCloseMin = b.event.ratingsCloseAfterEndMin,
                    pushTopic = b.event.pushTopic, status = b.event.status,
                    updatedAt = b.event.updatedAt,
                    addedAt = existingAddedAt ?: System.currentTimeMillis(),
                )
            )
            dao.clearDays(e); dao.clearRooms(e); dao.clearTalks(e); dao.clearSpeakers(e)
            dao.clearTalkSpeakers(e); dao.clearPartners(e); dao.clearContacts(e); dao.clearNews(e)

            dao.putDays(b.days.map { DayEntity(it.id, e, it.date, it.label, it.sort) })
            dao.putRooms(b.rooms.map { RoomEntity(it.id, e, it.name, it.sort) })
            dao.putTalks(b.talks.map { TalkEntity(it.id, e, it.dayId, it.roomId, it.title, it.abstract, it.startsAt, it.endsAt, it.sort) })
            dao.putSpeakers(b.speakers.map { SpeakerEntity(it.id, e, it.firstName, it.lastName, it.title, it.photoUrl, it.bio, it.sort) })
            dao.putTalkSpeakers(b.talkSpeakers.map { TalkSpeakerEntity(it.talkId, it.speakerId, e) })
            dao.putPartners(b.partners.map { PartnerEntity(it.id, e, it.name, it.logoUrl, it.description, it.tier, it.boothLocation, it.website, it.sort) })
            dao.putContacts(b.contacts.map { ContactEntity(it.id, e, it.label, it.name, it.phone, it.email, it.note, it.sort) })
            dao.putNews(b.news.map { NewsEntity(it.id, e, it.type, it.title, it.body, it.linkType, it.linkRef, it.pinned, it.publishedAt) })
        }
    }

    suspend fun deleteEvent(id: Long) = db.dao().deleteEvent(id)

    // ---- Oceny prelekcji (SPEC-OCENY §5): najpierw lokalnie, wysylka przez WorkManager ----

    /** Zapisuje glos lokalnie jako "pending" i zleca wysylke (od razu albo po odzyskaniu sieci). */
    suspend fun rate(eventId: Long, eventCode: String, talkId: Long, score: Int) {
        val prev = dao.ratingOnce(talkId)
        // wersja musi sie zmienic przy kazdej zmianie oceny (setRatingStatus porownuje updatedAt)
        val version = maxOf(System.currentTimeMillis(), (prev?.updatedAt ?: 0L) + 1)
        dao.putRating(TalkRatingEntity(talkId, eventId, eventCode.uppercase(), score, RatingStatus.PENDING, null, version))
        RatingSyncWorker.enqueue(appContext)
    }

    /** Dosyla zalegle glosy (np. po restarcie apki). */
    suspend fun syncPendingRatings() {
        if (dao.pendingRatings().isNotEmpty()) RatingSyncWorker.enqueue(appContext)
    }

    /**
     * Odtwarza oceny tego urzadzenia z serwera (GET .../ratings/mine), np. po ponownym
     * dodaniu eventu. Glosow "pending" nie nadpisujemy: poleca na serwer i tak.
     */
    suspend fun restoreMyRatings(eventId: Long, code: String) {
        val mine = ApiClient.fetchMyRatings(code, InstallId.get(appContext))
        db.withTransaction {
            for (m in mine) {
                val local = dao.ratingOnce(m.talkId)
                if (local != null && local.status == RatingStatus.PENDING) continue
                if (local != null && local.status == RatingStatus.SYNCED && local.score == m.score) continue
                dao.putRating(
                    TalkRatingEntity(m.talkId, eventId, code.uppercase(), m.score, RatingStatus.SYNCED, null, System.currentTimeMillis())
                )
            }
        }
    }

    companion object {
        @Volatile private var I: Repo? = null
        fun get(context: Context): Repo = I ?: synchronized(this) { I ?: Repo(context).also { I = it } }
    }
}
