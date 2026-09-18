#!/usr/bin/env bash
# Skenaario 06 — Snap- ja Flatpak-muotoiset profiilijuuret.
#
# MITÄ TÄMÄ MITTAA JA MITÄ EI: asennin löytää eristettyjen versioiden
# profiilijuuret, vie sanaston hiekkalaatikon omaan hakemistoon ja osoittaa
# prefs.js:n sinne; ilman yhtään profiilia .xpi päätyy Lataukset-kansioon.
# Se EI mittaa, että oikea Snap-/Flatpak-Firefox lukee sanaston tuosta
# polusta — siihen tarvittaisiin oikea snapd kontissa (ks. valeprofiilit.sh).
set -euo pipefail
# shellcheck source-path=SCRIPTDIR/.. source=tarkista.sh
source /repo/testi/tarkista.sh

JULKAISU="$HOME/julkaisu"
valmistele_julkaisu "$JULKAISU"

luo_profiili() { # luo_profiili <profiilihakemisto>
    mkdir -p "$1"
    printf '// Mozilla User Preferences\n\nuser_pref("browser.startup.page", 3);\n' > "$1/prefs.js"
}
aja() { # aja <koti>
    env -u XDG_CONFIG_HOME -u XDG_CACHE_HOME -u XDG_DATA_HOME HOME="$1" \
        JULKAISU_URL="file://$JULKAISU" bash /repo/install.sh --vain firefox 2>&1 | sed 's/^/  | /'
}
polku_prefsissa() { # polku_prefsissa <prefs.js>
    sed -n 's/^user_pref("spellchecker.dictionary_path", "\(.*\)");$/\1/p' "$1" | tail -1
}

# --- A: Snap-Firefox ja Flatpak-Thunderbird ---------------------------------
KOTI_A="$HOME/koti-eristetty"
SNAP_FF="$KOTI_A/snap/firefox/common"
FP_TB="$KOTI_A/.var/app/org.mozilla.Thunderbird"
luo_profiili "$SNAP_FF/.mozilla/firefox/aaaaaaaa.default"
luo_profiili "$FP_TB/.thunderbird/bbbbbbbb.default"
echo "# A: install.sh --vain firefox, Snap-Firefox ja Flatpak-Thunderbird"
aja "$KOTI_A"

vaite 24a 'Snap-Firefox: dictionary_path' "$SNAP_FF/suomen-kieliavut/hunspell" \
    "$(polku_prefsissa "$SNAP_FF/.mozilla/firefox/aaaaaaaa.default/prefs.js")"
vaite 24b 'Flatpak-Thunderbird: dictionary_path' "$FP_TB/suomen-kieliavut/hunspell" \
    "$(polku_prefsissa "$FP_TB/.thunderbird/bbbbbbbb.default/prefs.js")"
tila='puuttuu'
[ -s "$SNAP_FF/suomen-kieliavut/hunspell/fi_FI.dic" ] &&
    [ -s "$FP_TB/suomen-kieliavut/hunspell/fi_FI.dic" ] && tila='olemassa'
vaite 24c 'sanasto hiekkalaatikoiden omissa hakemistoissa' 'olemassa' "$tila"
# Eristetty ohjelma ei näe ~/.local/sharea, joten sinne ei pidä jäädä mitään.
vaite 24d 'ei sanastoa ~/.local/share-hakemistossa' 'ei' \
    "$( [ -e "$KOTI_A/.local/share/suomen-kieliavut" ] && printf 'on' || printf 'ei' )"

# --- B: ei profiilia — .xpi Lataukset-kansioon ------------------------------
KOTI_B="$HOME/koti-tyhja"
mkdir -p "$KOTI_B/Downloads"
echo "# B: install.sh --vain firefox, ei yhtään profiilia"
aja "$KOTI_B"
vaite 25 '.xpi Lataukset-kansiossa' 'on' \
    "$( [ -s "$KOTI_B/Downloads/fi-spell-0.2.xpi" ] && printf 'on' || printf 'ei' )"

yhteenveto
