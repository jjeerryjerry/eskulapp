# Notatka po spotkaniu z agencją (2026-10-14)

Surowa notatka Jarka:

```
sesja / wyklady -> prelegent / sesje - powiadmienia
konflikty czasowe
merytoryczna icena/ocena 3 pytania
kod qr
dane organizatora

- meta ds. + budżet ads + animacja na miejscu.
```

## Rozpisanie na zadania (vs stan apki 1.3.0)

| # | Punkt | Co już jest | Luka / do zrobienia | Decyzja Jarka |
|---|---|---|---|---|
| 1 | **Sesje i wykłady, prelegent i jego sesje, powiadomienia** | Prelekcje płasko w agendzie, prelegent ma listę swoich wystąpień (`SpeakerDetail`), przypomnienia lokalne per prelekcja | Brak bytu **sesja** (blok tematyczny z tytułem, moderatorem, salą, kilkoma wykładami). Nowa tabela `sessions` + `talks.session_id`, widok sesji w agendzie, przypomnienie na całą sesję, w profilu prelegenta podział na sesje (moderuje / wykłada) | Czy sesja ma moderatora/przewodniczącego? Przypomnienie per sesja, per wykład czy oba? |
| 2 | **Konflikty czasowe** | Przypomnienia lokalne | Przy włączaniu przypomnienia sprawdzenie nakładania się z innymi zaznaczonymi prelekcjami/sesjami i ostrzeżenie („Masz w tym czasie: X, sala Y”). Opcjonalnie widok „Mój plan” z oznaczonymi kolizjami. Tylko po stronie apki, bez backendu | Samo ostrzeżenie czy też osobny ekran „Mój plan”? |
| 3 | **Ocena merytoryczna: 3 pytania** | Ocena 1 do 10, jedna liczba, anonimowa (`SPEC-OCENY.md`) | Zmiana na **3 pytania** na prelekcję. Rozszerzenie `talk_ratings` o 3 kolumny (lub tabela odpowiedzi), API, UI w obu apkach, wyniki w CMS per pytanie | Treść 3 pytań, skala (1 do 10 czy 1 do 5), czy pytania stałe czy ustawiane per event w CMS. Czy ocena sesji, czy każdego wykładu? |
| 4 | **Kod QR** | Dołączanie wpisaniem kodu (np. FND2027) | Najbardziej prawdopodobnie: **QR zamiast wpisywania kodu** (skan aparatem, deep link `eskulapp.pl/e/FND2027` otwiera apkę albo sklep). W CMS generator QR do druku (plakat, identyfikator, roll-up) | Potwierdzić znaczenie: dołączanie do eventu? Czy też QR do check-inu / potwierdzenia obecności (np. punkty edukacyjne)? |
| 5 | **Dane organizatora** | Moduł Kontakt (tel/mail/www/adres) | Do ustalenia zakres: pełne dane firmy organizatora (nazwa, NIP, logo, regulamin), administrator danych RODO, ewentualnie dane w stopce eventu | Co dokładnie agencja chce widzieć i gdzie (apka, CMS, faktura/oferta)? |
| 6 | **Meta Ads + budżet ads + animacja na miejscu** | n/d | Część **ofertowa / marketingowa**, nie programistyczna: pakiet promocji eventu w Meta (kampania + budżet mediowy) oraz animacja na miejscu (zachęcanie do pobrania apki, QR na stanowisku). Do wyceny w ofercie, ewentualnie zlecenie agentowi `metaads` | Czy to element pakietu sprzedażowego Eskulapp? |

## Proponowana kolejność (pierwsza runda, nieaktualna, patrz niżej)
1. Kod QR do dołączania (mały zakres, duży efekt na miejscu, spina się z animacją).
2. Konflikty czasowe (tylko apka, bez backendu).
3. Ocena 3 pytania (migracja DB + API + obie apki + CMS).
4. Sesje (największy zakres: model danych, CMS, agenda, seedy).
5. Dane organizatora wg ustaleń.

## Decyzje Jarka (2026-10-14, druga runda)

- **QR = check-in** (potwierdzenie obecności), **na przyszłość**, nie teraz.
  Dołączanie do eventu zostaje przez wpisanie kodu.
- **Ocena:** 3 pytania o wystąpienie + 3 pytania o jakość. Propozycja treści poniżej,
  czeka na akceptację.
- **Sesja:** ma **moderatora** i **podwykłady**. Przypomnienia **dla sesji i dla
  każdego podwykładu** (oba).
- **Dane organizatora:** obecne są OK, bez zmian.
- **NOWE: nagłówek eventu** jako opcja: organizator może wgrać dedykowaną grafikę
  nagłówka w CMS, apka pokazuje ją zamiast domyślnego nagłówka. Brak grafiki = obecny wygląd.

## Pytania do oceny (skala 1 do 10). ZATWIERDZONE 2026-10-14

Decyzja Jarka: oceniamy **tylko wystąpienie** (merytoryka i treść), **eventu nie oceniamy**.
Część B poniżej ODRZUCONA, zostaje dla historii.

**A. Wystąpienie (każdy wykład, w oknie oceniania jak dziś):**
1. Wartość merytoryczna: na ile treść była aktualna i oparta na wiedzy?
2. Przydatność w praktyce: na ile wykorzystasz to w codziennej pracy?
3. Sposób przekazania: na ile prelegent przedstawił temat jasno i ciekawie?

**B. (ODRZUCONE) Jakość (interpretacja: raz na cały event, otwiera się w ostatnim dniu):**
1. Organizacja: punktualność i sprawny przebieg wydarzenia.
2. Program: dobór tematów i prelegentów.
3. Warunki: sale, nagłośnienie, catering, obsługa na miejscu.

Do potwierdzenia: czy B to jakość całego eventu (jak wyżej), czy 3 dodatkowe
pytania o jakość **każdego** wykładu (wtedy 6 pytań na wykład, ryzyko spadku liczby ocen).
Sesja jako całość nie jest oceniana, oceniamy podwykłady.

## Plan techniczny

1. **Sesje:** tabela `sessions` (event, dzień, sala, tytuł, start/koniec,
   `moderator_speaker_id` lub tabela `session_moderators`), `talks.session_id NULL`
   (wykład bez sesji działa jak dziś). Bundle: `sessions[]`. Agenda: karta sesji
   rozwijana do podwykładów, dzwonek na sesji i na każdym podwykładzie. Profil
   prelegenta: „Moderuje” + „Wykłada”. CMS: CRUD sesji, przypisanie wykładów.
2. **Konflikty czasowe:** przy włączaniu przypomnienia sprawdzenie kolizji z innymi
   zaznaczonymi wykładami/sesjami (sesja i jej własne podwykłady to nie konflikt).
   Ostrzeżenie z nazwą i salą kolidującej pozycji, decyzja zostaje u uczestnika.
3. **Oceny 3 pytania (tylko A):** migracja `talk_ratings` (q1..q3), bez `event_ratings`, API, obie apki, CMS wyniki per pytanie. Stare oceny 1 do 10
   zostają jako archiwum.
4. **Nagłówek eventu:** `events.header_image_url NULL`, upload w CMS (R2/CDN jak
   reszta grafik), pole w bundlu, apki Android i iOS.
5. QR check-in: odłożone.
