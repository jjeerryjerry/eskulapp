-- Migracja 2026-09: oceny prelekcji 1-10 (anonimowe), docs/SPEC-OCENY.md §3.
-- Idempotentna: mozna puscic wielokrotnie (MySQL 8 i MariaDB 10.x).
-- Import:  mysql -u <user> -p <db> < web/db/migrations/2026_09_ratings.sql
-- Przed importem na produkcji: backup bazy (docs/SPEC-OCENY.md §9).

SET NAMES utf8mb4;

-- ── events: przelacznik ocen + okno (minuty) per event ───────────────────
-- ADD COLUMN IF NOT EXISTS jest tylko w MariaDB, wiec warunek przez
-- information_schema + PREPARE (dziala tak samo w MySQL i MariaDB).
SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS
           WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'events' AND COLUMN_NAME = 'ratings_enabled');
SET @q := IF(@c = 0, 'ALTER TABLE events ADD COLUMN ratings_enabled TINYINT NOT NULL DEFAULT 1', 'DO 0');
PREPARE st FROM @q; EXECUTE st; DEALLOCATE PREPARE st;

SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS
           WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'events' AND COLUMN_NAME = 'ratings_open_after_start_min');
SET @q := IF(@c = 0, 'ALTER TABLE events ADD COLUMN ratings_open_after_start_min INT NOT NULL DEFAULT 10', 'DO 0');
PREPARE st FROM @q; EXECUTE st; DEALLOCATE PREPARE st;

SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS
           WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'events' AND COLUMN_NAME = 'ratings_close_after_end_min');
SET @q := IF(@c = 0, 'ALTER TABLE events ADD COLUMN ratings_close_after_end_min INT NOT NULL DEFAULT 30', 'DO 0');
PREPARE st FROM @q; EXECUTE st; DEALLOCATE PREPARE st;

-- ── Oceny: jeden glos na urzadzenie na prelekcje (upsert po uq_talk_voter) ──
-- voter_hash = sha256(install_id + RATING_SALT); surowego install_id NIE zapisujemy.
CREATE TABLE IF NOT EXISTS talk_ratings (
  id          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  event_id    BIGINT UNSIGNED NOT NULL,
  talk_id     BIGINT UNSIGNED NOT NULL,
  voter_hash  CHAR(64) NOT NULL,
  score       TINYINT UNSIGNED NOT NULL,          -- 1..10, CHECK w PHP
  created_at  DATETIME NOT NULL,
  updated_at  DATETIME NOT NULL,
  ip_hash     CHAR(64) NULL,                      -- do rate-limitu/analizy naduzyc, nie surowe IP
  PRIMARY KEY (id),
  UNIQUE KEY uq_talk_voter (talk_id, voter_hash),
  KEY idx_ratings_event (event_id),
  CONSTRAINT fk_tr_event FOREIGN KEY (event_id) REFERENCES events(id) ON DELETE CASCADE,
  CONSTRAINT fk_tr_talk  FOREIGN KEY (talk_id)  REFERENCES talks(id)  ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ── Rate-limit publicznego API ocen (okno przesuwne, czas UTC) ──────────
-- scope: 'ip' (key_hash = ip_hash) albo 'voter' (key_hash = voter_hash).
-- Stare wpisy (> 1 doba) sprzata samo API.
CREATE TABLE IF NOT EXISTS rating_rate_hits (
  id          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  scope       VARCHAR(16) NOT NULL,
  key_hash    CHAR(64) NOT NULL,
  created_at  DATETIME NOT NULL,
  PRIMARY KEY (id),
  KEY idx_rrh_key_time (scope, key_hash, created_at),
  KEY idx_rrh_time (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
