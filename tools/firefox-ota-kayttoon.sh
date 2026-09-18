#!/usr/bin/env bash
# Ottaa suomen oikoluvun käyttöön Firefoxin profiilissa ILMAN .xpi-lisäosaa.
#
# MIKSI TÄTÄ TARVITAAN: sanastolisäosa asennetaan about:addons-sivulta, ja se
# menee profiilin sisään. Monen profiilin koneella se tarkoittaa käsityötä
# joka profiilille ja oman ~15 Mt kopion sanastosta jokaiseen. Firefox osaa
# kuitenkin lukea hunspell-sanaston myös hakemistosta, jonka
# spellchecker.dictionary_path osoittaa — yksi kopio, kaikki profiilit.
#
# Mitattu Firefox 155.0.1:llä, ks. ../docs/sovellukset.md kohta 6.
#
# THUNDERBIRD JA BETTERBIRD: sama työkalu käy niihin, koska oikoluku on samaa
# Gecko-koodia ja profiilin rakenne on sama. Juurta ei tunnisteta
# automaattisesti, vaan se annetaan argumenttina: ~/.config/thunderbird (XDG)
# tai ~/.thunderbird. Todettu Betterbird 153.3.0esr:llä 2026-09-18.
#
# HUOM TUNNISTE: tätä reittiä sanasto rekisteröityy nimellä "fi-FI"
# (tiedostonimestä fi_FI), kun .xpi-lisäosa rekisteröi sen nimellä "fi".
# Siksi spellchecker.dictionary saa eri arvon kuin lisäosaohjeessa.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# EI ~/.local/share/hunspell eikä /usr/share/hunspell: enchant haravoi
# molemmat, ja fi_FI-sanasto siellä syrjäyttää Voikon GTK-sovelluksissa
# (kattavuus 95,0 % -> 88,0 %). Ks. ../README.md "enchant: enchant.ordering
# ei korjaa tätä". Oma polku näkyy vain Firefoxille.
JAETTU="${XDG_DATA_HOME:-$HOME/.local/share}/suomen-kieliavut/hunspell"
LAHDE="$REPO/dict/ginter"
KIELI="fi-FI"
JUURI=""
KAIKKI=0

usage() {
    cat <<'USAGE'
Käyttö: firefox-ota-kayttoon.sh [valitsimet] [profiilijuuri]

Asentaa suomen hunspell-sanaston jaettuun hakemistoon ja osoittaa Firefoxin
profiilit siihen. Profiilijuuri tunnistetaan automaattisesti:
~/.config/mozilla/firefox (XDG) tai ~/.mozilla/firefox (vanha sijainti).
Thunderbird ja Betterbird: anna juureksi ~/.config/thunderbird tai
~/.thunderbird.

  --kaikki-profiilit   kirjoita prefit jokaiseen profiiliin yhden
                       oletusprofiilin sijaan
  --sanastopolku HAK   jaettu sanastohakemisto (oletus
                       ~/.local/share/suomen-kieliavut/hunspell)
  --kieli KOODI        spellchecker.dictionary-arvo, oletus fi-FI
  -h, --help           tämä ohje

Ohjelman on oltava suljettuna: se kirjoittaa prefs.js:n uudelleen
lopettaessaan ja ylikirjoittaisi muutoksen.
USAGE
}

while [ $# -gt 0 ]; do
    case "$1" in
        --kaikki-profiilit) KAIKKI=1 ;;
        --sanastopolku)     JAETTU="${2:?--sanastopolku vaatii hakemiston}"; shift ;;
        --kieli)            KIELI="${2:?--kieli vaatii koodin}"; shift ;;
        -h|--help)          usage; exit 0 ;;
        -*)  echo "tuntematon valitsin: $1" >&2; usage >&2; exit 2 ;;
        *)   JUURI="$1" ;;
    esac
    shift
done

# --- profiilijuuri ----------------------------------------------------------
# Firefox 141+ siirtyi XDG-polkuun. Vanha ~/.mozilla/firefox on yhä käytössä
# päivitetyillä asennuksilla, joten kumpikin kelpaa.
if [ -z "$JUURI" ]; then
    for ehdokas in "${XDG_CONFIG_HOME:-$HOME/.config}/mozilla/firefox" "$HOME/.mozilla/firefox"; do
        [ -d "$ehdokas" ] || continue
        JUURI="$ehdokas"
        break
    done
fi
if [ -z "$JUURI" ] || [ ! -d "$JUURI" ]; then
    echo "Firefoxin profiilijuurta ei löydy. Anna se argumenttina." >&2
    exit 1
fi
echo "==> profiilijuuri: $JUURI"

# --- käynnissäolon tarkistus ------------------------------------------------
# Firefoxin profiililukko on symlinkki "lock" -> "<ip>:+<pid>". Vanhentunut
# lukko (pid kuollut) ei ole este — se jää jäljelle kaatumisen jälkeen.
# Tarkistus tehdään jokaiselle profiilille, koska Firefox voi ajaa useaa
# profiilia yhtä aikaa erillisinä prosesseina — toisin kuin Chromium, jossa
# yksi prosessi ja yksi lukko kattaa kaikki.
profiili_kaytossa() {
    local lukko="$1/lock" pid
    [ -L "$lukko" ] || return 1
    pid="$(readlink "$lukko" | sed 's/.*:+//')"
    [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null
}

# --- profiilien etsintä -----------------------------------------------------
# Levyltä, EI profiles.ini:stä. Firefoxin uusi profiilivalitsin tallentaa
# profiilit tietokantaan "Profile Groups/<id>.sqlite", eivätkä ne näy
# profiles.ini:ssä lainkaan — tällä koneella juuri luotu profiili puuttui
# sieltä. prefs.js:n olemassaolo on luotettavampi tunnus: se syntyy
# ensimmäisellä käynnistyksellä.
etsi_profiilit() {
    local d
    for d in "$JUURI"/*/; do
        d="${d%/}"
        [ -f "$d/prefs.js" ] && printf '%s\n' "$d"
    done
}

declare -a PROFIILIT=()
mapfile -t PROFIILIT < <(etsi_profiilit)
[ "${#PROFIILIT[@]}" -gt 0 ] || {
    echo "Yhtään käynnistettyä profiilia ei löytynyt: $JUURI" >&2
    echo "Profiili saa prefs.js:n vasta ensimmäisellä käynnistyksellä." >&2
    exit 1; }

if [ "$KAIKKI" -eq 0 ]; then
    # Yksi profiili: se jota Firefox oletuksena avaa. installs.ini kertoo sen
    # luotettavammin kuin profiles.ini:n Default-lippu, koska se on
    # asennuskohtainen.
    oletus=""
    if [ -f "$JUURI/installs.ini" ]; then
        oletus="$(sed -n 's/^Default=//p' "$JUURI/installs.ini" | head -1)"
    fi
    if [ -n "$oletus" ] && [ -f "$JUURI/$oletus/prefs.js" ]; then
        PROFIILIT=("$JUURI/$oletus")
    else
        PROFIILIT=("${PROFIILIT[0]}")
    fi
fi
echo "==> profiileja: ${#PROFIILIT[@]}"

# --- jaettu sanasto ---------------------------------------------------------
# Yksi kopio kaikille profiileille. Firefox lukee hakemistosta parin
# <tunnus>.aff + <tunnus>.dic, ja tunnus tulee tiedostonimestä.
for tied in fi_FI.aff fi_FI.dic; do
    [ -f "$LAHDE/$tied" ] || { echo "sanastoa ei löydy: $LAHDE/$tied" >&2; exit 1; }
done
if [ -f "$JAETTU/fi_FI.dic" ] && cmp -s "$LAHDE/fi_FI.dic" "$JAETTU/fi_FI.dic" \
   && cmp -s "$LAHDE/fi_FI.aff" "$JAETTU/fi_FI.aff"; then
    echo "==> sanasto on jo ajan tasalla: $JAETTU"
else
    install -Dm644 "$LAHDE/fi_FI.aff" "$JAETTU/fi_FI.aff"
    install -Dm644 "$LAHDE/fi_FI.dic" "$JAETTU/fi_FI.dic"
    echo "==> sanasto: $JAETTU"
fi

# --- prefien kirjoitus ------------------------------------------------------
# Paluuarvo: 0 kirjoitettiin, 1 ei tarvetta, 2 ohitettiin.
kasittele() {
    local prof="$1"
    local prefs="$prof/prefs.js"
    local tarve varmuus

    if profiili_kaytossa "$prof"; then
        echo "Ohjelma on käynnissä profiililla $prof — ohitetaan." >&2
        echo "Sulje se ja aja tämä uudelleen." >&2
        return 2
    fi

    tarve=0
    python3 "$REPO/tools/prefs-js-kirjoitus.py" tarkista "$prefs" "$JAETTU" \
        --kieli "$KIELI" || tarve=$?
    case "$tarve" in
        1) echo "==> asetukset ovat jo kohdallaan: $prof"; return 1 ;;
        2) echo "prefs.js ei jäsenny, siihen ei kosketa: $prefs" >&2; return 2 ;;
    esac

    varmuus="$prefs.bak-$(date +%Y%m%d%H%M%S)"
    cp -p "$prefs" "$varmuus"
    echo "==> varmuuskopio: $varmuus"
    python3 "$REPO/tools/prefs-js-kirjoitus.py" kirjoita "$prefs" "$JAETTU" \
        --kieli "$KIELI"
    return 0
}

MUUTETTU=0
VIRHEITA=0
for prof in "${PROFIILIT[@]}"; do
    tulos=0
    kasittele "$prof" || tulos=$?
    case "$tulos" in
        0) MUUTETTU=$((MUUTETTU + 1)) ;;
        2) VIRHEITA=$((VIRHEITA + 1)) ;;
    esac
done

if [ "$MUUTETTU" -gt 0 ]; then
    echo "==> valmis ($MUUTETTU profiilia muutettu). Käynnistä ohjelma ja kirjoita"
    echo "    tekstikenttään (Firefoxissa käy myös tools/oikoluku-testi.html):"
    echo "    maastopyörä     (ei saa alleviivautua)"
    echo "    maastopyöräz    (pitää alleviivautua)"
fi

[ "$VIRHEITA" -eq 0 ] || { echo "$VIRHEITA profiilia ohitettiin." >&2; exit 1; }
