#!/usr/bin/env bash
# Asentaa suomen oikolukusanaston Electron-sovellusten omiin profiileihin.
#
# MIKSI OMA TYÖKALU: Chromium-pohjainen Electron-sovellus ei käytä työpöydän
# Chromiumin sanastoa vaan lukee sen omasta profiilistaan
# ~/.config/<sovellus>/Dictionaries/. Sanasto on siis kopioitava jokaiseen
# sovellukseen erikseen — ja tiedostonimen on oltava täsmälleen se jota kyseinen
# Electron-versio hakee, muotoa <kielikoodi>-<sanastoversio>.bdic. Väärin nimetty
# tiedosto ohitetaan täysin ilman virheilmoitusta ja ilman lokiriviä.
# Ks. ../docs/convert-dict.md, osiot "Tiedoston nimi on kriittinen" ja
# "Electron-sovellukset".
#
# KAKSI SUDENKUOPPAA, JOTKA TÄMÄ SKRIPTI KIERTÄÄ:
#
# 1. Sanastoversiota EI voi päätellä profiilissa jo olevista tiedostoista.
#    Versiopääte on kielikohtainen: englanti on en-US-10-1, suomi fi-3-0.
#    Profiilissa oleva en-US-10-1.bdic ei siis kerro suomen päätteestä mitään.
#    Skripti näyttää löytyneet tiedostot tiedoksi, mutta ei johda niistä nimeä.
#    Suomen oletus on fi-3-0.bdic, koska -3-0 on Chromiumin oletusversiopääte
#    kaikille kielille joille Google ei ylläpidä omaa sanastoa — ja suomi on
#    juuri sellainen (ks. docs/convert-dict.md, "Varoitus: -3-0 ei kerro
#    tuesta"). Pakota tarvittaessa toinen nimi: --nimi.
#
# 2. Pelkkä tiedosto ei riitä. Sanasto avataan vasta kun kieli on sovelluksen
#    Preferences-tiedoston spellcheck.dictionaries-listassa. Sovellus
#    ylikirjoittaa Preferences-tiedoston lopettaessaan, joten kirjoitus on
#    tehtävä sovellus SULJETTUNA. Skripti kieltäytyy muuten.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}"

SANASTO="$REPO/build/fi-FI.bdic"
KIELI="fi"
BDIC_NIMI=""          # tyhjä = johdetaan kielestä: <kieli>-3-0.bdic
FORCE=0
KUIVA=0
LISTAA=0
TEE_PREF=1
ASETA_KIELI=0
PAKOTA_OIKOLUKU=0
declare -a VALITUT=()

usage() {
    cat <<'USAGE'
Käyttö: electron-sanastot.sh [valitsimet] [sovellus...]

Etsii Electron-sovellusten profiilit, näyttää niissä olevat .bdic-sanastot ja
asentaa suomen sanaston valittuihin. Ilman sovellusnimiä käsittelee kaikki
löytyneet. Idempotentti: ei ylikirjoita ilman --force.

  --listaa            vain etsi ja näytä, älä asenna mitään
  --kuiva             näytä mitä tehtäisiin, älä kirjoita mitään
  --force             ylikirjoita olemassa oleva sanasto
  --nimi <tiedosto>   pakota .bdic-tiedostonimi (oletus <kieli>-3-0.bdic)
  --kieli <koodi>     kielikoodi, oletus fi
  --sanasto <polku>   lähdesanasto, oletus build/fi-FI.bdic
  --ei-pref           kopioi vain tiedosto, älä koske Preferences-tiedostoon
  --aseta-kieli       lisää kieli myös intl.accept_languages-asetukseen. EI
                      oletuksena: se muuttaa sovelluksen verkkoon lähettämää
                      Accept-Language-otsaketta. Oikoluku toimii ilman
                      tätäkin.
  --pakota-oikoluku   kytke oikoluku päälle vaikka se olisi eksplisiittisesti
                      asetettu pois päältä
  -h, --help          tämä ohje

Esimerkkejä:
  electron-sanastot.sh --listaa
  electron-sanastot.sh --kuiva obsidian
  electron-sanastot.sh obsidian Codex
USAGE
}

while [ $# -gt 0 ]; do
    case "$1" in
        --listaa)   LISTAA=1 ;;
        --kuiva|--dry-run) KUIVA=1 ;;
        --force)    FORCE=1 ;;
        --nimi)     BDIC_NIMI="${2:?--nimi vaatii tiedostonimen}"; shift ;;
        --kieli)    KIELI="${2:?--kieli vaatii koodin}"; shift ;;
        --sanasto)  SANASTO="${2:?--sanasto vaatii polun}"; shift ;;
        --ei-pref)  TEE_PREF=0 ;;
        --aseta-kieli)     ASETA_KIELI=1 ;;
        --pakota-oikoluku) PAKOTA_OIKOLUKU=1 ;;
        -h|--help)  usage; exit 0 ;;
        -*)         echo "tuntematon valitsin: $1" >&2; usage >&2; exit 2 ;;
        *)          VALITUT+=("$1") ;;
    esac
    shift
done

[ -n "$BDIC_NIMI" ] || BDIC_NIMI="$KIELI-3-0.bdic"

declare -a PREF_LIPUT=()
[ "$ASETA_KIELI" -eq 1 ] && PREF_LIPUT+=(--aseta-kieli)
[ "$PAKOTA_OIKOLUKU" -eq 1 ] && PREF_LIPUT+=(--pakota-oikoluku)

say()  { printf '\033[1m==>\033[0m %s\n' "$*"; }
rivi() { printf '    %s\n' "$*"; }

# --- profiilien etsintä -------------------------------------------------------
# Kaksi paikkaa:
#   ~/.config/<sovellus>/Dictionaries          tavallinen asennus
#   ~/.var/app/<tunnus>/config/<sovellus>/Dictionaries   Flatpak
# Flatpak-polku on tämä siksi, että Flatpak asettaa sovellukselle
# XDG_CONFIG_HOME=~/.var/app/<tunnus>/config, jolloin Electron kirjoittaa
# profiilinsa sen alle täsmälleen samalla rakenteella. HUOM: tällä koneella ei
# ole yhtään Flatpak-sovellusta (~/.var/app puuttuu), joten polkua ei ole voitu
# todentaa käytännössä — se on johdettu Flatpakin ympäristömuuttujista.
etsi_profiilit() {
    local d
    for d in "$CONFIG"/*/Dictionaries "$HOME"/.var/app/*/config/*/Dictionaries; do
        [ -d "$d" ] || continue
        printf '%s\n' "${d%/Dictionaries}"
    done
}

# Preferences sijaitsee kahdessa eri paikassa riippuen siitä, käyttääkö
# sovellus Chromiumin monen profiilin rakennetta vai ei:
#   <profiili>/Default/Preferences   Chromium ja Chromium-pohjaiset selaimet
#   <profiili>/Preferences           useimmat Electron-sovellukset
# Molemmat esiintyvät oikeasti samalla koneella (mitattu 2026-09-16: chromium ja
# Codex käyttävät Default/-alihakemistoa, obsidian ja reticulum-meshchatx eivät).
etsi_prefs() {
    local prof="$1"
    if   [ -f "$prof/Default/Preferences" ]; then printf '%s\n' "$prof/Default/Preferences"
    elif [ -f "$prof/Preferences" ];         then printf '%s\n' "$prof/Preferences"
    fi
}

# Onko sovellus käynnissä? Tähän ei ole yhtä luotettavaa keinoa, joten
# tarkistuksia on kaksi ja kumpi tahansa osuma riittää estämään kirjoituksen:
#
# 1. SingletonLock on symlinkki "<kone>-<pid>". Chromium ja ne Electronit jotka
#    pyytävät requestSingleInstanceLock():n luovat sen. Vanhentunut lukko (pid
#    kuollut) ei ole este — esim. Codexin lukko osoitti mitatessa kuolleeseen
#    pidiin 191879.
# 2. Avoimet tiedostokahvat profiilihakemistoon. Tämä kattaa ne sovellukset
#    joilla SingletonLockia ei ole lainkaan (obsidian, reticulum-meshchatx).
#    find -lname vertaa symlinkin kohdetta, joten koko /proc:n läpikäynti hoituu
#    yhdellä kutsulla (~0,15 s). Vieras prosessi joka pitää profiilin tiedostoa
#    auki (varmuuskopiointi, tiedostonhallinta) tuottaa väärän positiivisen —
#    se on turvallinen suunta: skripti jättää väliin eikä riko mitään.
profiili_kaytossa() {
    local prof="$1"
    local lukko="$prof/SingletonLock"
    local pid
    if [ -L "$lukko" ]; then
        pid="$(readlink "$lukko" | sed 's/.*-//')"
        if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
            printf 'SingletonLock, pid %s\n' "$pid"
            return 0
        fi
    fi
    # Tulos otetaan komennon korvauksella eikä putkella: "find ... | grep -q"
    # antaa findille SIGPIPEn heti kun grep lopettaa, ja set -o pipefail tekee
    # koko putkesta silloin epäonnistuneen — havainto katoaisi satunnaisesti.
    local kahva
    kahva="$(find /proc -maxdepth 3 -path '/proc/[0-9]*/fd/*' -lname "$prof/*" \
             -print -quit 2>/dev/null || true)"
    if [ -n "$kahva" ]; then
        printf 'avoimia tiedostokahvoja profiiliin (%s)\n' "$kahva"
        return 0
    fi
    return 1
}

# --- pref-kirjoitus -----------------------------------------------------------
# Logiikka on tools/pref-kirjoitus.py:ssä, jota myös chromium-ota-kayttoon.sh
# kutsuu. Aiemmin sama koodi oli upotettuna heredocina molempiin skripteihin,
# jolloin jokainen korjaus piti tehdä kahdesti. Ks. sen tiedoston docstring:
# atominen kirjoitus, accept_languages vain pyydettäessä, eksplisiittisen
# enable_spellchecking=false kunnioittaminen.
#
# Tarvitseeko Preferences muutosta? Ilman tätä tarkistusta jokainen ajo tekisi
# uuden varmuuskopion vaikka mikään ei muutu, ja profiiliin kertyisi
# Preferences.bak-* -tiedostoja.
#
# Kolme paluuarvoa, koska lukukelvoton tiedosto on eri asia kuin "ei tarvetta":
#   0  muutos tarpeen
#   1  ei tarvetta
#   2  tiedosto ei jäsenny JSONina tai ei aukea — siihen EI kosketa
#
# Arvo 2 palautti aiemmin 0:n, jolloin kirjoitus yritettiin ja sen json.load
# nosti poikkeuksen. Se kaatoi set -e:n kautta koko ajon, vaikka tämän skriptin
# koko idea on käydä monta sovellusta läpi ja jatkaa seuraavaan.
pref_tarvitsee_muutosta() {
    local prefs="$1" kieli="$2"
    python3 "$REPO/tools/pref-kirjoitus.py" tarkista "$prefs" "$kieli" "${PREF_LIPUT[@]}"
}

kirjoita_pref() {
    local prefs="$1" kieli="$2"
    local varmuus
    varmuus="$prefs.bak-$(date +%Y%m%d%H%M%S)"
    cp -p "$prefs" "$varmuus"
    rivi "varmuuskopio: $varmuus"
    python3 "$REPO/tools/pref-kirjoitus.py" kirjoita "$prefs" "$kieli" "${PREF_LIPUT[@]}"
}

# --- pääsilmukka --------------------------------------------------------------
mapfile -t PROFIILIT < <(etsi_profiilit)

if [ ${#PROFIILIT[@]} -eq 0 ]; then
    echo "Electron-profiileja ei löytynyt hakemistosta $CONFIG" >&2
    echo "Etsitty: $CONFIG/*/Dictionaries ja ~/.var/app/*/config/*/Dictionaries" >&2
    exit 1
fi

if [ "$LISTAA" -eq 0 ] && [ ! -f "$SANASTO" ]; then
    echo "lähdesanastoa ei löydy: $SANASTO" >&2
    echo "rakenna se ensin: tools/build-bdic.sh frekvenssi" >&2
    exit 1
fi

say "Löytyi ${#PROFIILIT[@]} profiilia (haku: $CONFIG/*/Dictionaries)"
[ "$KUIVA" -eq 1 ] && rivi "KUIVA AJO — mitään ei kirjoiteta"
echo

KASITELTY=0
for prof in "${PROFIILIT[@]}"; do
    nimi="$(basename "$prof")"

    # Sovellusrajaus: jos nimiä annettiin, käsitellään vain ne.
    if [ ${#VALITUT[@]} -gt 0 ]; then
        osuma=0
        for v in "${VALITUT[@]}"; do [ "$v" = "$nimi" ] && osuma=1; done
        [ "$osuma" -eq 1 ] || continue
    fi
    KASITELTY=$((KASITELTY + 1))

    say "$nimi"
    rivi "profiili: $prof"

    # Näytetään mitä sanastoja siellä jo on. Tämä on TIEDOKSI, ei päättelyyn:
    # en-US-10-1.bdic ei kerro mitään siitä millä nimellä sama sovellus hakisi
    # suomea (ks. skriptin alun kohta 1).
    loydetyt="$(find "$prof/Dictionaries" -maxdepth 1 -name '*.bdic' -printf '%f ' 2>/dev/null)"
    if [ -n "$loydetyt" ]; then
        rivi "olemassa olevat sanastot: $loydetyt"
    else
        rivi "olemassa olevat sanastot: (ei yhtään)"
    fi

    if [ "$LISTAA" -eq 1 ]; then
        prefs="$(etsi_prefs "$prof")"
        rivi "Preferences: ${prefs:-(ei löydy)}"
        if syy="$(profiili_kaytossa "$prof")"; then
            rivi "tila: KÄYNNISSÄ ($syy)"
        else
            rivi "tila: ei käynnissä"
        fi
        echo
        continue
    fi

    kohde="$prof/Dictionaries/$BDIC_NIMI"

    # 1. sanastotiedosto
    if [ -e "$kohde" ] && [ "$FORCE" -eq 0 ]; then
        rivi "ohitetaan: $BDIC_NIMI on jo olemassa (--force ylikirjoittaa)"
    elif [ "$KUIVA" -eq 1 ]; then
        rivi "kopioisi: $SANASTO -> $kohde"
    else
        install -Dm644 "$SANASTO" "$kohde"
        rivi "$kohde"
    fi

    # 2. pref
    if [ "$TEE_PREF" -eq 0 ]; then
        rivi "--ei-pref: Preferences jätetään koskematta"
        rivi "HUOM: ilman spellcheck.dictionaries-merkintää sanastoa EI avata"
        echo
        continue
    fi

    prefs="$(etsi_prefs "$prof")"
    if [ -z "$prefs" ]; then
        rivi "Preferences ei löydy ($prof) — pref jää tekemättä"
        rivi "HUOM: ilman sitä sanastoa ei avata. Käynnistä sovellus kerran ja"
        rivi "      aja tämä uudelleen."
        echo
        continue
    fi

    if syy="$(profiili_kaytossa "$prof")"; then
        rivi "OHITETAAN PREF: sovellus on käynnissä ($syy)"
        rivi "Sovellus ylikirjoittaa Preferences-tiedoston lopettaessaan, joten"
        rivi "muutos katoaisi. Sulje $nimi ja aja tämä uudelleen."
        echo
        continue
    fi

    if pref_tarvitsee_muutosta "$prefs" "$KIELI"; then tarve=0; else tarve=$?; fi
    if [ "$tarve" -eq 2 ]; then
        rivi "OHITETAAN PREF: $prefs ei jäsenny JSONina"
        rivi "Tiedostoon ei kosketa. Sovellus kirjoittaa sen itse uudelleen"
        rivi "käynnistyessään — aja tämä sen jälkeen."
    elif [ "$tarve" -ne 0 ]; then
        rivi "$KIELI on jo spellcheck.dictionaries-listassa — Preferences ennallaan"
    elif [ "$KUIVA" -eq 1 ]; then
        rivi "kirjoittaisi spellcheck.dictionaries += $KIELI tiedostoon $prefs"
        rivi "(varmuuskopio $prefs.bak-<aikaleima>)"
    elif ! kirjoita_pref "$prefs" "$KIELI"; then
        # Sama peruste kuin yllä: yhden sovelluksen ongelma ei saa keskeyttää
        # muiden käsittelyä. Varmuuskopio on jo tehty ja jää talteen.
        rivi "VIRHE: Preferences-kirjoitus epäonnistui — jatketaan seuraavaan"
    fi
    echo
done

if [ "$KASITELTY" -eq 0 ]; then
    echo "yksikään annettu sovellus ei vastannut löytyneitä profiileja" >&2
    exit 2
fi

if [ "$LISTAA" -eq 1 ]; then
    say "Listaus valmis. Asennus: aja sama komento ilman --listaa."
    exit 0
fi

say "Valmis."
rivi "Sovelluksen on lisäksi pyydettävä suomea itse: Electron-sovellus voi"
rivi "asettaa oikolukukielet käynnistyessään session.setSpellCheckerLanguages()"
rivi "-kutsulla, jolloin se ylikirjoittaa tämän prefin. Silloin suomen saa"
rivi "käyttöön vain sovelluksen omista asetuksista, jos se tarjoaa ne."
rivi "Testi: kirjoita sovelluksessa tekstikenttään"
rivi "  maastopyörä     (ei saa alleviivautua)"
rivi "  maastopyöräz    (pitää alleviivautua)"
rivi "Jos oikoluku ei toimi, tiedostonimi voi olla väärä. Chromiumille oikean"
rivi "nimen selvittää tools/chromium-sanastonimi.sh; Electron-sovellukselle"
rivi "vastaavaa keinoa ei ole, koska useimmat eivät välitä --enable-logging-"
rivi "lippua eteenpäin. Kokeile silloin toista päätettä: --nimi $KIELI-4-0.bdic"
