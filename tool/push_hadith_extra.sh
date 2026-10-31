#!/usr/bin/env bash
# Nahra hadith_extra.db do app support adresara DEBUG dev buildu (D-05).
# Len na lokalne testovanie; balik sa do APK nepribaluje.
#
#   tool/push_hadith_extra.sh [cesta k sakina-content]
#
# Default: $SAKINA_CONTENT_DIR, inak ../sakina-content vedla repa.
# Env: APP_ID (default app.mursa.dev), ANDROID_SERIAL (vyber zariadenia).
#
# Balik musi byt z toho isteho buildu ako pribalena content.db
# (tool/bundle_content.sh): appka ho pri starte porovna s
# meta.hadith_extra_sha256/size content.db, inak je "zastaraly".
# run-as funguje len pre debuggable build (flutter run --flavor devLite).
set -euo pipefail

cd "$(dirname "$0")/.."

src="${1:-${SAKINA_CONTENT_DIR:-../sakina-content}}"
pack="$src/dist/hadith_extra.db"
app="${APP_ID:-app.mursa.dev}"

fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }

[[ -f "$pack" ]] || fail "chyba $pack (spusti make all v sakina-content)"
command -v adb >/dev/null || fail "adb nie je v PATH"
[[ "$app" == *.dev ]] || fail "len dev build ($app)"

got_sha="$(sha256sum "$pack" | cut -d' ' -f1)"
got_size="$(wc -c < "$pack" | tr -d ' ')"

# sha256 balika z manifest.packs (pribaleny manifest = rovnaky build).
pack_sha() {
  sed -n '/"id": "hadith_extra"/,/}/p' "$1" |
    sed -n 's/^ *"sha256": *"\([0-9a-f]*\)",\{0,1\}$/\1/p' | head -1
}
for m in "$src/dist/manifest.json" assets/content/manifest.json; do
  [[ -f "$m" ]] || continue
  want="$(pack_sha "$m")"
  [[ -z "$want" || "$want" == "$got_sha" ]] ||
    fail "$pack nesedi s $m (sha256 $got_sha != $want); spusti tool/bundle_content.sh"
done

adb shell run-as "$app" true 2>/dev/null ||
  fail "run-as $app zlyhal (nainstaluj debug dev build)"

adb shell run-as "$app" mkdir -p files/content
# Cez /data/local/tmp (exec-in + run-as na emulatore subor nevytvori);
# adb spaja argumenty do jedneho prikazu, preto vnorene uvodzovky.
# Najprv .next, potom atomicky mv.
tmp=/data/local/tmp/mursa_hadith_extra.db
adb push "$pack" "$tmp" >/dev/null
adb shell run-as "$app" sh -c "'cp $tmp files/content/hadith_extra.db.next'"
adb shell rm -f "$tmp"
adb shell run-as "$app" sh -c \
  "'rm -f files/content/hadith_extra.sha256 && mv files/content/hadith_extra.db.next files/content/hadith_extra.db'"
remote_size="$(adb shell run-as "$app" wc -c files/content/hadith_extra.db | awk '{print $1}' | tr -d '\r')"
[[ "$remote_size" == "$got_size" ]] || fail "velkost na zariadeni $remote_size != $got_size"

adb shell am force-stop "$app"
echo "OK: $app files/content/hadith_extra.db ($got_size B, sha256 $got_sha); spusti appku znova"
