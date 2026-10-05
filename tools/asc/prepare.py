#!/usr/bin/env python3
"""Przygotowanie wersji w App Store Connect do recenzji (BEZ wysylki do recenzji).

Teksty z docs/PUBLIKACJA.md (sekcje 1 i 2), zrzuty z tools/shots/store/ios.
Ustawia: numer wersji + copyright + wydanie reczne, build, opis/slowa/promo/URL-e,
podtytul + URL polityki, kategorie, prawa do tresci, ocene wiekowa (wszystko brak),
dostepnosc (kraje), dane dla recenzenta, zrzuty 6,9".
Czego API NIE umie: App Privacy (etykieta prywatnosci) i umowy, to robi Jarek w przegladarce.

Env: ASC_KEY_ID, ASC_ISSUER_ID, ASC_KEY_P8_BASE64; opcjonalnie ASC_VERSION, ASC_BUILD,
ASC_TERRITORIES (np. "POL" albo "ALL"). Bez --apply: tylko odczyt i plan.
"""
import base64, hashlib, json, os, re, sys, time, urllib.error, urllib.request
from pathlib import Path

import jwt

ROOT = Path(__file__).resolve().parents[2]
APP_ID = os.environ.get("ASC_APP_ID", "6810647099")
VERSION = os.environ.get("ASC_VERSION", "1.3.0")
BUILD = os.environ.get("ASC_BUILD", "17")
TERRITORIES = os.environ.get("ASC_TERRITORIES", "POL")
APPLY = "--apply" in sys.argv
KEY = base64.b64decode(os.environ["ASC_KEY_P8_BASE64"]).decode()

REVIEW_CONTACT = {"contactFirstName": "Jarosław", "contactLastName": "Gilewicz",
                  "contactPhone": "+48784367186", "contactEmail": "kontakt@eskulapp.pl"}
COPYRIGHT = "2026 Jarosław Gilewicz"
SHOT_TYPE = "APP_IPHONE_67"  # 6,9" (1320x2868) wchodzi w ten typ


def token():
    return jwt.encode({"iss": os.environ["ASC_ISSUER_ID"], "exp": int(time.time()) + 600,
                       "aud": "appstoreconnect-v1"}, KEY, algorithm="ES256",
                      headers={"kid": os.environ["ASC_KEY_ID"], "typ": "JWT"})


def api(path, method="GET", body=None, ok404=False):
    r = urllib.request.Request("https://api.appstoreconnect.apple.com" + path, method=method,
                               data=json.dumps(body).encode() if body is not None else None,
                               headers={"Authorization": "Bearer " + token(), "Content-Type": "application/json"})
    try:
        raw = urllib.request.urlopen(r).read()
        return json.loads(raw) if raw else {}
    except urllib.error.HTTPError as e:
        if e.code == 404 and ok404:
            return None
        print("HTTP", e.code, method, path, e.read()[:800].decode(errors="replace"))
        raise SystemExit(1)


def write(label, path, method, body):
    print(("ZAPIS " if APPLY else "PLAN  ") + label)
    return api(path, method, body) if APPLY else None


def texts():
    md = (ROOT / "docs/PUBLIKACJA.md").read_text()
    blocks = dict((k.strip(), v) for k, v in
                  re.findall(r"\*\*([^*\n]+)\*\*[^\n]*\n```\n(.*?)\n```", md, re.S))
    sub = re.search(r"\*\*Podtytuł\*\*[^`]*`([^`]+)`", md).group(1)
    t = {"description": blocks["Pełny opis"], "keywords": blocks["Słowa kluczowe"],
         "promotionalText": blocks["Tekst promocyjny"], "subtitle": sub,
         "notes": blocks["Uwagi dla recenzenta (App Review Information, Notes):"]}
    assert len(t["subtitle"]) <= 30 and len(t["keywords"]) <= 100 and len(t["promotionalText"]) <= 170
    assert len(t["description"]) <= 4000 and len(t["notes"]) <= 4000
    for v in t.values():
        assert not re.search("[–—→]", v), "myslnik/strzalka w tekscie"
    return t


def main():
    t = texts()
    print("tryb:", "APPLY" if APPLY else "podglad (bez zmian)", "| wersja", VERSION, "build", BUILD)

    # Wersja w przygotowaniu (pierwsze wydanie: jedna, PREPARE_FOR_SUBMISSION)
    vers = api(f"/v1/apps/{APP_ID}/appStoreVersions?filter[platform]=IOS&limit=10")["data"]
    ver = next((v for v in vers if v["attributes"]["appStoreState"] in
                ("PREPARE_FOR_SUBMISSION", "DEVELOPER_REJECTED", "REJECTED", "METADATA_REJECTED")), None)
    if not ver:
        print("Brak edytowalnej wersji:", [(v["attributes"]["versionString"], v["attributes"]["appStoreState"]) for v in vers])
        raise SystemExit(1)
    vid = ver["id"]
    write(f"wersja {ver['attributes']['versionString']} na {VERSION}, copyright, wydanie MANUAL",
          f"/v1/appStoreVersions/{vid}", "PATCH",
          {"data": {"type": "appStoreVersions", "id": vid, "attributes": {
              "versionString": VERSION, "copyright": COPYRIGHT, "releaseType": "MANUAL"}}})

    # Build
    blds = api(f"/v1/builds?filter[app]={APP_ID}&filter[version]={BUILD}&filter[preReleaseVersion.version]={VERSION}"
               f"&filter[processingState]=VALID&limit=1")["data"]
    if not blds:
        print("BRAK buildu", VERSION, BUILD, "w stanie VALID"); raise SystemExit(1)
    write(f"build {VERSION} ({BUILD}) do wersji", f"/v1/appStoreVersions/{vid}/relationships/build", "PATCH",
          {"data": {"type": "builds", "id": blds[0]["id"]}})

    # Lokalizacja wersji (pl)
    locs = api(f"/v1/appStoreVersions/{vid}/appStoreVersionLocalizations")["data"]
    loc = next(l for l in locs if l["attributes"]["locale"].startswith("pl"))
    write("opis, slowa kluczowe, promo, URL wsparcia/marketingowy (pl)",
          f"/v1/appStoreVersionLocalizations/{loc['id']}", "PATCH",
          {"data": {"type": "appStoreVersionLocalizations", "id": loc["id"], "attributes": {
              "description": t["description"], "keywords": t["keywords"],
              "promotionalText": t["promotionalText"], "supportUrl": "https://eskulapp.pl",
              "marketingUrl": "https://eskulapp.pl"}}})

    # App info: podtytul, polityka, kategorie, ocena wiekowa
    info = next(i for i in api(f"/v1/apps/{APP_ID}/appInfos")["data"]
                if i["attributes"].get("state") not in ("READY_FOR_DISTRIBUTION", "REPLACED_WITH_NEW_INFO"))
    iloc = next(l for l in api(f"/v1/appInfos/{info['id']}/appInfoLocalizations")["data"]
                if l["attributes"]["locale"].startswith("pl"))
    write(f"podtytul '{t['subtitle']}' + URL polityki", f"/v1/appInfoLocalizations/{iloc['id']}", "PATCH",
          {"data": {"type": "appInfoLocalizations", "id": iloc["id"], "attributes": {
              "subtitle": t["subtitle"], "privacyPolicyUrl": "https://eskulapp.pl/polityka-prywatnosci/"}}})
    write("kategorie BUSINESS / EDUCATION", f"/v1/appInfos/{info['id']}", "PATCH",
          {"data": {"type": "appInfos", "id": info["id"], "relationships": {
              "primaryCategory": {"data": {"type": "appCategories", "id": "BUSINESS"}},
              "secondaryCategory": {"data": {"type": "appCategories", "id": "EDUCATION"}}}}})

    ard = api(f"/v1/appInfos/{info['id']}/ageRatingDeclaration", ok404=True)
    if ard and ard.get("data"):
        cur = ard["data"]["attributes"]
        skip = {"kidsAgeBand", "ageRatingOverride", "ageRatingOverrideV2", "koreaAgeRatingOverride",
                "developerAgeRatingInfoUrl", "gracRatingClassificationNumber"}
        new = {}
        for k, v in cur.items():
            if k in skip: continue
            if isinstance(v, bool) or k in BOOL_KEYS: new[k] = False
            elif isinstance(v, str) or k in ENUM_KEYS: new[k] = "NONE"
        print("  ocena wiekowa, pola:", json.dumps(cur, ensure_ascii=False))
        write("ocena wiekowa: wszystko brak/nie", f"/v1/ageRatingDeclarations/{ard['data']['id']}", "PATCH",
              {"data": {"type": "ageRatingDeclarations", "id": ard["data"]["id"], "attributes": new}})

    write("prawa do tresci: bez tresci stron trzecich", f"/v1/apps/{APP_ID}", "PATCH",
          {"data": {"type": "apps", "id": APP_ID, "attributes": {
              "contentRightsDeclaration": "DOES_NOT_USE_THIRD_PARTY_CONTENT"}}})

    # Dostepnosc
    if api(f"/v1/apps/{APP_ID}/appAvailabilityV2", ok404=True) is None:
        every = [x["id"] for x in api("/v1/territories?limit=200")["data"]]
        on = set(every) if TERRITORIES == "ALL" else set(TERRITORIES.split(","))
        # Apple wymaga wszystkich krajow w jednym POST, kazdy z flaga available
        write(f"dostepnosc: {TERRITORIES} ({len(on)} z {len(every)} krajow)", "/v2/appAvailabilities", "POST", {
            "data": {"type": "appAvailabilities", "attributes": {"availableInNewTerritories": TERRITORIES == "ALL"},
                     "relationships": {"app": {"data": {"type": "apps", "id": APP_ID}},
                                       "territoryAvailabilities": {"data": [
                                           {"type": "territoryAvailabilities", "id": "${%s}" % c} for c in every]}}},
            "included": [{"type": "territoryAvailabilities", "id": "${%s}" % c, "attributes": {"available": c in on},
                          "relationships": {"territory": {"data": {"type": "territories", "id": c}}}} for c in every]})
    else:
        print("dostepnosc: juz ustawiona, pomijam")

    # Dane dla recenzenta
    attrs = {**REVIEW_CONTACT, "demoAccountRequired": False, "notes": t["notes"]}
    rd = api(f"/v1/appStoreVersions/{vid}/appStoreReviewDetail", ok404=True)
    if rd and rd.get("data"):
        write("dane dla recenzenta (aktualizacja)", f"/v1/appStoreReviewDetails/{rd['data']['id']}", "PATCH",
              {"data": {"type": "appStoreReviewDetails", "id": rd["data"]["id"], "attributes": attrs}})
    else:
        write("dane dla recenzenta (nowe)", "/v1/appStoreReviewDetails", "POST",
              {"data": {"type": "appStoreReviewDetails", "attributes": attrs, "relationships": {
                  "appStoreVersion": {"data": {"type": "appStoreVersions", "id": vid}}}}})

    # Zrzuty 6,9"
    files = sorted((ROOT / "tools/shots/store/ios").glob("*.png"))
    sets = api(f"/v1/appStoreVersionLocalizations/{loc['id']}/appScreenshotSets")["data"]
    sset = next((s for s in sets if s["attributes"]["screenshotDisplayType"] == SHOT_TYPE), None)
    have = api(f"/v1/appScreenshotSets/{sset['id']}/appScreenshots")["data"] if sset else []
    if len(have) == len(files):
        print(f"zrzuty {SHOT_TYPE}: juz {len(have)}, pomijam")
    elif not APPLY:
        print(f"PLAN  zrzuty {SHOT_TYPE}: {len(files)} plikow (teraz {len(have)})")
    else:
        if not sset:
            sset = api("/v1/appScreenshotSets", "POST", {"data": {"type": "appScreenshotSets",
                       "attributes": {"screenshotDisplayType": SHOT_TYPE}, "relationships": {
                           "appStoreVersionLocalization": {"data": {"type": "appStoreVersionLocalizations", "id": loc["id"]}}}}})["data"]
        for h in have:
            api(f"/v1/appScreenshots/{h['id']}", "DELETE")
        for f in files:
            data = f.read_bytes()
            shot = api("/v1/appScreenshots", "POST", {"data": {"type": "appScreenshots",
                       "attributes": {"fileName": f.name, "fileSize": len(data)}, "relationships": {
                           "appScreenshotSet": {"data": {"type": "appScreenshotSets", "id": sset["id"]}}}}})["data"]
            for op in shot["attributes"]["uploadOperations"]:
                chunk = data[op["offset"]:op["offset"] + op["length"]]
                req = urllib.request.Request(op["url"], data=chunk, method=op["method"],
                                             headers={h["name"]: h["value"] for h in op["requestHeaders"]})
                urllib.request.urlopen(req).read()
            api(f"/v1/appScreenshots/{shot['id']}", "PATCH", {"data": {"type": "appScreenshots", "id": shot["id"],
                "attributes": {"uploaded": True, "sourceFileChecksum": hashlib.md5(data).hexdigest()}}})
            print("ZAPIS  zrzut", f.name)

    print("GOTOWE." if APPLY else "Podglad zakonczony, nic nie zmieniono.")
    print("Recznie (Jarek, przegladarka): App Privacy, umowy (Business > Agreements), potem wysylka do recenzji.")


BOOL_KEYS = {"gambling", "unrestrictedWebAccess", "lootBox", "advertising", "ageAssurance",
             "healthOrWellnessTopics", "messagingAndChat", "parentalControls", "userGeneratedContent", "seventeenPlus",
             "socialMedia", "socialMediaAgeRestricted"}
ENUM_KEYS = {"alcoholTobaccoOrDrugUseOrReferences", "contests", "gamblingSimulated", "gunsOrOtherWeapons",
             "horrorOrFearThemes", "matureOrSuggestiveThemes", "medicalOrTreatmentInformation",
             "profanityOrCrudeHumor", "sexualContentGraphicAndNudity", "sexualContentOrNudity",
             "violenceCartoonOrFantasy", "violenceRealistic", "violenceRealisticProlongedGraphicOrSadistic"}

if __name__ == "__main__":
    main()
