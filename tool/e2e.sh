#!/usr/bin/env bash
# E2E testy (Patrol, patrol_test/) na pripojenom zariadeni alebo emulatore.
#
#   tool/e2e.sh [-c cesta k prosoche-content] [dalsie argumenty pre patrol test]
#   tool/e2e.sh -t patrol_test/s3_quran_search_test.dart
#
# Pribali realnu content.db (tool/bundle_content.sh), postavi devLite
# a spusti vsetky scenare. Appka sa pred behom odinstaluje (cerstva
# instalacia, systemove dialogy povoleni). Scenare s6a a s6b su zavisle,
# spustaju sa spolu.
#
# Poziadavky: patrol_cli (`dart pub global activate patrol_cli 4.8.0`),
# adb v PATH, jedno zariadenie v `adb devices` (inak `-d <id>`).
#
# CI: zatial nie (emulator v CI je mimo rozsahu Q-01). Pripraveny job by
# spustal tento skript na Linux runneri s KVM, napr. cez
# reactivecircus/android-emulator-runner (api-level 36, x86_64).
set -euo pipefail

cd "$(dirname "$0")/.."

content="${PROSOCHE_CONTENT_DIR:-../prosoche-content}"
if [[ "${1:-}" == "-c" ]]; then
  content="$2"
  shift 2
fi

fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }

command -v patrol >/dev/null ||
  fail "chyba patrol (dart pub global activate patrol_cli 4.8.0, PATH += ~/.pub-cache/bin)"
command -v adb >/dev/null || fail "chyba adb (PATH += \$ANDROID_HOME/platform-tools)"
[[ -n "$(adb devices | sed -n '2,$p' | grep -w device || true)" ]] ||
  fail "ziadne zariadenie v adb devices"

tool/bundle_content.sh "$content"

# Vygenerovany bundle testov nema ostat v strome (analyze).
trap 'rm -f patrol_test/test_bundle.dart' EXIT

patrol test \
  --flavor devLite \
  --package-name app.prosoche.dev \
  --app-name "Prosoche Dev" \
  "$@"
