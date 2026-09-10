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
        EventNotifyEntity::class, NewsReadEntity::class,
    ],
    version = 3,
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

        @Volatile private var INSTANCE: AppDatabase? = null
        fun get(context: Context): AppDatabase =
            INSTANCE ?: synchronized(this) {
                INSTANCE ?: Room.databaseBuilder(
                    context.applicationContext, AppDatabase::class.java, "eskulapp.db"
                )
                    // PRAWDZIWE migracje: aktualizacja apki NIE kasuje lokalnych danych
                    // (dodane eventy, dzwonki/powiadomienia, przeczytane aktualnosci).
                    .addMigrations(MIGRATION_1_2, MIGRATION_2_3)
                    .build().also { INSTANCE = it }
            }
    }
}
