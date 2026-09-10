#!/usr/bin/env bash
# Eskulapp , zbuduj podpisany AAB (offline) i wyslij na Google Play.
# Wzor uzycia:
#   tools/play/release.sh internal "Poprawka X"
#   tools/play/release.sh production "Wydanie 1.1" 0.2      # staged 20%
# Argumenty: <track> [notatki] [rollout 0..1]
set -euo pipefail

TRACK="${1:-internal}"
NOTES="${2:-}"
ROLLOUT="${3:-}"

ROOT="$HOME/agents/eskulapp"
APP="$ROOT/app"
AAB="$APP/app/build/outputs/bundle/release/app-release.aab"

echo "== Build AAB (offline, release) =="
cd "$APP"
JAVA_HOME="$HOME/jdk17" ANDROID_HOME="$HOME/android-sdk" ./gradlew --no-daemon --offline \
  --max-workers=2 -Dorg.gradle.java.home="$HOME/jdk17" :app:bundleRelease

[ -f "$AAB" ] || { echo "Brak AAB: $AAB"; exit 1; }

ARGS=(--aab "$AAB" --track "$TRACK")
[ -n "$NOTES" ] && ARGS+=(--notes "$NOTES")
[ -n "$ROLLOUT" ] && ARGS+=(--rollout "$ROLLOUT")

echo "== Wysylka na Play (track: $TRACK) =="
python3 "$ROOT/tools/play/deploy.py" "${ARGS[@]}"
