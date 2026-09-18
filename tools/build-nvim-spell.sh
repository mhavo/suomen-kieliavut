#!/usr/bin/env bash
# Kääntää hunspell-sanaston Neovimin .spl-muotoon.
# Ks. ../README.md kohta "Neovim"
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# mkspell vaatii että .aff ja .dic ovat samannimiset ja samassa hakemistossa,
# ja perusnimen on oltava kielikoodi jota :set spelllang= käyttää.
cp "$REPO/dict/ginter/fi_FI.aff" "$WORK/fi.aff"
cp "$REPO/dict/ginter/fi_FI.dic" "$WORK/fi.dic"

echo "==> :mkspell (14 MB sanasto — tämä kestää muutaman minuutin)"
# -u pakottaa ylikirjoituksen, --headless ajaa ilman käyttöliittymää.
nvim --headless -u NONE \
     -c "cd $WORK" \
     -c 'mkspell! fi fi' \
     -c 'qa!'

OUT="$WORK/fi.utf-8.spl"
[ -f "$OUT" ] || { echo "mkspell ei tuottanut $OUT" >&2; exit 1; }
cp "$OUT" "$REPO/build/fi.utf-8.spl"
echo "==> valmis: $REPO/build/fi.utf-8.spl ($(du -h "$REPO/build/fi.utf-8.spl" | cut -f1))"
