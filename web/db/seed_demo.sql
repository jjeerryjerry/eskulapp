-- Eskulapp - demo event FND2027 (zeby API /bundle mialo realne dane).
-- Idempotentne: czysci event o kodzie FND2027 i wstawia od nowa.
SET NAMES utf8mb4;

DELETE FROM events WHERE access_code = 'FND2027';

INSERT INTO events (slug, name, access_code, is_closed, starts_at, ends_at, venue_name, city, push_topic, status)
VALUES ('fnd-2027', 'Forum Nefrologii Dziecięcej 2027', 'FND2027', 1,
        '2026-08-20 09:00:00', '2026-08-21 16:00:00', 'Hala Expo', 'Warszawa', 'event_1', 'published');

SET @eid = LAST_INSERT_ID();

INSERT INTO event_days (event_id, date, label, sort) VALUES
 (@eid, '2026-08-20', 'Dzień 1', 0),
 (@eid, '2026-08-21', 'Dzień 2', 1);

INSERT INTO rooms (event_id, name, sort) VALUES
 (@eid, 'Sala A', 0), (@eid, 'Sala B', 1), (@eid, 'Sala C', 2);

INSERT INTO speakers (event_id, first_name, last_name, title, sort) VALUES
 (@eid, 'Anna', 'Kowalska', 'prof., Kier. Kliniki Nefrologii WUM', 0),
 (@eid, 'Jan', 'Nowak', 'prof., CZD Warszawa', 1),
 (@eid, 'Piotr', 'Wiśniewski', 'dr, USK Wrocław', 2);

INSERT INTO talks (event_id, day_id, room_id, title, starts_at, ends_at, sort)
SELECT @eid,
       (SELECT id FROM event_days WHERE event_id=@eid ORDER BY sort LIMIT 1),
       (SELECT id FROM rooms WHERE event_id=@eid ORDER BY sort LIMIT 1),
       'Sesja inauguracyjna', '2026-08-20 09:00:00', '2026-08-20 09:45:00', 0;
INSERT INTO talks (event_id, day_id, room_id, title, starts_at, ends_at, sort)
SELECT @eid,
       (SELECT id FROM event_days WHERE event_id=@eid ORDER BY sort LIMIT 1),
       (SELECT id FROM rooms WHERE event_id=@eid ORDER BY sort LIMIT 1),
       'Nowe wytyczne leczenia 2027', '2026-08-20 10:00:00', '2026-08-20 10:45:00', 1;
INSERT INTO talks (event_id, day_id, room_id, title, starts_at, ends_at, sort)
SELECT @eid,
       (SELECT id FROM event_days WHERE event_id=@eid ORDER BY sort LIMIT 1),
       (SELECT id FROM rooms WHERE event_id=@eid ORDER BY sort DESC LIMIT 1),
       'Warsztat USG nerek', '2026-08-20 11:00:00', '2026-08-20 12:30:00', 2;

-- powiazania prelekcja <-> prelegent (event testowy: przypisanie z puli prelegentow)
INSERT INTO talk_speakers (talk_id, speaker_id)
SELECT t.id, s.id FROM talks t JOIN speakers s ON s.event_id=@eid AND t.event_id=@eid
WHERE (t.title='Sesja inauguracyjna' AND s.last_name IN ('Kowalska','Nowak'))
   OR (t.title='Nowe wytyczne leczenia 2027' AND s.last_name='Kowalska')
   OR (t.title='Warsztat USG nerek' AND s.last_name='Wiśniewski');

INSERT INTO partners (event_id,name,description,tier,booth_location,website,sort) VALUES
 (@eid,'NefroMed Polska','Dializa i terapie nerkozastepcze','strategiczny','Stoisko A1','nefromed.pl',0),
 (@eid,'MedTech Sp. z o.o.','Aparatura USG i diagnostyka','partner','Stoisko A2','medtech.pl',1),
 (@eid,'RenalCare','Systemy dializy otrzewnowej','strategiczny','Stoisko A3','renalcare.pl',2),
 (@eid,'PediaLab','Diagnostyka laboratoryjna dzieci','partner','Stoisko A4','pedialab.pl',3),
 (@eid,'UroSystems','Urzadzenia urologiczne','partner','Stoisko A5','urosystems.pl',4),
 (@eid,'BioFiltr','Filtry i dreny medyczne','wspierajacy','Stoisko A6','biofiltr.pl',5),
 (@eid,'VitaPharma','Leki nefrologiczne','strategiczny','Stoisko A7','vitapharma.pl',6),
 (@eid,'Diagnostyka Plus','Testy moczu i krwi','partner','Stoisko A8','diagnostykaplus.pl',7),
 (@eid,'KidneyTech','Monitoring nerek','wspierajacy','Stoisko A9','kidneytech.pl',8),
 (@eid,'EduMed','Materialy edukacyjne dla rodzicow','wspierajacy','Stoisko A10','edumed.pl',9);

INSERT INTO contacts (event_id, label, name, phone, email, note, sort) VALUES
 (@eid, 'Biuro kongresu', 'Pol. Tow. Nefrologiczne', '+48 22 123 45 67', 'biuro@fnd2027.pl', 'pon-pt 9-17', 0);

INSERT INTO news (event_id, type, title, body, pinned, published_at) VALUES
 (@eid, 'sala', 'Zmiana sali: Wytyczne 2027', 'Prelekcja przeniesiona z Sali B do Sali A.', 1, '2026-08-20 09:40:00');
