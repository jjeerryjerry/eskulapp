#!/usr/bin/env python3
"""Promocja istniejacego versionCode na inny kanal Play (bez nowego buildu).

  python3 tools/play/promote.py --vc 21 --track production --rollout 0.2 [--commit]
Bez --commit: podglad i kasowanie editu. Notatki: blok "Co nowego" z docs/PUBLIKACJA.md.
"""
import argparse, json, sys
from pathlib import Path

import requests

sys.path.insert(0, str(Path(__file__).parent))
import deploy  # noqa: E402
import listing  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]

ap = argparse.ArgumentParser()
ap.add_argument("--vc", required=True)
ap.add_argument("--track", default="production")
ap.add_argument("--rollout", type=float, default=None)
ap.add_argument("--name", default="1.3.0")
ap.add_argument("--commit", action="store_true")
a = ap.parse_args()

_, notes = listing.texts()
env = deploy.load_env(ROOT / ".env")
sa = json.loads(Path(env.get("PLAY_SERVICE_ACCOUNT_JSON", ROOT / ".secrets/play-service-account.json")).read_text())
H = {"Authorization": "Bearer " + deploy.access_token(sa)}
B = f"https://androidpublisher.googleapis.com/androidpublisher/v3/applications/{env.get('PLAY_PACKAGE', 'pl.eskulapp.mobile')}"
rel = {"name": a.name, "versionCodes": [a.vc], "releaseNotes": [{"language": "pl-PL", "text": notes}],
       "status": "inProgress" if a.rollout and a.rollout < 1 else "completed"}
if a.rollout and a.rollout < 1:
    rel["userFraction"] = a.rollout
edit = requests.post(f"{B}/edits", headers=H, timeout=30).json()["id"]
try:
    print("release:", json.dumps(rel, ensure_ascii=False))
    r = requests.put(f"{B}/edits/{edit}/tracks/{a.track}", headers=H, json={"track": a.track, "releases": [rel]}, timeout=30)
    print("tracks.update", r.status_code, r.text[:300] if r.status_code >= 400 else "")
    r.raise_for_status()
    if a.commit:
        r = requests.post(f"{B}/edits/{edit}:commit", headers=H, timeout=60)
        print("commit", r.status_code, r.text[:400] if r.status_code >= 400 else "OK")
        r.raise_for_status(); edit = None
    else:
        print("(podglad, bez zmian)")
finally:
    if edit:
        requests.delete(f"{B}/edits/{edit}", headers=H, timeout=30)
