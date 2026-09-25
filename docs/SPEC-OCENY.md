# SPEC — Oceny prelekcji 1–10 (anonimowe)

_Decyzja Jarka 2026-09-25. Zakres: tylko oceny (bez grywalizacji, bez komentarzy tekstowych)._

## 1. Zasady produktowe
- Uczestnik ocenia prelekcję w skali **1–10** (liczby całkowite). Bez komentarzy tekstowych.
- **Anonimowo**: apka nadal działa bez logowania. Tożsamość oceniającego = losowy
  **install_id** (UUID v4 generowany przy pierwszym uruchomieniu, trzymany lokalnie,
  nigdy nie łączony z żadnymi danymi osobowymi). Serwer przechowuje wyłącznie
  **hash** `sha256(install_id + RATING_SALT)`, nie surowy UUID.
- **Okno oceniania**: otwiera się **10 min po starcie** prelekcji (`starts_at + 10 min`)
  i zamyka **30 min po jej końcu** (`ends_at + 30 min`). Poza oknem: brak możliwości
  oddania głosu (w apce przycisk nieaktywny z informacją, kiedy się otworzy / że się zamknęło).
- Jeden głos na urządzenie na prelekcję. **W oknie można zmienić ocenę** (nadpisanie, upsert).
- Prelekcja bez `starts_at` lub `ends_at` = nieoceniana.
- Organizator/admin może wyłączyć oceny dla całego eventu (przełącznik w CMS).
- Wyniki widzi tylko admin/organizator w CMS. **Uczestnik nie widzi średnich.**

## 2. Czas
- `talks.starts_at/ends_at` to `DATETIME` bez strefy, w **czasie lokalnym Europe/Warsaw**.
- Serwer liczy okno w `Europe/Warsaw` (jawnie, `DateTimeImmutable` z `DateTimeZone`),
  nie polega na strefie hostingu ani MySQL.
- Apka liczy okno lokalnie (UI), ale **serwer jest jedynym źródłem prawdy** — odrzuca
  głosy spoza okna. Liczy się wyłącznie czas serwera w chwili przyjęcia głosu
  (zegar telefonu i ewentualny `client_ts` są ignorowane). Skutki dla trybu offline: §5.

## 3. Baza (MySQL) — nowa migracja
Dodaj `web/db/migrations/2026_09_ratings.sql` (idempotentna, `IF NOT EXISTS`) i dopisz to samo do `schema.sql`.

```sql
ALTER TABLE events
  ADD COLUMN ratings_enabled TINYINT NOT NULL DEFAULT 1,
  ADD COLUMN ratings_open_after_start_min INT NOT NULL DEFAULT 10,
  ADD COLUMN ratings_close_after_end_min  INT NOT NULL DEFAULT 30;

CREATE TABLE IF NOT EXISTS talk_ratings (
  id          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  event_id    BIGINT UNSIGNED NOT NULL,
  talk_id     BIGINT UNSIGNED NOT NULL,
  voter_hash  CHAR(64) NOT NULL,
  score       TINYINT UNSIGNED NOT NULL,          -- 1..10, CHECK w PHP
  created_at  DATETIME NOT NULL,
  updated_at  DATETIME NOT NULL,
  ip_hash     CHAR(64) NULL,                      -- do rate-limitu/analizy nadużyć, nie surowe IP
  PRIMARY KEY (id),
  UNIQUE KEY uq_talk_voter (talk_id, voter_hash),
  KEY idx_ratings_event (event_id),
  CONSTRAINT fk_tr_event FOREIGN KEY (event_id) REFERENCES events(id) ON DELETE CASCADE,
  CONSTRAINT fk_tr_talk  FOREIGN KEY (talk_id)  REFERENCES talks(id)  ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```
Okna są konfigurowalne per event (domyślnie 10/30), żeby nie trzeba było zmieniać kodu.

## 4. API (czysty PHP 8.2, `web/cms/_app/router.php`, gałąź `BASE === '/api'`)
Styl jak istniejący `/lead`: bez frameworka, `json_out()`, prepared statements, `client_ip()`.

**`POST /api/public/events/{code}/talks/{talkId}/rating`** — body JSON:
`{"install_id":"<uuid v4>","score":7}`
- Walidacja: event istnieje, `status=published`, `ratings_enabled=1`; talk należy do eventu;
  `score` int 1..10; `install_id` poprawny UUID v4.
- Okno czasowe wg §1–2, inaczej `409 {"error":"window_closed"|"window_not_open","opens_at"|"closed_at":...}`.
- Upsert `INSERT ... ON DUPLICATE KEY UPDATE score=VALUES(score), updated_at=NOW()`.
- Odpowiedź `200 {"ok":true,"score":7}`.
- **Rate-limit**: per `ip_hash` np. 60 głosów / 10 min, per `voter_hash` 30 / 10 min
  (reużyj mechanizmu z `security.php`, jeśli pasuje; w przeciwnym razie prosta tabela/APCu). `429` przy przekroczeniu.
- Bez CORS dla przeglądarek (klient to apka natywna); nie wystawiaj GET z wynikami publicznie.

**`GET /api/public/events/{code}/ratings/mine?install_id=...`** — zwraca oceny tego urządzenia
(`[{talk_id, score}]`), żeby apka mogła odtworzyć stan po wyczyszczeniu lokalnej bazy przy zachowanym install_id.
Reinstalacja = nowy install_id = nowy głosujący; to akceptujemy. Endpoint opcjonalny, rate-limit jak wyżej.

**Bundle / CDN:** dodaj do eventu w bundlu pola `ratings_enabled`, `ratings_open_after_start_min`,
`ratings_close_after_end_min` (`Bundle.php` + `scripts/bake-bundle.sh`, jeśli bake mapuje pola jawnie).
Apka czyta je z bundla z CDN; zapis głosu idzie na `https://eskulapp.pl/api` (nie CDN).

## 5. Aplikacja — Android (Kotlin/Compose) i iOS (SwiftUI) — obie platformy
- **install_id**: Android `DataStore`/`SharedPreferences`, iOS `UserDefaults` (nie Keychain —
  ma znikać z odinstalowaniem). Generowany raz.
- **Ekran prelekcji** (`TalkScreen.kt` / odpowiednik w `Agenda.swift`): sekcja „Oceń wykład”,
  10 przycisków/kropli 1–10 (kolorystyka marki: petrol/coral, patrz `BRANDING-DESIGN-SPEC.md`).
  Stany: _jeszcze nieaktywne_ („Ocena od HH:MM”), _aktywne_, _oceniono (N) — możesz zmienić do HH:MM_,
  _zamknięte_. Bez średnich.
- **Offline-first**: głos zapisywany lokalnie (Android: nowa encja Room + migracja wersji 4→5;
  iOS: lokalny store jak reszta w `Store.swift`) ze statusem `pending`, wysyłany natychmiast albo
  po odzyskaniu sieci (Android `WorkManager`, jest już `ReminderWorker` jako wzorzec).
  Głos oddany offline w oknie, ale dosłany po zamknięciu okna, serwer odrzuci (409) —
  **akceptujemy to**, apka pokazuje „nie udało się zapisać, okno zamknięte”. Nie ufamy `client_ts`.
- Opcjonalnie: lokalne przypomnienie „Oceń wykład” przy otwarciu okna dla prelekcji
  dodanych do „Mojego planu” (jeśli taki mechanizm istnieje w `reminders/`). Jeśli wymaga to
  nowej zgody na powiadomienia, pomiń.
- Teksty bez strzałek i długich myślników (zasada marki).

## 6. CMS (panel admina, `/panel`)
- W formularzu eventu (`event_form.php`): przełącznik „Oceny prelekcji” + dwa pola minut (10/30).
- Nowy widok **„Oceny”** per event: tabela prelekcji z kolumnami: tytuł, prelegenci, sala, dzień,
  **liczba głosów, średnia (1 miejsce po przecinku), mediana, rozkład 1–10** (mini-histogram CSS),
  sortowanie po średniej/liczbie głosów. Drugi widok/zakładka: **ranking prelegentów**
  (średnia ważona liczbą głosów z ich prelekcji).
- Prelekcje z < 5 głosami oznacz „mała próba” (nie ukrywaj).
- **Eksport CSV** (UTF-8 z BOM, `;` jako separator — Excel PL).
- Zabezpieczenia jak reszta panelu: sesja, CSRF przy zmianach, `e()` przy wypisywaniu.

## 7. Testy i jakość
- PHP: lekkie testy bez composera (`web/tests/ratings_test.php` uruchamiany `php`), pokrywające:
  walidację score, okno czasowe (granice: start+9:59 odrzuca, start+10:00 przyjmuje,
  end+30:00 przyjmuje, end+30:01 odrzuca), strefę Europe/Warsaw (także zmiana czasu),
  upsert, event z wyłączonymi ocenami, talk z innego eventu.
  Logikę okna wydziel do czystej funkcji (`Ratings::window()`), żeby testować bez DB.
- Android: testy jednostkowe logiki okna (JVM) + `./gradlew assembleDebug` przechodzi.
- iOS: logika okna jako czysta funkcja; kompilacja sprawdzana w CI (workflow iOS istnieje).
- Nie ruszaj podpisywania, keystore, `keystore.properties`, fastlane `match`, sekretów.

## 8. Poza zakresem (świadomie)
Grywalizacja, komentarze tekstowe, publiczne wyniki dla uczestników, logowanie uczestników,
powiadomienia push o ocenach z CMS.

## 9. Wdrożenie (NIE w sesji chmurowej — robi lokalnie agent eskulapp po akceptacji Jarka)
1. Migracja SQL na `jjeerry_eskulapp` (backup przed). 2. `RATING_SALT` do `web/cms/_app/.env` na serwerze.
3. `scripts/deploy-web.sh`. 4. `scripts/bake-bundle.sh` dla eventów. 5. Buildy release Android/iOS i publikacja.
