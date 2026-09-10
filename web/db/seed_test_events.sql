-- Eskulapp - dwa dodatkowe wydarzenia testowe do listy eventow w apce:
--   KARD26 - wydarzenie w PRZESZLOSCI (archiwalne, wyszarzone na dole listy)
--   DIAB26 - wydarzenie ZA ~2 MIESIACE (aktywne, u gory listy)
-- Idempotentne po kodzie. Uzycie: mysql ... < seed_test_events.sql
SET NAMES utf8mb4;

-- =====================================================================
-- 1) WYDARZENIE PRZESZLE (archiwalne): Sympozjum Kardiologiczne 2026
-- =====================================================================
DELETE FROM events WHERE access_code = 'KARD26';

INSERT INTO events (slug,name,access_code,is_closed,starts_at,ends_at,venue_name,city,push_topic,status)
VALUES ('symp-kard-2026','Sympozjum Kardiologiczne 2026','KARD26',1,
        '2026-05-16 09:00:00','2026-05-17 15:00:00','ICE Kraków','Kraków','event_kard26','archived');
SET @e = LAST_INSERT_ID();

INSERT INTO event_days (event_id,date,label,sort) VALUES
 (@e,'2026-05-16','Dzień 1',0),
 (@e,'2026-05-17','Dzień 2',1);
SET @d1 = (SELECT id FROM event_days WHERE event_id=@e AND sort=0);
SET @d2 = (SELECT id FROM event_days WHERE event_id=@e AND sort=1);

INSERT INTO rooms (event_id,name,sort) VALUES (@e,'Sala Wisła',0),(@e,'Sala Wawel',1);
SET @r1 = (SELECT id FROM rooms WHERE event_id=@e AND sort=0);
SET @r2 = (SELECT id FROM rooms WHERE event_id=@e AND sort=1);

INSERT INTO speakers (event_id,first_name,last_name,title,bio,sort) VALUES
 (@e,'Andrzej','Lewandowski','prof. dr hab., Klinika Kardiologii UJ CM','Specjalista kardiolog, autor ponad 120 publikacji z zakresu niewydolności serca.',0),
 (@e,'Katarzyna','Zielińska','dr n. med., Szpital Uniwersytecki w Krakowie','Kardiolog interwencyjny, koordynatorka programu leczenia zawału serca.',1),
 (@e,'Marek','Woźniak','dr hab., prof. GUMed','Elektrofizjolog, ekspert w dziedzinie zaburzeń rytmu serca.',2);

INSERT INTO talks (event_id,day_id,room_id,title,abstract,starts_at,ends_at,sort) VALUES
 (@e,@d1,@r1,'Otwarcie sympozjum','Powitanie uczestników i wprowadzenie do programu.','2026-05-16 09:00:00','2026-05-16 09:15:00',0),
 (@e,@d1,@r1,'Nowoczesne leczenie niewydolności serca','Przegląd aktualnych wytycznych ESC i praktyka kliniczna.','2026-05-16 09:15:00','2026-05-16 10:00:00',1),
 (@e,@d1,@r2,'Kardiologia interwencyjna w ostrym zawale','Ścieżka pacjenta z zawałem STEMI, standardy postępowania.','2026-05-16 10:15:00','2026-05-16 11:00:00',2),
 (@e,@d2,@r1,'Zaburzenia rytmu serca u dorosłych','Diagnostyka i terapia arytmii, ablacja.','2026-05-17 09:30:00','2026-05-17 10:15:00',0),
 (@e,@d2,@r1,'Podsumowanie i wnioski','Dyskusja panelowa i zakończenie sympozjum.','2026-05-17 14:00:00','2026-05-17 15:00:00',1);

INSERT INTO talk_speakers (talk_id,speaker_id)
SELECT t.id, s.id FROM talks t JOIN speakers s ON s.event_id=@e AND t.event_id=@e
WHERE (t.title='Otwarcie sympozjum' AND s.last_name='Lewandowski')
   OR (t.title='Nowoczesne leczenie niewydolności serca' AND s.last_name='Lewandowski')
   OR (t.title='Kardiologia interwencyjna w ostrym zawale' AND s.last_name='Zielińska')
   OR (t.title='Zaburzenia rytmu serca u dorosłych' AND s.last_name='Woźniak')
   OR (t.title='Podsumowanie i wnioski' AND s.last_name IN ('Lewandowski','Woźniak'));

INSERT INTO partners (event_id,name,description,tier,booth_location,website,sort) VALUES
 (@e,'CardioTech Polska','Aparatura kardiologiczna i monitoring','strategiczny','Stoisko K1','cardiotech.pl',0),
 (@e,'PharmaSerce','Leki kardiologiczne','partner','Stoisko K2','pharmaserce.pl',1),
 (@e,'EKG Systems','Holtery i systemy EKG','partner','Stoisko K3','ekgsystems.pl',2),
 (@e,'StentMed','Stenty i cewniki','strategiczny','Stoisko K4','stentmed.pl',3),
 (@e,'RytmControl','Kardiowertery i rozruszniki','partner','Stoisko K5','rytmcontrol.pl',4),
 (@e,'VascularCare','Diagnostyka naczyniowa','wspierajacy','Stoisko K6','vascularcare.pl',5),
 (@e,'EchoDiag','Echokardiografia','partner','Stoisko K7','echodiag.pl',6),
 (@e,'LipidLab','Diagnostyka lipidowa','wspierajacy','Stoisko K8','lipidlab.pl',7),
 (@e,'HeartEdu','Edukacja pacjenta kardiologicznego','wspierajacy','Stoisko K9','heartedu.pl',8),
 (@e,'TeleKardio','Telemonitoring serca','strategiczny','Stoisko K10','telekardio.pl',9);

INSERT INTO contacts (event_id,label,name,phone,email,note,sort) VALUES
 (@e,'Biuro organizacyjne','Polskie Towarzystwo Kardiologiczne','+48 12 555 20 30','biuro@kard2026.pl','pon-pt 9-16',0);

INSERT INTO news (event_id,type,title,body,pinned,published_at) VALUES
 (@e,'ogloszenie','Materiały po sympozjum','Prezentacje z sesji są dostępne w biurze organizacyjnym.',0,'2026-05-17 16:00:00');

-- =====================================================================
-- 2) WYDARZENIE ZA ~2 MIESIACE (aktywne): Kongres Diabetologii Klinicznej 2026
-- =====================================================================
DELETE FROM events WHERE access_code = 'DIAB26';

INSERT INTO events (slug,name,access_code,is_closed,starts_at,ends_at,venue_name,city,push_topic,status)
VALUES ('kongres-diab-2026','Kongres Diabetologii Klinicznej 2026','DIAB26',1,
        '2026-10-20 09:00:00','2026-10-21 16:00:00','AmberExpo','Gdańsk','event_diab26','published');
SET @f = LAST_INSERT_ID();

INSERT INTO event_days (event_id,date,label,sort) VALUES
 (@f,'2026-10-20','Dzień 1',0),
 (@f,'2026-10-21','Dzień 2',1);
SET @g1 = (SELECT id FROM event_days WHERE event_id=@f AND sort=0);
SET @g2 = (SELECT id FROM event_days WHERE event_id=@f AND sort=1);

INSERT INTO rooms (event_id,name,sort) VALUES (@f,'Sala Bursztynowa',0),(@f,'Sala Morska',1);
SET @s1 = (SELECT id FROM rooms WHERE event_id=@f AND sort=0);
SET @s2 = (SELECT id FROM rooms WHERE event_id=@f AND sort=1);

INSERT INTO speakers (event_id,first_name,last_name,title,bio,sort) VALUES
 (@f,'Ewa','Kamińska','prof. dr hab., Katedra Diabetologii GUMed','Diabetolog, kierownik kliniki, ekspert leczenia cukrzycy typu 1.',0),
 (@f,'Tomasz','Jaworski','dr n. med., Uniwersyteckie Centrum Kliniczne','Specjalista chorób wewnętrznych i diabetologii.',1),
 (@f,'Magdalena','Nowicka','dr hab., prof. WUM','Endokrynolog, badaczka technologii CGM i pomp insulinowych.',2);

INSERT INTO talks (event_id,day_id,room_id,title,abstract,starts_at,ends_at,sort) VALUES
 (@f,@g1,@s1,'Inauguracja kongresu','Otwarcie i przywitanie gości.','2026-10-20 09:00:00','2026-10-20 09:20:00',0),
 (@f,@g1,@s1,'Technologie w leczeniu cukrzycy typu 1','Systemy CGM, pompy insulinowe i pętla zamknięta.','2026-10-20 09:20:00','2026-10-20 10:10:00',1),
 (@f,@g1,@s2,'Cukrzyca typu 2 - nowe leki','Flozyny, analogi GLP-1 i strategia terapii.','2026-10-20 10:30:00','2026-10-20 11:20:00',2),
 (@f,@g2,@s1,'Powikłania cukrzycy - profilaktyka','Nefropatia, retinopatia, stopa cukrzycowa.','2026-10-21 09:30:00','2026-10-21 10:20:00',0),
 (@f,@g2,@s1,'Panel ekspertów i zakończenie','Dyskusja i podsumowanie kongresu.','2026-10-21 14:30:00','2026-10-21 16:00:00',1);

INSERT INTO talk_speakers (talk_id,speaker_id)
SELECT t.id, s.id FROM talks t JOIN speakers s ON s.event_id=@f AND t.event_id=@f
WHERE (t.title='Inauguracja kongresu' AND s.last_name='Kamińska')
   OR (t.title='Technologie w leczeniu cukrzycy typu 1' AND s.last_name='Nowicka')
   OR (t.title='Cukrzyca typu 2 - nowe leki' AND s.last_name='Jaworski')
   OR (t.title='Powikłania cukrzycy - profilaktyka' AND s.last_name IN ('Jaworski','Kamińska'))
   OR (t.title='Panel ekspertów i zakończenie' AND s.last_name IN ('Kamińska','Jaworski','Nowicka'));

INSERT INTO partners (event_id,name,description,tier,booth_location,website,sort) VALUES
 (@f,'DiabCare Systems','Systemy ciągłego monitorowania glikemii','strategiczny','Stoisko D1','diabcare.pl',0),
 (@f,'InsulinaPlus','Pompy insulinowe i akcesoria','partner','Stoisko D2','insulinaplus.pl',1),
 (@f,'MediEdu','Platforma edukacyjna dla pacjentów','wspierajacy','Stoisko D3','mediedu.pl',2),
 (@f,'GlukoTest','Glukometry i paski testowe','partner','Stoisko D4','glukotest.pl',3),
 (@f,'PharmaDiab','Leki przeciwcukrzycowe','strategiczny','Stoisko D5','pharmadiab.pl',4),
 (@f,'SensorMed','Sensory glikemii','partner','Stoisko D6','sensormed.pl',5),
 (@f,'NutriCare','Zywienie w cukrzycy','wspierajacy','Stoisko D7','nutricare.pl',6),
 (@f,'FootCare Clinic','Profilaktyka stopy cukrzycowej','wspierajacy','Stoisko D8','footcare.pl',7),
 (@f,'TeleDiab','Telemedycyna diabetologiczna','partner','Stoisko D9','telediab.pl',8),
 (@f,'VisionLab','Diagnostyka retinopatii','strategiczny','Stoisko D10','visionlab.pl',9);

INSERT INTO contacts (event_id,label,name,phone,email,note,sort) VALUES
 (@f,'Biuro kongresu','Polskie Towarzystwo Diabetologiczne','+48 58 300 12 00','biuro@diab2026.pl','pon-pt 8-16',0);

INSERT INTO news (event_id,type,title,body,pinned,published_at) VALUES
 (@f,'ogloszenie','Rejestracja otwarta','Zapraszamy do rejestracji online. Liczba miejsc ograniczona.',1,'2026-08-18 10:00:00');
