#!/usr/bin/env bash
# Skenaario 05 — install.sh --vain hyphen,oxt,enchant päätteen kanssa.
#
# Kolme osaa jotka oletusajo jättää tekemättä: /usr/share/hyphen (sudo),
# LibreOfficen .oxt-varareitti ja enchantin järjestystiedosto.
#
# VOIKKO ASENNETAAN ENSIN: väite 10 mittaa että enchant tarjoaa tunnuksen fi
# nimenomaan voikko-tarjoajalta. Ilman Voikkoa väite mittaisi vain sitä että
# enchant.ordering-tiedosto on olemassa — ja se on tosi myös rikkinäisellä
# asennuksella.
#
# PAIKALLINEN JULKAISU: hyph_fi_FI.dic ei ole build/-hakemistossa vaan
# dict/hyphen/-hakemistossa, joten file:///repo/build ei riitä. Liitetiedostot
# kootaan litteäksi hakemistoksi kuten oikeassa julkaisussa.
set -euo pipefail
# shellcheck source-path=SCRIPTDIR/.. source=tarkista.sh
source /repo/testi/tarkista.sh

paivita_pakettilistat

JULKAISU_HAK="$HOME/julkaisu"
valmistele_julkaisu "$JULKAISU_HAK"

echo "# esityö: install.sh --vain voikko päätteen kanssa, vastaus k"
koodi=0
pty_aja 'k
' env JULKAISU_URL="file://$JULKAISU_HAK" bash /repo/install.sh --vain voikko 2>&1 \
    | riisu_cr | sed 's/^/  | /' || koodi=$?
printf '# esityön paluukoodi: %s\n' "$koodi"

echo "# install.sh --vain hyphen,oxt,enchant päätteen kanssa, vastaus k"
koodi=0
pty_aja 'k
' env JULKAISU_URL="file://$JULKAISU_HAK" \
    bash /repo/install.sh --vain hyphen,oxt,enchant 2>&1 \
    | riisu_cr | sed 's/^/  | /' || koodi=$?
vaite 27 'install.sh --vain hyphen,oxt,enchant paluukoodi' '0' "$koodi"

joukko_sudo_osat
yhteenveto
