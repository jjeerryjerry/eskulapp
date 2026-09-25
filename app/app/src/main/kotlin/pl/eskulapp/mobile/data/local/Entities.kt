package pl.eskulapp.mobile.data.local

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "events")
data class EventEntity(
    @PrimaryKey val id: Long,
    val slug: String,
    val name: String,
    val accessCode: String,
    val isClosed: Boolean,
    val startsAt: String?,
    val endsAt: String?,
    val venueName: String?,
    val city: String?,
    val mapImageUrl: String?,
    val mapEmbed: String?,
    val mapEnabled: Boolean = true,
    val ratingsEnabled: Boolean = false,
    val ratingsOpenMin: Int = 10,
    val ratingsCloseMin: Int = 30,
    val pushTopic: String?,
    val status: String,
    val updatedAt: String?,
    val addedAt: Long,
)

@Entity(tableName = "days")
data class DayEntity(
    @PrimaryKey val id: Long,
    val eventId: Long,
    val date: String?,
    val label: String?,
    val sort: Int,
)

@Entity(tableName = "rooms")
data class RoomEntity(
    @PrimaryKey val id: Long,
    val eventId: Long,
    val name: String,
    val sort: Int,
)

@Entity(tableName = "talks")
data class TalkEntity(
    @PrimaryKey val id: Long,
    val eventId: Long,
    val dayId: Long?,
    val roomId: Long?,
    val title: String,
    val abstract: String?,
    val startsAt: String?,
    val endsAt: String?,
    val sort: Int,
)

@Entity(tableName = "speakers")
data class SpeakerEntity(
    @PrimaryKey val id: Long,
    val eventId: Long,
    val firstName: String,
    val lastName: String,
    val title: String?,
    val photoUrl: String?,
    val bio: String?,
    val sort: Int,
)

@Entity(tableName = "talk_speakers", primaryKeys = ["talkId", "speakerId"])
data class TalkSpeakerEntity(
    val talkId: Long,
    val speakerId: Long,
    val eventId: Long,
)

@Entity(tableName = "partners")
data class PartnerEntity(
    @PrimaryKey val id: Long,
    val eventId: Long,
    val name: String,
    val logoUrl: String?,
    val description: String?,
    val tier: String?,
    val boothLocation: String?,
    val website: String?,
    val sort: Int,
)

@Entity(tableName = "contacts")
data class ContactEntity(
    @PrimaryKey val id: Long,
    val eventId: Long,
    val label: String?,
    val name: String?,
    val phone: String?,
    val email: String?,
    val note: String?,
    val sort: Int,
)

@Entity(tableName = "news")
data class NewsEntity(
    @PrimaryKey val id: Long,
    val eventId: Long,
    val type: String,
    val title: String,
    val body: String?,
    val linkType: String?,
    val linkRef: String?,
    val pinned: Int,
    val publishedAt: String?,
)

@Entity(tableName = "reminders")
data class ReminderEntity(
    @PrimaryKey val talkId: Long,
    val eventId: Long,
    val title: String,
    val subtitle: String?,
    val triggerAt: Long,
)

@Entity(tableName = "event_notify")
data class EventNotifyEntity(
    @PrimaryKey val eventId: Long,
)

@Entity(tableName = "news_read")
data class NewsReadEntity(
    @PrimaryKey val newsId: Long,
    val eventId: Long,
)

/**
 * Lokalny glos na prelekcje (offline-first, SPEC-OCENY §5). Jeden na prelekcje.
 * status: pending | synced | rejected (RatingStatus); error = kod z serwera przy rejected.
 * updatedAt = lokalna wersja glosu (do bezpiecznej zmiany statusu po wysylce), NIE jest
 * wysylany: serwer liczy okno wylacznie wedlug wlasnego zegara.
 */
@Entity(tableName = "talk_ratings")
data class TalkRatingEntity(
    @PrimaryKey val talkId: Long,
    val eventId: Long,
    val eventCode: String,
    val score: Int,
    val status: String,
    val error: String?,
    val updatedAt: Long,
)
