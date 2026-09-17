#!/usr/bin/env bash
# Pieczenie statycznego bundla eventu do Cloudflare R2 (architektura B).
#
# Dla kazdego kodu eventu:
#   1. pobiera bundel z zywego API (GET /api/public/events/CODE/bundle),
#   2. normalizuje (usuwa pola zmienne: generated_at, _demo),
#   3. liczy wersje = sha256 tresci (content-addressed, wiec KAZDA zmiana = nowa wersja),
#   4. wgrywa NIEZMIENNY plik events/CODE/<wersja>.json (cache dlugi, immutable),
#   5. wgrywa MALY manifest events/CODE/manifest.json (cache krotki) z numerem wersji,
#   6. weryfikuje publiczny odczyt przez CDN.
#
# Apka odpytuje TYLKO manifest (maly), a bundel ciagnie dopiero gdy wersja sie zmieni.
# Manifest trzyma sciezke wzgledna (bundle_path), wiec przelaczenie r2.dev -> cdn.eskulapp.pl
# NIE wymaga ponownego pieczenia.
#
# Uzycie:  scripts/bake-bundle.sh FND2025 TEST01 TEST03 TEST02
#          scripts/bake-bundle.sh --all      (upiecze wszystkie znane kody)
#
# Wymaga: .env z R2_* i R2_PUBLIC_BASE; narzedzia jq, curl, rclone.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

# --- sekrety / konfiguracja ---
set -a; . ./.env; set +a
API_BASE="${API_BASE:-https://eskulapp.pl/api}"
: "${R2_BUCKET:?brak R2_BUCKET w .env}"
: "${R2_PUBLIC_BASE:?brak R2_PUBLIC_BASE w .env}"

# rclone -> R2 (env, bez zapisu sekretow do rclone.conf; WYMUS IPv4: brak egress IPv6)
export RCLONE_CONFIG_R2_TYPE=s3 RCLONE_CONFIG_R2_PROVIDER=Cloudflare RCLONE_CONFIG_R2_REGION=auto
export RCLONE_CONFIG_R2_ACCESS_KEY_ID="$R2_ACCESS_KEY_ID"
export RCLONE_CONFIG_R2_SECRET_ACCESS_KEY="$R2_SECRET_ACCESS_KEY"
export RCLONE_CONFIG_R2_ENDPOINT="$R2_ENDPOINT"
RCLONE="rclone --bind 0.0.0.0"

CC_IMMUTABLE="Cache-Control: public, max-age=31536000, immutable"
CC_MANIFEST="Cache-Control: public, max-age=30, must-revalidate"

ALL_CODES=(FND2025 TEST01 TEST03 TEST02)
if [[ "${1:-}" == "--all" ]]; then set -- "${ALL_CODES[@]}"; fi
if [[ $# -lt 1 ]]; then echo "Uzycie: $0 KOD [KOD...]  |  $0 --all" >&2; exit 2; fi

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
ok=0; fail=0

bake_one() {
  local code="$1"
  code="${code^^}"
  echo "== $code =="

  # 1) pobierz bundel z zywego API
  local raw="$TMP/$code.raw.json"
  local http
  http=$(curl -sS -m 30 -o "$raw" -w "%{http_code}" "$API_BASE/public/events/$code/bundle" 2>/dev/null || echo 000)
  if [[ "$http" != "200" ]]; then echo "  POMIJAM: API zwrocilo http=$http"; fail=$((fail+1)); return; fi
  if ! jq -e '.event.id' "$raw" >/dev/null 2>&1; then echo "  POMIJAM: brak .event.id (odpowiedz to blad?)"; fail=$((fail+1)); return; fi

  # 2) normalizuj (usun pola zmienne, ustal deterministyczny porzadek kluczy)
  local norm="$TMP/$code.norm.json"
  jq -S 'del(.generated_at, ._demo)' "$raw" > "$norm"

  # 3) wersja = sha256 tresci (12 znakow)
  local version eid updated_at
  version=$(sha256sum "$norm" | cut -c1-12)
  eid=$(jq -r '.event.id' "$norm")
  updated_at=$(jq -r '.event.updated_at // ""' "$norm")

  local bundle_path="events/$code/$version.json"
  local manifest_path="events/$code/manifest.json"

  # 4) wgraj niezmienny bundel (idempotentnie; jesli juz jest ta wersja, nadpisanie tym samym)
  $RCLONE copyto "$norm" "r2:$R2_BUCKET/$bundle_path" \
    --header-upload "Content-Type: application/json; charset=utf-8" \
    --header-upload "$CC_IMMUTABLE" >/dev/null

  # 5) zbuduj i wgraj manifest (maly, krotki cache)
  local manifest="$TMP/$code.manifest.json"
  jq -n --arg code "$code" --argjson eid "$eid" --arg version "$version" \
        --arg updated_at "$updated_at" --arg bundle_path "$bundle_path" \
        --arg bundle_url "$R2_PUBLIC_BASE/$bundle_path" --arg gen "$(date -u +%FT%TZ)" \
        '{code:$code, event_id:$eid, version:$version, updated_at:$updated_at,
          bundle_path:$bundle_path, bundle_url:$bundle_url, generated_at:$gen}' > "$manifest"
  $RCLONE copyto "$manifest" "r2:$R2_BUCKET/$manifest_path" \
    --header-upload "Content-Type: application/json; charset=utf-8" \
    --header-upload "$CC_MANIFEST" >/dev/null

  # 6) weryfikuj publiczny odczyt
  local mc bc
  mc=$(curl -sS -4 -m 20 -o /dev/null -w "%{http_code}" "$R2_PUBLIC_BASE/$manifest_path" 2>/dev/null || echo 000)
  bc=$(curl -sS -4 -m 20 -o /dev/null -w "%{http_code}" "$R2_PUBLIC_BASE/$bundle_path" 2>/dev/null || echo 000)
  echo "  wersja=$version  event_id=$eid"
  echo "  manifest: $R2_PUBLIC_BASE/$manifest_path  (http=$mc)"
  echo "  bundel:   $R2_PUBLIC_BASE/$bundle_path  (http=$bc)"
  if [[ "$mc" == "200" && "$bc" == "200" ]]; then ok=$((ok+1)); else echo "  UWAGA: publiczny odczyt != 200"; fail=$((fail+1)); fi
}

for c in "$@"; do bake_one "$c"; done
echo "== gotowe: OK=$ok, bledy=$fail =="
[[ $fail -eq 0 ]]
