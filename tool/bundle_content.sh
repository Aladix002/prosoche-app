#!/usr/bin/env bash
# Pribali content.db do assetov (D-03, Q-03). Subory su gitignored.
#
#   tool/bundle_content.sh [--build] [cesta k prosoche-content]
#
# Default: $PROSOCHE_CONTENT_DIR, inak prvy existujuci z ../prosoche-content
# a ../../prosoche-content (git worktree v prosoche/wt/<ID>).
# --build (alebo chybajuci dist/) spusti v prosoche-content `make build sign`
# (lokalny dev kluc keys/content-dev.pem, nikdy v gite).
# Skopiruje dist/content.db.gz a dist/manifest.json do assets/content/
# a overi gz_sha256/gz_size podla manifestu. Db (content.db v1, ~3,5 MB) sa
# pribaluje komprimovana (~1,4 MB), appka ju rozbali pri prvom starte
# a overi sha256/size a integritu (ContentPackService.ensureInstalled).
set -euo pipefail

cd "$(dirname "$0")/.."

build=false
if [[ "${1:-}" == "--build" ]]; then
  build=true
  shift
fi

fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }

src="${1:-${PROSOCHE_CONTENT_DIR:-}}"
if [[ -z "$src" ]]; then
  for c in ../prosoche-content ../../prosoche-content; do
    if [[ -d "$c/schema" ]]; then src="$c"; break; fi
  done
fi
[[ -n "$src" && -d "$src" ]] || fail "prosoche-content nenajdeny (PROSOCHE_CONTENT_DIR)"
dist="$src/dist"
out="assets/content"

if $build || [[ ! -f "$dist/content.db.gz" || ! -f "$dist/manifest.json" ]]; then
  make -C "$src" build sign
fi

for f in content.db.gz manifest.json; do
  [[ -f "$dist/$f" ]] || fail "chyba $dist/$f (spusti make build sign v prosoche-content)"
done

# Hodnota z bloku "db" v manifeste.
field() {
  sed -n '/"db": {/,/}/p' "$dist/manifest.json" |
    sed -n "s/^ *\"$1\": *\"\{0,1\}\([0-9a-f]*\)\"\{0,1\},\{0,1\}$/\1/p" |
    head -1
}
want_sha="$(field gz_sha256)"
want_size="$(field gz_size)"
got_sha="$(sha256sum "$dist/content.db.gz" | cut -d' ' -f1)"
got_size="$(wc -c < "$dist/content.db.gz" | tr -d ' ')"
[[ -n "$want_sha" && "$got_sha" == "$want_sha" ]] ||
  fail "gz_sha256 $got_sha != manifest $want_sha"
[[ "$got_size" == "$want_size" ]] ||
  fail "gz_size $got_size != manifest $want_size"

mkdir -p "$out"
# Stara nekomprimovana db z predoslej verzie skriptu by isla do APK navyse.
rm -f "$out/content.db"
cp "$dist/content.db.gz" "$out/content.db.gz.tmp"
mv "$out/content.db.gz.tmp" "$out/content.db.gz"
cp "$dist/manifest.json" "$out/manifest.json"
cv="$(sed -n 's/^ *"content_version": *\([0-9]*\),$/\1/p' "$dist/manifest.json" | head -1)"
echo "OK: $out/content.db.gz content_version=$cv ($got_size B)"
