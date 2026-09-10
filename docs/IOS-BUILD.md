# Eskulapp iOS , kompilacja i wydanie

Status: **rusztowanie gotowe (2026-09-10).** Warstwa wspolna kompiluje sie lokalnie
(Android/common). Faktyczna kompilacja i podpis iOS wykonuja sie na macOS (CI).

## Decyzje (Jarek, 2026-09-10)
- Kod: **KMP tylko na logike** (modul `:shared`), UI iOS **natywne SwiftUI**.
  Android w Compose zostaje nietkniety.
- Build i podpis iOS: **GitHub Actions, macOS runner** + fastlane + klucz
  App Store Connect API.

## Co jest w repo
- `app/shared/` , modul Kotlin Multiplatform (commonMain + androidMain + iosMain):
  - `model/Dto.kt` , wspolny model bundla (ten sam kontrakt co Android).
  - `EskulappApi.kt` , klient API na Ktor (`fetchBundle(code)`), silnik OkHttp
    na Androidzie, Darwin na iOS (`HttpEngine.android.kt` / `HttpEngine.ios.kt`).
  - Targety iOS deklarowane tylko na hoscie macOS (na Linuksie budujemy android/common).
- `app/iosApp/` , natywna apka iOS:
  - `project.yml` , specyfikacja XcodeGen (projekt Xcode generowany na CI).
  - `Sources/EskulappApp.swift`, `Sources/EntryView.swift` , waski pion: wejscie
    kodem -> pobranie bundla przez `:shared` -> pokazanie nazwy eventu i licznikow.
  - `fastlane/Fastfile`, `fastlane/Appfile` , lane `beta`: build, podpis, TestFlight.
- `.github/workflows/ios.yml` , pipeline na macOS.

## Co kompiluje sie GDZIE
- **Serwer agenta (Linux)**: `:shared` na Android/common. Zweryfikowane:
  `cd app && ./gradlew :shared:compileDebugKotlinAndroid` , BUILD SUCCESSFUL.
  iOS TU sie NIE zbuduje (brak macOS/Xcode, to nie do obejscia).
- **macOS (CI albo dowolny Mac)**: XCFramework + apka iOS:
  ```
  cd app && ./gradlew :shared:assembleSharedReleaseXCFramework
  cd iosApp && xcodegen generate && fastlane beta
  ```

## Co musi dostarczyc Jarek (jednorazowo, zanim CI wyda)
1. **Apple Developer Program** , 99 USD/rok. Konto firmowe wymaga numeru **D-U-N-S**
   (warto ruszyc wczesnie, nadanie D-U-N-S potrafi trwac).
2. **Rekord aplikacji w App Store Connect** dla bundle id `pl.eskulapp.mobile`.
3. **Klucz App Store Connect API** (App Store Connect -> Users and Access -> Integrations
   -> App Store Connect API -> Generate). Zapisz: **Key ID**, **Issuer ID**, plik **.p8**.
4. **Repo na certyfikaty dla `match`** (prywatne repo git) , fastlane match tam trzyma
   podpisany certyfikat dystrybucji i profil. Alternatywa: konfiguracja manualna.
5. **Repozytorium GitHub** dla tego projektu (teraz go nie ma) + sekrety Actions.

## Sekrety w GitHub Actions (Settings -> Secrets and variables -> Actions)
- `ASC_KEY_ID` , Key ID klucza App Store Connect API.
- `ASC_ISSUER_ID` , Issuer ID.
- `ASC_KEY_P8_BASE64` , zawartosc pliku .p8 zakodowana base64
  (`base64 -w0 AuthKey_XXX.p8`).
- `MATCH_PASSWORD` , haslo szyfrujace repo match.
- `MATCH_GIT_URL` , url prywatnego repo z certyfikatami match.
- `MATCH_GIT_BASIC_AUTH` , `base64("user:token")` do dostepu do repo match.

## Uruchomienie wydania
- Reczne: zakladka Actions -> `iOS build (TestFlight)` -> Run workflow.
- Automatyczne: push na `main` zmieniajacy `app/shared/**` lub `app/iosApp/**`.
- Efekt: build ladowany do TestFlight (`skip_waiting_for_build_processing`).

## Nastepne kroki (przyrostowo)
1. Domkniecie iOS UI: reszta ekranow (Agenda, Prelegenci, Partnerzy, Mapa, Kontakt,
   Aktualnosci) w SwiftUI, wzorem androidowych.
2. Persystencja offline iOS (Android ma Room): rozwazyc SQLDelight w `:shared` albo
   natywny store; teraz warstwa wspolna to siec + model.
3. Powiadomienia lokalne iOS (Android: WorkManager) przez UNUserNotificationCenter.
4. Ikona/launch screen, listing App Store.
