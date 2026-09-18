#!/usr/bin/env bash
# Skenaario 04 — pelkät profiilityökalut, ilman asenninta.
#
# Kaksi Firefox-profiilia ja kolme Chromium-profiilia, joista yksi on
# "System Profile" jota työkalu dokumentoidusti ei kosketa. Molemmat työkalut
# ajetaan KAHDESTI: toinen ajo mittaa idempotenssin (väite 13) ja sen, ettei
# se jätä toista varmuuskopiota.
set -euo pipefail
# shellcheck source-path=SCRIPTDIR/.. source=tarkista.sh
source /repo/testi/tarkista.sh

REPO=/repo bash /repo/testi/valeprofiilit.sh

echo "# firefox-ota-kayttoon.sh --kaikki-profiilit (ajo 1)"
bash /repo/tools/firefox-ota-kayttoon.sh --kaikki-profiilit 2>&1 | sed 's/^/  | /'
echo "# firefox-ota-kayttoon.sh --kaikki-profiilit (ajo 2)"
koodi=0
bash /repo/tools/firefox-ota-kayttoon.sh --kaikki-profiilit 2>&1 | sed 's/^/  | /' || koodi=$?
vaite 13a 'firefox-ota-kayttoon.sh toinen ajo, paluukoodi' '0' "$koodi"

echo "# chromium-ota-kayttoon.sh --kaikki-profiilit (ajo 1)"
bash /repo/tools/chromium-ota-kayttoon.sh --kaikki-profiilit 2>&1 | sed 's/^/  | /'
echo "# chromium-ota-kayttoon.sh --kaikki-profiilit (ajo 2)"
koodi=0
bash /repo/tools/chromium-ota-kayttoon.sh --kaikki-profiilit 2>&1 | sed 's/^/  | /' || koodi=$?
vaite 13b 'chromium-ota-kayttoon.sh toinen ajo, paluukoodi' '0' "$koodi"

# Toinen ajo ei saa jättää toista varmuuskopiota kumpaankaan profiiliin.
varmuudet="$(find "$HOME/.mozilla/firefox" "${XDG_CONFIG_HOME:-$HOME/.config}/chromium" \
    -name '*.bak-*' | wc -l)"
vaite 13c 'varmuuskopioita yhteensä kahden ajon jälkeen' '4' "$varmuudet"

joukko_profiilit
yhteenveto
