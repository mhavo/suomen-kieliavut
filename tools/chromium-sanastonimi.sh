#!/usr/bin/env bash
# Selvittää, millä nimellä tämä Chromium-versio etsii suomen oikolukusanastoa.
#
# Nimi on <kielikoodi>-<sanastoversio>.bdic ja sanastoversio on KIELIKOHTAINEN
# (en-US on 10-1 mutta fi on 3-0), joten sitä ei voi päätellä muista kielistä
# eikä arvata. Se on kovakoodattu Chromiumin lähdekoodiin ja voi muuttua
# päivityksissä. Väärin nimetty .bdic ohitetaan täysin ilman virheilmoitusta.
#
# Temppu: ajetaan kertakäyttöisellä profiililla, jossa suomen oikoluku on päällä
# mutta sanastoa ei ole. Chromium yrittää silloin hakea puuttuvan tiedoston
# Googlelta, ja lokista näkee tarkan tiedostonimen. Lataus epäonnistuu (404),
# koska Google ei toimita suomen sanastoa — se on tässä sivuseikka.
set -euo pipefail

KIELI="${1:-fi}"
BROWSER="${CHROMIUM:-chromium}"
command -v "$BROWSER" >/dev/null || { echo "$BROWSER puuttuu (aseta CHROMIUM=)" >&2; exit 1; }

WORK="$(mktemp -d)"; trap 'rm -rf "$WORK"' EXIT
mkdir -p "$WORK/Default" "$WORK/Dictionaries"
cat > "$WORK/Default/Preferences" <<JSON
{"intl":{"accept_languages":"$KIELI,en-US,en"},
 "spellcheck":{"dictionaries":["$KIELI"],"dictionary":""},
 "browser":{"enable_spellchecking":true}}
JSON

echo "==> käynnistetään kertakäyttöinen profiili ($KIELI)"
( cd "$WORK" && timeout 90 "$BROWSER" --headless=new --no-sandbox --disable-gpu \
    --user-data-dir="$WORK" --enable-logging=stderr --v=1 \
    --virtual-time-budget=5000 --dump-dom "data:text/html,<textarea>x</textarea>" \
    >/dev/null 2>"$WORK/log.txt" ) || true

NIMI="$(grep -oE "/dict/${KIELI}-[0-9]+-[0-9]+\.bdic" "$WORK/log.txt" 2>/dev/null \
        | head -1 | sed 's|.*/||')"

if [ -z "$NIMI" ]; then
    NIMI="$(grep -oE "${KIELI}-[0-9]+-[0-9]+\.bdic" "$WORK/log.txt" 2>/dev/null | head -1)"
fi

if [ -z "$NIMI" ]; then
    echo "Tiedostonimeä ei löytynyt lokista." >&2
    echo "Mahdollisia syitä: Chromium ei tue kieltä '$KIELI' lainkaan, tai" >&2
    echo "lokimuoto on muuttunut. Raakaloki: $WORK/log.txt (poistuu heti)." >&2
    exit 1
fi

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
echo "==> $("$BROWSER" --version) etsii nimeä: $NIMI"
echo
echo "asennus:"
echo "  install -Dm644 $REPO/build/fi-FI.bdic ~/.config/chromium/Dictionaries/$NIMI"
echo
echo "muista myös: pelkkä tiedosto ei riitä. Kieli on merkittävä profiilin"
echo "             Preferences-tiedostoon, EIKÄ sitä voi tehdä sivulta"
echo "             chrome://settings/languages — suomi ei ole Chromiumin"
echo "             tuettujen oikolukukielten listassa, joten sivu ei tarjoa"
echo "             sille oikolukurastia lainkaan (ks. tämän skriptin alku)."
echo "             Tee se selain suljettuna: tools/chromium-ota-kayttoon.sh"
