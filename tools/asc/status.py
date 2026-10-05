#!/usr/bin/env python3
"""Stan buildow iOS w App Store Connect (TestFlight), tylko odczyt.
Env: ASC_KEY_ID, ASC_ISSUER_ID, ASC_KEY_P8_BASE64. Nie wypisuje danych osobowych testerow."""
import base64, json, os, sys, time, urllib.request, urllib.error
import jwt

APP_ID = os.environ.get("ASC_APP_ID", "6810647099")
key = base64.b64decode(os.environ["ASC_KEY_P8_BASE64"]).decode()

def token():
    return jwt.encode({"iss": os.environ["ASC_ISSUER_ID"], "exp": int(time.time()) + 600, "aud": "appstoreconnect-v1"},
                      key, algorithm="ES256", headers={"kid": os.environ["ASC_KEY_ID"], "typ": "JWT"})

def get(path, method="GET", body=None):
    tok = token()
    r = urllib.request.Request("https://api.appstoreconnect.apple.com" + path, method=method,
                               data=json.dumps(body).encode() if body is not None else None,
                               headers={"Authorization": "Bearer " + tok, "Content-Type": "application/json"})
    try:
        raw = urllib.request.urlopen(r).read()
        return json.loads(raw) if raw else {"data": [], "included": []}
    except urllib.error.HTTPError as e:
        print("HTTP", e.code, path, e.read()[:300]); return {"data": [], "included": []}

b = get(f"/v1/builds?filter[app]={APP_ID}&sort=-uploadedDate&limit=6&include=preReleaseVersion,buildBetaDetail")
inc = {(i["type"], i["id"]): i["attributes"] for i in b.get("included", [])}
print("== BUILDY (najnowsze) ==")
for d in b["data"]:
    a = d["attributes"]; rel = d["relationships"]
    pv = inc.get(("preReleaseVersions", (rel["preReleaseVersion"]["data"] or {}).get("id")), {})
    bd = inc.get(("buildBetaDetails", (rel["buildBetaDetail"]["data"] or {}).get("id")), {})
    print(f"{pv.get('version','?')} ({a['version']})  upload={a['uploadedDate']}  processing={a['processingState']}"
          f"  encryption={a.get('usesNonExemptEncryption')}  expired={a['expired']}"
          f"  internal={bd.get('internalBuildState')}  external={bd.get('externalBuildState')}")

g = get(f"/v1/apps/{APP_ID}/betaGroups?limit=50")
print("== GRUPY TESTEROW ==")
if not g["data"]: print("(brak grup)")
for d in g["data"]:
    a = d["attributes"]
    t = get(f"/v1/betaGroups/{d['id']}/betaTesters?limit=200")
    bl = get(f"/v1/betaGroups/{d['id']}/builds?limit=5")
    print(f"{a['name']}: internal={a['isInternalGroup']} auto_dystrybucja={a.get('hasAccessToAllBuilds')}"
          f" testerow={len(t['data'])} buildow_w_grupie={len(bl['data'])}")

# Stan rekordu App Store (wersje do wydania), tylko odczyt.
print("== APP STORE ==")
for d in get(f"/v1/apps/{APP_ID}/appStoreVersions?limit=5")["data"]:
    a = d["attributes"]
    print(f"wersja {a['versionString']} stan={a.get('appStoreState')} wydanie={a.get('releaseType')}")
    bld = get(f"/v1/appStoreVersions/{d['id']}/build")["data"]
    print("  build:", bld["attributes"]["version"] if bld else "BRAK")
    for loc in get(f"/v1/appStoreVersions/{d['id']}/appStoreVersionLocalizations")["data"]:
        la = loc["attributes"]
        print(f"  [{la['locale']}] opis={bool(la.get('description'))} slowa={bool(la.get('keywords'))}"
              f" promo={bool(la.get('promotionalText'))} wsparcie={la.get('supportUrl')}")
        for ss in get(f"/v1/appStoreVersionLocalizations/{loc['id']}/appScreenshotSets")["data"]:
            n = len(get(f"/v1/appScreenshotSets/{ss['id']}/appScreenshots")["data"])
            print(f"    zrzuty {ss['attributes']['screenshotDisplayType']}: {n}")
    rd = get(f"/v1/appStoreVersions/{d['id']}/appStoreReviewDetail")["data"]
    print("  review detail:", "jest, demo wymagane=" + str(rd["attributes"].get("demoAccountRequired")) + " notatki=" + str(bool(rd["attributes"].get("notes"))) if rd else "BRAK")
for ai in get(f"/v1/apps/{APP_ID}/appInfos")["data"]:
    a = ai["attributes"]
    print(f"appInfo stan={a.get('appStoreState') or a.get('state')} wiek={a.get('appStoreAgeRating')}")
    for loc in get(f"/v1/appInfos/{ai['id']}/appInfoLocalizations")["data"]:
        la = loc["attributes"]
        print(f"  [{la['locale']}] nazwa={la.get('name')} podtytul={la.get('subtitle')} polityka={la.get('privacyPolicyUrl')}")
    pc = get(f"/v1/appInfos/{ai['id']}/primaryCategory")["data"]
    print("  kategoria:", pc["id"] if pc else "BRAK")
app = get(f"/v1/apps/{APP_ID}")["data"]
print("app:", {k: app["attributes"].get(k) for k in ("name", "primaryLocale", "contentRightsDeclaration")} if app else "?")
pr = get(f"/v1/apps/{APP_ID}/appPricePoints?limit=1")
print("cennik ustawiony:", bool(get(f"/v1/apps/{APP_ID}/appPriceSchedule")["data"]))
print("dostepnosc:", bool(get(f"/v1/apps/{APP_ID}/appAvailabilityV2")["data"]))

# --fix: najnowszy gotowy build do grup wewnetrznych (API nie pozwala wlaczyc auto dystrybucji).
# --wait: najpierw czekaj (max 45 min), az najnowszy build skonczy przetwarzanie u Apple.
if "--fix" in sys.argv:
    if "--wait" in sys.argv:
        # EXPECT_BUILD = numer buildu z tego runu CI (GITHUB_RUN_NUMBER): czekamy az Apple go zarejestruje
        want = os.environ.get("EXPECT_BUILD")
        for _ in range(90):
            latest = get(f"/v1/builds?filter[app]={APP_ID}&sort=-uploadedDate&limit=1")["data"]
            ver = latest[0]["attributes"]["version"] if latest else None
            st = latest[0]["attributes"]["processingState"] if latest else None
            print("najnowszy build:", ver, st, "oczekiwany:", want, flush=True)
            if (not want or ver == want) and st in ("VALID", "FAILED", "INVALID"): break
            time.sleep(30)
        b = get(f"/v1/builds?filter[app]={APP_ID}&sort=-uploadedDate&limit=6")
    ready = [d for d in b["data"] if d["attributes"]["processingState"] == "VALID" and not d["attributes"]["expired"]]
    for d in g["data"]:
        if not d["attributes"]["isInternalGroup"] or not ready: continue
        get(f"/v1/betaGroups/{d['id']}/relationships/builds", "POST", {"data": [{"type": "builds", "id": ready[0]["id"]}]})
        print(f"{d['attributes']['name']}: dodany build {ready[0]['attributes']['version']}")
    print("== PO ZMIANIE ==")
    for d in get(f"/v1/apps/{APP_ID}/betaGroups?limit=50")["data"]:
        bl = get(f"/v1/betaGroups/{d['id']}/builds?limit=10")
        print(d["attributes"]["name"], "buildy:", [x["attributes"]["version"] for x in bl["data"]])
