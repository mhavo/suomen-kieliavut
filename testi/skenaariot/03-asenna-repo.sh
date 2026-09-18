#!/usr/bin/env bash
# Skenaario 03 — tools/asenna.sh repoklonista.
#
# Toinen asennin, eri oletukset: asenna.sh asentaa myös tavutuskuviot
# (sudo) ja lukee sanastot suoraan repon build/-hakemistosta ilman
# summantarkistusta — klonissa summa on jo tarkistettu gitin toimesta.
#
# Pääte varataan, koska asenna.sh:n sudo-osa voisi kysyä salasanaa; kontissa
# sudo on salasanaton, joten vastaus jää käyttämättä.
set -euo pipefail
# shellcheck source-path=SCRIPTDIR/.. source=tarkista.sh
source /repo/testi/tarkista.sh

paivita_pakettilistat

echo "# tools/asenna.sh oletusosilla"
koodi=0
pty_aja 'k
' bash /repo/tools/asenna.sh 2>&1 | riisu_cr | sed 's/^/  | /' || koodi=$?
vaite 26 'tools/asenna.sh paluukoodi' '0' "$koodi"

# asenna.sh:n voikko-osa tuntee vain pacmanin ja yayn. Muualla se tulostaa
# huomautuksen eikä asenna mitään — §5:n moottoriväitteet kertovat sen sitten
# suoraan.
printf '# distro: %s\n' "$(distro)"

# Repoklonissa .xpi on repossa eikä välimuistissa: asenna.sh vain tulostaa
# polun sen sijaan että noutaisi tiedoston.
export XPI_POLKU=/repo/build/fi-spell-0.2.xpi
joukko_taysi
yhteenveto
