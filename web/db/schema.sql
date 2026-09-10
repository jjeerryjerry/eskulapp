-- Eskulapp — schemat MySQL (MVP)
-- Zgodny z docs/MODEL-DANYCH.md + decyzjami §0 (app bez logowania uczestnika).
-- Import:  mysql -u <user> -p <db> < web/db/schema.sql
-- Silnik InnoDB, utf8mb4. Migracje wersjonujemy w web/db/migrations/.

SET NAMES utf8mb4;
SET foreign_key_checks = 0;

-- ── Tożsamość: TYLKO organizatorzy (CMS) ────────────────────────────────
CREATE TABLE IF NOT EXISTS organizers (
  id            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  email         VARCHAR(190) NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  name          VARCHAR(190) NOT NULL,
  role          ENUM('admin','organizer') NOT NULL DEFAULT 'organizer',
  created_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_organizers_email (email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Refresh-tokeny organizatorów (JWT access krótki, refresh w bazie z rotacją)
CREATE TABLE IF NOT EXISTS organizer_tokens (
  id           BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  organizer_id BIGINT UNSIGNED NOT NULL,
  token_hash   CHAR(64) NOT NULL,                 -- sha256 refresh-tokenu
  user_agent   VARCHAR(255) NULL,
  created_at   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  expires_at   DATETIME NOT NULL,
  revoked_at   DATETIME NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_token_hash (token_hash),
  KEY idx_tok_org (organizer_id),
  CONSTRAINT fk_tok_org FOREIGN KEY (organizer_id) REFERENCES organizers(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Rate-limit logowania (proste okno per email+IP)
CREATE TABLE IF NOT EXISTS login_attempts (
  id          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  email       VARCHAR(190) NOT NULL,
  ip          VARCHAR(45) NOT NULL,
  ok          TINYINT(1) NOT NULL DEFAULT 0,
  created_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_la_email_time (email, created_at),
  KEY idx_la_ip_time (ip, created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ── Eventy (dostęp po kodzie, bez konta uczestnika) ─────────────────────
CREATE TABLE IF NOT EXISTS events (
  id          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  organizer_id BIGINT UNSIGNED NULL,
  slug        VARCHAR(120) NOT NULL,
  name        VARCHAR(190) NOT NULL,
  access_code VARCHAR(32) NOT NULL,               -- np. FND2027
  is_closed   TINYINT(1) NOT NULL DEFAULT 1,
  starts_at   DATETIME NULL,
  ends_at     DATETIME NULL,
  venue_name  VARCHAR(190) NULL,
  city        VARCHAR(120) NULL,
  map_image_url VARCHAR(255) NULL,
  map_embed   TEXT NULL,
  push_topic  VARCHAR(64) NULL,                    -- event_<id>
  status      ENUM('draft','published','archived') NOT NULL DEFAULT 'draft',
  created_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_events_slug (slug),
  UNIQUE KEY uq_events_code (access_code),
  KEY idx_events_org (organizer_id),
  CONSTRAINT fk_events_org FOREIGN KEY (organizer_id) REFERENCES organizers(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ── Treść eventu ─────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS event_days (
  id        BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  event_id  BIGINT UNSIGNED NOT NULL,
  date      DATE NOT NULL,
  label     VARCHAR(120) NULL,
  sort      INT NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  KEY idx_days_event (event_id),
  CONSTRAINT fk_days_event FOREIGN KEY (event_id) REFERENCES events(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS rooms (
  id        BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  event_id  BIGINT UNSIGNED NOT NULL,
  name      VARCHAR(120) NOT NULL,
  sort      INT NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  KEY idx_rooms_event (event_id),
  CONSTRAINT fk_rooms_event FOREIGN KEY (event_id) REFERENCES events(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS speakers (
  id         BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  event_id   BIGINT UNSIGNED NOT NULL,
  first_name VARCHAR(120) NOT NULL,
  last_name  VARCHAR(120) NOT NULL,
  title      VARCHAR(190) NULL,
  photo_url  VARCHAR(255) NULL,
  bio        TEXT NULL,
  sort       INT NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  KEY idx_speakers_event (event_id),
  CONSTRAINT fk_speakers_event FOREIGN KEY (event_id) REFERENCES events(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS talks (
  id        BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  event_id  BIGINT UNSIGNED NOT NULL,
  day_id    BIGINT UNSIGNED NULL,
  room_id   BIGINT UNSIGNED NULL,
  title     VARCHAR(255) NOT NULL,
  abstract  TEXT NULL,
  starts_at DATETIME NULL,
  ends_at   DATETIME NULL,
  sort      INT NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  KEY idx_talks_event (event_id),
  KEY idx_talks_day (day_id),
  KEY idx_talks_room (room_id),
  CONSTRAINT fk_talks_event FOREIGN KEY (event_id) REFERENCES events(id) ON DELETE CASCADE,
  CONSTRAINT fk_talks_day  FOREIGN KEY (day_id)  REFERENCES event_days(id) ON DELETE SET NULL,
  CONSTRAINT fk_talks_room FOREIGN KEY (room_id) REFERENCES rooms(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS talk_speakers (
  talk_id    BIGINT UNSIGNED NOT NULL,
  speaker_id BIGINT UNSIGNED NOT NULL,
  PRIMARY KEY (talk_id, speaker_id),
  KEY idx_ts_speaker (speaker_id),
  CONSTRAINT fk_ts_talk    FOREIGN KEY (talk_id)    REFERENCES talks(id) ON DELETE CASCADE,
  CONSTRAINT fk_ts_speaker FOREIGN KEY (speaker_id) REFERENCES speakers(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS partners (
  id            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  event_id      BIGINT UNSIGNED NOT NULL,
  name          VARCHAR(190) NOT NULL,
  logo_url      VARCHAR(255) NULL,
  description   TEXT NULL,
  tier          VARCHAR(60) NULL,                  -- strategiczny / partner / ...
  booth_location VARCHAR(60) NULL,                 -- Stoisko A3
  website       VARCHAR(255) NULL,
  sort          INT NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  KEY idx_partners_event (event_id),
  CONSTRAINT fk_partners_event FOREIGN KEY (event_id) REFERENCES events(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS contacts (
  id       BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  event_id BIGINT UNSIGNED NOT NULL,
  label    VARCHAR(120) NULL,
  name     VARCHAR(190) NULL,
  phone    VARCHAR(60) NULL,
  email    VARCHAR(190) NULL,
  note     VARCHAR(255) NULL,
  sort     INT NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  KEY idx_contacts_event (event_id),
  CONSTRAINT fk_contacts_event FOREIGN KEY (event_id) REFERENCES events(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ── Aktualności ──────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS news (
  id          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  event_id    BIGINT UNSIGNED NOT NULL,
  type        ENUM('prelegent','sala','ogloszenie','promocja') NOT NULL DEFAULT 'ogloszenie',
  title       VARCHAR(190) NOT NULL,
  body        TEXT NULL,
  link_type   ENUM('none','talk','partner','url') NULL DEFAULT 'none',
  link_ref    VARCHAR(255) NULL,
  pinned      TINYINT(1) NOT NULL DEFAULT 0,
  published_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  push_sent   TINYINT(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  KEY idx_news_event (event_id, published_at),
  CONSTRAINT fk_news_event FOREIGN KEY (event_id) REFERENCES events(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ── Powiadomienia push (harmonogram → cron → FCM) ───────────────────────
CREATE TABLE IF NOT EXISTS notifications (
  id           BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  event_id     BIGINT UNSIGNED NOT NULL,
  type         ENUM('promo','zmiana','info') NOT NULL DEFAULT 'info',
  title        VARCHAR(190) NOT NULL,
  body         TEXT NULL,
  link_type    ENUM('none','talk','partner','url') NULL DEFAULT 'none',
  link_ref     VARCHAR(255) NULL,
  audience     ENUM('all') NOT NULL DEFAULT 'all',
  scheduled_at DATETIME NOT NULL,
  sent_at      DATETIME NULL,
  status       ENUM('draft','scheduled','sent','canceled') NOT NULL DEFAULT 'draft',
  created_by   BIGINT UNSIGNED NULL,
  PRIMARY KEY (id),
  KEY idx_notif_event (event_id),
  KEY idx_notif_due (status, scheduled_at),
  CONSTRAINT fk_notif_event FOREIGN KEY (event_id) REFERENCES events(id) ON DELETE CASCADE,
  CONSTRAINT fk_notif_by FOREIGN KEY (created_by) REFERENCES organizers(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ── Leady z formularza „dla organizatora" na landingu ───────────────────
CREATE TABLE IF NOT EXISTS leads (
  id         BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  name       VARCHAR(190) NOT NULL,
  email      VARCHAR(190) NOT NULL,
  org        VARCHAR(190) NULL,
  message    TEXT NULL,
  event_hint VARCHAR(190) NULL,
  ip         VARCHAR(45) NULL,
  status     ENUM('new','handled') NOT NULL DEFAULT 'new',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_leads_status (status, created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

SET foreign_key_checks = 1;
