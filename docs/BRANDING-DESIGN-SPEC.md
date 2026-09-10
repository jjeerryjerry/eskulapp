# Eskulapp — Specyfikacja brandingowo-projektowa (brief pod Claude Design)

> **Cel dokumentu:** kompletny brief do zaprojektowania w **Claude Design**
> najpierw **pełnego brandingu**, a następnie **strony WWW** i **widoków aplikacji**.
> Kolejność pracy: **(A) BRANDING → (B) WWW → (C) APP**. Sekcja A jest priorytetem
> i fundamentem dla B i C.
>
> Powiązane: `SPEC-ZRODLOWA.md` (wymagania), `ARCHITEKTURA.md`, `MODEL-DANYCH.md`.
> Wartości oznaczone **[wariant]** są do eksploracji na canvasie (2–3 kierunki).

---

## 0. Skrót dla projektanta (design canvas w 30 sekund)

- **Produkt:** Eskulapp — platforma + aplikacja dla **uczestników eventów i
  konferencji medycznych**. Konto centralne (SSO), w apce: profil, lista eventów,
  dołączanie kodem (np. `FND2027`), agenda, prelegenci, partnerzy, mapa, kontakt.
- **Odbiorca:** lekarze, pielęgniarki, farmaceuci, przedstawiciele branży med —
  ludzie **zajęci, wymagający, ceniący porządek i zaufanie**, używający apki „na
  sali", często przy słabym zasięgu (offline-first).
- **Odczucie marki:** *profesjonalna i godna zaufania jak medycyna, ale
  nowoczesna, klarowna i wygodna jak dobra aplikacja.* Klinicznie czysto, bez
  taniego marketingu.
- **Kotwica nazwy:** **Eskulap** = Asklepios, bóg medycyny; po polsku „eskulap" =
  lekarz. Symbol → **Laska Eskulapa** (jedna laska + jeden wąż). **UWAGA:** to NIE
  kaduceusz (dwa węże + skrzydła — to symbol handlu, częsty błąd w medycynie).

---

# A. BRANDING (priorytet)

## A1. Fundament marki

- **Esencja:** „Twój przewodnik po wydarzeniu medycznym."
- **Obietnica:** cała konferencja w kieszeni — uporządkowana, zawsze pod ręką,
  działa nawet bez zasięgu.
- **Pozycjonowanie:** profesjonalne, zaufane narzędzie dla środowiska medycznego;
  nowoczesna alternatywa dla papierowych programów i chaotycznych PDF-ów.
- **Osobowość (archetyp: Mędrzec + Opiekun):** kompetentny, uporządkowany,
  spokojny, pomocny. Nie krzykliwy, nie „startupowo-zabawowy".
- **Wartości:** zaufanie · klarowność · rzetelność · nowoczesność · szacunek dla
  czasu użytkownika.

### Ton głosu
Rzeczowy, klarowny, uprzejmy. Krótkie zdania. Zero żargonu marketingowego i zero
medycznego przeciążenia. Szanuje czas zajętego profesjonalisty.

| Mówimy | Nie mówimy |
|---|---|
| „Twoja agenda na dziś" | „Odjazdowy harmonogram!" |
| „Dołącz do wydarzenia kodem" | „Odblokuj magiczny event 🎉" |
| „Brak zasięgu? Program działa offline." | „Rewolucyjna technologia synchronizacji" |

## A2. Logo i system znaku

Zaprojektuj **system**, nie jeden plik:

1. **Sygnet (symbol):** zminimalizowana **Laska Eskulapa** — pojedynczy pionowy
   element z owiniętym wężem, geometryczny, czysty. Kierunki do eksploracji:
   - **[wariant 1]** laska stylizowana na literę **„E"** (wąż tworzy zawijasy E),
   - **[wariant 2]** laska = **pinezka/marker lokalizacji** (event + mapa),
   - **[wariant 3]** laska wpisana w **zaokrąglony kwadrat** (gotowy app-icon).
   Wąż uproszczony do 1–2 płynnych łuków; unikać dosłownej „gadziny" — ma być
   ikoniczny i przyjazny, nie kliniczny-straszny.
2. **Wordmark:** „Eskulapp" — font nagłówkowy (patrz A4), lekko dociśnięty
   tracking, „app" może być subtelnie wyróżnione (kolor akcentu lub waga).
3. **Lockupy:** poziomy (sygnet + wordmark), pionowy (sygnet nad wordmarkiem),
   sam sygnet, **app icon** (sygnet na petrolu).
4. **Warianty kolorystyczne:** pełny kolor, mono-ciemny (ink), mono-jasny (na
   ciemnym tle / zdjęciu).
5. **Zasady:** pole ochronne (= wysokość „E"), min. rozmiar (sygnet 24 px, wordmark
   96 px), **misuse** (nie rozciągać, nie zmieniać kolorów, nie dodawać cienia, nie
   używać kaduceusza).

## A3. Kolory (z tokenami i kontrastem)

Paleta: **zaufanie (petrol/teal) + klarowność (neutrale) + ciepły akcent (coral)**.
Coral „ociepla" chłodną medyczną biel i prowadzi wzrok (CTA, „na żywo").

| Rola | Token | HEX | Uwaga a11y |
|---|---|---|---|
| Marka / primary | `brand-700` | `#0C5A63` | biały tekst OK (~6.9:1) — CTA, logo |
| Marka ciemny | `brand-900` | `#08363B` | ciemne tła, hover |
| Marka jasny | `brand-100` | `#D7EAEC` | tła sekcji, chipy |
| Ink / tekst | `ink-900` | `#0A1B2A` | tekst główny, nagłówki |
| Tekst 2. rzędu | `ink-500` | `#5B6B72` | podpisy, meta |
| Akcent / CTA-2 / „live" | `coral-500` | `#FF6B57` | **tekst na coralu = ink, nie biały** |
| Akcent głęboki | `coral-700` | `#D9503B` | gdy potrzebny biały tekst na coralu |
| Tło | `bg` | `#F6F8F9` | |
| Powierzchnia | `surface` | `#FFFFFF` | karty |
| Obramowanie | `border` | `#E1E7E9` | |
| Sukces | `success` | `#1E9E6A` | |
| Ostrzeżenie | `warning` | `#E8A21C` | |
| Błąd | `danger` | `#D64545` | |
| **Archiwalny event** | `muted` | `#9AA7AD` | wyszarzenie kart zakończonych |

Zasady: **primary button = petrol** (biały tekst, bezpieczny kontrast). **Coral =
akcent** (badge „NA ŻYWO", podkreślenia, secondary CTA) — na wypełnieniu coralowym
tekst **ink**, na coral-700 może być biały. Dark mode: tła `ink-900`/`brand-900`,
powierzchnie podniesione o ~6–8% jasności, teksty odwrócone; sprawdź kontrasty.

**[wariant palety]** alternatywa „indigo": primary `#3B4CCA`/`#2A2F8F` zamiast
petrolu — bardziej „tech", mniej „health". Zrób 1 artboard porównawczy.

## A4. Typografia

- **Nagłówki / display:** **Sora** *(alt: Plus Jakarta Sans)* — nowoczesny,
  zdecydowany, z charakterem. Wagi 600/700.
- **UI / tekst / agenda:** **Inter** — wzorcowa czytelność w gęstych listach.
  Wagi 400/500/600; **tabular figures** dla godzin i dat.
- Oba z **Google Fonts** (działa w artefaktach Claude).
- **Skala (web, rem):** H1 3.0 · H2 2.25 · H3 1.75 · H4 1.375 · body 1.0 · small
  0.875 · caption 0.75. Line-height 1.2 nagłówki / 1.55 tekst.
- **Skala (app, sp):** Title 22 · Section 18 · Body 15 · Label 13 · Caption 11.

## A5. Ikony, komponenty, motyw wizualny

- **Ikony:** linia, stroke ~1.75 px, zaokrąglone końce, spójny zestaw
  (styl Lucide). Osobny piktogram dla każdego modułu: Agenda, Prelegenci,
  Partnerzy, Mapa, Kontakt.
- **Zaokrąglenia:** radius 12 px (karty), 8 px (inputy/chipy), 999 px (pill/badge).
- **Cień:** miękki, niski (`0 2px 8px rgba(10,27,42,.06)`), bez dramatu.
- **Komponenty do zaprojektowania (design system):** przyciski (primary/secondary/
  ghost), pola formularza + stany, chip/tag, **badge statusu** („NA ŻYWO" coral,
  „NADCHODZI" teal, „ARCHIWALNY" muted), karta eventu, karta prelekcji, karta
  prelegenta, karta partnera, tab bar (mobile), top bar, pusty stan, toast.
- **Motyw graficzny:** subtelny wątek „**węzła/połączenia**" lub „**siatki
  agendy**" jako tekstura tła sekcji — delikatny, nie dominujący.
- **Zdjęcia:** realne, ludzkie ujęcia z konferencji (ciepłe, nie sterylne
  stocki); duotone w petrolu jako spójnik.

---

# B. STRONA WWW (platforma webowa) — kierunek: V3 „Identyfikator”

Desktop-first + responsywność. Ekrany do zaprojektowania:

1. **Landing / marketing (V3 Identyfikator)** — hero z motywem cyfrowego
   identyfikatora; **obowiązkowo: link do pobrania aplikacji** (główne CTA) i
   **link do kontaktu / formularz dla organizatora**. Sekcje: dla uczestnika, dla
   organizatora, moduły, zaufanie/RODO, stopka. **Miejsce na zrzuty z apki**
   (placeholder do czasu zbudowania aplikacji). **Bez logowania uczestnika.**
2. **Formularz kontaktu (dla organizatora)** — zgłoszenie wdrożenia eventu; pola
   konfigurowalne przez organizatora, zapis jako `leads`.
3. **Panel CMS (organizator, desktop)** — kluczowe widoki:
   - lista eventów + „nowy event” + generowanie **kodu dostępu**,
   - **edytor agendy** (dni, sale/sceny, prelekcje — drag/sort),
   - prelegenci i partnerzy (z lokalizacją stoiska), mapa, kontakt,
   - **Aktualności** (news) + **kreator/harmonogram powiadomień push** (promo/zmiany).
   Ton: gęsty, funkcjonalny, tabelaryczny, ale spójny z brandingiem.

---

# C. APLIKACJA (Android, potem iOS) — offline-first, BEZ logowania

> **Zmiana modelu (Jarek 2026-08-18, `ARCHITEKTURA.md §0`):** aplikacja **nie ma
> logowania uczestnika**. Wpisujesz **kod eventu** → dane pobierają się **lokalnie
> na telefon**. Doszedł moduł **Aktualności** i **powiadomienia push** (planowane z
> CMS). Zrzuty ekranu z apki trafią na WWW po zbudowaniu.

Material 3 dostrojony do brandingu. Widoki:

1. **Wejście kodem (onboarding, bez logowania)** — pieczęć E1, „Wpisz kod
   wydarzenia” (np. `FND2027`), przycisk „Pobierz wydarzenie”, nota „bez konta —
   dane zapiszą się na telefonie”.
2. **Moje wydarzenia** — lista eventów pobranych lokalnie: aktywne/nadchodzące u
   góry, **archiwalne wyszarzone na dole**; przycisk **„Dodaj kodem”**.
3. **Ekran eventu** — nazwa/daty, **baner Aktualności** (np. „zmiana sali”), siatka
   modułów (Agenda/Prelegenci/Partnerzy/Mapa/Kontakt/Aktualności), dolny pasek nawigacji.
4. **Agenda** — **dni** (taby), **filtr po salach**, kafelki prelekcji z godziną
   (tabular figures), ikona **przypomnienia (dzwonek, lokalne)**, badge „NA ŻYWO”.
5. **Szczegół prelekcji + Prelegent** — tytuł, czas, sala, abstrakt, prelegenci
   (zdjęcie, tytuł, bio); „Przypomnij”.
6. **Aktualności** — feed komunikatów (zmiana prelegenta/sali, ogłoszenia,
   **promocja partnera** np. „zaproszenie na stoisko”); typy z kolorem/ikoną;
   przykład **powiadomienia push** (promo).
7. **Partnerzy / Mapa / Kontakt** — partnerzy z **lokalizacją stoiska**, mapa
   (zoom/pan), dane kontaktowe organizatora.
8. **Stany:** offline (baner „tryb offline — dane z pamięci”), pusty, ładowanie.

---

## D. Plan artboardów na canvasie (kolejność)

**Faza A — Branding (najpierw):**
A1 Okładka/esencja · A2 Logo + lockupy + app icon · A3 Paleta (tokeny + kontrast +
wariant indigo) · A4 Typografia · A5 Ikony + komponenty (design system) · A6 Ton
głosu (do/don't).

**Faza B — WWW:** B1 Landing · B2 Auth · B3 CMS (2–3 kluczowe widoki).

**Faza C — App:** C1 Logowanie · C2 Dashboard/lista eventów · C3 Ekran eventu ·
C4 Agenda · C5 Szczegół prelekcji + Prelegent · C6 Partnerzy/Mapa/Kontakt.

> Rekomendacja realizacji: **najpierw Faza A** (zatwierdzić znak, paletę, typo,
> komponenty), dopiero potem B i C — żeby WWW i apka dziedziczyły spójny system,
> a nie odwrotnie.
