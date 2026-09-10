# app/ — Aplikacja Mobilna Eskulapp (Android)

Tu mieszka **projekt Android** (Kotlin/Compose, MVVM, offline-first/Room). Pusty do
Fazy 2 (patrz `docs/PLAN-MVP.md`). Projekt Gradle zakłada agent przy pierwszym
kamieniu.

Build (toolchain wspólny z `aapsbuilder`/`foodvision` — NIE instaluj od zera):
```bash
cd ~/agents/eskulapp/app
JAVA_HOME=~/jdk17 ANDROID_HOME=~/android-sdk \
  ./gradlew --no-daemon --max-workers=2 -Dorg.gradle.java.home=$HOME/jdk17 \
  :app:assembleDebug
```
- `local.properties`: `sdk.dir=/home/jjeerry/android-sdk`
- Build w tle, log do `app/build.log`.
- Package: `pl.eskulapp.mobile` [DO USTALENIA]. Podpis: własny nowy keystore
  (chmod 600, `keystore.properties`) — NIE klucz aaps-mobile/foodvision.
