#!/usr/bin/env python3
"""
Eskulapp , wysylka AAB do Google Play przez Android Publisher API v3.

Bez pluginu Gradle (buildy trzymamy offline), tylko service account + REST.
Autoryzacja: JWT RS256 z klucza service accountu -> access token (scope
androidpublisher). Potem: edits.insert -> bundles.upload -> tracks.update ->
edits.commit.

Sekrety w ~/agents/eskulapp/.env:
  PLAY_SERVICE_ACCOUNT_JSON=/sciezka/do/klucza.json   (chmod 600, poza repo)
  PLAY_PACKAGE=pl.eskulapp.mobile

Uzycie:
  python3 deploy.py --aab app/app/build/outputs/bundle/release/app-release.aab \\
      --track internal --notes "Poprawka X" [--rollout 0.2] [--dry-run]

Kanaly (--track): internal | alpha (closed) | beta (open) | production.
--rollout U (0<U<=1): staged rollout (release inProgress z userFraction=U).
Bez --rollout: pelne wdrozenie (status completed).
--dry-run: policz, nie commituj (usuwa edit na koncu, nic sie nie publikuje).
"""
import argparse, json, os, sys, time
from pathlib import Path

try:
    import jwt  # PyJWT
    import requests
except Exception as e:
    sys.exit(f"Brak zaleznosci: {e} (potrzebne: pyjwt, requests, cryptography)")

TOKEN_URI = "https://oauth2.googleapis.com/token"
API = "https://androidpublisher.googleapis.com/androidpublisher/v3/applications"
UPLOAD = "https://androidpublisher.googleapis.com/upload/androidpublisher/v3/applications"
SCOPE = "https://www.googleapis.com/auth/androidpublisher"


def load_env(env_path):
    env = {}
    if Path(env_path).exists():
        for line in Path(env_path).read_text().splitlines():
            line = line.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            k, v = line.split("=", 1)
            env[k.strip()] = v.strip()
    return env


def access_token(sa):
    now = int(time.time())
    claim = {
        "iss": sa["client_email"],
        "scope": SCOPE,
        "aud": TOKEN_URI,
        "iat": now,
        "exp": now + 3600,
    }
    assertion = jwt.encode(claim, sa["private_key"], algorithm="RS256")
    r = requests.post(TOKEN_URI, data={
        "grant_type": "urn:ietf:params:oauth:grant-type:jwt-bearer",
        "assertion": assertion,
    }, timeout=30)
    r.raise_for_status()
    return r.json()["access_token"]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--aab", required=True)
    ap.add_argument("--track", default="internal")
    ap.add_argument("--notes", default="")
    ap.add_argument("--rollout", type=float, default=None)
    ap.add_argument("--lang", default="pl-PL")
    ap.add_argument("--dry-run", action="store_true")
    ap.add_argument("--env", default=str(Path.home() / "agents/eskulapp/.env"))
    a = ap.parse_args()

    env = load_env(a.env)
    sa_path = env.get("PLAY_SERVICE_ACCOUNT_JSON")
    pkg = env.get("PLAY_PACKAGE", "pl.eskulapp.mobile")
    if not sa_path or not Path(sa_path).exists():
        sys.exit("Brak PLAY_SERVICE_ACCOUNT_JSON w .env albo plik nie istnieje.")
    if not Path(a.aab).exists():
        sys.exit(f"Nie ma pliku AAB: {a.aab}")
    sa = json.loads(Path(sa_path).read_text())

    print(f"[1/5] Autoryzacja jako {sa['client_email']} ...")
    tok = access_token(sa)
    H = {"Authorization": f"Bearer {tok}"}

    print(f"[2/5] Tworze edit dla {pkg} ...")
    r = requests.post(f"{API}/{pkg}/edits", headers=H, timeout=30)
    r.raise_for_status()
    edit_id = r.json()["id"]

    try:
        print(f"[3/5] Wysylam AAB ({Path(a.aab).stat().st_size/1e6:.1f} MB) ...")
        with open(a.aab, "rb") as f:
            r = requests.post(
                f"{UPLOAD}/{pkg}/edits/{edit_id}/bundles?uploadType=media",
                headers={**H, "Content-Type": "application/octet-stream"},
                data=f, timeout=600)
        r.raise_for_status()
        vc = r.json()["versionCode"]
        print(f"      -> versionCode {vc}")

        release = {"status": "completed", "versionCodes": [vc]}
        if a.rollout is not None:
            release = {"status": "inProgress", "userFraction": a.rollout,
                       "versionCodes": [vc]}
        if a.notes:
            release["releaseNotes"] = [{"language": a.lang, "text": a.notes}]

        print(f"[4/5] Ustawiam track '{a.track}' (status {release['status']}"
              + (f", rollout {a.rollout}" if a.rollout is not None else "") + ") ...")
        r = requests.put(f"{API}/{pkg}/edits/{edit_id}/tracks/{a.track}",
                         headers={**H, "Content-Type": "application/json"},
                         data=json.dumps({"track": a.track, "releases": [release]}),
                         timeout=60)
        r.raise_for_status()

        if a.dry_run:
            print("[5/5] DRY-RUN , usuwam edit, nic nie publikuje.")
            requests.delete(f"{API}/{pkg}/edits/{edit_id}", headers=H, timeout=30)
            print("OK (dry-run). Wszystko przeszlo az do commita.")
            return

        print("[5/5] Commit ...")
        r = requests.post(f"{API}/{pkg}/edits/{edit_id}:commit", headers=H, timeout=60)
        r.raise_for_status()
        print(f"GOTOWE. versionCode {vc} wdrozony na '{a.track}'.")
    except requests.HTTPError as e:
        body = e.response.text if e.response is not None else str(e)
        # sprzataj edit, zeby nie zostawac z wiszacym draftem
        requests.delete(f"{API}/{pkg}/edits/{edit_id}", headers=H, timeout=30)
        sys.exit(f"BLAD API: {body}")


if __name__ == "__main__":
    main()
