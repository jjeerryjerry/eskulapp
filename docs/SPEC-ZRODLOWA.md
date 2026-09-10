# Specyfikacja źródłowa — Eskulapp

> Wierny przepis dokumentacji dostarczonej przez Jarka
> (`G:\Mój dysk\__Eskulapp\Specyfikacja_Eskulapp.pdf`, Google Drive id
> `1N_etBTvMQ6RrFSRRAIlqJ41c1gxwh-dr`, folder `__Eskulapp`).
> To jest **źródło prawdy o wymaganiach**. Decyzje wdrożeniowe (stack, hosting)
> są w `ARCHITEKTURA.md`.

## 1. Założenia Systemu Eskulapp

### 1.1. Cel i Architektura
Głównym celem ekosystemu **Eskulapp** jest wsparcie uczestników **eventów i
konferencji medycznych**. System składa się z trzech głównych komponentów:

- **Aplikacja Mobilna Eskulapp** — dla uczestników (początkowo **Android**,
  docelowo również **iOS**).
- **Platforma Webowa Eskulapp** — centralny serwis internetowy odpowiedzialny za
  autoryzację, tworzenie kont użytkowników oraz globalne logowanie (**Single
  Sign-On**).
- **Panel Administracyjny (CMS)** — system zarządzania treścią dla organizatorów.

### 1.2. Przepływ użytkownika (User Flow) z logowaniem
- **Autoryzacja:** po uruchomieniu aplikacji mobilnej użytkownik jest
  przekierowany do logowania obsługiwanego przez **centralny serwis Eskulapp**
  (konto założone na stronie internetowej).
- **Ekran główny (Dashboard):** po zalogowaniu aplikacja prezentuje **profil
  użytkownika** oraz **listę eventów**, do których ma dostęp.
- **Dodawanie wydarzeń:** użytkownik przypisuje się do nowego **zamkniętego**
  wydarzenia wpisując **dedykowany kod eventu** (np. `FND2027`).
- **Sortowanie:** eventy aktualne i nadchodzące na **szczycie** listy; eventy
  archiwalne (zakończone) na **dole** i **wizualnie wyszarzone**.

### 1.3. Główne moduły aplikacji mobilnej
- **Prelekcje (Agenda):** lista prelekcji z podziałem na **dni** wydarzenia,
  **filtrowanie po salach/scenach**, lokalne **przypomnienie** o zbliżającej się
  prelekcji.
- **Prelegenci:** profile szczegółowe — zdjęcie, imię, nazwisko, tytuł naukowy, bio.
- **Partnerzy:** sponsorzy/partnerzy z profilem i **lokalizacją stoiska**
  wystawowego.
- **Mapa Eventu:** podgląd przestrzeni (plik graficzny z CMS lub zagnieżdżona mapa).
- **Kontakt:** osobna zakładka z aktualnymi danymi kontaktowymi organizatorów
  danego eventu.

## 2. Prompt systemowy dla agenta (ze specyfikacji)

> Jesteś zaawansowanym Architektem Systemów i Programistą Full-Stack. Twoim celem
> jest asystowanie w tworzeniu od zera ekosystemu „Eskulapp" — platformy dla
> uczestników eventów medycznych.

**Kontekst systemu:** (1) centralny serwis webowy — globalne logowanie i
tworzenie kont (usługa autoryzacji); (2) aplikacja mobilna Android/iOS —
logowanie kontem z serwisu, po zalogowaniu widok eventów lub dodanie nowego
kodem dostępowym (np. `FND2027`); (3) panel CMS dla organizatorów (CRUD);
(4) funkcje aplikacji: lista eventów (aktywne u góry, archiwalne wyszarzone na
dole), agenda (dni, filtr sal, przypomnienia lokalne), prelegenci, partnerzy,
mapa, kontakt.

**Zadania:** (1) bezpieczna architektura logowania/autoryzacji między aplikacją a
serwisem (JWT/OAuth); (2) baza danych relacji użytkownik–event; (3) kod
front-endu mobilnego i backendu; (4) powiadomienia natywne.

**Zasady ze specyfikacji:**
- wysoka jakość i **modułowość** — rozdziel logikę logowania (serwis webowy) od
  logiki eventowej;
- **offline-first** (cache harmonogramu), żeby apka działała w miejscach o słabym
  zasięgu;
- zawsze **najnowsze standardy bezpieczeństwa** przy autoryzacji.
