#!/usr/bin/env python3
"""Karta sklepu Google Play (pl-PL) z docs/PUBLIKACJA.md + grafiki z tools/shots/store.

Teksty: nazwa, krotki i pelny opis (bloki ``` z sekcji 1). Grafiki: ikona 512,
feature 1024x500, zrzuty telefonu (zastepuje wszystkie). Bez --commit robi
podglad i kasuje edit (nic nie zmienia w Play).

  python3 tools/play/listing.py            # podglad
  python3 tools/play/listing.py --commit   # zapis w Play
"""
import argparse, json, re, sys
from pathlib import Path

import requests

sys.path.insert(0, str(Path(__file__).parent))
import deploy  # noqa: E402  (access_token, load_env, API)

ROOT = Path(__file__).resolve().parents[2]
LANG = "pl-PL"


def texts():
    md = (ROOT / "docs/PUBLIKACJA.md").read_text()
    sec = md.split("## 1. Teksty Google Play", 1)[1].split("\n## ", 1)[0]
    blocks = re.findall(r"\*\*([^*\n]+)\*\*[^\n]*\n```\n(.*?)\n```", sec, re.S)
    found = {k.strip(): v for k, v in blocks}
    short = found["Krótki opis"]
    full = found["Pełny opis"]
    notes = next(v for k, v in found.items() if k.startswith("Co nowego"))
    assert len(short) <= 80 and len(full) <= 4000 and len(notes) <= 500
    for t in (short, full, notes):
        assert not re.search("[–—→]", t), "myslnik/strzalka w tekscie"
    return {"title": "Eskulapp", "shortDescription": short, "fullDescription": full}, notes


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--commit", action="store_true")
    ap.add_argument("--env", default=str(ROOT / ".env"))
    a = ap.parse_args()

    listing, notes = texts()
    env = deploy.load_env(a.env)
    sa = json.loads(Path(env.get("PLAY_SERVICE_ACCOUNT_JSON", ROOT / ".secrets/play-service-account.json")).read_text())
    pkg = env.get("PLAY_PACKAGE", "pl.eskulapp.mobile")
    H = {"Authorization": "Bearer " + deploy.access_token(sa)}
    B = f"https://androidpublisher.googleapis.com/androidpublisher/v3/applications/{pkg}"
    U = f"https://androidpublisher.googleapis.com/upload/androidpublisher/v3/applications/{pkg}"

    edit = requests.post(f"{B}/edits", headers=H, timeout=30).json()["id"]
    try:
        print("krotki:", len(listing["shortDescription"]), "znakow, pelny:", len(listing["fullDescription"]))
        if not a.commit:
            print(listing["fullDescription"]); print("(podglad, bez zmian)")
            return
        r = requests.put(f"{B}/edits/{edit}/listings/{LANG}", headers=H, json={"language": LANG, **listing}, timeout=30)
        r.raise_for_status(); print("teksty OK")

        store = ROOT / "tools/shots/store"
        imgs = [("icon", store / "icon-512.png"), ("featureGraphic", store / "feature-1024x500.png")]
        imgs += [("phoneScreenshots", p) for p in sorted((store / "android").glob("*.png"))]
        for t in {t for t, _ in imgs}:
            requests.delete(f"{B}/edits/{edit}/listings/{LANG}/{t}", headers=H, timeout=30).raise_for_status()
        for t, p in imgs:
            r = requests.post(f"{U}/edits/{edit}/listings/{LANG}/{t}?uploadType=media",
                              headers={**H, "Content-Type": "image/png"}, data=p.read_bytes(), timeout=120)
            r.raise_for_status(); print("grafika", t, p.name)
        r = requests.post(f"{B}/edits/{edit}:commit", headers=H, timeout=60)
        if r.status_code >= 400:
            print("commit:", r.status_code, r.text[:400]); r.raise_for_status()
        edit = None
        print("ZAPISANE w Play")
    finally:
        if edit:
            requests.delete(f"{B}/edits/{edit}", headers=H, timeout=30)


if __name__ == "__main__":
    main()
