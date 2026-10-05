# Eskulapp, publikacja w sklepach (Google Play + App Store)

_Stan: 2026-10-05. Wersja do wydania: Android 1.3.0 (versionCode 21), iOS 1.3.0 (build 17)._

Kody testowe (także dla recenzentów Google i Apple):

| Kod | Wydarzenie | Status w apce | Mapa | Oceny prelekcji |
|---|---|---|---|---|
| **TEST01** | Forum Nefrologii Dziecięcej 2027 (dane demo) | archiwalny (daty 20-21.08.2026) | włączona | okno standardowe (zamknięte) |
| **TEST02** | Kongres Diabetologii Klinicznej 2026 | nadchodzące (20-21.10.2026) | włączona | **bez limitu czasu** (demo dla klientów) |
| **TEST03** | Sympozjum Kardiologiczne 2026 | archiwalny | **wyłączona** (test ukrywania Mapy) | okno standardowe (zamknięte) |
| FND2025 | 7. Forum Nowoczesnej Diabetologii (realny program) | archiwalny | włączona | okno standardowe (zamknięte) |

Stare kody FND2027, DIAB26, KARD26 już nie działają (usunięte z bazy i z CDN).

---

## 1. Teksty Google Play (PL)

**Nazwa aplikacji** (30): `Eskulapp`

**Krótki opis** (80, jest 75):
```
Agenda, prelegenci, partnerzy i mapa konferencji medycznej. Działa offline.
```

**Pełny opis** (4000):
```
Eskulapp to aplikacja dla uczestników konferencji, kongresów i szkoleń medycznych. Program wydarzenia, prelegenci, partnerzy i plan stoisk są w jednym miejscu, także bez internetu.

Jak zacząć
Wpisz kod wydarzenia, który otrzymasz od organizatora. Aplikacja pobierze cały program na telefon. Nie zakładasz konta i nie podajesz żadnych danych.

Co znajdziesz w środku
• Agenda: program podzielony na dni, filtr sal, lista obserwowanych prelekcji i przypomnienie przed ich startem.
• Prelegenci: sylwetki, afiliacje i lista wystąpień każdej osoby.
• Partnerzy: wystawcy z opisem, stroną www i numerem stoiska.
• Mapa: plan strefy wystawców z zaznaczonymi stoiskami (gdy organizator udostępnia plan).
• Aktualności: zmiany sal, przesunięcia i ogłoszenia organizatora.
• Kontakt: telefon i e-mail do biura wydarzenia jednym dotknięciem.
• Oceny: anonimowa ocena prelekcji w skali od 1 do 10, gdy organizator ją włączy.

Działa offline
Po pobraniu programu korzystasz z aplikacji bez zasięgu: na sali wykładowej, w hali wystawienniczej, w podziemiach centrum kongresowego.

Wiele wydarzeń w jednym miejscu
Dodawaj kolejne wydarzenia kodami. Trwające i nadchodzące są na górze listy, zakończone zostają w archiwum.

Prywatność
Aplikacja nie wymaga konta, nie wyświetla reklam i nie śledzi użytkownika. Dane wydarzenia są zapisywane lokalnie na Twoim telefonie, a oceny prelekcji są anonimowe.

Jesteś organizatorem i chcesz mieć swoje wydarzenie w Eskulapp? Napisz: kontakt@eskulapp.pl
```

**Co nowego w 1.3.0** (500):
```
• Nowość: anonimowa ocena prelekcji w skali od 1 do 10.
• Przypomnienie o ocenie dla obserwowanych prelekcji.
• Moduł Mapa pojawia się tylko wtedy, gdy organizator udostępnia plan wydarzenia.
• Drobne poprawki wyglądu i tekstów.
```

**Kategoria:** Wydarzenia • **E-mail:** kontakt@eskulapp.pl • **WWW:** https://eskulapp.pl •
**Polityka prywatności:** https://eskulapp.pl/polityka-prywatnosci/

---

## 2. Teksty App Store (PL)

**Nazwa** (30): `Eskulapp`

**Podtytuł** (30, jest 28): `Twój przewodnik po kongresie`

**Tekst promocyjny** (170, jest 156, można zmieniać bez nowego buildu):
```
Program konferencji medycznej zawsze pod ręką. Wpisz kod od organizatora i miej agendę, prelegentów oraz stoiska partnerów w telefonie, także bez internetu.
```

**Opis** (4000): ten sam co pełny opis Google Play (wyżej).

**Słowa kluczowe** (100, jest 100, bez spacji):
```
konferencja,kongres,agenda,program,prelegenci,sympozjum,medycyna,lekarz,szkolenie,wydarzenie,stoisko
```

**Co nowego:** jak w Google Play (dla pierwszego wydania w App Store pole jest ukryte).

**URL wsparcia:** https://eskulapp.pl • **URL marketingowy:** https://eskulapp.pl •
**Polityka prywatności:** https://eskulapp.pl/polityka-prywatnosci/ •
**Copyright:** `2026 Jarosław Gilewicz`

**Kategoria główna:** Biznes • **dodatkowa:** Edukacja
(Świadomie NIE „Medycyna": Apple sprawdza tam aplikacje pod kątem funkcji zdrowotnych, a Eskulapp to przewodnik po wydarzeniu.)

**Uwagi dla recenzenta (App Review Information, Notes):**
```
Eskulapp is a companion app for attendees of medical conferences. No account or sign-in is required. Content is unlocked with an event code provided by the organizer.

Demo codes:
TEST01 (full demo event with agenda, speakers, partners, map, news)
TEST02 (upcoming event)
TEST03 (past event without a venue map)

Steps: open the app, type TEST01, tap "Pobierz wydarzenie". Local notifications are used only for talk reminders the user sets (bell icon in Agenda).
Talk ratings (1-10, anonymous) can be tested with TEST02: open Agenda, pick any talk, scroll to "Oceń wykład". Ratings are sent with a random per-install ID only (no personal data).
```
Login wymagany: **NIE** (odznaczyć „Sign-in required").

---

## 3. LISTA DO PUBLIKACJI

### A. Przed wysyłką, test (Jarek, ok. 20 min na telefon)
- [ ] Android: zainstalować 1.2.0 z Internal testing (link testera, aktualizacja w Play).
- [ ] iOS: zainstalować najnowszy build z TestFlight (1.2.0 build 13 lub nowszy; CI sam przypisuje nowe buildy do grupy „Jerry").
- [ ] Na obu: ekran startowy bez przykładu FND2027, pole pokazuje „Kod wydarzenia".
- [ ] Dodać **TEST01**: kafle Agenda/Prelegenci/Partnerzy/Mapa, dolne menu z Mapą.
- [ ] Dodać **TEST03**: w miejscu kafla Mapa puste miejsce (Partnerzy na pół szerokości), brak zakładki Mapa w dolnym menu, brak pinezki przy partnerze i „Zobacz na mapie".
- [ ] Dodać **TEST02**: status NADCHODZĄCE, dzwonek na liście, przypomnienie prelekcji.
- [ ] Tryb samolotowy: wydarzenia dalej się otwierają (offline).
- [ ] iOS: polskie znaki w etykietach (Więcej, Aktualności, Dołącz...).
- [ ] Usunięcie wydarzenia z „Więcej" i ponowne dodanie kodem.

### B. Zrzuty ekranu: GOTOWE (z prawdziwej apki, 2026-09-17)
Robione automatem na CI (workflow `screenshots.yml`: emulator Android + symulator iPhone 6,9"),
dane z kodów TEST01-03, pasek statusu 9:41. Ponowne zrobienie: `gh workflow run screenshots.yml`.
- [x] Android (8 szt., 1080x1920): `tools/shots/store/android/`
- [x] iOS (9 szt., 1320x2868, 6,9"): `tools/shots/store/ios/`
- Drive: folder `Eskulapp/Store-1.2.0` (zrzuty, ikona, grafika 1024x500, ten dokument).
- Stare makiety z canvasu przeniesione do `tools/shots/store/_makiety/` (NIE wysyłać do sklepów).

### C. Google Play Console (Eskulapp, pl.eskulapp.mobile)
- [x] 1.3.0 (vc 21) na Internal + Alpha (2026-09-25).
- [x] Karta sklepu: teksty z §1, ikona 512, grafika 1024x500, 8 zrzutów (2026-10-05, `tools/play/listing.py --commit`).
- [ ] **Bezpieczeństwo danych: DO POPRAWY (oceny od 1.3.0).** Zbierane: „Aktywność w aplikacji: inne treści
  generowane przez użytkownika” (ocena) oraz „Identyfikatory urządzenia lub inne” (losowy ID instalacji).
  Nieudostępniane, opcjonalne, cel: funkcje aplikacji (i analityka dla organizatora), szyfrowanie w tranzycie TAK,
  brak możliwości żądania usunięcia (dane anonimowe, brak kont).
- [ ] Sprawdzić w Panelu, czy pozostałe deklaracje są zielone (dostęp do aplikacji z kodem TEST01, reklamy NIE,
  grupa docelowa 18+, IARC, aplikacje zdrowotne: brak), kraje: Polska.
- [ ] Produkcja: promocja vc 21 z testów (agent przez API, po zgodzie Jarka; rollout np. 20% potem 100%).

### D. App Store Connect (app id 6810647099)
- [x] Wersja 1.3.0, build 17, copyright, wydanie RĘCZNE po akceptacji (2026-10-05, `asc-prepare.yml`).
- [x] Opis, słowa kluczowe, promo, URL wsparcia/marketingowy, podtytuł, URL polityki, kategorie Biznes/Edukacja.
- [x] Ocena wiekowa 4+ (wszystko brak), prawa do treści: bez treści stron trzecich, cena: darmowa, dostępność: Polska.
- [x] App Review Information (kontakt, notatka z kodami TEST01-03 i oceną na TEST02, bez logowania).
- [x] 9 zrzutów 6,9".
- [ ] **App Privacy (tylko przeglądarka, brak API)**: zbierane „Identifiers: Device ID” (losowy ID instalacji) i
  „User Content: Other User Content” (ocena). Oba: NIE powiązane z tożsamością, NIE śledzenie, cel App Functionality
  (opcjonalnie Analytics). Potem „Publish”.
- [ ] Business > Agreements: brak zaległych umów do akceptacji.
- [ ] Wysyłka do recenzji (agent przez API albo przycisk „Add for Review”), po zgodzie Jarka.

### E. Po publikacji (agent)
- [ ] Linki do sklepów na eskulapp.pl (sekcja pobierania apki).
- [ ] Aktualizacja `state/STATUS.md` + zadanie w Todoist.
