#!/usr/bin/env bash
# Kontrola povoleni v manifeste APK (PLAN_VYVOJA S-01b, docs/10 6.1).
#
#   tool/check_manifest.sh [--build] [--edition lite|full] [APK alebo manifest.xml]
#   tool/check_manifest.sh --rules   # len pravidla zalohy (bez APK)
#
# Bez argumentu kontroluje build/app/outputs/flutter-apk/app-devlite-debug.apk,
# s --build ho najprv postavi. Edition sa odvodi z nazvu suboru (lite/full),
# inak sa berie lite (prisnejsia kontrola).
#
# lite: nesmie mat FOREGROUND_SERVICE_SPECIAL_USE, PACKAGE_USAGE_STATS,
#       SYSTEM_ALERT_WINDOW (brana je len vo full).
# vsetky: nesmu mat QUERY_ALL_PACKAGES, REQUEST_IGNORE_BATTERY_OPTIMIZATIONS,
#       USE_EXACT_ALARM, SCHEDULE_EXACT_ALARM (F-01: len inexact), polohu,
#       BIND_ACCESSIBILITY_SERVICE (PLAN_VYVOJA 5.5 bod 6).
# zaloha (C-02): manifest odkazuje na dataExtractionRules (Android 12+)
#       a fullBackupContent (starsie), subory pravidiel existuju, zalohuju
#       user.db a NIKDY nezahrnu dennik (journal.db) ani cely adresar.
set -euo pipefail

cd "$(dirname "$0")/.."

build=false
rules_only=false
edition=""
target=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --build) build=true ;;
    --rules) rules_only=true ;;
    --edition) edition="${2:?--edition potrebuje lite alebo full}"; shift ;;
    -h|--help) sed -n '2,19p' "$0"; exit 0 ;;
    *) target="$1" ;;
  esac
  shift
done

# ------------------------------------------------------------ pravidla zalohy
res="android/app/src/main/res"
extraction="$res/xml/data_extraction_rules.xml"
legacy_files=("$res/xml/backup_rules_legacy.xml" "$res/xml-v28/backup_rules_legacy.xml")
rules_fail=0
rule_error() { echo "ZALOHA: $*" >&2; rules_fail=1; }
for f in "$extraction" "${legacy_files[@]}"; do
  if [[ ! -f "$f" ]]; then
    rule_error "chyba $f"
    continue
  fi
  # Dennik nesmie byt v zalohe ani v prenose (privacy policy: neopusti zariadenie).
  if grep -Eq '<include[^>]*journal' "$f"; then
    rule_error "$f zahrna dennik (journal*)"
  fi
  if grep -Eq '<include[^>]*path="\.?/?"' "$f"; then
    rule_error "$f zahrna cely adresar (path=\".\")"
  fi
done
if [[ -f "$extraction" ]]; then
  for section in cloud-backup device-transfer; do
    grep -q "<$section" "$extraction" || rule_error "$extraction: chyba <$section>"
  done
  grep -q 'path="user.db"' "$extraction" || rule_error "$extraction: chyba include user.db"
fi
manifest_src="android/app/src/main/AndroidManifest.xml"
for attr in 'android:dataExtractionRules="@xml/data_extraction_rules"' \
  'android:fullBackupContent="@xml/backup_rules_legacy"'; do
  grep -qF "$attr" "$manifest_src" || rule_error "$manifest_src: chyba $attr"
done
if [[ $rules_fail -ne 0 ]]; then
  exit 1
fi
echo "Pravidla zalohy OK (journal.db sa nezalohuje)"
if $rules_only; then
  exit 0
fi

if [[ -z "$target" ]]; then
  target="build/app/outputs/flutter-apk/app-devlite-debug.apk"
  if $build; then
    flutter build apk --debug --flavor devLite
  fi
fi

if [[ -z "$edition" ]]; then
  case "$(basename "$target" | tr '[:upper:]' '[:lower:]')" in
    *full*) edition=full ;;
    *) edition=lite ;;
  esac
fi
if [[ "$edition" != lite && "$edition" != full ]]; then
  echo "Neznama edition: $edition" >&2
  exit 2
fi

if [[ ! -f "$target" ]]; then
  echo "Subor neexistuje: $target (spusti s --build)" >&2
  exit 2
fi

# Text manifestu: priamo XML alebo z APK cez aapt2.
case "$target" in
  *.apk)
    sdk="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-}}"
    aapt2="$(command -v aapt2 || true)"
    if [[ -z "$aapt2" && -n "$sdk" ]]; then
      aapt2="$(find "$sdk/build-tools" -name aapt2 -type f 2>/dev/null | sort -V | tail -1)"
    fi
    if [[ -z "$aapt2" ]]; then
      echo "aapt2 nenajdene (nastav ANDROID_HOME)" >&2
      exit 2
    fi
    manifest="$("$aapt2" dump xmltree --file AndroidManifest.xml "$target")"
    ;;
  *) manifest="$(cat "$target")" ;;
esac

forbidden=(
  android.permission.QUERY_ALL_PACKAGES
  android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS
  android.permission.USE_EXACT_ALARM
  android.permission.SCHEDULE_EXACT_ALARM
  android.permission.ACCESS_FINE_LOCATION
  android.permission.ACCESS_COARSE_LOCATION
  android.permission.BIND_ACCESSIBILITY_SERVICE
)
if [[ "$edition" == lite ]]; then
  forbidden+=(
    android.permission.FOREGROUND_SERVICE_SPECIAL_USE
    android.permission.PACKAGE_USAGE_STATS
    android.permission.SYSTEM_ALERT_WINDOW
  )
fi

fail=0
for p in "${forbidden[@]}"; do
  if grep -qF "\"$p\"" <<<"$manifest"; then
    echo "ZAKAZANE ($edition): $p v $target" >&2
    fail=1
  fi
done

# Vysledny manifest (APK/merged) musi odkazovat na pravidla zalohy.
for attr in dataExtractionRules fullBackupContent; do
  if ! grep -q "$attr" <<<"$manifest"; then
    echo "ZALOHA: v $target chyba android:$attr" >&2
    fail=1
  fi
done

if [[ $fail -ne 0 ]]; then
  exit 1
fi
echo "Manifest OK ($edition): $target"
