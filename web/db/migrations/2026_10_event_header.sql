-- Migracja 2026-10: opcjonalna grafika naglowka eventu (NOTATKA-AGENCJA-2026-10-14).
-- NULL = apka pokazuje domyslny naglowek. Idempotentna (MySQL 8 i MariaDB 10.x).

SET NAMES utf8mb4;

SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS
           WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'events' AND COLUMN_NAME = 'header_image_url');
SET @q := IF(@c = 0, 'ALTER TABLE events ADD COLUMN header_image_url VARCHAR(255) NULL AFTER map_enabled', 'DO 0');
PREPARE st FROM @q; EXECUTE st; DEALLOCATE PREPARE st;
