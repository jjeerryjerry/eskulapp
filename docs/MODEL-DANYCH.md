# Model danych Eskulapp (wersja robocza)

> Schemat MySQL. **Uwzględnia decyzje Jarka 2026-08-18** (patrz `ARCHITEKTURA.md §0`):
> brak kont uczestników (app bez logowania), powiadomienia push planowane z CMS,
> moduł Aktualności. Wersjonowany w `web/db/migrations/`.

## Tożsamość — TYLKO organizatorzy (CMS)

> Uczestnicy **nie mają kont**. Jedyne konta = organizatorzy/admini panelu.

**organizers** — konta CMS
`id, email UNIQUE, password_hash, name, role(admin|organizer), created_at, updated_at`

**organizer_tokens** (jeśli JWT) — `id, organizer_id FK, token_hash, expires_at, revoked_at`

## Eventy i dostęp (po kodzie, bez konta)

**events**
| kolumna | typ | uwagi |
|---|---|---|
| id | BIGINT PK | |
| slug | VARCHAR UNIQUE | |
| name | VARCHAR | |
| access_code | VARCHAR(32) UNIQUE | **kod eventu**, np. `FND2027` |
| is_closed | TINYINT | zamknięte = wymaga kodu |
| starts_at, ends_at | DATETIME | sortowanie aktywne/archiwalne (po stronie apki) |
| venue_name, city | VARCHAR | |
| map_image_url | VARCHAR | mapa (plik z CMS) |
| map_embed | TEXT NULL | alternatywa |
| map_enabled | TINYINT | 0 = apka ukrywa Mapę |
| ratings_enabled | TINYINT DEFAULT 1 | oceny prelekcji włączone (SPEC-OCENY) |
| ratings_open_after_start_min | INT DEFAULT 10 | okno ocen od `starts_at` + N min |
| ratings_close_after_end_min | INT DEFAULT 30 | okno ocen do `ends_at` + N min |
| push_topic | VARCHAR | FCM topic, np. `event_<id>` |
| status | ENUM(draft,published,archived) | |
| updated_at | DATETIME | do delta-sync `?since=` |

> **Brak `event_members`** — nie ma kont uczestników. Powiązanie telefon↔event
> żyje **lokalnie na urządzeniu** (Room) + subskrypcja FCM topicu. Ewentualne
> zliczanie pobrań = anonimowy licznik, bez tożsamości.

## Treść eventu (CMS)

**event_days** `id, event_id FK, date, label, sort`
**rooms** `id, event_id FK, name, sort`
**talks** `id, event_id FK, day_id FK, room_id FK, title, abstract TEXT, starts_at, ends_at, sort`
**speakers** `id, event_id FK, first_name, last_name, title, photo_url, bio TEXT, sort`
**talk_speakers** `talk_id FK, speaker_id FK` (M:N)
**partners** `id, event_id FK, name, logo_url, description TEXT, tier, booth_location VARCHAR, website, sort`
**contacts** `id, event_id FK, label, name, phone, email, note`

## NOWE — Aktualności

**news** — aktualności eventu (zmiana prelegenta/sali, ogłoszenia, promocje)
| kolumna | typ | uwagi |
|---|---|---|
| id | BIGINT PK | |
| event_id | FK | |
| type | ENUM(prelegent, sala, ogloszenie, promocja) | ikona/kolor w apce |
| title | VARCHAR | |
| body | TEXT | |
| link_type | ENUM(none, talk, partner, url) NULL | opcjonalny cel |
| link_ref | VARCHAR NULL | id prelekcji/partnera lub URL |
| pinned | TINYINT | przypięte na górze |
| published_at | DATETIME | |
| push_sent | TINYINT | czy wypchnięto push |

## NOWE — Powiadomienia push (planowane / promocyjne)

**notifications** — kolejka/harmonogram push (wysyłka przez cron → FCM)
| kolumna | typ | uwagi |
|---|---|---|
| id | BIGINT PK | |
| event_id | FK | |
| type | ENUM(promo, zmiana, info) | |
| title | VARCHAR | |
| body | TEXT | |
| link_type | ENUM(none, talk, partner, url) NULL | np. stoisko partnera |
| link_ref | VARCHAR NULL | |
| audience | ENUM(all) DEFAULT all | segmentacja = faza późniejsza |
| scheduled_at | DATETIME | kiedy wysłać |
| sent_at | DATETIME NULL | |
| status | ENUM(draft, scheduled, sent, canceled) | |
| created_by | FK organizers | |

> Powiadomienie może być powiązane z wpisem **news** (opcjonalnie) — publikacja
> Aktualności może od razu utworzyć zaplanowany/natychmiastowy push.

## NOWE — Oceny prelekcji 1–10 (anonimowe, `docs/SPEC-OCENY.md`)

Migracja: `web/db/migrations/2026_09_ratings.sql` (idempotentna). Bez kont: tożsamość
głosującego = losowy `install_id` z telefonu, na serwerze tylko hash.

**talk_ratings** — jeden głos na urządzenie na prelekcję (upsert po `uq_talk_voter`)
| kolumna | typ | uwagi |
|---|---|---|
| id | BIGINT PK | |
| event_id | FK events (CASCADE) | |
| talk_id | FK talks (CASCADE) | UNIQUE (talk_id, voter_hash) |
| voter_hash | CHAR(64) | `sha256(install_id + RATING_SALT)`, surowego UUID nie ma |
| score | TINYINT UNSIGNED | 1..10 (walidacja w PHP) |
| created_at, updated_at | DATETIME | czas lokalny Europe/Warsaw (zegar serwera) |
| ip_hash | CHAR(64) NULL | hash IP do analizy nadużyć, nie surowe IP |

**rating_rate_hits** — rate-limit publicznego API ocen (okno przesuwne 10 min, UTC)
`id, scope ('ip'|'voter'), key_hash CHAR(64), created_at` — stare wpisy (> 1 doba)
sprząta samo API.

Okno oceniania liczy serwer (`Ratings::window()`), apki tylko dla UI. Wyniki (średnia,
mediana, rozkład, ranking prelegentów, CSV) widzi wyłącznie panel CMS.

## Kontakt / formularz WWW

**leads** — zgłoszenia z formularza „dla organizatora” na landingu
`id, name, email, org, message, event_hint, created_at, status(new|handled)`
> Adresata/obsługę konfiguruje organizator (do kogo mailem trafia lead). Pola
> formularza konfigurowalne — **[DO USTALENIA]** zakres.

## Bundle dla aplikacji (READ, publiczne)

`GET /public/events/{code}/bundle` → jeden JSON: event + days + rooms + talks +
speakers + partners + map + contacts + **news**, z `updated_at` (delta `?since=`).
Event w bundlu niesie też `ratings_enabled`, `ratings_open_after_start_min`,
`ratings_close_after_end_min` (głos idzie na `POST /api/public/events/{code}/talks/{id}/rating`,
nie na CDN).
Powiadomienia (**notifications**) NIE idą w bundlu — lecą przez FCM push; ich
„trwały ślad” w apce to zwykle odpowiadający wpis **news**.
