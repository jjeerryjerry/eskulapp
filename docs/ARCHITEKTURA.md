# Architektura Eskulapp — decyzje wdrożeniowe

> Wymagania bazowe: `SPEC-ZRODLOWA.md`. Tu są **decyzje techniczne**. Sekcja §0
> zawiera **decyzje nadrzędne Jarka** — mają priorytet nad specyfikacją źródłową,
> gdy się różnią.

## 0. Decyzje nadrzędne (Jarek, 2026-08-18) — MAJĄ PIERWSZEŃSTWO

1. **Aplikacja NIE wymaga logowania po stronie uczestnika.** Użytkownik pobiera
   apkę, wpisuje **kod eventu** (np. `FND2027`), a dane wydarzenia **pobierają się
   lokalnie na telefon** (offline-first). Brak kont uczestników, brak SSO dla
   uczestnika. ⇒ **To zmienia pierwotną specyfikację** (która zakładała centralne
   logowanie/SSO uczestnika — pkt 1.1/1.2 spec). Logowanie zostaje **tylko dla
   organizatora** (panel CMS).
2. **Powiadomienia push — w tym „specjalne/promocyjne”** (np. zaproszenie na
   stoisko partnera), **planowane z poziomu CMS** (data/godzina wysyłki).
3. **Moduł „Aktualności”** w aplikacji — komunikaty typu: zmiana prelegenta,
   zmiana sali, opóźnienia, ważne ogłoszenia. Pobierane z danymi eventu + mogą
   wyzwalać powiadomienie push.
4. **Strona główna WWW** musi mieć: **link do pobrania aplikacji** oraz **link do
   kontaktu (formularz)** — formularz do wypełnienia/konfiguracji przez
   organizatora eventu. Kierunek wizualny WWW: **V3 „Identyfikator”**.
5. **Zrzuty ekranu z aplikacji** dodamy na WWW, gdy aplikacja powstanie.

## 1. Trzy komponenty

```
        ┌──────────────────────────────────────────┐
        │  BACKEND (PHP + MySQL, cyber-folks)       │
        │  • publiczne READ API po KODZIE eventu    │  ← uczestnik bez konta
        │  • CMS API (auth organizatora)            │
        │  • planowanie powiadomień → FCM           │
        └───────┬───────────────────────┬──────────┘
                │ bundle po kodzie       │ auth (organizator)
     ┌──────────▼─────────┐    ┌─────────▼──────────┐
     │  Aplikacja Android │    │  WWW: landing +    │
     │  (bez logowania)   │    │  Panel CMS         │
     │  dane lokalnie/Room│    └────────────────────┘
     │  + push (FCM topic)│
     └────────────────────┘
```

- **Aplikacja mobilna (Android, potem iOS)** — bez logowania uczestnika. Kod
  eventu → pobranie „bundla” → zapis lokalny (Room) → subskrypcja powiadomień
  eventu. Moduły: Agenda, Prelegenci, Partnerzy, Mapa, Kontakt, **Aktualności**.
- **Platforma Webowa** — landing (V3 Identyfikator: link do apki + formularz
  kontaktu) + **Panel CMS** dla organizatora.
- **Backend** — publiczne READ API po kodzie eventu (bez auth), CMS API (auth
  organizatora), integracja z **FCM** do wysyłki/harmonogramu powiadomień.

## 2. Hosting i stack backendu — narzucony przez serwer

Serwer = **cyber-folks / `edu-serwer` (s18.cyber-folks.pl:222)** — tam gdzie
`jerrymarketing.pl`/`cukrzyca.*`. **PHP 8.2 + MySQL + wp-cli; BRAK Node.js.**
⇒ **Backend = PHP 8.2 + MySQL**, REST API (JSON).

- **Framework:** Slim 4 (domyślnie) lub czysty PHP; `composer` lokalnie → `vendor/`
  na serwer. **[DO USTALENIA]**
- **Auth (tylko organizator/CMS):** sesja PHP lub JWT + `password_hash`. Uczestnik
  BEZ auth.
- **Push:** **Firebase Cloud Messaging (FCM)** — darmowy, zewnętrzny. Backend woła
  FCM HTTP v1 API **kluczem serwera** (w `.env`). Model adresowania: **topic per
  event** (`event_<id>`) — telefon subskrybuje topic po wpisaniu kodu, bez
  tożsamości użytkownika. Harmonogram: rekord powiadomienia + **cron** na serwerze
  (cyber-folks cron / wp-cron-like) wysyła zaplanowane o właściwej godzinie.
- **Domena/subdomena:** **[DO USTALENIA]**; do czasu decyzji subdomena robocza.

## 3. Przepływ aplikacji (bez logowania)

1. Pobranie aplikacji (link z WWW / sklep).
2. **Wpisanie kodu eventu** (np. `FND2027`) → `GET /public/events/{code}/bundle`
   (bez auth) → komplet: event, dni, sale, prelekcje, prelegenci, partnerzy, mapa,
   kontakt, **aktualności**. Zapis do **Room** (SQLite) — działa offline.
3. **Subskrypcja powiadomień**: telefon subskrybuje FCM topic `event_<id>`.
4. **Synchronizacja**: apka odpytuje `?since=<updated_at>` (delta) przy starcie /
   pull-to-refresh; push wyzwala odświeżenie (np. nowa Aktualność / zmiana sali).
5. Wiele eventów lokalnie naraz (lista: aktywne u góry, archiwalne wyszarzone).

**Brak danych osobowych uczestnika po stronie serwera** (nie ma kont) — to
upraszcza RODO. Ewentualne przypomnienia o prelekcjach = **lokalne** (WorkManager),
niezależne od push.

## 4. Powiadomienia i Aktualności (CMS)

- **Aktualności (news)** — organizator publikuje wpis (typ: zmiana prelegenta /
  zmiana sali / ogłoszenie / promocja). Trafia do bundla eventu (widoczne w apce)
  i **opcjonalnie** wypycha push do topicu eventu.
- **Powiadomienia zaplanowane / promocyjne** — osobny obiekt: treść, typ
  (promo/zmiana/info), **czas wysyłki** (harmonogram), ewentualny link (np.
  stoisko partnera / prelekcja). Status: szkic → zaplanowane → wysłane / anulowane.
  Wysyłkę realizuje cron backendu przez FCM.
- Adresowanie w MVP: **cały event** (topic). Segmentacja (np. tylko zainteresowani
  daną salą) — faza późniejsza **[DO USTALENIA]**.

## 5. Aplikacja mobilna (Android — pierwsza)

- **Kotlin + Jetpack Compose (Material 3)**, MVVM + repository, **offline-first**
  (Room). Sieć: Retrofit/Ktor + `kotlinx.serialization`.
- **FCM SDK** do odbioru push; przypomnienia o prelekcjach = lokalne (WorkManager).
- Toolchain buildów = wspólny z `aapsbuilder`/`foodvision` (`~/jdk17`,
  `~/android-sdk`, `./gradlew`) — **nie instaluj od zera**. Własny nowy keystore.
- **Package [DO USTALENIA]:** `pl.eskulapp.mobile`.
- **Konfiguracja Firebase** (`google-services.json`) — załóż projekt FCM; klucz
  serwera po stronie backendu (nie w APK).

## 6. Strona WWW (kierunek: V3 Identyfikator)

- **Landing** musi zawierać: **link do pobrania aplikacji** (hero CTA) i **link do
  kontaktu / formularz** (dla organizatora zainteresowanego wdrożeniem eventu).
- Formularz kontaktu — pola konfigurowalne/obsługiwane przez organizatora (do
  kogo trafia zgłoszenie). Sekcje: dla uczestnika, dla organizatora, moduły,
  zaufanie/RODO, stopka.
- **Zrzuty ekranu z apki** — dodane po zbudowaniu aplikacji (placeholdery na razie).
- **Panel CMS (organizator, desktop):** eventy + kod dostępu, edytor agendy (dni/
  sale/prelekcje), prelegenci, partnerzy (stoisko), mapa, kontakt, **Aktualności**
  i **kreator/harmonogram powiadomień** (promo/zmiany).

## 7. iOS — faza późniejsza
Natywny (SwiftUI) lub KMP **[DO USTALENIA]**. Na tym serwerze nie budujemy iOS.

## 8. Otwarte kwestie
- [ ] domena/subdomena · Slim 4 vs czysty PHP · package name
- [ ] segmentacja powiadomień (poza „cały event”)
- [ ] mechanizm harmonogramu (cron cyber-folks) — szczegóły
- [ ] czy kody eventów mogą być prywatne/jednorazowe vs współdzielone
