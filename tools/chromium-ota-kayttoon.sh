#!/usr/bin/env bash
# Ottaa suomen oikoluvun käyttöön Chromiumin profiilissa.
#
# MIKSI TÄTÄ TARVITAAN: suomi ei ole Chromiumin tuettujen oikolukukielten
# listassa, joten chrome://settings/languages EI tarjoa suomelle
# "Tarkista tämän kielen oikeinkirjoitus" -rastia lainkaan. Asetus on siis
# kirjoitettava suoraan profiilin Preferences-tiedostoon.
#
# Sanastotiedoston lataus itse toimii normaalisti: Chromium avaa, tarkistaa
# ja käyttää ~/.config/chromium/Dictionaries/fi-3-0.bdic:tä kun pref on
# paikallaan. Ks. ../docs/convert-dict.md.
#
# MONTA PROFIILIA: sanastoa ei tarvitse kopioida monesti. Dictionaries/ on
# käyttäjädatahakemiston tasolla, joten sama .bdic palvelee kaikkia profiileja.
# Profiilikohtaista on vain spellcheck.dictionaries-pref, ja --kaikki-profiilit
# kirjoittaa sen jokaiseen selainprofiiliin kerralla.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

PROFIILI=""
KIELI="fi"
ASETA_KIELI=0
PAKOTA=0
KAIKKI=0

usage() {
    cat <<'USAGE'
Käyttö: chromium-ota-kayttoon.sh [valitsimet] [käyttäjädatahakemisto]

Lisää suomen Chromiumin profiilin oikolukukieliin. Oletushakemisto
~/.config/chromium, oletusprofiili sen Default.

  --kaikki-profiilit   kirjoita pref jokaiseen hakemiston selainprofiiliin
                       (Default, Profile 1, Profile 2, ...) yhden pelkän
                       Defaultin sijaan. Chromiumin sisäinen "System Profile"
                       ja "Guest Profile" ohitetaan: niissä ei kirjoiteta
                       tekstiä.
  --aseta-kieli        lisää kieli myös intl.accept_languages-asetukseen.
                       EI oletuksena: se muuttaa selaimen jokaiselle sivustolle
                       lähettämää Accept-Language-otsaketta. Oikoluku toimii
                       ja kieli näkyy chrome://settings/languages-listassa
                       ilman tätäkin.
  --pakota-oikoluku    kytke oikoluku päälle vaikka se olisi eksplisiittisesti
                       asetettu pois päältä
  -h, --help           tämä ohje
USAGE
}

while [ $# -gt 0 ]; do
    case "$1" in
        --kaikki-profiilit) KAIKKI=1 ;;
        --aseta-kieli)     ASETA_KIELI=1 ;;
        --pakota-oikoluku) PAKOTA=1 ;;
        --kieli)           KIELI="${2:?--kieli vaatii koodin}"; shift ;;
        -h|--help)         usage; exit 0 ;;
        -*)  echo "tuntematon valitsin: $1" >&2; usage >&2; exit 2 ;;
        *)   PROFIILI="$1" ;;
    esac
    shift
done

[ -n "$PROFIILI" ] || PROFIILI="$HOME/.config/chromium"

declare -a LIPUT=()
[ "$ASETA_KIELI" -eq 1 ] && LIPUT+=(--aseta-kieli)
[ "$PAKOTA" -eq 1 ] && LIPUT+=(--pakota-oikoluku)

# --- käynnissäolon tarkistus ------------------------------------------------
# Chromium kirjoittaa Preferences-tiedoston uudelleen lopettaessaan, joten
# muutos katoaisi jos selain on käynnissä. Tunnistus tehdään Chromiumin omasta
# lukosta: SingletonLock on symlinkki "<kone>-<pid>". Lukko on
# käyttäjädatahakemiston tasolla — yksi prosessi ajaa kaikkia profiileja — joten
# tämä tarkistetaan kerran riippumatta siitä montako profiilia käsitellään.
# (pgrep ei kelpaa: se osuisi myös tämän skriptin omaan komentoriviin.)
LUKKO="$PROFIILI/SingletonLock"
if [ -L "$LUKKO" ]; then
    lukkopid="$(readlink "$LUKKO" | sed 's/.*-//')"
    if [ -n "$lukkopid" ] && kill -0 "$lukkopid" 2>/dev/null; then
        echo "Chromium on käynnissä profiililla $PROFIILI (pid $lukkopid)." >&2
        echo "Sulje selain kokonaan — myös --app-ikkunat, esim. WhatsApp —" >&2
        echo "ja aja tämä uudelleen." >&2
        exit 1
    fi
    echo "==> vanhentunut SingletonLock, selain ei ole käynnissä"
fi

# --- profiilien etsintä -----------------------------------------------------
# Selainprofiili on se alihakemisto, jossa on Preferences-tiedosto. Kaksi
# poikkeusta ohitetaan tietoisesti:
#   System Profile  Chromiumin sisäinen profiili, ei selainikkunaa
#   Guest Profile   nollataan joka istunnossa, kirjoitus katoaisi
etsi_profiilit() {
    local d
    for d in "$PROFIILI"/*/; do
        d="${d%/}"
        [ -f "$d/Preferences" ] || continue
        case "${d##*/}" in
            "System Profile"|"Guest Profile") continue ;;
        esac
        printf '%s\n' "$d/Preferences"
    done
}

declare -a PREFSIT=()
if [ "$KAIKKI" -eq 1 ]; then
    mapfile -t PREFSIT < <(etsi_profiilit)
    [ "${#PREFSIT[@]}" -gt 0 ] || {
        echo "Yhtään profiilia ei löytynyt hakemistosta: $PROFIILI" >&2; exit 1; }
    echo "==> profiileja: ${#PREFSIT[@]}"
else
    PREFSIT=("$PROFIILI/Default/Preferences")
    [ -f "${PREFSIT[0]}" ] || {
        echo "Preferences ei löydy: ${PREFSIT[0]}" >&2; exit 1; }
fi

# --- kirjoitus --------------------------------------------------------------
# Paluuarvo: 0 kirjoitettiin, 1 ei tarvetta, 2 ei jäsenny JSONina.
kasittele() {
    local prefs="$1" tarve varmuus

    # Paluuarvo talteen ilman set +e -kikkailua: set -e on globaali, joten sen
    # palauttaminen funktion sisällä ohittaisi kutsupaikan set +e:n ja
    # alla oleva "return 1" lopettaisi koko skriptin ensimmäiseen profiiliin.
    tarve=0
    python3 "$REPO/tools/pref-kirjoitus.py" tarkista "$prefs" "$KIELI" "${LIPUT[@]}" || tarve=$?
    case "$tarve" in
        1) echo "==> asetukset ovat jo kohdallaan: $prefs"; return 1 ;;
        2) echo "Preferences ei jäsenny JSONina, siihen ei kosketa: $prefs" >&2
           return 2 ;;
    esac

    varmuus="$prefs.bak-$(date +%Y%m%d%H%M%S)"
    cp -p "$prefs" "$varmuus"
    echo "==> varmuuskopio: $varmuus"

    python3 "$REPO/tools/pref-kirjoitus.py" kirjoita "$prefs" "$KIELI" "${LIPUT[@]}"
    return 0
}

# Yhden profiilin rikkinäinen Preferences ei saa jättää muita käsittelemättä,
# joten virhe kerätään ja raportoidaan vasta lopuksi.
MUUTETTU=0
VIRHEITA=0
for prefs in "${PREFSIT[@]}"; do
    tulos=0
    kasittele "$prefs" || tulos=$?
    case "$tulos" in
        0) MUUTETTU=$((MUUTETTU + 1)) ;;
        2) VIRHEITA=$((VIRHEITA + 1)) ;;
    esac
done

if [ "$MUUTETTU" -gt 0 ]; then
    echo "==> valmis ($MUUTETTU profiilia muutettu). Käynnistä Chromium ja testaa"
    echo "    kirjoittamalla tekstikenttään:"
    echo "    maastopyörä     (ei saa alleviivautua)"
    echo "    maastopyöräz    (pitää alleviivautua)"
fi

[ "$VIRHEITA" -eq 0 ] || { echo "$VIRHEITA profiilia ohitettiin virheen takia." >&2; exit 1; }
