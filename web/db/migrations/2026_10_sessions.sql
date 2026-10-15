-- Migracja 2026-10: sesje (blok tematyczny z moderatorami i podwykladami).
-- docs/NOTATKA-AGENCJA-2026-10-14.md. Idempotentna (MySQL 8 i MariaDB 10.x).
-- Import:  mysql -u <user> -p <db> < web/db/migrations/2026_10_sessions.sql

SET NAMES utf8mb4;

CREATE TABLE IF NOT EXISTS sessions (
  id          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  event_id    BIGINT UNSIGNED NOT NULL,
  day_id      BIGINT UNSIGNED NULL,
  room_id     BIGINT UNSIGNED NULL,
  title       VARCHAR(255) NOT NULL,
  description TEXT NULL,
  starts_at   DATETIME NULL,
  ends_at     DATETIME NULL,
  sort        INT NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  KEY idx_sessions_event (event_id),
  CONSTRAINT fk_sessions_event FOREIGN KEY (event_id) REFERENCES events(id) ON DELETE CASCADE,
  CONSTRAINT fk_sessions_day  FOREIGN KEY (day_id)  REFERENCES event_days(id) ON DELETE SET NULL,
  CONSTRAINT fk_sessions_room FOREIGN KEY (room_id) REFERENCES rooms(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Moderatorzy sesji (zwykle 1 do 3 osob) to prelegenci tego samego eventu.
CREATE TABLE IF NOT EXISTS session_moderators (
  session_id BIGINT UNSIGNED NOT NULL,
  speaker_id BIGINT UNSIGNED NOT NULL,
  sort       INT NOT NULL DEFAULT 0,
  PRIMARY KEY (session_id, speaker_id),
  CONSTRAINT fk_sm_session FOREIGN KEY (session_id) REFERENCES sessions(id) ON DELETE CASCADE,
  CONSTRAINT fk_sm_speaker FOREIGN KEY (speaker_id) REFERENCES speakers(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- talks.session_id: NULL = wyklad samodzielny (jak dotad).
SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS
           WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'talks' AND COLUMN_NAME = 'session_id');
SET @q := IF(@c = 0, 'ALTER TABLE talks ADD COLUMN session_id BIGINT UNSIGNED NULL AFTER room_id, ADD KEY idx_talks_session (session_id), ADD CONSTRAINT fk_talks_session FOREIGN KEY (session_id) REFERENCES sessions(id) ON DELETE SET NULL', 'DO 0');
PREPARE st FROM @q; EXECUTE st; DEALLOCATE PREPARE st;
