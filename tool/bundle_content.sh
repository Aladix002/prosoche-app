#!/usr/bin/env bash
# Pribali content.db do assetov (D-03, Q-03). Subory su gitignored.
#
#   tool/bundle_content.sh [cesta k sakina-content]
#
# Default: $SAKINA_CONTENT_DIR, inak ../sakina-content vedla repa.
# Skopiruje dist/content.db.gz a dist/manifest.json do assets/content/
# a overi gz_sha256/gz_size podla manifestu. Db sa pribaluje komprimovana
# (~9,5 MB namiesto ~32 MB), appka ju rozbali pri prvom starte a overi
# sha256/size rozbalenej db (ContentPackService.ensureInstalled).
set -euo pipefail

cd "$(dirname "$0")/.."

src="${1:-${SAKINA_CONTENT_DIR:-../sakina-content}}"
dist="$src/dist"
out="assets/content"

fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }

for f in content.db.gz manifest.json; do
  [[ -f "$dist/$f" ]] || fail "chyba $dist/$f (spusti make all v sakina-content)"
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
