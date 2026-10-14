-- Migracja 2026-10: ocena wykladu = 3 pytania 1..10 (NOTATKA-AGENCJA-2026-10-14).
-- q1 wartosc merytoryczna, q2 przydatnosc w praktyce, q3 sposob przekazania.
-- score zostaje: ocena ogolna = zaokraglona srednia z q1..q3 (glosy starych wersji
-- apki maja tylko score, q1..q3 = NULL). Idempotentna (MySQL 8 i MariaDB 10.x).

SET NAMES utf8mb4;

SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS
           WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'talk_ratings' AND COLUMN_NAME = 'q1');
SET @q := IF(@c = 0, 'ALTER TABLE talk_ratings ADD COLUMN q1 TINYINT UNSIGNED NULL AFTER score, ADD COLUMN q2 TINYINT UNSIGNED NULL AFTER q1, ADD COLUMN q3 TINYINT UNSIGNED NULL AFTER q2', 'DO 0');
PREPARE st FROM @q; EXECUTE st; DEALLOCATE PREPARE st;
