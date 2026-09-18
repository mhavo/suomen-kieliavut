#!/usr/bin/env bash
# Paketoi hunspell-sanaston Firefoxin sanastolaajennukseksi (.xpi).
#
# HUOM: tämä EI rakenna uudelleen tiedostoa build/fi-spell-0.2.xpi. Se on Filip
# Ginterin alkuperäinen julkaisu (fginter/hunspell-fi release 0.2) sellaisenaan,
# omine kuvakkeineen ja omine manifesteineen. Tämä skripti tuottaa erikseen
# nimetyn build/fi-spell-oma-<versio>.xpi:n, jottei alkuperäistä voi vahingossa
# ylikirjoittaa. Ks. ../README.md kohta "Firefox" ja ../LICENSES.md.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
    cat <<'USAGE'
Käyttö: build-xpi.sh [versio] [ginter|karsittu|myspell]

  versio    laajennuksen versionumero, oletus 0.2.1
  sanasto   ginter (oletus) | karsittu | myspell

Tulos: build/fi-spell-oma-<versio>.xpi

Tämä ei rakenna uudelleen build/fi-spell-0.2.xpi:tä — se on upstreamin
alkuperäinen julkaisu sellaisenaan.
USAGE
    exit 0
fi

VERSION="${1:-0.2.1}"
SANASTO="${2:-ginter}"

# Firefox hyväksyy vain muodon 1-4 pistein erotettua numeroa.
case "$VERSION" in
    [0-9]*) ;;
    *) echo "virheellinen versio: $VERSION (odotettiin numeroa, ks. --help)" >&2; exit 2 ;;
esac

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

case "$SANASTO" in
    ginter)   AFF="$REPO/dict/ginter/fi_FI.aff";         DIC="$REPO/dict/ginter/fi_FI.dic" ;;
    karsittu) AFF="$REPO/dict/ginter/fi_FI.aff";         DIC="$REPO/dict/ginter-karsittu/fi_FI.dic" ;;
    myspell)  AFF="$REPO/dict/myspell-fi-0.7/fi-FI.aff"; DIC="$REPO/dict/myspell-fi-0.7/fi-FI.dic" ;;
    *) echo "tuntematon sanasto: $SANASTO (ks. --help)" >&2; exit 2 ;;
esac

case "$SANASTO" in
    ginter)   LISENSSI="CC0-1.0"; TEKIJA="Filip Ginter" ;;
    karsittu) LISENSSI="CC0-1.0"; TEKIJA="Filip Ginter (karsittu)" ;;
    myspell)  LISENSSI="GPL-2.0-only"; TEKIJA="Martin Vermeer, Pauli Virtanen" ;;
esac

mkdir -p "$WORK/dictionaries/fi_FI"
cp "$AFF" "$WORK/dictionaries/fi_FI/fi_FI.aff"
cp "$DIC" "$WORK/dictionaries/fi_FI/fi_FI.dic"

# Firefoxin dictionary-laajennus: manifest_version 2, tyyppi määräytyy
# "dictionaries"-avaimesta. MDN: "If you use the dictionaries key, you must
# also set an ID for your extension using the browser_specific_settings key."
# Gecko-id:n on oltava muotoa <kielikoodi>@dictionaries.addons.mozilla.org tai
# Firefox ei tunnista laajennusta sanastoksi.
#
# browser_specific_settings on nykyinen avain; vanha "applications" on
# vanhentunut (deprecated Firefox 109:stä). Molemmat on mukana, jotta paketti
# asentuu myös vanhoihin Firefoxeihin (< 48), jotka eivät tunne uutta avainta.
cat > "$WORK/manifest.json" <<JSON
{
  "manifest_version": 2,
  "name": "Finnish Spell Dictionary",
  "description": "Suomen oikolukusanasto ($TEKIJA, $LISENSSI)",
  "version": "$VERSION",
  "author": "$TEKIJA",
  "browser_specific_settings": {
    "gecko": { "id": "fi@dictionaries.addons.mozilla.org" }
  },
  "applications": {
    "gecko": { "id": "fi@dictionaries.addons.mozilla.org" }
  },
  "dictionaries": { "fi": "dictionaries/fi_FI/fi_FI.dic" }
}
JSON

python3 -c 'import json,sys; json.load(open(sys.argv[1]))' "$WORK/manifest.json"

OUT="$REPO/build/fi-spell-oma-$VERSION.xpi"
rm -f "$OUT"
( cd "$WORK" && zip -qrX "$OUT" manifest.json dictionaries )
echo "==> valmis: $OUT ($(du -h "$OUT" | cut -f1))"
echo "    sanasto: $SANASTO ($(( $(wc -l < "$DIC") - 1 )) sanuetta, $LISENSSI)"
echo "    asennus: about:addons -> Asenna lisäosa tiedostosta"
# Extension Workshop, "Signing and distribution overview":
#   "Extensions and themes need to be signed by Mozilla before they can be
#    installed in release and beta versions of Firefox. Dictionaries don't
#    need to be signed."
echo "    huom: sanastolaajennukset EIVÄT tarvitse Mozillan allekirjoitusta —"
echo "          tämä asentuu myös tavalliseen Release-Firefoxiin."
