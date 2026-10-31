#!/usr/bin/env bash
# Kontrola povoleni v manifeste APK (PLAN_VYVOJA S-01b, docs/10 6.1).
#
#   tool/check_manifest.sh [--build] [--edition lite|full] [APK alebo manifest.xml]
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
set -euo pipefail

cd "$(dirname "$0")/.."

build=false
edition=""
target=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --build) build=true ;;
    --edition) edition="${2:?--edition potrebuje lite alebo full}"; shift ;;
    -h|--help) sed -n '2,14p' "$0"; exit 0 ;;
    *) target="$1" ;;
  esac
  shift
done

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

if [[ $fail -ne 0 ]]; then
  exit 1
fi
echo "Manifest OK ($edition): $target"
