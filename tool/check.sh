#!/usr/bin/env bash
# Vsetky kontroly ako CI (PLAN_VYVOJA 4.2 bod 1, docs/06 D.2).
#
#   ./tool/check.sh
#
# Poradie: pub get, merge_arb + gen-l10n + build_runner (bez diffu),
# format, analyze, zakazane vzory, testy s pokrytim, prah pokrytia.
set -euo pipefail

cd "$(dirname "$0")/.."

step() { printf '\n== %s\n' "$*"; }
fail() { printf '\nFAIL: %s\n' "$*" >&2; exit 1; }

# Odtlacok generovanych suborov (obsah aj zoznam), aby sa dal zistit diff
# aj lokalne s neulozenymi zmenami.
generated_fingerprint() {
  {
    find lib test -type f \( -name '*.g.dart' -o -name '*.freezed.dart' \
      -o -name '*.pigeon.dart' \) 2>/dev/null
    find lib/core/l10n/generated -type f 2>/dev/null
    find lib/l10n -maxdepth 1 -name 'app_*.arb' -type f 2>/dev/null
  } | LC_ALL=C sort | while read -r f; do
    printf '%s ' "$f"
    sha256sum "$f" | cut -d' ' -f1
  done | sha256sum | cut -d' ' -f1
}

step "verzia Flutteru (pubspec environment.flutter)"
pinned="$(awk '/^environment:/ {e=1; next} e && /^[^ ]/ {e=0} e && $1 == "flutter:" {print $2}' pubspec.yaml | tr -d "\"'")"
actual="$(flutter --version --machine 2>/dev/null | sed -n 's/.*"frameworkVersion": *"\([^"]*\)".*/\1/p' | head -1)"
echo "pin: $pinned, lokalne: $actual"
[[ -n "$pinned" && "$pinned" == "$actual" ]] || fail "Flutter $actual != pin $pinned"

step "flutter pub get"
before="$(generated_fingerprint)"
flutter pub get

step "codegen: merge_arb, gen-l10n, build_runner"
dart run tool/merge_arb.dart
flutter gen-l10n
dart run build_runner build --delete-conflicting-outputs
after="$(generated_fingerprint)"
if [[ "$before" != "$after" ]]; then
  git status --short -- lib test || true
  fail "Generovany kod nebol aktualny. Skontroluj zmeny vyssie a commitni ich."
fi

step "dart format"
dart format --output=none --set-exit-if-changed lib test tool

step "flutter analyze"
flutter analyze --fatal-infos

step "zakazane vzory (docs/06 D.2)"
violations=0
check_absent() {
  local what="$1"
  shift
  local out
  out="$("$@" || true)"
  if [[ -n "$out" ]]; then
    printf '%s:\n%s\n' "$what" "$out" >&2
    violations=1
  fi
}
check_absent "print/debugPrint mimo AppLogger" \
  bash -c "grep -rnE '\\b(print|debugPrint)\\(' lib --include='*.dart' | grep -v 'lib/core/logging/app_logger.dart'"
check_absent "DateTime.now() v lib/domain" \
  grep -rn 'DateTime.now()' lib/domain
check_absent "flutter/drift import v lib/domain" \
  grep -rnE 'package:(flutter|drift)/' lib/domain
check_absent "kluce a tajomstva" \
  grep -rnE '(BEGIN (RSA|OPENSSH|PRIVATE) KEY|AIza[0-9A-Za-z_-]{35})' . \
  --exclude-dir=.git --exclude-dir=build --exclude-dir=.dart_tool
[[ $violations -eq 0 ]] || fail "Zakazane vzory"

step "pravidla Android zalohy (C-02: dennik sa nezalohuje)"
./tool/check_manifest.sh --rules

step "flutter test --coverage"
flutter test --coverage

step "pokrytie (PLAN_VYVOJA 4.2 bod 2)"
# Suhrn LH/LF z lcov.info pre subory pod danym prefixom, bez lcov nastroja.
# Generovany kod (*.g.dart, *.freezed.dart) sa nepocita: drift *.g.dart
# ma ~90 % riadkov lib/data a prekryval by pokrytie rucne pisaneho kodu.
coverage_gate() {
  local prefix="$1" min="$2"
  awk -v prefix="$prefix" -v min="$min" '
    /^SF:/ { sf = substr($0, 4); sub(/^.*\/lib\//, "lib/", sf); on = index(sf, prefix) == 1 && sf !~ /\.(g|freezed)\.dart$/ }
    on && /^LF:/ { lf += substr($0, 4) }
    on && /^LH:/ { lh += substr($0, 4) }
    END {
      if (lf == 0) { printf "%s: bez kodu, preskocene\n", prefix; exit 0 }
      pct = 100 * lh / lf
      printf "%s: %.1f %% (%d/%d), minimum %d %%\n", prefix, pct, lh, lf, min
      exit (pct < min)
    }' coverage/lcov.info
}
coverage_gate lib/domain/ 90 || fail "Pokrytie lib/domain < 90 %"
coverage_gate lib/data/ 80 || fail "Pokrytie lib/data < 80 %"

printf '\nOK: vsetky kontroly presli.\n'
