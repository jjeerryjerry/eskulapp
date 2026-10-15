package pl.eskulapp.mobile.data.local

import android.content.Context
import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase
import androidx.room.migration.Migration
import androidx.sqlite.db.SupportSQLiteDatabase

@Database(
    entities = [
        EventEntity::class, DayEntity::class, RoomEntity::class, TalkEntity::class,
        SpeakerEntity::class, TalkSpeakerEntity::class, PartnerEntity::class,
        ContactEntity::class, NewsEntity::class, ReminderEntity::class,
        EventNotifyEntity::class, NewsReadEntity::class, TalkRatingEntity::class,
        SessionEntity::class, SessionModeratorEntity::class, SessionReminderEntity::class,
    ],
    version = 6,
    exportSchema = false,
)
abstract class AppDatabase : RoomDatabase() {
    abstract fun dao(): EskDao

    companion object {
        // v1 -> v2: subskrypcje powiadomien per-event (tabela event_notify)
        private val MIGRATION_1_2 = object : Migration(1, 2) {
            override fun migrate(db: SupportSQLiteDatabase) {
                db.execSQL(
                    "CREATE TABLE IF NOT EXISTS `event_notify` " +
                        "(`eventId` INTEGER NOT NULL, PRIMARY KEY(`eventId`))"
                )
            }
        }

        // v2 -> v3: przeczytane aktualnosci (tabela news_read)
        private val MIGRATION_2_3 = object : Migration(2, 3) {
            override fun migrate(db: SupportSQLiteDatabase) {
                db.execSQL(
                    "CREATE TABLE IF NOT EXISTS `news_read` " +
                        "(`newsId` INTEGER NOT NULL, `eventId` INTEGER NOT NULL, PRIMARY KEY(`newsId`))"
                )
            }
        }

        // v3 -> v4: flaga mapy per event (organizator moze wylaczyc Mape)
        private val MIGRATION_3_4 = object : Migration(3, 4) {
            override fun migrate(db: SupportSQLiteDatabase) {
                db.execSQL("ALTER TABLE `events` ADD COLUMN `mapEnabled` INTEGER NOT NULL DEFAULT 1")
            }
        }

        // v4 -> v5: oceny prelekcji (SPEC-OCENY): ustawienia ocen per event + lokalne glosy.
        // Istniejace eventy dostaja ratingsEnabled=0 do najblizszego odswiezenia bundla.
        private val MIGRATION_4_5 = object : Migration(4, 5) {
            override fun migrate(db: SupportSQLiteDatabase) {
                db.execSQL("ALTER TABLE `events` ADD COLUMN `ratingsEnabled` INTEGER NOT NULL DEFAULT 0")
                db.execSQL("ALTER TABLE `events` ADD COLUMN `ratingsOpenMin` INTEGER NOT NULL DEFAULT 10")
                db.execSQL("ALTER TABLE `events` ADD COLUMN `ratingsCloseMin` INTEGER NOT NULL DEFAULT 30")
                db.execSQL(
                    "CREATE TABLE IF NOT EXISTS `talk_ratings` (`talkId` INTEGER NOT NULL, " +
                        "`eventId` INTEGER NOT NULL, `eventCode` TEXT NOT NULL, `score` INTEGER NOT NULL, " +
                        "`status` TEXT NOT NULL, `error` TEXT, `updatedAt` INTEGER NOT NULL, PRIMARY KEY(`talkId`))"
                )
            }
        }

        // v5 -> v6: sesje (blok z moderatorami i podwykladami) + przypomnienia o sesjach,
        // oceny 3 pytania (q1..q3 w talk_ratings; stare glosy maja sam score),
        // opcjonalna grafika naglowka eventu.
        private val MIGRATION_5_6 = object : Migration(5, 6) {
            override fun migrate(db: SupportSQLiteDatabase) {
                db.execSQL("ALTER TABLE `talks` ADD COLUMN `sessionId` INTEGER")
                db.execSQL("ALTER TABLE `events` ADD COLUMN `headerImageUrl` TEXT")
                db.execSQL("ALTER TABLE `talk_ratings` ADD COLUMN `q1` INTEGER")
                db.execSQL("ALTER TABLE `talk_ratings` ADD COLUMN `q2` INTEGER")
                db.execSQL("ALTER TABLE `talk_ratings` ADD COLUMN `q3` INTEGER")
                db.execSQL(
                    "CREATE TABLE IF NOT EXISTS `sessions` (`id` INTEGER NOT NULL, `eventId` INTEGER NOT NULL, " +
                        "`dayId` INTEGER, `roomId` INTEGER, `title` TEXT NOT NULL, `description` TEXT, " +
                        "`startsAt` TEXT, `endsAt` TEXT, `sort` INTEGER NOT NULL, PRIMARY KEY(`id`))"
                )
                db.execSQL(
                    "CREATE TABLE IF NOT EXISTS `session_moderators` (`sessionId` INTEGER NOT NULL, " +
                        "`speakerId` INTEGER NOT NULL, `eventId` INTEGER NOT NULL, `sort` INTEGER NOT NULL, " +
                        "PRIMARY KEY(`sessionId`, `speakerId`))"
                )
                db.execSQL(
                    "CREATE TABLE IF NOT EXISTS `session_reminders` (`sessionId` INTEGER NOT NULL, " +
                        "`eventId` INTEGER NOT NULL, `title` TEXT NOT NULL, `subtitle` TEXT, " +
                        "`triggerAt` INTEGER NOT NULL, PRIMARY KEY(`sessionId`))"
                )
            }
        }

        @Volatile private var INSTANCE: AppDatabase? = null
        fun get(context: Context): AppDatabase =
            INSTANCE ?: synchronized(this) {
                INSTANCE ?: Room.databaseBuilder(
                    context.applicationContext, AppDatabase::class.java, "eskulapp.db"
                )
                    // PRAWDZIWE migracje: aktualizacja apki NIE kasuje lokalnych danych
                    // (dodane eventy, dzwonki/powiadomienia, przeczytane aktualnosci).
                    .addMigrations(MIGRATION_1_2, MIGRATION_2_3, MIGRATION_3_4, MIGRATION_4_5, MIGRATION_5_6)
                    .build().also { INSTANCE = it }
            }
    }
}
