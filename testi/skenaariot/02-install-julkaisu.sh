#!/usr/bin/env bash
# Skenaario 02 — install.sh oikeaa GitHub-julkaisua vastaan.
#
# Ainoa skenaario joka koskee verkkoon. Se mittaa yhtä asiaa jota mikään muu
# ei mittaa: täsmäävätkö julkaistut liitetiedostot niihin SHA-256-summiin
# jotka on upotettu install.sh:hon. Erkaantuminen näyttäisi käyttäjälle
# hyökkäykseltä.
#
# Verkon puuttuessa tämä raportoi SKIPin eikä virhettä (§3.2): offline
# työskentelevän ylläpitäjän on saatava käyttökelpoinen tulos muista ajoista.
set -euo pipefail
# shellcheck source-path=SCRIPTDIR/.. source=tarkista.sh
source /repo/testi/tarkista.sh

# Tagi luetaan install.sh:sta, ei kopioida tänne (§"Edge cases"): kun julkaisu
# etenee v0.9:n ohi, tämä skenaario seuraa mukana ilman muutosta.
TAGI="$(sed -n 's/^JULKAISU_TAGI="\(.*\)"$/\1/p' /repo/install.sh)"
printf '# julkaisutagi install.sh:sta: %s\n' "${TAGI:-tuntematon}"

if ! curl -fsS --max-time 20 -o /dev/null "https://github.com/"; then
    echo "# SKIP: github.com ei tavoitettavissa"
    exit "$KOODI_SKIP"
fi

# Julkaisun olemassaolo on tämän skenaarion esiehto, ei sen mittaama asia.
# Jos tagia ei ole, install.sh saa 404:n ensimmäisestä latauksesta ja poistuu
# koodilla 1, jolloin väitteet 25, 21, 9b, 14 ja 15 punastuvat kaikki saman
# syyn takia — seitsemän punaista, joista yksikään ei kerro julkaisun summista
# mitään. Mitattu 2026-09-18 (tulokset/2026-09-18_160646). SKIPataan siksi ja
# nimetään syy. Vain 404 johtaa SKIPiin: muut koodit (403, 5xx) saavat ajon
# jatkua, jottei aito rikkoutuminen peity SKIP-riviksi.
#
# Omistaja ja nimi luetaan install.sh:sta samasta syystä kuin tagi (§"Edge
# cases"): kopio täällä erkaantuisi hiljaa.
OMISTAJA="$(sed -n 's/^REPO_OMISTAJA="\(.*\)"$/\1/p' /repo/install.sh)"
NIMI="$(sed -n 's/^REPO_NIMI="\(.*\)"$/\1/p' /repo/install.sh)"
JULKAISUSIVU="https://github.com/$OMISTAJA/$NIMI/releases/tag/$TAGI"
HTTP="$(curl -sS -o /dev/null -w '%{http_code}' --max-time 20 "$JULKAISUSIVU" \
    || echo 000)"
if [ "$HTTP" = "404" ]; then
    printf '# SKIP: julkaisua %s ei ole julkaistu (%s -> HTTP 404).\n' \
        "$TAGI" "$JULKAISUSIVU"
    printf '#       install.sh:n JULKAISU_TAGI osoittaa tagiin jota ei ole,\n'
    printf '#       joten myös README:n asennuskomento raw/%s/install.sh on\n' \
        "$TAGI"
    printf '#       404 kaikille käyttäjille. Tämä on tuotelöydös, ei\n'
    printf '#       testiympäristön vika — ks. FEATURE.md §3.2.\n'
    exit "$KOODI_SKIP"
fi

paivita_pakettilistat

# --- vaihe A: ilman päätettä, oletusosat, oikea julkaisu --------------------
echo "# vaihe A: install.sh ilman päätettä, julkaisu $TAGI"
koodi=0
tuloste="$(bash /repo/install.sh 2>&1)" || koodi=$?
printf '%s\n' "$tuloste" | sed 's/^/  | /'

summavirhe="ei"
case "$tuloste" in *'SHA-256 EI TÄSMÄÄ'*) summavirhe="kyllä" ;; esac
vaite 25 "julkaisun $TAGI liitetiedostot vastaavat install.sh:n summia" \
    'summavirhe=ei paluukoodi=0' "summavirhe=$summavirhe paluukoodi=$koodi"

viesti="ei"
case "$tuloste" in *'(ei päätettä — ei kysytä, ohitetaan)'*) viesti="kyllä" ;; esac
vaite 21 'ilman päätettä: ohitusviesti ja paluukoodi' \
    'viesti=kyllä paluukoodi=0' "viesti=$viesti paluukoodi=$koodi"

# --- vaihe B: päätteellä, Voikko-osa ----------------------------------------
echo "# vaihe B: install.sh --vain voikko päätteen kanssa, vastaus k"
koodi=0
pty_aja 'k
' bash /repo/install.sh --vain voikko 2>&1 | riisu_cr | sed 's/^/  | /' || koodi=$?
printf '# vaihe B paluukoodi: %s\n' "$koodi"

# --- §5 väitejoukko ---------------------------------------------------------
export XPI_POLKU="${XDG_CACHE_HOME:-$HOME/.cache}/suomen-kieliavut/fi-spell-0.2.xpi"
joukko_taysi
yhteenveto
