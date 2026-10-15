-- Eskulapp: sesje demo w TEST02 (Kongres Diabetologii Klinicznej 2026).
-- Wymaga migracji 2026_10_sessions.sql. Idempotentne: mozna puszczac wielokrotnie.
-- Celowo sesja I (Sala Bursztynowa 09:20-10:40) nachodzi na wyklad 10:30 w Sali Morskiej,
-- zeby pokazac ostrzezenie o konflikcie czasowym w apce.
SET NAMES utf8mb4;

SET @f  = (SELECT id FROM events WHERE access_code = 'TEST02');
SET @g1 = (SELECT id FROM event_days WHERE event_id=@f AND sort=0);
SET @g2 = (SELECT id FROM event_days WHERE event_id=@f AND sort=1);
SET @s1 = (SELECT id FROM rooms WHERE event_id=@f AND sort=0);

-- sprzatanie poprzedniego przebiegu
DELETE FROM sessions WHERE event_id=@f;
DELETE FROM talks WHERE event_id=@f AND title IN ('AID w praktyce klinicznej','Stopa cukrzycowa: nowe standardy');

INSERT INTO sessions (event_id,day_id,room_id,title,description,starts_at,ends_at,sort) VALUES
 (@f,@g1,@s1,'Sesja I: Nowe technologie w cukrzycy typu 1','Od CGM do systemów automatycznego podawania insuliny.','2026-10-20 09:20:00','2026-10-20 10:40:00',0),
 (@f,@g2,@s1,'Sesja II: Powikłania cukrzycy','Profilaktyka i leczenie powikłań przewlekłych.','2026-10-21 09:30:00','2026-10-21 11:00:00',1);
SET @x1 = (SELECT id FROM sessions WHERE event_id=@f AND sort=0);
SET @x2 = (SELECT id FROM sessions WHERE event_id=@f AND sort=1);

INSERT INTO session_moderators (session_id,speaker_id,sort)
SELECT @x1, id, 0 FROM speakers WHERE event_id=@f AND last_name='Kamińska';
INSERT INTO session_moderators (session_id,speaker_id,sort)
SELECT @x2, id, sort FROM speakers WHERE event_id=@f AND last_name IN ('Nowicka','Jaworski');

INSERT INTO talks (event_id,day_id,room_id,session_id,title,abstract,starts_at,ends_at,sort) VALUES
 (@f,@g1,@s1,@x1,'AID w praktyce klinicznej','Kwalifikacja pacjentów, start terapii i najczęstsze problemy.','2026-10-20 10:10:00','2026-10-20 10:40:00',3),
 (@f,@g2,@s1,@x2,'Stopa cukrzycowa: nowe standardy','Aktualne zalecenia i ścieżka pacjenta.','2026-10-21 10:20:00','2026-10-21 11:00:00',2);

UPDATE talks SET session_id=@x1 WHERE event_id=@f AND title='Technologie w leczeniu cukrzycy typu 1';
UPDATE talks SET session_id=@x2 WHERE event_id=@f AND title='Powikłania cukrzycy - profilaktyka';

INSERT INTO talk_speakers (talk_id,speaker_id)
SELECT t.id, s.id FROM talks t JOIN speakers s ON s.event_id=@f AND t.event_id=@f
WHERE (t.title='AID w praktyce klinicznej' AND s.last_name='Nowicka')
   OR (t.title='Stopa cukrzycowa: nowe standardy' AND s.last_name='Kamińska');

UPDATE events SET updated_at=NOW() WHERE id=@f;
