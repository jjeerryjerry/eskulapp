#!/usr/bin/env python3
"""Podmiana pola „Co nowego” (pl) w wersji ASC_VERSION, bez ruszania reszty i bez zmiany stanu recenzji.
Tekst: blok „Co nowego” z docs/PUBLIKACJA.md. Bez --apply: tylko podglad."""
import os, sys
sys.argv += []
import prepare as P

t = P.texts()
vers = P.api(f"/v1/apps/{P.APP_ID}/appStoreVersions?filter[platform]=IOS&filter[versionString]={P.VERSION}")["data"]
if not vers:
    print("Brak wersji", P.VERSION); raise SystemExit(1)
v = vers[0]
print("wersja", P.VERSION, "stan", v["attributes"]["appStoreState"])
loc = next(l for l in P.api(f"/v1/appStoreVersions/{v['id']}/appStoreVersionLocalizations")["data"]
           if l["attributes"]["locale"].startswith("pl"))
print("teraz:\n" + (loc["attributes"].get("whatsNew") or "") + "\nnowe:\n" + t["whatsNew"])
P.write("whatsNew (pl)", f"/v1/appStoreVersionLocalizations/{loc['id']}", "PATCH",
        {"data": {"type": "appStoreVersionLocalizations", "id": loc["id"], "attributes": {"whatsNew": t["whatsNew"]}}})
print("GOTOWE." if P.APPLY else "Podglad, nic nie zmieniono.")
