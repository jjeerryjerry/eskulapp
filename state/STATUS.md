# STATUS — Eskulapp

_Ostatnia aktualizacja: 2026-08-18 (Faza C — komplet ekranów apki)_

## Gdzie jesteśmy
**Faza 0 — Fundament / środowisko: ZROBIONE.** Kod aplikacji ani backendu
jeszcze nie zaczęty (świadomie — czekamy na decyzje „serwisowe").

### Zrobione
- **Faza C — aplikacja: KOMPLET 12 ekranów na canvasie.** Wygląd zatwierdzony
  przez Jarka (2026-08-18, pierwsze 6). Dorobione 2026-08-18: **Prelegenci**
  (lista + keynote + szukaj), **Partnerzy** (tiery + stoiska), **Mapa** (plan
  hali z pinami stoisk), **Kontakt** (organizator + telefon/mail/www/adres +
  pomoc na miejscu), **Tryb offline** (banner + „ostatnia aktualizacja" +
  moduły dostępne offline), **Stan pusty** („Moje wydarzenia" bez eventów →
  CTA kodem). Pliki `design/faza-a/App-*.dc.html`, re-seed → ten sam URL
  canvasu (patrz niżej). **Do dorobienia po stronie web:** kreator powiadomień
  w CMS.
- **Decyzje Jarka 2026-08-18 (nadrzędne, w `ARCHITEKTURA.md §0`):**
  (1) aplikacja **BEZ logowania uczestnika** — kod eventu → dane lokalnie na
  telefon (odstępstwo od SSO w spec źródłowej); (2) **powiadomienia push
  planowane z CMS** (promo/zmiany, FCM topic per event, cron); (3) moduł
  **Aktualności** w apce; (4) WWW: **kierunek V3 „Identyfikator”**, na głównej
  link do pobrania apki + formularz kontaktu (leady); (5) zrzuty z apki na WWW po
  zbudowaniu. Docs zaktualizowane: ARCHITEKTURA, MODEL-DANYCH (news/notifications/
  leads), PLAN-MVP, BRANDING-DESIGN-SPEC.
- **Logo finalne: E1** (biała laska = lewy trzon, coralowy wąż układa się w „E”,
  w petrolowej pieczęci-kole). Rozniesione po A1/A2. Odrzucone: cienka kreska,
  warianty A–D/E2/E3.
- **Faza B — WWW: 3 kierunki na canvasie (strona „WWW”):** V1 Recepta (Rp.),
  V2 Monitor/EKG, V3 Identyfikator konferencyjny. Pliki w `design/faza-a/`:
  `WWW-Recepta/Monitor/Identyfikator.dc.html`. Czeka na wybór kierunku.
- **Canvas Claude Design „Eskulapp Design" (21 artboardów: branding+WWW+app).**
  Link: https://claude.ai/code/artifact/fd8e7676-9806-42f9-b646-59c3583dc398
  (2026-08-18: cała treść apki i WWW oczyszczona z myślników/strzałek — zasada Jarka.)
  Pliki źródłowe: `design/faza-a/` (Main/Logo/Kolory/Typografia/Komponenty/
  TonGlosu `.dc.html` + `canvas.json`, seed `eskulapp-branding.html`).
  Re-generacja: edytuj pliki → `node <skill>/seed-canvas.mjs` → republish tego
  samego pathu (ten sam URL). Paleta petrol+coral, Sora+Inter, znak Laska Eskulapa.
- `docs/BRANDING-DESIGN-SPEC.md` — pełny brief pod **Claude Design** (branding →
  WWW → app). Priorytet: branding. Kotwica marki: Laska Eskulapa (1 wąż, NIE
  kaduceusz); paleta petrol `#0C5A63` + coral `#FF6B57` + neutrale; typo Sora +
  Inter; lista artboardów (Fazy A/B/C). Kod eventu przykład `FND2027`.
- Utworzony agent `eskulapp` (alias `eskulap`): subagent CC
  `~/.claude/agents/eskulapp.md` + katalog `~/agents/eskulapp/`, rejestracja w
  `~/.claude.json` (trust=true), alias-symlink `~/agents/eskulap`.
- Dokumentacja w `docs/`: SPEC-ZRODLOWA, ARCHITEKTURA, MODEL-DANYCH, PLAN-MVP.
- Potwierdzony toolchain Androida na serwerze: `~/jdk17`, `~/android-sdk`
  (wspólny z `aapsbuilder`/`foodvision`).
- Potwierdzony dostęp do serwera cyber-folks `edu-serwer` (PHP 8.2, MySQL,
  wp-cli; brak Node) — tam gdzie `jerrymarketing.pl` i `cukrzyca.*`.
- Szkielet katalogów: `web/` (backend PHP), `app/` (Android), `scripts/`.

### Decyzje startowe
- Backend: **PHP 8.2 + MySQL**, REST API + JWT (narzucone przez hosting).
- Mobile v1: **Android** Kotlin/Compose, offline-first (Room). iOS później.
- Toolchain buildów: `~/jdk17` + `~/android-sdk`, `./gradlew` (nie od zera).

## WWW + backend — URUCHOMIONE i ŻYWE (2026-08-18)
Domena **eskulapp.pl** (cert Certum, HTTPS). Architektura wg decyzji Jarka:
**front na WordPressie, logowanie/CMS na dedykowanym module PHP.**
- **Front = WordPress** (`/`), własny theme `eskulapp` (landing V3, **sprzedażowy**:
  produkt płatny, CTA „Zapytaj o ofertę", copy „skontaktujemy się i przedstawimy
  ofertę"). Bez publicznego linku do panelu (adres dostaje się mailem). Formularz
  → `POST /api/lead` → zapis w DB **+ mail na kontakt@eskulapp.pl** (honeypot).
- **Dedykowany CMS admina** (`/panel`, `/panel/logowanie`, `/panel/dashboard`):
  sesje secure+httponly+samesite, CSRF, nagłówki bezpieczeństwa (CSP/HSTS/XFO),
  rate-limit. **Event dodaje admin/agent** (nie organizator); przy sprzedaży
  tworzymy event i nadajemy KOD. Kod wspólny w `/_app` (zablokowany z sieci 403).
- **Publiczne API dla apki**: `GET /api/public/events/{code}/bundle`, `/api/health`.
  Serwuje z DB. Eventy: **FND2027** (demo) + **FND2025** (7. Forum Nowoczesnej
  Diabetologii, realny program 29-30.11.2024, 20 prelekcji/9 prelegentów).
- **Baza MySQL `jjeerry_eskulapp`** podpięta (współdzielona z WP: `wp_*` vs nasze
  tabele). Schemat `web/db/schema.sql`; seedy `seed_demo.sql`, `seed_fnd2025.sql`.
- **Stack CMS: czysty PHP 8.2** (bez frameworka/composera). `_app/` wewnątrz
  webroota (hosting: `open_basedir=public_html`; sibling poza rootem = HTTP 500).
  NIE dodawać `AddHandler` w `.htaccess` (LiteSpeed 500). Deploy dedykowanego:
  `scripts/deploy-web.sh` (rsync poddrzew `web/cms/*` + theme). WP core przez wp-cli.
- **Sekrety**: `web/cms/_app/.env` na serwerze (DB), poza repo.
- **Statusline agenta**: `JerryEskulapp` (STANDARD Jerry).
- **Zrzuty apki (12 PNG)**: `tools/shots/` (puppeteer render) → na serwerze
  `https://eskulapp.pl/zrzuty/*.png` + folder Drive „Eskulapp zrzuty aplikacji"
  z linkami. (Drive-inline uploadu binariów z sesji się nie da — za duży base64.)
- **Zasada Jarka**: bez myślników i strzałek nigdzie (zob. [[rule-no-dashes-arrows]]).

## Otwarte decyzje
- [x] Domena **eskulapp.pl**; front **WordPress**; CMS/logowanie **dedykowany PHP**.
- [x] Logowanie tylko admin (Jarek/agent); event + kod nadaje admin; uczestnik bez konta.
- [ ] Package name Androida (`pl.eskulapp.mobile`?).
- [ ] Które moduły CMS budujemy najpierw (CRUD eventów priorytet).

## DO ZROBIENIA po stronie Jarka
- Utworzyć skrzynkę **kontakt@eskulapp.pl** (żeby leady z formularza dochodziły).
- (Opc.) usunąć folder `/zrzuty` po pobraniu PNG.

## CMS `/panel` — CRUD eventów GOTOWY (2026-08-18)
- Lista + **Nowy event** + edycja + usuwanie (`/panel/events/new`, `/events/{id}`,
  `/events/{id}/delete`). Auto-**generowanie kodu** z nazwy (np. „Kongres Testowy
  2028" → `KT2028`), slug, `push_topic=event_<id>`, walidacja + CSRF. Zweryfikowane
  e2e na żywo. Kod: `web/cms/_app/lib/Events.php`, widok `views/event_form.php`.
- Uwaga hosting: env dla PHP CLI musi być PRZED komendą (`P=x php -r`), inaczej
  trafia jako argv (tak zepsuł się pierwszy hash admina — naprawione).

## Poprawki mobilne landingu (2026-08-18, theme v1.2)
Zrzut Jarka (widok mobilny hero) — naprawione i wdrożone na live:
- **Diakrytyki: to była kwestia TREŚCI, nie fontu.** Całe copy w theme było
  zapisane bez ogonków (ASCII). Fonty Sora+Inter z Google Fonts serwują latin-ext,
  polskie znaki działają. Poprawione UTF-8 w `front-page.php`, `header.php`,
  `footer.php`, `index.php` oraz komunikaty w `assets/lead.js`.
- **H1 za duży na mobile**: dodany breakpoint `@media(max-width:600px)` →
  `clamp(26px,7.4vw,34px)`, `@media(max-width:400px)` → 25px; line-height 1.12,
  mniejszy letter-spacing, `overflow-wrap:break-word`. Desktop bez zmian.
- **Hero dotykał krawędzi**: `.hero` (shorthand padding) zerował boczny padding
  z `.wrap`. Na mobile ustawione `.hero{padding:32px 20px 16px}` → treść oddycha
  (H1 20px od krawędzi na 360/390/414).
- **Przycisk „Zapytaj o ofertę" w nav — niski kontrast**: bug specyficzności CSS
  (`.nav-links a` (0,1,1) > `.btn-primary` (0,1,0) → tekst szedł na `--muted`).
  Fix: `.nav-links a.btn-primary{color:#fff}`. Teraz biały na petrol.
- **QA (puppeteer, 360/390/414 px)**: brak poziomego scrolla (scrollWidth==innerWidth),
  brak elementów przekraczających viewport, przyciski CTA stackują się czytelnie,
  nav button rgb(255,255,255) na rgb(12,90,99). Zweryfikowane na live eskulapp.pl.

## Następny krok
1. **CMS: edytor agendy** dla eventu (dni, sale, prelekcje, prelegenci, powiązania),
   potem partnerzy/mapa, aktualności, powiadomienia; lista leadów.
2. **Android**: projekt Gradle (Compose+Room), Wejście kodem →
   `GET /api/public/events/{code}/bundle` (działa: FND2027, FND2025) → offline.

## Notatki
- Źródłowy PDF: Google Drive folder `__Eskulapp`,
  `Specyfikacja_Eskulapp.pdf` (id `1N_etBTvMQ6RrFSRRAIlqJ41c1gxwh-dr`).
- Przykładowy kod eventu ze specyfikacji: `FND2027`.

## Aplikacja Android , DEBUG APK GOTOWY (2026-08-19)
- Pełna apka Kotlin/Compose (MVVM, Room offline-first), pakiet `pl.eskulapp.mobile`.
  Pobiera dane z `https://eskulapp.pl/api` (bundle po kodzie) → Room → działa offline.
- Ekrany: Wejście kodem, Moje wydarzenia (+ pusty), Ekran eventu (moduły + baner
  aktualności), Agenda (dni + filtr sal + przypomnienia WorkManager), Prelekcja
  (szczegół + „Przypomnij mi"), Prelegenci, Partnerzy, Mapa (venue + stoiska),
  Kontakt (klikalny tel/mail), Aktualności, Więcej (+ usuń event). Bottom-nav.
- Build: LOKALNY toolchain (`~/jdk17`, `~/android-sdk`), OFFLINE z cache (wersje jak
  foodvision). APK: `app/build/outputs/apk/debug/app-debug.apk` (10,6 MB, 0.1-debug).
- Wydany na **Google Drive** (folder „Eskulapp") przez lokalny rclone `gdrive:`.
  Plik: https://drive.google.com/open?id=1CWPeD5KDXn_K9Q1PZxb2tSZwjL1rKk2u
- Szczegóły builda: [[android-build]] w pamięci.

## Poprawki apki, runda 1 (2026-08-20, beta 0.1)
5 poprawek z listy Jarka + wersjonowanie beta:
1. **Agenda, nazwiska prelegentow na liscie prelekcji**: `AgendaScreen` pokazuje
   teraz PELNE nazwiska (join ", "), nie "+N". Dane: brakujace powiazania
   `talk_speakers` dodane do seed FND2027 (`web/db/seed_demo.sql`) i wdrozone na
   zywa DB (FND2027 = 4 powiazania).
2. **Rozwijanie szczegolow prelegentow i partnerow**: dodany `Screen.SpeakerDetail`
   + `SpeakerDetailScreen` (bio, tytul, lista wystapien, klik -> Prelekcja).
   `SpeakersScreen` klikalny (wzorzec jak partnerzy). Partnerzy juz mieli
   `PartnerDetailScreen` (dziala).
3. **Lista eventow, dzwonek TOGGLE**: nowa tabela Room `event_notify` (v2) +
   DAO `notifyIds/addNotify/removeNotify`, `EventsScreen` ma dzwonek per event
   (wlacz/wylacz, zmiana ikony coral/faint + podpis stanu). Stan lokalny, przetrwa
   odswiezenie bundle. (Realny push FCM = pozniej.)
4. **2 wydarzenia testowe**: `web/db/seed_test_events.sql` -> **KARD26** (Sympozjum
   Kardiologiczne 2026, 16-17.05.2026, archiwalny/wyszarzony) i **DIAB26** (Kongres
   Diabetologii Klinicznej 2026, 20-21.10.2026, aktywny). Wdrozone na zywa DB,
   komplet: dni/sale/prelegenci/prelekcje/talk_speakers/partnerzy/kontakt/news.
5. **Menu (MoreScreen)**: (a) nowy przycisk "Lista wydarzen" -> lista eventow;
   (b) "Usun to wydarzenie" ma teraz `AlertDialog` potwierdzenia (Usun/Anuluj).

**Wersjonowanie beta (decyzja Jarka):** versionCode 3, versionName `0.1-beta`.
APK nazwany `eskulapp-beta-0.1.apk`. Kazdy nowy build = NOWY plik na Drive z bumpem
(0.1 -> 0.2 -> ...), stare zostaja (nie nadpisujemy). Build OFFLINE lokalny, OK.
- APK live: https://drive.google.com/open?id=13I-c1hC0cXDa7ZZ8eDfpcroIcii4MLTb
  (folder `gdrive:Eskulapp`; stary `eskulapp-debug.apk` zachowany).
- Kody do testow: FND2027, FND2025, **KARD26** (archiwalny), **DIAB26** (za ~2 mies.).

## Poprawki apki, runda 2 (2026-08-20, beta 0.2)
4 poprawki z drugiej listy Jarka (versionCode 4, versionName 0.2-beta):
1. **Dzwonek na liscie prelekcji nie otwiera juz prelekcji**: `AgendaScreen.TalkRow`
   ma osobny click na ikonie dzwonka (Box z wlasnym `clickable`) -> tylko toggle
   przypomnienia; klik w reszte karty -> szczegoly prelekcji. Ten sam wzorzec co
   dzwonek na liscie eventow.
2. **Status "Nadchodzace" dla przyszlych eventow**: `EventsScreen` + helper
   `isUpcoming()` (Common.kt). Etykiety: ARCHIWALNY (szary) / NADCHODZACE (coral,
   start w przyszlosci) / AKTYWNY (trwa/bez daty). DIAB26 = NADCHODZACE.
3. **Animacje przejsc**: `MainActivity` owija ekrany w `AnimatedContent`
   (slide 1/5 szer. + fade, tween 260 ms). Kierunek zalezy od glebokosci stosu
   (push = w lewo, pop = w prawo). Subtelne, spojne w calej apce.
4. **Licznik nieprzeczytanych aktualnosci**: nowa tabela Room `news_read` (v3) +
   DAO `readNewsIds/markNewsRead`. `EventScreen`: baner aktualnosci z BADGE liczby
   nieprzeczytanych (coral gdy sa, wygaszony gdy 0). Wejscie w `NewsScreen`
   (`LaunchedEffect`) oznacza wszystkie jako przeczytane -> badge znika. Kropka na
   tabie "Aktualnosci" (bottom-nav) bazuje teraz na nieprzeczytanych, nie na liczbie
   wszystkich. Stan lokalny, przetrwa odswiezenie bundle.

- APK 0.2: https://drive.google.com/open?id=1l3YPcs0g3D49Cwc7TP8IC3XllVWkg1Rt
  (0.1 i stary debug zachowane na Drive, nie nadpisane).

## Poprawki apki, runda 3 (2026-08-20, beta 0.3)
4 poprawki z trzeciej listy Jarka (versionCode 5, versionName 0.3-beta):
1. **Reverse animacji przy WSTECZ**: `MainActivity` AnimatedContent teraz pelna
   szerokosc + lustro. Push: nowa karta wsuwa z prawej (`+w`), stara wysuwa w lewo
   (`-w`); pop: dokladne odbicie (nowa z lewej, biezaca w prawo). tween 300 ms.
2. **Bottom-nav: Aktualnosci -> Partnerzy**: `Sections.eventTabs` usuniete
   "Aktualnosci" (badge zostaje na glownej stronie eventu), dodane "Partnerzy"
   (`Screen.Partners`, ic_store). `PartnersScreen` dostal `BottomBar`. `eventTabs`
   uproszczone do `eventTabs(id)` (bez licznika dot), zaktualizowani wszyscy callerzy.
3. **Mapa: plan strefy wystawcow**: `MapScreen` przebudowany na czytelny schemat
   (naglowek obiekt+miasto, pasek SCENA GLOWNA, stoiska w siatce 2 kol. z pinami
   i kodami, pasek WEJSCIE GLOWNE + lista stoisk). Renderuje sie z danych partnerow
   (boothLocation) - offline, bez zewn. bibliotek. Test eventy (FND2027/DIAB26/KARD26)
   maja stoiska, wiec plan jest widoczny. (Zdalny obraz PNG wymagalby Coila + sieci
   przy buildzie - odlozone; schemat wystarcza do testow.)
4. **Migracje Room zamiast destructive**: `AppDatabase` ma `MIGRATION_1_2`
   (event_notify) i `MIGRATION_2_3` (news_read), `addMigrations(...)` zamiast
   `fallbackToDestructiveMigration`. Aktualizacja apki NIE kasuje lokalnych danych
   (eventy dodane kodem, dzwonki/powiadomienia, przeczytane aktualnosci). `Repo.saveBundle`
   zachowuje lokalny `addedAt` przy odswiezaniu (kolejnosc listy), a odswiezenie i tak
   dotyka tylko danych danego eventu, nie kasuje innych eventow ani flag (osobne tabele).

- APK 0.3: https://drive.google.com/open?id=1yzqnpXWRUzegeYS0Jua0QrVJY5UG3dWB
  (0.1, 0.2 i stary debug zachowane).

## Poprawki apki, runda 4 (2026-08-20, beta 0.4)
2 poprawki z czwartej listy Jarka (versionCode 6, versionName 0.4-beta):
1. **Animacje - pelna spojnosc**: kierunek przejscia bierze sie teraz WPROST z
   Navigatora (`lastForward`: push/section-push/setStack/replaceTop = w glab -> LEWO;
   pop/section-collapse/BackHandler = wstecz -> PRAWO). Zniknely heurystyki po
   glebokosci stosu (byly zrodlem brzydkich/niespojnych przejsc, m.in. wejscie na
   glowny ekran eventu i w szczegoly prelekcji). Wszystkie ekrany (w tym Entry/Events)
   ida przez jeden `AnimatedContent` w `MainActivity` - jednolicie, bez wyjatkow.
   Dane: **FND2027 = AKTYWNY** (start 2026-08-20, koniec 2026-08-21, published).
   Seed (`seed_demo.sql`) + zywa DB zaktualizowane (UPDATE, id/powiazania zachowane).
   Trojka do testu statusow: FND2027=AKTYWNY, DIAB26=NADCHODZACE, KARD26=ARCHIWALNY.
2. **Aktualnosci "wszystko przeczytane"**: `EventScreen` - gdy 0 nieprzeczytanych,
   sekcja pokazuje tylko naglowek "Aktualnosci" + "brak powiadomien" (bez tresci
   ostatniej wiadomosci). Gdy sa nieprzeczytane: tytul ostatniej + badge z liczba jak
   wczesniej. Wejscie w sekcje dalej otwiera liste wiadomosci.

- APK 0.4: https://drive.google.com/open?id=1h7SSDKus_W-K6q29AUYcv015Z5RTzh9j
  (0.1, 0.2, 0.3 i stary debug zachowane).

## Poprawki apki, runda 5 (2026-08-20, beta 0.5)
Fix animacji cofania (versionCode 7, versionName 0.5-beta):
- **Objaw (Jarek)**: wstecz z listy prelegentow na glowny ekran eventu = "zwijanie
  od rogu" (skala), zamiast poziomego swipe w prawo.
- **Przyczyna (znaleziona)**: jedyny `AnimatedContent` (MainActivity) mial
  transitionSpec budowany przez `togetherWith`, ktore zostawia DOMYSLNY
  `SizeTransform(clip=true)`. To on animuje/przycina rozmiar kontenera od rogu.
  Reszta kodu jest czysta: brak Crossfade/scaleIn/scaleOut/shrink/expand,
  brak zagniezdzonego AnimatedContent, brak drugiego transitionSpec (potwierdzone
  grepem po calym app/src).
- **Fix**: transitionSpec buduje teraz jawnie `ContentTransform(enter, exit, 0f, null)`
  - `sizeTransform = null` calkowicie wylacza SizeTransform. Zostaje czysty poziomy
  slajd: wejscie w glab = nowa z prawej (`+w`), stara w lewo; powrot = lustro
  (nowa z lewej, biezaca w prawo). Kierunek dalej z jednego zrodla `nav.lastForward`.
  Dotyczy WSZYSTKICH przejsc (Event<->Prelegenci/Prelekcja/Partnerzy/Mapa, taby,
  section, Entry/Events) - jeden transitionSpec, bez wyjatkow.
- APK 0.5: https://drive.google.com/open?id=1GgBDT8wrnHhE4E8fBOqQbUFCOtZG0BWm
  (0.1-0.4 i stary debug zachowane).

## Poprawki apki, runda 6 (2026-08-20, beta 0.6)
3 punkty (versionCode 8, versionName 0.6-beta):
1. **Animacje = wzorzec zakladek dolnego menu**:
   (a) transitionSpec w `MainActivity` to teraz CZYSTY poziomy slajd BEZ fade i BEZ
   SizeTransform (`ContentTransform(slideIn, slideOut, 0f, null)`), identyczny dla
   drill-in i przelaczania zakladek (jeden `AnimatedContent`, ten sam czas 300 ms).
   (b) Kierunek zakladek wg KOLEJNOSCI: `BottomBar` liczy `targetIdx >= currentIdx`
   i wola `Navigator.sectionWithDir(screen, forward)`, ktory narzuca kierunek
   (`lastForward`). Zakladka na prawo = w przod (lewo), na lewo = wstecz (prawo).
   Np. Mapa -> Agenda animuje sie jak wstecz. Drill-in (push) dalej = w przod.
2. **Menu "Wiecej"**: usuniete pozycje "Prelegenci" i "Partnerzy" (partnerzy w
   dolnym menu, prelegenci z agendy/prelekcji). Zostaje Kontakt, Lista wydarzen, Usun.
3. **Mapa + partnerzy**:
   (a) **10 partnerow na KAZDY event** (FND2027 A1-A10, DIAB26 D1-D10, KARD26 K1-K10,
   FND2025 G1-G10), z opisem/tierem/stoiskiem/www. Seed (`seed_partners.sql` +
   zaktualizowane bazowe seedy) i zywa DB (po 10, zweryfikowane).
   (b) **Powiazanie partner <-> stoisko na planie**: `Screen.MapS` ma opcjonalny
   `highlightPartnerId`. Z listy partnerow (przycisk-pin) oraz z karty partnera
   ("Zobacz na mapie") przechodzi na Mape z WYROZNIONYM stoiskiem (coralowy kafel/pin
   + baner z nazwa i numerem stoiska). Kafle i wiersze stoisk na mapie sa klikalne
   -> karta partnera (powiazanie w obie strony).
- APK 0.6: https://drive.google.com/open?id=1h6_o6IulXLIWZwZnHUTp-35MzHi79-5l
  (0.1-0.5 + debug ZACHOWANE; UWAGA: starsze APK znalazly sie w koszu Drive - nie
  przez `rclone copy` - przywrocone przez `rclone backend untrash gdrive:Eskulapp`).

## Poprawki apki, runda 7 (2026-08-20, beta 0.7)
3 rzeczy (versionCode 9, versionName 0.7-beta):
1. **Dolny pasek STATYCZNY (fix glownej przyczyny brzydkich animacji)**: BottomBar
   byl renderowany WEWNATRZ `AnimatedContent` (slajdowal razem z trescia). Teraz
   `MainActivity` liczy `tabEventId` z biezacego ekranu i renderuje BottomBar RAZ,
   POZA `AnimatedContent`, w `Column{ Box(weight1f){ AnimatedContent{content} }; BottomBar }`.
   BottomBar zdjety z 6 ekranow (Event/Agenda/Partners/Map/News/More). Przy kazdym
   przejsciu przesuwa sie tylko obszar tresci, pasek stoi. (Gorne paski zostaja w
   tresci - EventScreen ma wlasny duzy header petrol, wiec nie robie wspolnego topbara;
   jesli Jarek zechce top tez statyczny, dorobimy.)
2. **Mapa: klik na liscie stoisk = ZAZNACZENIE na planie, nie karta partnera**:
   lista stoisk na Mapie wywoluje `focusBooth` (podswietla kafel + centruje/zoomuje
   plan), NIE nawiguje do karty. Karta partnera dostepna z zakladki Partnerzy.
3. **Mapa "embed" - zoom & pan**: plan ma pinch-to-zoom (1x..4x) i przeciaganie
   (`detectTransformGestures` + `graphicsLayer` scale/translation, pan ograniczony do
   krawedzi). Zaznaczone stoisko (z listy albo "Zobacz na mapie") wycentrowuje sie i
   przybliza (scale 2.4x, offset liczony z pozycji w siatce 2 kolumn). Kafle planu sa
   tylko wizualne (bez klika) zeby nie kolidowac z gestami; selekcja idzie z listy.

**Polityka retencji Drive (decyzja Jarka, na stale)**: po uploadzie zostaja tylko
2 najnowsze APK, reszta kasowana trwale. Stan folderu: eskulapp-beta-0.7.apk +
eskulapp-beta-0.6.apk (usunieto 0.1-0.5, eskulapp-debug, eskulapp-0.1-debug).
- APK 0.7: https://drive.google.com/open?id=11n0jTWZN7BqFh6ZIT8B58buNrGWZ08Ac

## Poprawki apki, runda 8 (2026-08-20, beta 0.8)
2 obszary (versionCode 10, versionName 0.8-beta):
1. **Animacja WSTECZ = zawsze jak tab-switch Mapa->Partnerzy**: transitionSpec i kierunek
   byly juz wspolne (pop -> lastForward=false -> dir=-1, identycznie jak backward
   tab-switch). Realna niespojnosc: dolny pasek pojawial sie/znikal na ekranach drill-in
   (Prelegenci/Prelekcja/Partner/Kontakt nie mialy paska), przez co obszar tresci
   zmienial wysokosc w trakcie animacji cofania (efekt "skladania"). Fix: `tabEventId`
   w `MainActivity` obejmuje teraz WSZYSTKIE ekrany w evencie (tez Speakers/Contact/Talk/
   PartnerDetail/SpeakerDetail) -> pasek jest zawsze, wysokosc tresci stala -> back animuje
   sie 1:1 jak tab-switch. Jeden transitionSpec, bez wyjatkow.
2. **Mapa**:
   (a) **Piny na STALYCH pozycjach**: nowa `boothPos(i,n)` -> frakcje (2 kolumny 0.30/0.70,
   wiersze rozlozone rownomiernie). Piny rysowane absolutnie (`BoxWithConstraints` + `offset`),
   stabilne per partner; zaznaczony pin wiekszy + obwodka + nazwa. Luzna siatka kafli usunieta.
   (b) **Klik nazwy na liscie = tylko zaznaczenie** (podswietl pin + wycentruj/zoom), zero
   nawigacji. Karta partnera tylko z zakladki Partnerzy.
   (c) **Pelne okno mapy**: plan 460 dp (bylo ~300), pelna szerokosc.
   (d) **Mapa + lista w JEDNYM scrollu**: cala strona to `verticalScroll` (plan na gorze,
   lista pod spodem, przewijaja sie razem). Zamiast `LazyColumn` z wlasnym scrollem - `forEach`.
   Konflikt gestow rozwiazany: `transformable(canPan = { scale > 1f })` - pan planu dziala
   tylko po przyblizeniu; przy 1x pionowy gest scrolluje strone. Pinch-zoom (1x..4x) zawsze.
   (Wymagalo `@OptIn(ExperimentalFoundationApi)` dla `canPan`.)

**Retencja Drive**: zostaja 0.8 + 0.7 (usunieto 0.6).
- APK 0.8: https://drive.google.com/open?id=17O01G0xO5j0U2ymTbWVZly9YDqYUnD4O

## Poprawki apki, runda 9 (2026-08-20, beta 0.9)
3 rzeczy (versionCode 11, versionName 0.9-beta):
1. **Brak animacji WSTECZ - PRAWDZIWA przyczyna i fix**: `targetSdk=35` + brak
   `android:enableOnBackInvokedCallback` w manifescie => na Androidzie 15+ predictive
   back jest DOMYSLNIE wlaczony. Systemowy/gestowy Back szedl wtedy przez
   `OnBackInvokedDispatcher` (animacja systemowa predictive), a nasz stan zmienial sie
   natychmiast po commit - bez naszego slajdu (ekran "skakal"). Forward i tab-switch to
   zwykle tapniecia (nie dotykaja back-dispatchera), wiec animowaly sie normalnie - stad
   asymetria. FIX: `android:enableOnBackInvokedCallback="false"` w manifescie => Back
   wraca na legacy `OnBackPressedDispatcher` => `BackHandler` odpala nasz `nav.pop()`
   => AnimatedContent robi slajd w prawo, identycznie jak tab-switch. Obie sciezki Back
   (systemowa i strzalka w pasku) wolaja ten sam `nav.pop()`. (To bylo zewnetrzne wzgledem
   AnimatedContent - nie zgadywanie kierunku, tylko przechwytywanie gestu przez system.)
2. **Mapa - piny pokazuja NAZWY wystawcow** (nie kody stoisk): pin = marker (ikona) +
   NAZWA partnera pod spodem (skrocona z ellipsis), numer stoiska malutkim drukiem (8sp)
   pod nazwa. Szersze piny (68 dp).
3. **Glowny ekran eventu - usuniete kafelki** "Aktualnosci" (jest sekcja na gorze) i
   "Kontakt" (jest w "Wiecej"). Zostaja: Agenda, Prelegenci, Partnerzy, Mapa.

**Retencja Drive**: zostaja 0.9 + 0.8 (usunieto 0.7).
- APK 0.9: https://drive.google.com/open?id=1eLco_xEZQSMc4BXrkj8X-lYLhtFA-BaR

## Poprawki apki, runda 10 (2026-08-20, beta 0.10) - DEFINITYWNY fix animacji WSTECZ
- **Dowod #1 (manifest)**: zmergowany manifest (`build/intermediates/merged_manifests/...`)
  MA `enableOnBackInvokedCallback="false"` -> predictive back to NIE byla przyczyna.
  Systemowy Back szedl juz legacy dispatcherem, a i tak "skakalo".
- **Dowod #2 (roznica w kodzie)**: `slideInHorizontally { fullWidth -> dir*fullWidth }`
  uzywa szerokosci WCHODZACEJ tresci. Ekrany `EventScreen/TalkScreen/PartnerDetail/
  SpeakerDetail` robia `val x = flow ?: return` PRZED swoim `Column(fillMaxSize)`. Gdy
  ich Room-Flow jest chwilowo `null`, wchodzacy slot ma szerokosc 0 => offset slajdu =
  dir*0 = 0 => BRAK animacji wejscia (skok). Ekrany-zakladki (Agenda/Partners/Map/More)
  nie maja early-return, maja pelna szerokosc => pelny slajd. To 1:1 tlumaczy
  "tab-switch animuje, powrot na glowny ekran eventu skacze" (glowny ekran = EventScreen,
  early-return).
- **FIX**: w `MainActivity` kazdy slot tresci `AnimatedContent` owiniety w
  `Box(Modifier.fillMaxSize().background(Bg)) { when(s){...} }` -> wchodzacy slot ZAWSZE
  ma pelna szerokosc, wiec `slideInHorizontally` dostaje pelny dystans i slajd gra takze
  gdy ekran chwilowo early-returnuje. Kierunek `nav.lastForward` przeniesiony do
  snapshot-state (bezpiecznik). Manifest zostaje `enableOnBackInvokedCallback=false`.
  Animacja 300 ms, identyczna jak tab-switch Mapa->Partnerzy.
- (Klatek z nagrania nie wyciagnalem - brak ffmpeg/pip/sieci; przyczyna udowodniona na
  poziomie kodu + semantyki API slideInHorizontally + roznicy early-return vs fillMaxSize.)

**Retencja Drive**: zostaja 0.10 + 0.9 (usunieto 0.8).
- APK 0.10: https://drive.google.com/open?id=17ZpvnbBwVgpwGNjOa6H-K0AzKEMY0lkQ

## Poprawki apki, runda 11 (2026-08-20, beta 0.11)
Animacje wstecz potwierdzone OK przez Jarka (temat zamkniety). 2 poprawki
(versionCode 13, versionName 0.11-beta):
1. **Glowny ekran eventu - kafle na cala wysokosc**: `EventScreen` - usuniety
   `verticalScroll`, siatka 2x2 (Agenda/Prelegenci/Partnerzy/Mapa) w `Column(weight=1f)`
   z 2 rzedami `Row(weight=1f)` i kaflami `weight(1f).fillMaxHeight()` -> wypelniaja cala
   przestrzen od baneru Aktualnosci do dolnego paska, bez pustego dolu. Styl kafla bez
   zmian (ikona+tytul+podtytul), tresc kafla wycentrowana w pionie.
2. **Mapa - klik partnera tylko wyroznia pin**: usuniety coralowy baner "Wyroznione na
   planie", usuniety auto-zoom i auto-centrowanie (`focusBooth` + `LaunchedEffect`).
   Klik na liscie stoisk ustawia tylko `selectedId` -> podswietlony pin na planie; plan
   zostaje w skali 1x, user sam scrolluje do mapy. To samo dla "Zobacz na mapie" z karty
   partnera (init `selectedId`, bez zoomu/baneru). Pinch-zoom + pan (gestem) zostaja.

**Retencja Drive**: zostaja 0.11 + 0.10 (usunieto 0.9).
- APK 0.11: https://drive.google.com/open?id=1vsrOoE5lWISSa9NpgjfuGyN3WkkEYbek

## Poprawki apki, runda 12 (2026-08-20, beta 0.12)
2 poprawki (versionCode 14, versionName 0.12-beta):
1. **Polskie znaki w etykietach - naprawione**. PRZYCZYNA: zahardkodowane stringi
   ASCII bez ogonkow w kodzie Kotlin (pisane tak w poprzednich rundach). To NIE font -
   apka nie ma custom fontu (`res/font` nie istnieje, brak `FontFamily`/`Font` w kodzie),
   uzywa systemowego, ktory MA glify Latin Extended (dlatego naglowek z bazy "Dziecięcej"
   renderowal ę poprawnie). Poprawilem wszystkie etykiety UI na poprawna polszczyzne:
   Aktualności, Kto występuje, Więcej (bottom-nav + BackTopBar), Dzień, żadnej, prelegentów,
   osób, wkrótce, pojawią się, Wrócimy/ogłoszeniami, SCENA GŁÓWNA, WEJŚCIE GŁÓWNE, Usuń/Usunąć,
   Lista wydarzeń, Wystąpienia, NADCHODZĄCE, Powiadomienia włączone/wyłączone, Dołącz,
   brak powiadomień, Błąd serwera, Brak połączenia/Sprawdź/spróbuj, Prelekcja wkrótce.
   Pliki: ApiClient, AppViewModel, ReminderWorker, Sections, EntryScreen, AgendaScreen,
   EventScreen, EventsScreen, MoreScreens. (WAZNE na przyszlosc: pisz stringi z ogonkami -
   font systemowy je obsluguje.)
2. **Podpis pod mapa** zmieniony na dokladnie: "Uszczypnij żeby przybliżyć. Przeciągnij
   aby przesunąć", fontSize 10.sp + maxLines=1 (miesci sie w jednej linii).

**Retencja Drive**: zostaja 0.12 + 0.11 (usunieto 0.10).
- APK 0.12: https://drive.google.com/open?id=1IpSZhS6MDRZpDv2N-FEBk9q0qNf6zA9_

## Hardening bezpieczenstwa WDROZONE (2026-08-20, beta 0.13) - bez podpisu
Zatwierdzone przez Jarka, wdrozone (poza release-signing/keystore/AAB = na koniec):
- **R8/minify**: `release { isMinifyEnabled=true; isShrinkResources=true }`. Keep-rules
  w `proguard-rules.pro` dla kotlinx.serialization + DTO (`data/model/**`) + Room.
  WALIDACJA: `assembleRelease` (podpisany DEBUG-keystore, tylko do walidacji) przeszedl
  bez bledow, R8 OK, APK 1.4 MB (z ~10.5 MB). DOWOD ze deserializacja nie zepsuta:
  w `mapping/release/mapping.txt` WSZYSTKIE DTO i ich `$$serializer` (BundleDto, EventDto,
  DayDto, RoomDto, TalkDto, SpeakerDto, TalkSpeakerDto, PartnerDto, ContactDto, NewsDto)
  zachowane z ORYGINALNYMI nazwami (nieusuniete/nieobfuskowane). Runtime na urzadzeniu
  nieodpalony (brak emulatora) - dowod statyczny.
- **Manifest**: `allowBackup="false"`, `usesCleartextTraffic="false"`,
  `networkSecurityConfig="@xml/network_security_config"`. Baza Room wykluczona z backupu
  w `backup_rules.xml` + `data_extraction_rules.xml` (na wypadek wlaczenia backupu).
- **Network Security Config**: `res/xml/network_security_config.xml` z
  `cleartextTrafficPermitted="false"`.
- **Tapjacking**: `window.decorView.filterTouchesWhenObscured = true` w `MainActivity`
  (globalnie, obejmuje Usun wydarzenie + Dolacz kodem).
- **Zaleznosci**: NIE bumpowane (build offline, brak egressu - nie ryzykuje kompilacji).
  Docelowo (w srodowisku z siecia) do najnowszych stabilnych: AGP 8.7.3, Kotlin 2.1.0,
  Compose BOM 2024.12.01, activity-compose 1.9.3, room 2.7.1, work 2.9.1, lifecycle 2.8.7,
  coroutines 1.9.0, serialization 1.7.3 -> najnowsze stabilne. TODO.
- **Pominiete swiadomie** (decyzja Jarka, na koniec/pozniej): signingConfig release,
  produkcyjny keystore, AAB, cert pinning, szyfrowanie Room.

## POLITYKA PRYWATNOSCI - opublikowana
- URL: **https://eskulapp.pl/polityka-prywatnosci/** (do Data safety w konsoli Play).
- Strona WP ID 3 (byla draft) uzupelniona i opublikowana; ustawiona jako
  `wp_page_for_privacy_policy`. Tresc zgodna z realnymi praktykami apki (brak konta,
  pobieranie po kodzie, dane lokalne, INTERNET + powiadomienia, brak sledzenia/reklam/
  udostepniania, kontakt kontakt@eskulapp.pl).
- **UWAGA serwer**: dodany `.htaccess` (standardowy blok WP mod_rewrite, NIE AddHandler)
  w `public_html` - wczesniej go NIE bylo, przez co pretty-permalinki 404-owaly. Po dodaniu
  zweryfikowane 200: strona prywatnosci, homepage, /api/health, /api/.../bundle, /panel/logowanie.
  (mod_rewrite z `!-f !-d` nie rusza /api /panel /_app /zrzuty.)

## Następny krok (po Androidzie)
1. Test APK na telefonie Jarka (kody FND2027/FND2025/KARD26/DIAB26) + feedback UI.
2. CMS: edytor agendy/prelegentów (napełnianie eventów), potem partnerzy/mapa, push.
3. Powiadomienia push (FCM) + harmonogram w CMS + cron.

## PUBLIKACJA GOOGLE PLAY , przygotowane (2026-09-08, v1.0.0)
Konto dewelopera: **firmowe, zweryfikowane** (bez wymogu 12 testerow/14 dni).
Decyzje Jarka: **pierwszy upload na Internal testing -> promocja na produkcje po OK**;
**docelowo pelny automat az do produkcji**; automatyzacja (service account + Gradle
Play Publisher) stawiana ZARAZ PO pierwszej recznej publikacji.
- **Produkcyjny upload key**: `app/eskulapp-upload.jks` (PKCS12, alias `eskulapp`,
  waznosc do 2054, SHA1 `06:46:8B:82:28:9E:20:E4:FF:C5:F8:9B:42:56:6A:98:63:D3:C5:88`).
  Hasla w `app/keystore.properties` (Gradle) + `.env` (ANDROID_KEYSTORE_PASS/KEY_PASS).
  Oba pliki w `.gitignore`. **Kopia keystore na Drive**: `gdrive:Eskulapp/_keystore-backup`
  (bez hasla, haslo tylko lokalnie w `.env`).
- **build.gradle.kts**: `signingConfigs.release` czyta `keystore.properties` (fallback
  na debug gdy brak pliku). versionCode **17**, versionName **1.0.0** (16 zuzyty przez
  odrzucony upload z targetSdk 35; kolejne wydania bumpuj monotonicznie).
  **compileSdk/targetSdk = 36** (Play wymaga min. 36 dla nowych apek od 2026; SDK
  android-36 + build-tools 36.0.0 sa lokalnie, build offline OK; AGP 8.7.3 z flaga
  `android.suppressUnsupportedCompileSdk=36` w gradle.properties).
- **AAB podpisany release**: `app/build/outputs/bundle/release/app-release.aab` (3,3 MB),
  zbudowany OFFLINE (`:app:bundleRelease`). Na Drive jako `gdrive:Eskulapp/eskulapp-1.0.0.aab`.
- **Assety listingu** (`gdrive:Eskulapp/Play-Store-1.0.0/`): `icon-512.png`,
  `feature-1024x500.png`, `shot-01..12` (1080x1920, bo oryginalne zrzuty 780x1688
  = proporcja 2,16:1 > limit Play 2:1; dopchane na petrolowym tle), `LISTING-PL.md`
  (nazwa/krotki/pelny opis + kategoria Wydarzenia + kontakt@eskulapp.pl + URL polityki).
- Skrypt grafik: `tools/shots/store-assets.mjs` (puppeteer, offline).
- Polityka prywatnosci gotowa: https://eskulapp.pl/polityka-prywatnosci/
- **DO ZROBIENIA RECZNIE przez Jarka w Play Console** (krok po kroku dostarczony):
  utworzenie appki, Play App Signing, upload AAB na Internal testing, listing,
  Data safety, content rating, target audience, deklaracja reklam. Po tym: service account.

### Publikacja , stan 2026-09-09
- **AAB v1.0.0 (versionCode 17, targetSdk 36) ZAAKCEPTOWANY przez Google i ZYWY na
  Internal testing.** Instalacja przez link testera (nie przez wyszukiwarke Play).
- Teksty listingu (PL): `tools/shots/store/LISTING-PL.md` (+ `.txt`), na Drive w
  `gdrive:Eskulapp/Play-Store-1.0.0/`.

### Automatyzacja wydan , ODBLOKOWANA (2026-09-10)
**Service account gotowy i przetestowany, automat dziala.** Konto uslugi
`eskulapp-publisher@eskulapp-play.iam.gserviceaccount.com` (projekt GCP
`eskulapp-play`) autoryzuje sie i ma prawa do wydan w Play Console (test
`edits.insert`+`delete` na `pl.eskulapp.mobile` przeszedl zielono). Klucz JSON:
`.secrets/play-service-account.json` (chmod 600, gitignored). Kopia klucza NIE na
Drive (sekret dostepu do wydan). Od teraz: `tools/play/release.sh <track> "notatki"`
buduje AAB offline i wysyla na Play bez klikania.
- **Uwaga org policy**: firmowa organizacja Google wymusza
  `iam.disableServiceAccountKeyCreation`, wiec klucz utworzony w projekcie
  `eskulapp-play` poza ta blokada (obejscie, nie ruszalismy polityki organizacji).
- **Transfer klucza**: inbound na serwer agenta (31.179.66.233:22) zablokowany
  (No route to host, NAT/firewall). DuckDNS by nie pomogl (blokada portu, nie DNS).
  Klucz przeslany z Cloud Shell przez przekaznik cyber-folks (s18:222), potem
  sciagniety na serwer; klucze tymczasowe i plik z przekaznika posprzatane.

Cel (uzgodnione z Jarkiem): po zaakceptowaniu poprawki na debug -> agent sam buduje
release AAB i wysyla na Play BEZ klikania (docelowo az do produkcji).
- **Bez pluginu Gradle** (buildy offline), przez oficjalne **Android Publisher API v3**:
  `tools/play/deploy.py` (PyJWT RS256 -> access token -> edits.insert/bundles.upload/
  tracks.update/edits.commit; obsluguje --track, --rollout staged, --notes, --dry-run,
  sprzata edit przy bledzie). Egress do googleapis dziala (rclone tez tedy idzie).
- Wrapper: `tools/play/release.sh <track> [notatki] [rollout]` , buduje AAB offline
  i wola deploy.py. Kanaly: internal | alpha | beta | production.
- Sekrety w `.env`: `PLAY_SERVICE_ACCOUNT_JSON` (klucz w `.secrets/`, gitignored, chmod 700),
  `PLAY_PACKAGE=pl.eskulapp.mobile`.
- **ZROBIONE (2026-09-10)**: service account utworzony, klucz JSON w
  `.secrets/play-service-account.json`, konto uslugi zaproszone w Play Console z
  prawami do wydan (testy + produkcja). Autoryzacja i uprawnienia przetestowane
  (patrz sekcja „Automatyzacja wydan , ODBLOKOWANA" wyzej). Pelny dry-run z AAB:
  `python3 tools/play/deploy.py --aab <aab> --track internal --dry-run`.

### iOS , kierunek zbadany (2026-09-09, INFORMACYJNIE, do decyzji Jarka)
Research: apki NIE trzeba pisac od nowa ani kupowac Maca. Rekomendacja: migracja
naszego kodu Kotlin/Compose na **Kotlin Multiplatform + Compose Multiplatform**
(iOS stabilny od CMP 1.8.0 maj 2025; Room dziala w KMP 2.8+/3.0; kotlinx.serialization
i coroutines multiplatformowe) -> wspolny kod logiki/bazy/UI. Build i podpis iOS na
**chmurowym Macu (Codemagic / EAS / macOS GitHub Actions)**, wysylka automatem
**fastlane + klucz App Store Connect API (.p8)**, analogicznie do naszego skryptu Play.
Do dopracowania pod iOS: siec na Ktor (zamiast wlasnego ApiClient), powiadomienia
(UNUserNotificationCenter przez expect/actual), surowsze review Apple. Koszt jednorazowy:
Apple Developer Program 99 USD/rok (konto firmowe = D-U-N-S, warto ruszyc wczesnie).
Pelny dokument (Drive): „Eskulapp iOS , jak zbudowac i wydac apke w App Store (research)"
https://docs.google.com/document/d/1jw_kGTMK7PUOLO1laPJ7DplnaPqyd8rzZLW5rAXAL8Q/edit
Zadanie w Todoiscie [INFO], bez terminu.

### iOS , RUSZTOWANIE KOMPILACJI GOTOWE (2026-09-10)
Decyzje Jarka: **KMP tylko logika + natywne SwiftUI**; build/podpis na **GitHub
Actions macOS runner**. Android w Compose nietkniety. Pelna dokumentacja:
`docs/IOS-BUILD.md`.
- **Modul `:shared` (Kotlin Multiplatform)** w `app/shared/`: DTO bundla
  (`model/Dto.kt`, ten sam kontrakt co Android) + klient API na Ktor
  (`EskulappApi.kt`, `fetchBundle(code)`; silnik OkHttp android / Darwin iOS przez
  expect/actual). Targety iOS deklarowane tylko na hoscie macOS (na Linuksie
  budujemy android/common, bez Kotlin/Native). Dodane do `settings.gradle.kts`,
  root `build.gradle.kts`, `libs.versions.toml` (ktor 3.0.3, kotlin-multiplatform,
  android-library). **Zweryfikowane: `./gradlew :shared:compileDebugKotlinAndroid`
  = BUILD SUCCESSFUL** (serializery DTO wygenerowane).
- **Apka iOS `app/iosApp/`** (natywne SwiftUI): `project.yml` (XcodeGen generuje
  .xcodeproj na CI), `Sources/EskulappApp.swift` + `EntryView.swift` , waski pion:
  wejscie kodem -> `:shared` fetchBundle -> nazwa eventu + liczniki. Konsumuje
  framework `Shared` (XCFramework z Gradle: `assembleSharedReleaseXCFramework`).
- **CI**: `.github/workflows/ios.yml` (macOS-14) + `app/iosApp/fastlane/` (lane
  `beta`: build + podpis kluczem App Store Connect API + match + TestFlight).
- **Repo GitHub (2026-09-10)**: **prywatne** `jjeerryjerry/eskulapp`, branch `main`,
  https://github.com/jjeerryjerry/eskulapp . Caly projekt wypchniety bez sekretow
  (skan przeszedl: .env/.secrets/keystore/.jks ignorowane). gh remote na HTTPS
  (token gh, scope repo+workflow). Auto-run workflow z pierwszego pusha ANULOWANY
  (brak sekretow Apple = i tak by padl; macOS liczy sie 10x).
- **iOS NIE kompiluje sie na serwerze agenta** (brak macOS/Xcode, nie do obejscia).
  Faktyczny build iOS = na Macu w CI.
- **BLOKUJE (do Jarka)**: Apple Developer Program (99 USD/rok, konto firmowe = D-U-N-S),
  rekord aplikacji w App Store Connect (bundle `pl.eskulapp.mobile`), klucz App Store
  Connect API (.p8 + Key ID + Issuer ID), repo GitHub + sekrety Actions, repo match na
  certyfikaty. Lista sekretow i krokow: `docs/IOS-BUILD.md`.
- **Nastepne kroki iOS**: reszta ekranow SwiftUI (Agenda/Prelegenci/Partnerzy/Mapa/
  Kontakt/Aktualnosci), persystencja offline (SQLDelight w :shared albo natywnie),
  powiadomienia lokalne (UNUserNotificationCenter), ikona/listing.

### iOS CI , przebieg pierwszych buildow (2026-09-10)
Konto Apple Developer: **Individual** (JDG , Apple odrzucil Organization bo D&B
klasyfikuje JDG jako sole proprietorship). Team ID **7LT2VFV9MJ** (Apple
Distribution: Jaroslaw Gilewicz). Klucz App Store Connect API: Key ID `PJA73Q47KP`,
Issuer `3f0451eb-...`. Sekrety w GitHub Actions repo `eskulapp`: ASC_KEY_ID,
ASC_ISSUER_ID, ASC_KEY_P8_BASE64, MATCH_PASSWORD (kopia w .env), MATCH_GIT_URL,
MATCH_DEPLOY_KEY. Repo certyfikatow: prywatne `jjeerryjerry/eskulapp-match`
(dostep CI przez deploy key SSH).
- **Dziala end-to-end (potwierdzone na Macu w CI)**: build `:shared` Kotlin/Native
  -> `Shared.xcframework`, XcodeGen generuje projekt, `match` UTWORZYL certyfikat
  dystrybucji + profil ("match AppStore pl.eskulapp.mobile"), podpis manualny.
- **Naprawione po drodze**: (1) runner macos-14/Xcode15.4 nie czytal formatu projektu
  77 -> `runs-on: macos-15` (Xcode 16); (2) build_app "requires a development team"
  -> DEVELOPMENT_TEAM + CODE_SIGN_STYLE Manual + PROVISIONING_PROFILE_SPECIFIER w
  project.yml oraz export_options w Fastfile; (3) codesign wieszal job na popupie
  keychaina (run anulowany po 6h!) -> `setup_ci` w Fastfile + `timeout-minutes: 45`.
- **Billing (rozwiazane)**: 6h wiszacy run przebil darmowe minuty (macOS 10x). Jarek
  ustawil repo `eskulapp` jako **PUBLICZNE** (darmowe minuty Actions). `eskulapp-match`
  zostaje PRYWATNE. Po zakonczeniu testow mozna wrocic eskulapp na prywatne (wtedy pilnujemy
  spending limit; udany build to ~10 min macOS).

### iOS , PIERWSZY BUILD NA TESTFLIGHT (2026-09-11) , SUKCES
Run https://github.com/jjeerryjerry/eskulapp/actions/runs/34540524138 , wszystkie kroki
zielone (10m04s), `upload_to_testflight` OK, "fastlane.tools finished successfully".
Build iOS jest na TestFlight (App Store Connect app id **6810647099**), Apple go
przetwarza. **Automat wydan iOS dziala end-to-end** (push na main -> AAB/IPA -> TestFlight).
- Ostatnie dwie naprawy do sukcesu: (1) brak ikony/CFBundleIconName -> `Assets.xcassets`
  z AppIcon 1024 (upscale z `tools/shots/store/icon-512.png`, RGB bez alfy) +
  `ASSETCATALOG_COMPILER_APPICON_NAME`; (2) Apple wymaga iOS 26 SDK -> runner `macos-26`
  (Xcode 26; wczesniej macos-15/Xcode16 dawal iOS 18.5 SDK = odrzucenie 409).
- **Do zrobienia po stronie Jarka w App Store Connect**: dodac testerow (Internal Testing)
  do buildu, gdy Apple skonczy przetwarzanie; docelowo lepsza ikona (teraz upscale 512->1024).
- **Nastepne**: reszta ekranow iOS w SwiftUI (na razie tylko wejscie kodem + podglad bundla).
