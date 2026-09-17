#!/usr/bin/env python3
"""Stan buildow iOS w App Store Connect (TestFlight), tylko odczyt.
Env: ASC_KEY_ID, ASC_ISSUER_ID, ASC_KEY_P8_BASE64. Nie wypisuje danych osobowych testerow."""
import base64, json, os, sys, time, urllib.request, urllib.error
import jwt

APP_ID = os.environ.get("ASC_APP_ID", "6810647099")
key = base64.b64decode(os.environ["ASC_KEY_P8_BASE64"]).decode()
tok = jwt.encode({"iss": os.environ["ASC_ISSUER_ID"], "exp": int(time.time()) + 600, "aud": "appstoreconnect-v1"},
                 key, algorithm="ES256", headers={"kid": os.environ["ASC_KEY_ID"], "typ": "JWT"})

def get(path, method="GET", body=None):
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

# --fix: najnowszy gotowy build do grup wewnetrznych + automatyczna dystrybucja kolejnych buildow
if "--fix" in sys.argv:
    ready = [d for d in b["data"] if d["attributes"]["processingState"] == "VALID" and not d["attributes"]["expired"]]
    for d in g["data"]:
        if not d["attributes"]["isInternalGroup"]: continue
        if not d["attributes"].get("hasAccessToAllBuilds"):
            get(f"/v1/betaGroups/{d['id']}", "PATCH", {"data": {"type": "betaGroups", "id": d["id"], "attributes": {"hasAccessToAllBuilds": True}}})
            print(f"{d['attributes']['name']}: wlaczona automatyczna dystrybucja")
        if ready:
            get(f"/v1/betaGroups/{d['id']}/relationships/builds", "POST", {"data": [{"type": "builds", "id": ready[0]["id"]}]})
            print(f"{d['attributes']['name']}: dodany build {ready[0]['attributes']['version']}")
    print("== PO ZMIANIE ==")
    for d in get(f"/v1/apps/{APP_ID}/betaGroups?limit=50")["data"]:
        bl = get(f"/v1/betaGroups/{d['id']}/builds?limit=10")
        print(d["attributes"]["name"], "auto_dystrybucja=", d["attributes"].get("hasAccessToAllBuilds"),
              "buildy:", [x["attributes"]["version"] for x in bl["data"]])
