-- Eskulapp - 10 partnerow na KAZDE wydarzenie testowe, z przypisanym stoiskiem.
-- Idempotentne: czysci partnerow danego eventu i wstawia 10 od nowa.
-- Uzycie: mysql ... < seed_partners.sql
SET NAMES utf8mb4;

-- ============ FND2027 (nefrologia dziecieca), stoiska A1..A10 ============
SET @e = (SELECT id FROM events WHERE access_code='FND2027');
DELETE FROM partners WHERE event_id=@e;
INSERT INTO partners (event_id,name,description,tier,booth_location,website,sort) VALUES
 (@e,'NefroMed Polska','Dializa i terapie nerkozastepcze','strategiczny','Stoisko A1','nefromed.pl',0),
 (@e,'MedTech Sp. z o.o.','Aparatura USG i diagnostyka','partner','Stoisko A2','medtech.pl',1),
 (@e,'RenalCare','Systemy dializy otrzewnowej','strategiczny','Stoisko A3','renalcare.pl',2),
 (@e,'PediaLab','Diagnostyka laboratoryjna dzieci','partner','Stoisko A4','pedialab.pl',3),
 (@e,'UroSystems','Urzadzenia urologiczne','partner','Stoisko A5','urosystems.pl',4),
 (@e,'BioFiltr','Filtry i dreny medyczne','wspierajacy','Stoisko A6','biofiltr.pl',5),
 (@e,'VitaPharma','Leki nefrologiczne','strategiczny','Stoisko A7','vitapharma.pl',6),
 (@e,'Diagnostyka Plus','Testy moczu i krwi','partner','Stoisko A8','diagnostykaplus.pl',7),
 (@e,'KidneyTech','Monitoring nerek','wspierajacy','Stoisko A9','kidneytech.pl',8),
 (@e,'EduMed','Materialy edukacyjne dla rodzicow','wspierajacy','Stoisko A10','edumed.pl',9);

-- ============ DIAB26 (diabetologia), stoiska D1..D10 ============
SET @e = (SELECT id FROM events WHERE access_code='DIAB26');
DELETE FROM partners WHERE event_id=@e;
INSERT INTO partners (event_id,name,description,tier,booth_location,website,sort) VALUES
 (@e,'DiabCare Systems','Systemy ciaglego monitorowania glikemii','strategiczny','Stoisko D1','diabcare.pl',0),
 (@e,'InsulinaPlus','Pompy insulinowe i akcesoria','partner','Stoisko D2','insulinaplus.pl',1),
 (@e,'MediEdu','Platforma edukacyjna dla pacjentow','wspierajacy','Stoisko D3','mediedu.pl',2),
 (@e,'GlukoTest','Glukometry i paski testowe','partner','Stoisko D4','glukotest.pl',3),
 (@e,'PharmaDiab','Leki przeciwcukrzycowe','strategiczny','Stoisko D5','pharmadiab.pl',4),
 (@e,'SensorMed','Sensory glikemii','partner','Stoisko D6','sensormed.pl',5),
 (@e,'NutriCare','Zywienie w cukrzycy','wspierajacy','Stoisko D7','nutricare.pl',6),
 (@e,'FootCare Clinic','Profilaktyka stopy cukrzycowej','wspierajacy','Stoisko D8','footcare.pl',7),
 (@e,'TeleDiab','Telemedycyna diabetologiczna','partner','Stoisko D9','telediab.pl',8),
 (@e,'VisionLab','Diagnostyka retinopatii','strategiczny','Stoisko D10','visionlab.pl',9);

-- ============ KARD26 (kardiologia), stoiska K1..K10 ============
SET @e = (SELECT id FROM events WHERE access_code='KARD26');
DELETE FROM partners WHERE event_id=@e;
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

-- ============ FND2025 (Forum Nowoczesnej Diabetologii), stoiska G1..G10 ============
SET @e = (SELECT id FROM events WHERE access_code='FND2025');
DELETE FROM partners WHERE event_id=@e;
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
