package pl.eskulapp.mobile.data.local

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import kotlinx.coroutines.flow.Flow

@Dao
interface EskDao {
    // events
    @Query("SELECT * FROM events ORDER BY (status='archived') ASC, COALESCE(startsAt, addedAt) DESC")
    fun events(): Flow<List<EventEntity>>

    @Query("SELECT * FROM events WHERE id = :id LIMIT 1")
    fun event(id: Long): Flow<EventEntity?>

    @Query("SELECT * FROM events WHERE accessCode = :code LIMIT 1")
    suspend fun eventByCode(code: String): EventEntity?

    @Query("SELECT COUNT(*) FROM events")
    suspend fun eventCount(): Int

    // per-event content (Flows)
    @Query("SELECT * FROM days WHERE eventId = :e ORDER BY sort, date")
    fun days(e: Long): Flow<List<DayEntity>>

    @Query("SELECT * FROM rooms WHERE eventId = :e ORDER BY sort, name")
    fun rooms(e: Long): Flow<List<RoomEntity>>

    @Query("SELECT * FROM talks WHERE eventId = :e ORDER BY startsAt, sort")
    fun talks(e: Long): Flow<List<TalkEntity>>

    @Query("SELECT * FROM talks WHERE id = :id LIMIT 1")
    fun talk(id: Long): Flow<TalkEntity?>

    @Query("SELECT * FROM speakers WHERE eventId = :e ORDER BY sort, lastName")
    fun speakers(e: Long): Flow<List<SpeakerEntity>>

    @Query("SELECT * FROM speakers WHERE id = :id LIMIT 1")
    fun speaker(id: Long): Flow<SpeakerEntity?>

    @Query("SELECT s.* FROM speakers s JOIN talk_speakers ts ON ts.speakerId = s.id WHERE ts.talkId = :talkId ORDER BY s.sort")
    fun speakersForTalk(talkId: Long): Flow<List<SpeakerEntity>>

    @Query("SELECT t.* FROM talks t JOIN talk_speakers ts ON ts.talkId = t.id WHERE ts.speakerId = :speakerId ORDER BY t.startsAt, t.sort")
    fun talksForSpeaker(speakerId: Long): Flow<List<TalkEntity>>

    @Query("SELECT * FROM talk_speakers WHERE eventId = :e")
    fun talkSpeakers(e: Long): Flow<List<TalkSpeakerEntity>>

    @Query("SELECT * FROM partners WHERE eventId = :e ORDER BY sort, name")
    fun partners(e: Long): Flow<List<PartnerEntity>>

    @Query("SELECT * FROM partners WHERE id = :id LIMIT 1")
    fun partner(id: Long): Flow<PartnerEntity?>

    @Query("SELECT * FROM contacts WHERE eventId = :e ORDER BY sort")
    fun contacts(e: Long): Flow<List<ContactEntity>>

    @Query("SELECT * FROM news WHERE eventId = :e ORDER BY pinned DESC, publishedAt DESC")
    fun news(e: Long): Flow<List<NewsEntity>>

    @Query("SELECT COUNT(*) FROM news WHERE eventId = :e")
    fun newsCount(e: Long): Flow<Int>

    // reminders
    @Query("SELECT * FROM reminders")
    fun reminders(): Flow<List<ReminderEntity>>

    @Query("SELECT talkId FROM reminders")
    fun reminderIds(): Flow<List<Long>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun addReminder(r: ReminderEntity)

    @Query("DELETE FROM reminders WHERE talkId = :talkId")
    suspend fun removeReminder(talkId: Long)

    // powiadomienia per-event (subskrypcja lokalna, przetrwa odswiezenie bundle)
    @Query("SELECT eventId FROM event_notify")
    fun notifyIds(): Flow<List<Long>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun addNotify(n: EventNotifyEntity)

    @Query("DELETE FROM event_notify WHERE eventId = :eventId")
    suspend fun removeNotify(eventId: Long)

    // przeczytane aktualnosci (stan lokalny, przetrwa odswiezenie bundle)
    @Query("SELECT newsId FROM news_read WHERE eventId = :e")
    fun readNewsIds(e: Long): Flow<List<Long>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun markNewsRead(x: List<NewsReadEntity>)

    // upserts
    @Insert(onConflict = OnConflictStrategy.REPLACE) suspend fun putEvent(e: EventEntity)
    @Insert(onConflict = OnConflictStrategy.REPLACE) suspend fun putDays(x: List<DayEntity>)
    @Insert(onConflict = OnConflictStrategy.REPLACE) suspend fun putRooms(x: List<RoomEntity>)
    @Insert(onConflict = OnConflictStrategy.REPLACE) suspend fun putTalks(x: List<TalkEntity>)
    @Insert(onConflict = OnConflictStrategy.REPLACE) suspend fun putSpeakers(x: List<SpeakerEntity>)
    @Insert(onConflict = OnConflictStrategy.REPLACE) suspend fun putTalkSpeakers(x: List<TalkSpeakerEntity>)
    @Insert(onConflict = OnConflictStrategy.REPLACE) suspend fun putPartners(x: List<PartnerEntity>)
    @Insert(onConflict = OnConflictStrategy.REPLACE) suspend fun putContacts(x: List<ContactEntity>)
    @Insert(onConflict = OnConflictStrategy.REPLACE) suspend fun putNews(x: List<NewsEntity>)

    @Query("DELETE FROM days WHERE eventId = :e") suspend fun clearDays(e: Long)
    @Query("DELETE FROM rooms WHERE eventId = :e") suspend fun clearRooms(e: Long)
    @Query("DELETE FROM talks WHERE eventId = :e") suspend fun clearTalks(e: Long)
    @Query("DELETE FROM speakers WHERE eventId = :e") suspend fun clearSpeakers(e: Long)
    @Query("DELETE FROM talk_speakers WHERE eventId = :e") suspend fun clearTalkSpeakers(e: Long)
    @Query("DELETE FROM partners WHERE eventId = :e") suspend fun clearPartners(e: Long)
    @Query("DELETE FROM contacts WHERE eventId = :e") suspend fun clearContacts(e: Long)
    @Query("DELETE FROM news WHERE eventId = :e") suspend fun clearNews(e: Long)
    @Query("DELETE FROM events WHERE id = :e") suspend fun deleteEvent(e: Long)
}
