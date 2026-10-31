#!/usr/bin/env bash
# Lokalny release build ako v CI (docs/06 B.5, D.3, PLAN_VYVOJA Q-02).
#
#   tool/build_release.sh [--flavor prodLite] [--build-number N] [--apk]
#
# Postavi AAB (s --apk aj APK) s R8 a obfuskaciou Dartu, symboly da do
# build/symbols, skontroluje manifest (tool/check_manifest.sh) a vypise
# velkost a podpis. Podpis: android/key.properties alebo PROSOCHE_UPLOAD_* env
# (pozri android/app/build.gradle.kts); bez nich debug kluc s warningom,
# taky AAB sa do Google Play neda nahrat.
set -euo pipefail

cd "$(dirname "$0")/.."

flavor=prodLite
build_number=""
apk=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    --flavor) flavor="${2:?--flavor potrebuje hodnotu}"; shift ;;
    --build-number) build_number="${2:?--build-number potrebuje cislo}"; shift ;;
    --apk) apk=true ;;
    -h|--help) sed -n '2,10p' "$0"; exit 0 ;;
    *) echo "Neznamy argument: $1" >&2; exit 2 ;;
  esac
  shift
done

# prodLite -> prodLiteRelease (gradle) a prod-lite (nazov suboru).
variant="${flavor}Release"
kebab="$(sed -E 's/([A-Z])/-\L\1/g' <<<"$flavor")"
lower="$(tr '[:upper:]' '[:lower:]' <<<"$flavor")"

if [[ ! -f android/key.properties && -z "${PROSOCHE_UPLOAD_STORE_FILE:-}" ]]; then
  echo "WARNING: chyba android/key.properties aj PROSOCHE_UPLOAD_* env," \
    "release sa podpise DEBUG klucom (len lokalne testovanie)." >&2
fi

args=(--release --flavor "$flavor" --obfuscate --split-debug-info=build/symbols)
if [[ -n "$build_number" ]]; then
  args+=(--build-number="$build_number")
fi

flutter build appbundle "${args[@]}"
aab="build/app/outputs/bundle/${variant}/app-${kebab}-release.aab"

manifest="build/app/intermediates/merged_manifests/${variant}/process${flavor^}ReleaseManifest/AndroidManifest.xml"
./tool/check_manifest.sh --edition "$([[ $lower == *full* ]] && echo full || echo lite)" "$manifest"

if $apk; then
  flutter build apk "${args[@]}"
  ./tool/check_manifest.sh "build/app/outputs/flutter-apk/app-${lower}-release.apk"
fi

printf '\nAAB: %s (%s)\n' "$aab" "$(du -h "$aab" | cut -f1)"
printf 'Mapping: build/app/outputs/mapping/%s/mapping.txt\n' "$variant"
printf 'Dart symboly: build/symbols\n'
if command -v keytool >/dev/null; then
  keytool -printcert -jarfile "$aab" 2>/dev/null | grep -m1 -E '^(Owner|Vlastn)' || true
fi
