#!/usr/bin/env bash
# Skenaario 01 — install.sh paikallista "julkaisua" vastaan (file://).
#
# Kattaa: oletusosat, sudo-osien ohittumisen ilman päätettä (väite 21),
# summaportin (väite 20), argumenttitarkistuksen (väite 22) ja --force-
# sopimuksen (väite 23).
#
# KAKSIVAIHEINEN AJO: install.sh:n voikko-osa kysyy luvan /dev/tty:stä eikä
# asenna mitään ilman päätettä. Ensimmäinen vaihe ajetaan tarkoituksella
# ilman päätettä, koska juuri sitä väite 21 mittaa; toinen vaihe antaa
# päätteen ja vastaa "k", jotta §5:n moottoriväitteillä on moottori mitattavana.
set -euo pipefail
# shellcheck source-path=SCRIPTDIR/.. source=tarkista.sh
source /repo/testi/tarkista.sh

# Valejulkaisu rakennetaan valmistele_julkaisu:lla eikä osoiteta suoraan
# repon build/-hakemistoon: install.sh noutaa julkaisusta myös Chromium- ja
# Firefox-osien työkalut (pref-kirjoitus.py ym.), jotka ovat repossa
# tools/-hakemistossa. Suoraan build/:iin osoittava JULKAISU kaataisi vaiheen
# A lataukseen ja näyttäisi asentimen vialta, vaikka aito julkaisu sisältää
# ne tiedostot — ks. testi/tarkista.sh:n valmistele_julkaisu.
JULKAISU_HAK="$HOME/julkaisu"
valmistele_julkaisu "$JULKAISU_HAK"
JULKAISU="file://$JULKAISU_HAK"

paivita_pakettilistat

# --- vaihe A: ilman päätettä, oletusosat ------------------------------------
echo "# vaihe A: install.sh ilman päätettä, oletusosat"
koodi=0
tuloste="$(JULKAISU_URL="$JULKAISU" bash /repo/install.sh 2>&1)" || koodi=$?
printf '%s\n' "$tuloste" | sed 's/^/  | /'

# Väite 21 on yksi väite kahdesta ehdosta: ohitusviesti JA paluukoodi 0.
# Molemmat kuuluvat dokumentoituun "curl | bash" -käytökseen, ja kumpi tahansa
# yksin läpäisisi rikkinäisenkin asentimen.
viesti="ei"
case "$tuloste" in *'(ei päätettä — ei kysytä, ohitetaan)'*) viesti="kyllä" ;; esac
vaite 21 'ilman päätettä: ohitusviesti ja paluukoodi' \
    'viesti=kyllä paluukoodi=0' "viesti=$viesti paluukoodi=$koodi"

# --- väite 22: tuntematon osa -----------------------------------------------
koodi=0
JULKAISU_URL="$JULKAISU" bash /repo/install.sh --vain tuntematon >/dev/null 2>&1 || koodi=$?
vaite 22 'install.sh --vain tuntematon' '2' "$koodi"

# --- väite 23: --force-sopimus ----------------------------------------------
# Mitataan nvim-osalla, koska se on pienin oletusosa ja kirjoittaa yhden
# tiedoston. Asennettu sanasto korvataan tunnisteella; toinen ajo ilman
# --force:a ei saa koskea siihen, --force:n kanssa sen on palattava oikeaksi.
spl="$HOME/.config/nvim/spell/fi.utf-8.spl"
printf 'TUNNISTE\n' > "$spl"
JULKAISU_URL="$JULKAISU" bash /repo/install.sh --vain nvim >/dev/null 2>&1
vaite 23a 'toinen ajo ilman --force ei ylikirjoita' 'TUNNISTE' "$(cat "$spl")"
JULKAISU_URL="$JULKAISU" bash /repo/install.sh --vain nvim --force >/dev/null 2>&1
vaite 23b 'ajo --force:lla ylikirjoittaa' 'ei enää tunniste' \
    "$( [ "$(cat "$spl")" = "TUNNISTE" ] && printf 'yhä tunniste' || printf 'ei enää tunniste' )"

# --- väite 20: summaportti --------------------------------------------------
# Oma HOME, jotta "levylle ei kirjoitettu mitään" on mitattavissa: vaihe A on
# jo kirjoittanut varsinaiseen kotihakemistoon.
echo "# väite 20: yksi tavu rikki julkaisussa"
RIKKI="$HOME/rikki-julkaisu"
valmistele_julkaisu "$RIKKI"
printf 'x' | dd of="$RIKKI/fi-FI.bdic" bs=1 seek=1024 count=1 conv=notrunc status=none

KOTI20="$HOME/koti-vaite-20"
mkdir -p "$KOTI20"
koodi=0
tuloste="$(env -u XDG_CONFIG_HOME -u XDG_CACHE_HOME -u XDG_DATA_HOME \
    HOME="$KOTI20" JULKAISU_URL="file://$RIKKI" \
    bash /repo/install.sh --vain chromium 2>&1)" || koodi=$?
printf '%s\n' "$tuloste" | sed 's/^/  | /'
summaviesti="ei"
case "$tuloste" in *'SHA-256 EI TÄSMÄÄ'*) summaviesti="kyllä" ;; esac
jaljet="$(find "$KOTI20" -mindepth 1 | wc -l)"
vaite 20 'rikottu julkaisu: paluukoodi, viesti ja koskematon koti' \
    'paluukoodi=1 viesti=kyllä tiedostoja=0' \
    "paluukoodi=$koodi viesti=$summaviesti tiedostoja=$jaljet"

# --- vaihe B: päätteellä, Voikko-osa ----------------------------------------
echo "# vaihe B: install.sh --vain voikko päätteen kanssa, vastaus k"
koodi=0
pty_aja 'k
' env JULKAISU_URL="$JULKAISU" bash /repo/install.sh --vain voikko 2>&1 \
    | riisu_cr | sed 's/^/  | /' || koodi=$?
printf '# vaihe B paluukoodi: %s\n' "$koodi"

# --- §5 väitejoukko ---------------------------------------------------------
export XPI_POLKU="${XDG_CACHE_HOME:-$HOME/.cache}/suomen-kieliavut/fi-spell-0.2.xpi"
joukko_taysi
yhteenveto
