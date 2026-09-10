# Plan MVP Eskulapp

> Uwzględnia decyzje Jarka 2026-08-18 (`ARCHITEKTURA.md §0`): app bez logowania,
> push z CMS, Aktualności. Postęp: `state/STATUS.md`.

## Faza 0 — Fundament ✅
- [x] Agent, dokumentacja, toolchain Androida, dostęp do serwera.
- [x] **Branding (Faza A)** — zatwierdzony (logo E1, petrol+coral, Sora+Inter).
- [x] **WWW — kierunek wybrany: V3 Identyfikator.**
- [ ] **Projekt aplikacji (Faza C)** — w toku (Claude Design).

## Faza 1 — Backend: publiczne API po kodzie eventu
- [ ] Baza MySQL + migracje: `organizers`, `events`, treść eventu, `news`.
- [ ] `GET /public/events/{code}/bundle` (bez auth) + delta `?since=`.
- [ ] Deploy na subdomenę roboczą, HTTPS, smoke-test `curl`.

## Faza 2 — Aplikacja: kod → pobranie → offline (BEZ logowania)
- [ ] Projekt Gradle (Compose, MVVM, Room).
- [ ] Ekran wejścia: wpisz kod → pobierz bundle → zapis lokalny.
- [ ] Lista „Moje wydarzenia” (aktywne u góry, archiwalne wyszarzone) + „Dodaj kodem”.
- [ ] Ekran eventu + Agenda (dni, filtr sal). Podpisany APK do testu.

## Faza 3 — Moduły treści + Aktualności
- [ ] Prelegenci, Partnerzy (stoisko), Mapa, Kontakt.
- [ ] **Aktualności** (news feed) w apce + w CMS.
- [ ] Przypomnienia lokalne o prelekcjach (WorkManager).

## Faza 4 — Powiadomienia push (FCM) + harmonogram
- [ ] Projekt Firebase, `google-services.json`, subskrypcja topicu `event_<id>`.
- [ ] Backend → FCM HTTP v1 (klucz serwera w `.env`).
- [ ] CMS: kreator + **harmonogram powiadomień** (promo/zmiana/info, data wysyłki).
- [ ] Cron na serwerze wysyła zaplanowane.

## Faza 5 — WWW pełna + CMS + szlif
- [ ] Landing V3 (link do apki + **formularz kontaktu** dla organizatora + leads).
- [ ] Panel CMS: eventy/kody, edytor agendy, ludzie, partnerzy, mapa, Aktualności,
      powiadomienia.
- [ ] **Zrzuty ekranu z apki** na WWW.
- [ ] (Później) segmentacja push, iOS, sklep Google Play.

## Zasady
- Przyrostowo, interaktywnie; nie zamrażaj kwestii **[DO USTALENIA]** bez potrzeby.
- Aktualizuj `state/STATUS.md` po każdym większym kroku.
