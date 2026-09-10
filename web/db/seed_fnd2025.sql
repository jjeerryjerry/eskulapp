-- Eskulapp - przykladowy event FND2025 z realnym programem 7. Forum Nowoczesnej
-- Diabetologii (29-30.11.2024, zrodlo: nowoczesnadiabetologia.pl/program_7fnd).
-- Idempotentne po kodzie FND2025.
SET NAMES utf8mb4;

DELETE FROM events WHERE access_code = 'FND2025';

INSERT INTO events (slug,name,access_code,is_closed,starts_at,ends_at,venue_name,city,push_topic,status)
VALUES ('fnd-2025','7. Forum Nowoczesnej Diabetologii','FND2025',1,
        '2024-11-29 16:00:00','2024-11-30 15:00:00','Centrum Kongresowe','Poznań','event_fnd2025','published');
SET @e = LAST_INSERT_ID();

INSERT INTO event_days (event_id,date,label,sort) VALUES
 (@e,'2024-11-29','Piątek',0),
 (@e,'2024-11-30','Sobota',1);
SET @d1 = (SELECT id FROM event_days WHERE event_id=@e AND sort=0);
SET @d2 = (SELECT id FROM event_days WHERE event_id=@e AND sort=1);

INSERT INTO rooms (event_id,name,sort) VALUES (@e,'Sala główna',0);
SET @r = LAST_INSERT_ID();

-- prelegenci
INSERT INTO speakers (event_id,first_name,last_name,title,sort) VALUES
 (@e,'Dorota','Zozulińska-Ziółkiewicz','prof. dr hab.',0),
 (@e,'Christopher','Kosinski','dr',1),
 (@e,'Irina','Kowalska','prof. dr hab.',2),
 (@e,'Mariusz','Dąbrowski','dr hab., prof. UR',3),
 (@e,'Mateusz','Rudyk','',4),
 (@e,'Jacek','Juszczyk','prof. dr hab.',5),
 (@e,'Piotr','Voelkel','',6),
 (@e,'Tomasz','Klupa','prof. dr hab.',7),
 (@e,'Aleksandra','Araszkiewicz','prof. dr hab.',8);

-- prelekcje: dzien 1
INSERT INTO talks (event_id,day_id,room_id,title,starts_at,ends_at,sort) VALUES
 (@e,@d1,@r,'Otwarcie Forum','2024-11-29 16:00:00','2024-11-29 16:10:00',0),
 (@e,@d1,@r,'Diabetes care in Switzerland','2024-11-29 16:10:00','2024-11-29 16:40:00',1),
 (@e,@d1,@r,'Co nowego wniosła kanagliflozyna do leczenia pacjentów z cukrzycą typu 2?','2024-11-29 16:40:00','2024-11-29 17:00:00',2),
 (@e,@d1,@r,'Rewolucja insulinowa w Polsce Anno Domini 2024, fakty i mity [Sanofi]','2024-11-29 17:00:00','2024-11-29 17:20:00',3),
 (@e,@d1,@r,'Jazda na czas z Eversense [Ascensia]','2024-11-29 17:20:00','2024-11-29 17:40:00',4),
 (@e,@d1,@r,'Przerwa kawowa','2024-11-29 17:40:00','2024-11-29 18:00:00',5),
 (@e,@d1,@r,'Warsztaty (30 min każdy)','2024-11-29 18:00:00','2024-11-29 20:30:00',6),
 (@e,@d1,@r,'Zakończenie i poczęstunek','2024-11-29 20:30:00',NULL,7);

-- prelekcje: dzien 2
INSERT INTO talks (event_id,day_id,room_id,title,starts_at,ends_at,sort) VALUES
 (@e,@d2,@r,'Walne Zebranie Sekcji Diabetologii Społecznej i Edukacji','2024-11-30 07:50:00','2024-11-30 08:50:00',0),
 (@e,@d2,@r,'Przerwa','2024-11-30 08:50:00','2024-11-30 09:00:00',1),
 (@e,@d2,@r,'Wprowadzenie','2024-11-30 09:00:00','2024-11-30 09:05:00',2),
 (@e,@d2,@r,'Medycyna w pryzmatach malarstwa','2024-11-30 09:05:00','2024-11-30 09:20:00',3),
 (@e,@d2,@r,'Dlaczego czasem potrzebna jest radykalna zmiana?','2024-11-30 09:20:00','2024-11-30 09:45:00',4),
 (@e,@d2,@r,'Panel dyskusyjny: System. Zmiana. Pacjent','2024-11-30 09:45:00','2024-11-30 10:15:00',5),
 (@e,@d2,@r,'Mniej jeść i więcej się ruszać','2024-11-30 10:15:00','2024-11-30 10:35:00',6),
 (@e,@d2,@r,'Czas na działanie [Boehringer Ingelheim]','2024-11-30 10:35:00','2024-11-30 10:55:00',7),
 (@e,@d2,@r,'Przerwa kawowa','2024-11-30 10:55:00','2024-11-30 11:15:00',8),
 (@e,@d2,@r,'Warsztaty i Akademia CGM (30 min każdy)','2024-11-30 11:15:00','2024-11-30 13:45:00',9),
 (@e,@d2,@r,'Zakończenie i poczęstunek','2024-11-30 13:45:00',NULL,10),
 (@e,@d2,@r,'Debata Konsultantów Wojewódzkich','2024-11-30 14:30:00',NULL,11);

-- powiazania prelekcja <-> prelegent (po tytule i nazwisku)
INSERT INTO talk_speakers (talk_id,speaker_id)
SELECT t.id, s.id FROM talks t JOIN speakers s ON s.event_id=@e AND t.event_id=@e
WHERE (t.title='Otwarcie Forum' AND s.last_name='Zozulińska-Ziółkiewicz')
   OR (t.title='Diabetes care in Switzerland' AND s.last_name='Kosinski')
   OR (t.title LIKE 'Co nowego wniosła kanagliflozyna%' AND s.last_name='Kowalska')
   OR (t.title LIKE 'Rewolucja insulinowa%' AND s.last_name='Dąbrowski')
   OR (t.title LIKE 'Jazda na czas%' AND s.last_name IN ('Zozulińska-Ziółkiewicz','Rudyk'))
   OR (t.title='Wprowadzenie' AND s.last_name='Zozulińska-Ziółkiewicz')
   OR (t.title='Medycyna w pryzmatach malarstwa' AND s.last_name='Juszczyk')
   OR (t.title='Dlaczego czasem potrzebna jest radykalna zmiana?' AND s.last_name='Voelkel')
   OR (t.title='Mniej jeść i więcej się ruszać' AND s.last_name='Klupa')
   OR (t.title LIKE 'Czas na działanie%' AND s.last_name='Araszkiewicz');

-- partnerzy (stoiska G1..G10)
INSERT INTO partners (event_id,name,description,tier,booth_location,website,sort) VALUES
 (@e,'Ascensia Diabetes Care','Systemy CGM Eversense','strategiczny','Stoisko G1','ascensia.pl',0),
 (@e,'Sanofi','Insuliny i terapie','strategiczny','Stoisko G2','sanofi.pl',1),
 (@e,'Boehringer Ingelheim','Leki przeciwcukrzycowe','strategiczny','Stoisko G3','boehringer.pl',2),
 (@e,'Roche Diabetes','Glukometry Accu-Chek','partner','Stoisko G4','roche.pl',3),
 (@e,'Medtronic','Pompy insulinowe','partner','Stoisko G5','medtronic.pl',4),
 (@e,'Abbott','System FreeStyle Libre','strategiczny','Stoisko G6','abbott.pl',5),
 (@e,'Bioton','Insuliny krajowe','partner','Stoisko G7','bioton.pl',6),
 (@e,'Polfa','Leki generyczne','wspierajacy','Stoisko G8','polfa.pl',7),
 (@e,'DiabetesPL','Portal edukacyjny','wspierajacy','Stoisko G9','diabetes.pl',8),
 (@e,'NutriMed','Dietetyka kliniczna','wspierajacy','Stoisko G10','nutrimed.pl',9);

-- kontakt organizacyjny
INSERT INTO contacts (event_id,label,name,phone,email,sort) VALUES
 (@e,'Biuro organizacyjne','Grupa casusBTL','+48 662 021 182','krzysztof.chodan@casusbtl.pl',0);
