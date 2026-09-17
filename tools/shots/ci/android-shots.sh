#!/usr/bin/env bash
# Zrzuty ekranu PRAWDZIWEJ apki Android na emulatorze (CI, android-emulator-runner).
# Przechodzi przez apke po tekstach z uiautomator (Compose wystawia semantyke) i robi PNG.
# Uzycie: tools/shots/ci/android-shots.sh <apk> <katalog_wyjscia>
set -uo pipefail
APK="$1"; OUT="$2"; mkdir -p "$OUT"
PKG=pl.eskulapp.mobile.debug
N=0

dump() { adb shell uiautomator dump /sdcard/ui.xml >/dev/null 2>&1; adb exec-out cat /sdcard/ui.xml; }

# tap_match <regex> [indeks]: stuknij w srodek wezla, ktorego text/content-desc pasuje do regexu
# ("EditText" = pierwsze pole tekstowe po klasie; indeks -1 = ostatnie trafienie, np. dolne menu)
tap_match() {
  local re="$1" idx="${2:-0}" xy
  for _ in 1 2 3 4 5 6 7 8; do
    xy=$(dump | python3 -c '
import re, sys, xml.etree.ElementTree as ET
rx, idx = re.compile(sys.argv[1]), int(sys.argv[2])
hits = []
for n in ET.fromstring(sys.stdin.read()).iter("node"):
    t = n.get("text") or n.get("content-desc") or ""
    ok = rx.search(n.get("class") or "") if sys.argv[1].startswith("EditText") else rx.search(t)
    if ok:
        x1, y1, x2, y2 = map(int, re.findall(r"\d+", n.get("bounds")))
        hits.append(((x1 + x2) // 2, (y1 + y2) // 2))
if len(hits) > idx: print(*hits[idx])
elif hits: print(*hits[-1])
' "$re" "$idx" 2>/dev/null)
    if [[ -n "$xy" ]]; then adb shell input tap $xy; sleep 2; return 0; fi
    sleep 1.5
  done
  echo "NIE ZNALEZIONO: $re"; dump | grep -o 'text="[^"]*"' | head -40; return 1
}

shot() { N=$((N+1)); sleep 2.5; adb exec-out screencap -p > "$OUT/$(printf %02d $N)-$1.png"; echo "zrzut $N: $1"; }

add_code() {
  tap_match "EditText" 0 || adb shell input tap 540 900
  adb shell input text "$1"; sleep 1
  adb shell input keyevent 111; sleep 1   # schowaj klawiature
  [[ "${2:-}" == shot ]] && shot wejscie-kodem
  tap_match "^Pobierz wydarzenie$"; sleep 5
}

adb install -r "$APK"
adb shell pm grant $PKG android.permission.POST_NOTIFICATIONS 2>/dev/null
# Czysty pasek statusu (tryb demo): 9:41, pelna bateria i zasieg, bez ikon powiadomien
adb shell settings put global sysui_demo_allowed 1
adb shell am broadcast -a com.android.systemui.demo -e command enter >/dev/null
adb shell am broadcast -a com.android.systemui.demo -e command clock -e hhmm 0941 >/dev/null
adb shell am broadcast -a com.android.systemui.demo -e command battery -e level 100 -e plugged false >/dev/null
adb shell am broadcast -a com.android.systemui.demo -e command network -e wifi show -e level 4 >/dev/null
adb shell am broadcast -a com.android.systemui.demo -e command network -e mobile show -e level 4 -e datatype none >/dev/null
adb shell am broadcast -a com.android.systemui.demo -e command notifications -e visible false >/dev/null

adb shell monkey -p $PKG -c android.intent.category.LAUNCHER 1 >/dev/null; sleep 6

# Najpierw dwa pozostale eventy (lista ma pokazac rozne statusy), na koncu TEST02 = glowny.
dump > /dev/null
add_code TEST03
adb shell input keyevent 4; sleep 2
tap_match "^Dodaj wydarzenie kodem$"
add_code TEST01
adb shell input keyevent 4; sleep 2
tap_match "^Dodaj wydarzenie kodem$"
add_code TEST02 shot

shot ekran-wydarzenia
tap_match "^Agenda$" 0; shot agenda
tap_match "^[0-9]{2}:[0-9]{2}$" 1; shot prelekcja
adb shell input keyevent 4; sleep 2
tap_match "^Wydarzenie$"; tap_match "^Prelegenci$" 0; shot prelegenci
tap_match "^Partnerzy$" -1 || true; shot partnerzy
tap_match "^Mapa$" -1; sleep 1; shot mapa
tap_match "^Wydarzenie$"; tap_match "Aktualności" 0; shot aktualnosci
adb shell input keyevent 4; sleep 2
adb shell input keyevent 4; sleep 3
shot moje-wydarzenia
ls -la "$OUT"
