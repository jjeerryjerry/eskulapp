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
    ],
    version = 5,
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

        @Volatile private var INSTANCE: AppDatabase? = null
        fun get(context: Context): AppDatabase =
            INSTANCE ?: synchronized(this) {
                INSTANCE ?: Room.databaseBuilder(
                    context.applicationContext, AppDatabase::class.java, "eskulapp.db"
                )
                    // PRAWDZIWE migracje: aktualizacja apki NIE kasuje lokalnych danych
                    // (dodane eventy, dzwonki/powiadomienia, przeczytane aktualnosci).
                    .addMigrations(MIGRATION_1_2, MIGRATION_2_3, MIGRATION_3_4, MIGRATION_4_5)
                    .build().also { INSTANCE = it }
            }
    }
}
